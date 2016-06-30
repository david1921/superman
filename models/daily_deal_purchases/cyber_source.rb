module DailyDealPurchases
  module CyberSource
    def self.included(base)
      base.send :attr_reader, :previously_executed
      base.send :include, InstanceMethods
    end
    
    module InstanceMethods
      def cyber_source_order_type
        "sale"
      end
      
      def cyber_source_order_number
        analog_purchase_id
      end
      
      def cyber_source_order_amount
        "%.2f" % total_price
      end
      
      def cyber_source_order_currency
        currency_code.downcase
      end

      def cyber_source_card_types
        ::CyberSource::Order::CARD_CODE_FROM_TYPE.keys
      end
      
      def cyber_source_merchant_reference(order = nil)
        timestamp = order.try(:created_at) || Time.now
        "#{cyber_source_order_number}-#{timestamp.utc.to_formatted_s(:number)}"
      end
      
      def cyber_source_credentials
        options = daily_deal_payment.present? ? { :time => daily_deal_payment.payment_at } : {}
        publisher.cyber_source_credentials(options)
      end
      
      def handle_cyber_source_sale!(order)
        check_cyber_source_sale order, :type
        check_cyber_source_sale order, :amount
        check_cyber_source_sale order, :currency

        if cyber_source_executable?
          cyber_source_execute! order
        else
          @previously_executed = true
        end
      end
      
      def cyber_source_void_or_full_refund!(admin)
        raise "Purchase #{id} is not in a voidable or refundable state" unless cyber_source_voidable? || cyber_source_refundable?

        begin
          cyber_source_void! admin if cyber_source_voidable?
        rescue ::CyberSource::Gateway::Error => e
          Rails.logger.warn "Failed to void purchase #{id} via CyberSource: #{e}"
        end
        
        unless voided?
          cyber_source_refund! admin if cyber_source_refundable?
        end
      end
      
      def cyber_source_partial_refund!(admin, partial_amount)
        raise "Purchase #{id} is not in a refundable state" unless cyber_source_refundable?
        cyber_source_refund! admin, partial_amount
      end
      
      def executed_by_cyber_source_order?(cyber_source_order)
        CyberSourcePayment === daily_deal_payment && daily_deal_payment.from_order?(cyber_source_order)
      end

      private
      
      def check_cyber_source_sale(order, attr)
        want_value = send("cyber_source_order_#{attr}")
        have_value = order.send(attr)
        raise "Expect order #{attr} '#{want_value}' but have '#{have_value}' in #{order} for #{inspect}" unless want_value == have_value
      end
      
      def cyber_source_executable?
        !executed? || (voided? && allow_execution?)
      end
      
      def cyber_source_voidable?
        captured?
      end

      def cyber_source_refundable?
        captured? || partially_refunded?
      end

      def cyber_source_execute!(order)
        self.daily_deal_payment ||= create_cyber_source_payment!(
          :daily_deal_purchase => self,
          :payment_gateway_id => order.request_id,
          :payment_gateway_receipt_id => order.reconciliation_id,
          :payment_at => order.authorized_at,
          :amount => order.amount,
          :credit_card_last_4 => order.card_last_4,
          :payer_postal_code => order.billing_postal_code,
          :payer_status => order.decision,
          :name_on_card => "#{order.billing_first_name} #{order.billing_last_name}",
          :billing_first_name => order.billing_first_name,
          :billing_last_name => order.billing_last_name,
          :billing_address_line_1 => order.billing_address_line_1,
          :billing_address_line_2 => order.billing_address_line_2,
          :billing_city => order.billing_city,
          :billing_state => order.billing_state,
          :billing_country_code => order.billing_country,
          :credit_card_bin => order.credit_card_bin
        )

        self.executed_at = order.authorized_at
        self.payment_status_updated_by_txn_id = order.request_id
        set_payment_status! "captured"
      end
      
      def cyber_source_void!(admin)
        ::CyberSource::Gateway.void(cyber_source_credentials, payment_gateway_id, cyber_source_merchant_reference)
        self.daily_deal_payment.amount = 0.00
        self.daily_deal_payment.save!
        
        self.refunded_at = Time.zone.now
        self.refunded_by = admin.login
        set_payment_status! "voided"
      end
      
      def cyber_source_refund!(admin, partial_amount = nil)
        remaining = actual_purchase_price - refund_amount
        amount = partial_amount || remaining
        raise "Can't refund #{'%.02f' % amount} for purchase #{id} with #{'%.02f' % remaining} remaining" unless remaining >= amount
        
        currency = cyber_source_order_currency
        reference = cyber_source_merchant_reference

        options = publisher.cyber_source_credit_options(self) || {}
        options.to_options!
        
        credit = ::CyberSource::Gateway.credit(cyber_source_credentials, payment_gateway_id, amount, currency, reference, options)
        
        self.payment_status_updated_by_txn_id = credit.request_id
        self.refund_amount += amount
        self.refunded_at = credit.created_at
        self.refunded_by = admin.login
        set_payment_status! "refunded"
      end
    end

    def create_cyber_source_payment!(*attrs)
      CyberSourcePayment.create!(*attrs)
    end

    def notify_exceptional(msg)
      Exceptional.handle(Exception.new(msg))
    end
  end
end
