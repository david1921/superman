class PaypalPayment < DailyDealPayment

  def self.find_or_create_by_paypal_notification(ipn_params)
    ipn_params = (ipn_params||{}).with_indifferent_access
    PaypalPayment.find_by_analog_purchase_id(ipn_params[:invoice]) || create_with_paypal_notification(ipn_params)
  end

  def self.create_with_paypal_notification(ipn_params)
    invoice = ipn_params[:invoice]
    raise RuntimeError, "[ERROR] Unable to find invoice number in IPN request." unless invoice
    daily_deal_purchase_id = invoice.match(/[0-9]+/).to_s
    daily_deal_purchase = DailyDealPurchase.find_by_id(daily_deal_purchase_id)
    raise RuntimeError, "[ERROR] Unable to find daily deal purchase for invoice '#{daily_deal_purchase_id}' associated with IPN (paypal)" unless daily_deal_purchase
    PaypalPayment.create({
      :analog_purchase_id => invoice,
      :daily_deal_purchase => daily_deal_purchase,
      :payer_email => ipn_params[:payer_email],
      :payment_gateway_id => ipn_params[:txn_id]
    })
  end

  def void_or_full_refund!(admin)
    raise NotImplementedError, "void_or_full_refund! isn't implemented yet for PaypalPayment"
  end

  def partial_refund!(admin, partial_refund_amount)
    raise NotImplementedError, "partial_refund! isn't implement yet for PaypalPayment"
  end

  def refundable?
    raise NotImplementedError, "refundable? isn't implement yet for PaypalPayment"
  end

  def submit_for_settlement!
    raise NotImplementedError, "submit_for_settlement! isn't implement yet for PaypalPayment"
  end

end