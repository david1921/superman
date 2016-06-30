module PaymentGateway
  class Error
    def self.list_from_braintree_result(result)
      Set.new(result.errors.map(&:message)).tap do |set|
        #
        # To avoid fraud, don't give precise reasons for failure due to AVS or CVV check, or processor declines.
        #
        if result.respond_to?(:credit_card_verification) && result.credit_card_verification.respond_to?(:status)
          if %w{ processor_declined gateway_rejected }.include?(result.credit_card_verification.status)
            set.add "The payment processor declined the transaction"
          end
        end
        if result.respond_to?(:transaction) && result.transaction.respond_to?(:status)
          if %w{ processor_declined gateway_rejected }.include?(result.transaction.status)
            set.add "The payment processor declined the transaction"
          end
        end
      end.to_a
    end
  end
end
