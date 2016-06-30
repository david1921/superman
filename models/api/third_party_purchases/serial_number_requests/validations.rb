module Api::ThirdPartyPurchases::SerialNumberRequests::Validations

  include Api::ThirdPartyPurchases::SerialNumberRequests::Xml::Validations

  def validate_xml
    validate_xml_root(@doc)
    validate_xml_uuid(@doc)
    validate_xml_purchase_elements(@doc)
  end

  def validate_daily_deal_listing
    if valid_xml?
      listing = xml_data[:daily_deal_listing]
      if listing.present?
        @daily_deal = find_daily_deal_by_listing(listing)
        errors.add(:daily_deal_listing, "unknown daily deal listing") unless @daily_deal
      end
    end
  end

  def validate_store
    if valid_xml?
      listing_xml = xml_data[:location_listing]
      if listing_xml
        @store = find_store_by_listing(listing_xml)
        errors.add(:location_listing, "unknown location") unless @store
      end
    end
  end

  def validate_deal_availability
    if insufficient_deal_qty?
      errors.add(:availability, "%{attribute} is of an insufficient quantity")
    end
  end

  def validate_executed_at
    if valid_xml?
      executed_at = xml_data[:executed_at]
      begin
        Time.parse(executed_at)
      rescue
        errors.add(:xml, "executed_at was not a valid iso8601 time string")
      end
    end
  end


  private

  def valid_xml?
    !errors.invalid?(:xml)
  end

  def insufficient_deal_qty?
    requested = requested_qty
    remaining = deal_qty_remaining
    requested && remaining && (requested > remaining)
  end

end
