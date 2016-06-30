module PaypalPurchase

  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods
    #
    # Methods for use with PayPal
    #

    def handle_buy_now(ipn_params)
      daily_deal_payment = PaypalPayment.find_or_create_by_paypal_notification(ipn_params)
      unless daily_deal_purchase = daily_deal_payment.try(:daily_deal_purchase)
        raise "IPN invoice number #{ipn_params['invoice']} doesn't match a daily deal purchase"
      end
      daily_deal_purchase.send(:buy_now, daily_deal_payment, ipn_params)
    end

    def handle_chargeback(ipn_params)
      find_and_save_with_payment_status! "reversed", ipn_params
    end

    def handle_chargeback_reversal(ipn_params)
      find_and_save_with_payment_status! "captured", ipn_params
    end

    def handle_refund(ipn_params)
      find_and_save_with_payment_status! "refunded", ipn_params
    end

    def find_from_ipn_params(ipn_params)
      #
      # For chargeback and chargeback-reversed IPNs, the txn_id is the transaction number of the
      # chargeback/reversed case and the parent_txn_id is the txn_id of the original payment IPN.
      #
      payment = DailyDealPayment.find_by_payment_gateway_id(ipn_params["txn_id"])
      payment ||= DailyDealPayment.find_by_payment_gateway_id(ipn_params["parent_txn_id"])
      payment.daily_deal_purchase
    end

    def find_and_save_with_payment_status!(payment_status, ipn_params)
      if (daily_deal_purchase = find_from_ipn_params(ipn_params))
        daily_deal_purchase.send(:save_with_payment_status!, payment_status, ipn_params)
      else
        raise "can't find daily deal purchase matching IPN #{ipn_params['txn_id']}"
      end
    end

  end

  module InstanceMethods

    def paypal_item
      "%d-BBD" % daily_deal.id
    end

    def save_with_payment_status!(payment_status, ipn_params)
        self.payment_status_updated_by_txn_id = ipn_params['txn_id']
        set_payment_status! payment_status
    end

    def buy_now(payment, params)
      where = "#{inspect}#buy_now(#{params.inspect})"
      payment.payment_at = DateTime.strptime(params["payment_date"], "%H:%M:%S %b %d, %Y %Z").utc
      payment.payment_gateway_id = params["txn_id"]
      payment.payment_gateway_receipt_id = params["receipt_id"]
      # NOTE: payment_gross is for USD only payments, see https://cms.paypal.com/us/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_html_IPNandPDTVariables
      # under mc_gross variable.
      payment.amount = params["payment_gross"].present? ? params["payment_gross"] : params["mc_gross"]
      payment.payer_email = params["payer_email"]
      payment.payer_status = params["payer_status"]
      payment.payer_status = params["payer_status"]
      payment.billing_first_name = params["first_name"]
      payment.billing_last_name = params["last_name"]
      payment.billing_address_line_1 = params["address_street"]
      payment.billing_city = params["address_city"]
      payment.billing_state = params["address_state"]
      payment.payer_postal_code = params["address_zip"]
      payment.billing_country_code = params["address_country_code"]

      payment.save!


      #
      # Workaround for bad BigDecimal comparison in our production Ruby (ruby 1.8.6 (2007-09-23 patchlevel 110))
      #
      unless BigDecimal.new(total_price.to_s) == BigDecimal.new(payment.amount.to_s)
        raise "Expect txn amount '#{BigDecimal.new(total_price.to_s)}' in #{where}"
      end

      self.executed_at = payment.payment_at
      self.payment_status_updated_by_txn_id = params['txn_id']
      set_payment_status! "captured"
    end

  end

end