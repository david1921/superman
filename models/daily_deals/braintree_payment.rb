class BraintreePayment < DailyDealPayment

  with_options :if => Proc.new { |record| record.payment_gateway_id.present? } do |this|
    this.validates_presence_of :credit_card_last_4
    this.validates_format_of :credit_card_last_4, :with => /\A\d{4}\z/
  end

  # Getting the response from braintree redirect
  def self.new_from_braintree_transaction(purchase, braintree_transaction)
    braintree_payment = BraintreePayment.new( :daily_deal_purchase => purchase,
                          :payment_gateway_id => braintree_transaction.id,
                          :payment_at => braintree_transaction.created_at,
                          :amount => purchase.daily_deal_order_id ? purchase.total_price : braintree_transaction.amount,
                          :billing_first_name => braintree_transaction.billing_details.first_name,
                          :billing_last_name => braintree_transaction.billing_details.last_name,
                          :billing_address_line_1 => braintree_transaction.billing_details.street_address,
                          :billing_address_line_2 => braintree_transaction.billing_details.extended_address,
                          :billing_city => braintree_transaction.billing_details.locality,
                          :billing_state => braintree_transaction.billing_details.region,
                          :billing_country_code => braintree_transaction.billing_details.country_code_alpha2,
                          :payer_postal_code => braintree_transaction.billing_details.postal_code,
                          :name_on_card => braintree_transaction.credit_card_details.cardholder_name,
                          :credit_card_last_4 => braintree_transaction.credit_card_details.last_4,
                          :credit_card_bin => braintree_transaction.credit_card_details.bin )

    if braintree_transaction.respond_to?(:custom_fields) && braintree_transaction.custom_fields &&  braintree_transaction.custom_fields[:use_shipping_address_as_billing_address]
      braintree_payment.populate_billing_address_from_shipping_address
    end

    return braintree_payment
  end

  def void_or_full_refund!(admin)
    daily_deal_purchase.braintree_void_or_full_refund!(admin)
  end

  def partial_refund!(admin, partial_refund_amount)
    daily_deal_purchase.braintree_partial_refund!(admin, partial_refund_amount)
  end

  def refundable?
    daily_deal_purchase.braintree_refundable?
  end

  def submit_for_settlement!
    daily_deal_purchase.braintree_submit_for_settlement!
  end

end
