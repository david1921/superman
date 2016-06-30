module DailyDealPurchases::Core

  def set_attributes_if_pending(params)
    return unless pending?
    #
    # The only attributes we allow the consumer to update, and only before the purchase is complete.
    #
    params.symbolize_keys.slice(
      :quantity,
      :gift,
      :recipient_names,
      :store_id,
      :discount_code,
      :discount_uuid,
      :post_to_facebook,
      :credit_used,
      :donation_name,
      :donation_city,
      :donation_state,
      :device,
      :made_via_qr_code,
      :fulfillment_method
    ).each { |key, val| send "#{key}=", val }

    if params[:recipients_attributes]
      self.recipients_attributes = params[:recipients_attributes]
      self.recipient_names = recipients.map(&:name)
    end

    if params[:mailing_address_attributes]
      build_mailing_address(params[:mailing_address_attributes])
    end

    if params[:fulfillment_method]
      set_voucher_shipping_amount(params[:fulfillment_method])
    end

    if params[:daily_deal_variation_id]
      set_daily_variation_id(params[:daily_deal_variation_id])
    end

  end

  def set_voucher_shipping_amount(fulfillment_method)
    if fulfillment_method == 'ship' && daily_deal.try(:publisher).try(:allow_voucher_shipping)
      self.voucher_shipping_amount = daily_deal.publisher.voucher_shipping_fee
    else
      self.voucher_shipping_amount = nil
    end
  end

  def expected_number_of_recipients
    gift? ? gift_expected_number_of_recipients : 1
  end

  def gift_expected_number_of_recipients
    quantity * certificates_to_generate_per_unit_quantity
  end

  # only set the variation id if the associated publisher
  # is enabled for daily deal variations and if the variation
  # id is associated with the associated daily deal.
  def set_daily_variation_id(variation_id)
    return unless publisher && publisher.enable_daily_deal_variations?
    return unless daily_deal
    variation = daily_deal.daily_deal_variations.find_by_id(variation_id)
    self.daily_deal_variation = variation if variation
  end

  def travelsavers_product_code
    daily_deal_variation ? daily_deal_variation.travelsavers_product_code : daily_deal.travelsavers_product_code
  end
end