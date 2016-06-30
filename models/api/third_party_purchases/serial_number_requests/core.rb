module Api::ThirdPartyPurchases::SerialNumberRequests::Core

  def execute
    if valid?
      create_and_capture_purchase
    end
  end

  def success?
    purchase_persisted?
  end

  def vouchers
    daily_deal_certificates
  end

  def deal_qty_remaining
    remaining_deal_qty_with_zero_minimum
  end

  def deal_sold_out?
    deal_qty_remaining && deal_qty_remaining <= 0
  end

  def requested_qty
    num_xml_voucher_requests
  end


  private

  def xml_data
    HashWithIndifferentAccess.new(Hash.from_xml(@xml)['daily_deal_purchase'] || {})
  end

  def attributes_from_xml
    data = xml_data
    voucher_requests = voucher_requests_from_xml_data(xml_data)
    {
        :uuid => data['uuid'],
        :executed_at => data['executed_at'],
        :gross_price => data['gross_price'],
        :actual_purchase_price => data['actual_purchase_price'],
        :daily_deal_id => daily_deal ? daily_deal.id : nil,
        :store_id => @store ? @store.id : nil,
        :recipient_names => sort_voucher_requests_by_sequence(voucher_requests),
        :quantity => voucher_requests.size,
        :api_user => @user
    }
  end

  def find_daily_deal_by_listing(listing)
    DailyDeal.find_by_listing(listing)
  end

  def find_store_by_listing(listing)
    Store.find_by_listing(listing)
  end

  def purchase_errors(purchase)
    purchase ? purchase.errors.inject({}) { |s, e| s[e[0]] = e[1]; s } : {}
  end

  def create_and_capture_purchase
    @purchase = purchase_from_attrs(attributes_from_xml).tap do |purchase|
      if purchase.save
        purchase.capture!
      end
    end
  end

  def purchase_from_attrs(attrs)
    OffPlatformDailyDealPurchase.new.tap do |purchase|
      # Mass assignment protection forces us to do this
      attrs.each do |k, v|
        purchase.send("#{k}=", v)
      end
    end
  end

  def purchase_persisted?
    purchase && !purchase.new_record?
  end

  def daily_deal_certificates
    purchase ? purchase.daily_deal_certificates : []
  end

  def remaining_deal_qty_with_zero_minimum
    qty = daily_deal.try(:number_left)
    if qty
      qty < 0 ? 0 : qty
    else
      nil
    end
  end

  def set_doc_from_xml
    @doc = Nokogiri::XML(@xml)
  end

  def num_xml_voucher_requests
    @doc.search('voucher_request').size
  end

  def voucher_requests_from_xml_data(data)
    [data['voucher_requests']['voucher_request']].flatten
  end

  def sort_voucher_requests_by_sequence(voucher_requests)
    voucher_requests.sort { |a, b| (a['sequence'].to_i || 1) <=> (b['sequence'].to_i || 1) }.collect { |r| r['redeemer_name'] }
  end
end