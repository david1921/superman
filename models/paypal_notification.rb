class PaypalNotification < Paypal::Notification
  def dispatch!
    if type =~ /subscr_(cancel|eot|failed|modify|signup)/
      PaypalSubscriptionNotification.handle_ipn(params)
    else
      case status
        when /completed/i        : handle_purchase
        when /reversed/i         : handle_chargeback
        when /canceled_reversal/i: handle_chargeback_reversal
        when /refunded/i         : handle_refund
        else Rails.logger.warn "IPN #{transaction_id}: payment_status '#{status}' ignored"
      end
    end
  end
  
  private

  def handle_purchase
    if type =~ /web_accept/i
      handler_class.handle_buy_now(params)
    elsif type == "cart"
      if handler_class.respond_to?(:handle_shopping_cart_purchase)
        handler_class.handle_shopping_cart_purchase(params)
      else
        Rails.logger.warn "IPN #{transaction_id}: #{handler_class} doesn't know how to handle shopping " +
                          "cart purchases. Details of this transaction will not be stored in the database!"
      end
    else
      Rails.logger.warn "IPN #{transaction_id}: purchase txn_type '#{type}' ignored"
    end
  end

  def handle_chargeback
    handler_class.handle_chargeback(params)
  end

  def handle_chargeback_reversal
    handler_class.handle_chargeback_reversal(params)
  end

  def handle_refund
    handler_class.handle_refund(params)
  end

  def handler_class
    begin
      params['custom'].to_s.downcase.camelize.constantize
    rescue
      raise %Q(No handler matches IPN custom type '#{params["custom"]}')
    end
  end
end
