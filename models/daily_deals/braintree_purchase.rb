module BraintreePurchase
  class AlreadyExecutedError < RuntimeError
  end

  def braintree?
    daily_deal_payment instance_of? BraintreePayment
  end

  def submit_for_settlement!
    if daily_deal_payment.present?
      daily_deal_payment.submit_for_settlement!
    else
      settle_free_purchase
    end
  end

  def ready_for_settlement?
    authorized?
  end

  def settle_free_purchase
    if ready_for_settlement?
      set_payment_status! "captured"
      captured?
    end
  end

  def handle_braintree_sale!(braintree_transaction)
    where = "#{inspect}#handle_braintree_sale!(#{braintree_transaction.inspect})"

    unless Braintree::Transaction::Type::Sale == braintree_transaction.type
      raise "Expect txn type '#{Braintree::Transaction::Type::Sale}' in #{where}"
    end

    if !daily_deal_order_id && analog_purchase_id != braintree_transaction.order_id
      raise "Expect txn order_id '#{analog_purchase_id}' but had '#{braintree_transaction.order_id}' in:\n #{where}"
    end
    if !daily_deal_order_id && BigDecimal.new(total_price.to_s) != BigDecimal.new(braintree_transaction.amount.to_s)
      raise "Expect txn amount '#{total_price}' but was '#{braintree_transaction.amount}' in #{where}"
    end

    if !executed? || voided?
      braintree_execute! braintree_transaction
    else
      raise AlreadyExecutedError, "Purchase already executed in #{where}"
    end
  end

  def braintree_fake_execution!
    if Rails.env.production?
      raise RuntimeError, "method can't be called in production"
    end
    self.daily_deal_payment = BraintreePayment.new
    self.daily_deal_payment.payment_gateway_id = "fake_#{rand(1000000)}"
    self.daily_deal_payment.credit_card_last_4 = "0000"
    self.daily_deal_payment.payer_postal_code = "00000"
    self.daily_deal_payment.amount = 10
    self.daily_deal_payment.payment_at = Time.zone.now
    self.daily_deal_payment.save!
    set_payment_status! "captured"
  end

  def find_braintree_transaction!
    return nil unless payment_gateway_id.present?
    publisher.find_braintree_credentials!
    Braintree::Transaction.find(payment_gateway_id)
  end

  def find_payment_status_update_transaction!
    return nil unless payment_status_updated_by_txn_id.present?
    publisher.find_braintree_credentials!
    Braintree::Transaction.find(payment_status_updated_by_txn_id)
  end

  def braintree_void_or_full_refund!(admin)
    raise "Payment not voidable or refundable" unless voidable_or_refundable?
    prevent_production_entertainment_account_refund!
    
    braintree_transaction = find_braintree_transaction
    prevent_production_flagship_account_refund!(braintree_transaction)
    case braintree_transaction.status
      when Braintree::Transaction::Status::Authorized, Braintree::Transaction::Status::SubmittedForSettlement
        braintree_void_payment! admin, braintree_transaction
      when Braintree::Transaction::Status::Settled
        braintree_refund! admin, braintree_transaction
      else
        raise "Payment not voidable or refundable because of Braintree status"
    end
  end

  def braintree_partial_refund!(admin, partial_refund_amount)
    raise "Payment not voidable or refundable" unless voidable_or_refundable?
    prevent_production_entertainment_account_refund! partial_refund_amount
    
    braintree_transaction = find_braintree_transaction
    unless braintree_refundable?(braintree_transaction)
      raise "Not partially refundable because not settled in Braintree."
    end
    prevent_production_flagship_account_refund!(braintree_transaction)
    
    braintree_refund! admin, braintree_transaction, partial_refund_amount
  end

  def braintree_submit_for_settlement!
    if payment_gateway_id.present?
      publisher.find_braintree_credentials!
      result = Braintree::Transaction.submit_for_settlement(payment_gateway_id)
      if result.success?
        braintree_execute! result.transaction
      else
        logger.warn "WARNING: #{inspect}#submit_for_settlement: #{result.inspect}"
        true
      end
    end
  end

  def find_braintree_transaction
    publisher.find_braintree_credentials!
    Braintree::Transaction.find(payment_gateway_id)
  end

  def braintree_voidable?
    return false unless voidable_or_refundable?
    braintree_transaction = find_braintree_transaction
    braintree_transaction.status == Braintree::Transaction::Status::Authorized ||  braintree_transaction.status == Braintree::Transaction::Status::SubmittedForSettlement
  end

  def braintree_refundable?(braintree_transaction = nil)
    braintree_transaction ||= find_braintree_transaction
    braintree_transaction.status == Braintree::Transaction::Status::Settled
  end

  private
  
  def prevent_production_entertainment_account_refund!(amount = nil)
    #
    # Entertainment are closing their US Bank account and associated Braintree account.
    #
    if production_entertainment_refund?
      braintree_txn_id = daily_deal_payment.try(:payment_gateway_id)
      message = "Can't refund Entertainment Braintree transaction #{braintree_txn_id}"
      message += " for $#{'%.02f' % amount}" if amount
      raise message
    end
  end

  def production_entertainment_refund?
    #
    # The Braintree account may no longer exist, so we can't get transaction info.
    #
    Rails.env.production? && "entertainment" == publisher.publishing_group.try(:label)
  end

  def prevent_production_flagship_account_refund!(braintree_transaction)
    # FIXME: hack for dealing with closure of our Flagship merchant account.
    raise "Can't void or refund Flagship transactions" if production_flagship_refund?(braintree_transaction)
  end

  def production_flagship_refund?(braintree_transaction)
    Rails.env.production? && braintree_transaction.merchant_account_id.to_s.starts_with?("AnalogAnalytics")
  end
  #
  # Braintree handlers
  #
  def payment_status_from_braintree_transaction(braintree_transaction)
    case braintree_transaction.status
    when Braintree::Transaction::Status::Authorized
      "authorized"
    when Braintree::Transaction::Status::SubmittedForSettlement, Braintree::Transaction::Status::Settled
      "captured"
    when Braintree::Transaction::Status::Voided
      "voided"
    else
      logger.warn "WARNING: status ignored for #{braintree_transaction.inspect}"
      true
    end
  end

  def braintree_execute!(braintree_transaction)        
    new_payment_status = payment_status_from_braintree_transaction(braintree_transaction)    
    if payment_status != new_payment_status
      if (!executed? || (voided? && allow_execution?)) && %w{ authorized captured }.include?(new_payment_status)
        self.daily_deal_payment ||= BraintreePayment.new_from_braintree_transaction(self, braintree_transaction)
        daily_deal_payment.save!
        self.executed_at = braintree_transaction.created_at
      end
      self.payment_status_updated_by_txn_id = braintree_transaction.id
      set_payment_status! new_payment_status
      logger.info "#{inspect}#braintree_execute!(#{braintree_transaction.inspect}) completed"
    else
      logger.warn "WARNING: #{inspect}#braintree_execute!(#{braintree_transaction.inspect}) has no effect"
    end
    true
  end

  def braintree_void_payment!(admin, braintree_transaction)
    result = Braintree::Transaction.void(braintree_transaction.id)
    if result.success?
      self.daily_deal_payment.amount = 0.00
      self.refunded_at = Time.zone.now
      self.refunded_by = admin.login
      self.daily_deal_payment.save!
      set_payment_status! "voided"
    else
      raise "Error voiding Braintree TXN #{braintree_transaction.id}: #{result.errors}"
    end
  end

  def braintree_refund!(admin, braintree_transaction, partial_refund_amount = nil)
    result = if partial_refund_amount.present?
      Braintree::Transaction.refund(braintree_transaction.id, partial_refund_amount)
    else
      Braintree::Transaction.refund(braintree_transaction.id)
    end

    if result.success?
      self.payment_status_updated_by_txn_id = result.transaction.id
      self.refund_amount += result.transaction.amount
      self.refunded_at = Time.zone.now
      self.refunded_by = admin.login
      self.daily_deal_payment.save!
      set_payment_status! "refunded"
    else
      raise "Error refunding Braintree TXN #{braintree_transaction.id}: #{format_braintree_errors(result.errors)}"
    end
  end

  private
  
  def format_braintree_errors(bt_errors)
    return bt_errors unless bt_errors.is_a?(Braintree::Errors)
    bt_errors.map { |e| "[#{e.code}] #{e.message}" }.join(" ")
  end
  
end
