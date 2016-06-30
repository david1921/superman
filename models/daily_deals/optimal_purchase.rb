module OptimalPurchase

  def handle_optimal_return(confirmation_number)
    self.daily_deal_payment ||= OptimalPayment.new
    self.daily_deal_payment.payment_gateway_receipt_id = confirmation_number
    self.daily_deal_payment.save!
  end
  
  def capture_optimal_payment_and_send_certificates!(profile_checkout_response)
    unless profile_checkout_response.payment_accepted?
      raise ArgumentError, "must be called with successful profile checkout response. got #{profile_checkout_response}"
    end
    
    txn_time = Time.parse(profile_checkout_response.txn_time)

    self.daily_deal_payment ||= OptimalPayment.create!(:daily_deal_purchase_id => self.id)
    self.daily_deal_payment.update_attributes :payment_at => txn_time,
                                              :amount => self.actual_purchase_price, 
                                              :payment_gateway_receipt_id => profile_checkout_response.confirmation_number,
                                              :credit_card_last_4 => profile_checkout_response.last_four_digits
    self.executed_at = txn_time
    set_payment_status! "captured"
  end

  def optimal_params(amount)
    { :merchant_ref_num => uuid,
      :confirmation_number => payment_gateway_receipt_id,
      :payment_at => payment_at,
      :amount => amount }
  end

  def optimal_payment_void_or_full_refund!(admin)
    raise "Payment not voidable or refundable" unless voidable_or_refundable?
    login = login_from_admin(admin)
    params = optimal_params(daily_deal_payment.amount)
    if optimal_voidable?(params)
      optimal_payment_void(login, params)
    elsif optimal_refundable?(params) && captured?
      optimal_payment_refund(login, params)
    else
      raise "Payment not voidable or refundable because of Optimal status."
    end
  end

  def optimal_partial_refund!(admin, partial_refund_amount)
    login = login_from_admin(admin)
    return unless voidable_or_refundable?
    params = optimal_params(partial_refund_amount)
    raise "Purchase cannot be partially refunded until midnight Eastern time on day of purchase." unless optimal_refundable?(params)
    optimal_payment_refund(login, params)
  end

  def optimal_refundable?(params)
    OptimalPayments::WebService.refundable?(params)
  end

  def optimal_voidable?(params)
    OptimalPayments::WebService.voidable?(params)
  end

  private

  def login_from_admin(admin)
    admin.respond_to?(:login) ? admin.login : admin
  end

  def optimal_payment_void(login, params)
    result = optimal_webservice_void(params)
    if result.success?
      self.daily_deal_payment.amount = 0
      self.refunded_at = Time.zone.now
      self.refunded_by = login
      self.daily_deal_payment.save!
      set_payment_status! "voided"
    else
      raise "Error Optimal Payment Void: #{result.error_message}"
    end
  end

  def optimal_payment_refund(login, params)
    result = optimal_webservice_refund(params)
    if result.success?
      self.refund_amount = refund_amount + params[:amount]
      self.refunded_at = Time.zone.now
      self.refunded_by = login
      self.daily_deal_payment.save!
      set_payment_status! "refunded"
    else
      raise "Error Optimal Payment Refund: #{result.error_message}"
    end
  end

  def optimal_webservice_void(params)
    OptimalPayments::WebService.void(params)
  end

  def optimal_webservice_refund(params)
    OptimalPayments::WebService.refund(params)
  end

end