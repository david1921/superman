module DailyDealPurchases
  module Braintree
    def handle_braintree_redirect
      @publisher.find_braintree_credentials!
      begin
        @result = ::Braintree::TransparentRedirect.confirm(request.query_string)
      rescue ::Braintree::NotFoundError
        #
        # Probably a client reload of the transparent-redirect URL after it was already processed.
        #
        return :already_executed
      end
      if @result.success?
        BraintreeGatewayResult.create :daily_deal_purchase => @daily_deal_purchase, :error => false
        braintree_transaction = @result.transaction
        begin
          @daily_deal_purchase.handle_braintree_sale! braintree_transaction
          if braintree_transaction.credit_card_details.token.present?
            consumer = @daily_deal_purchase.consumer
            consumer.check_vault_id!(braintree_transaction.customer_details.id)
            consumer.create_or_update_credit_card(braintree_transaction.credit_card_details, braintree_transaction.billing_details)
          end
        rescue DailyDealPurchase::AlreadyExecutedError => error
          #
          # Probably a resubmission of the credit-card form for an already executed purchase.
          #
          logger.warn error
          void_duplicate_braintree_transaction braintree_transaction
          @result = nil
          return :already_executed
        end
        if @daily_deal_purchase.executed?
          return :success
        end
      else
        BraintreeGatewayResult.create :daily_deal_purchase => @daily_deal_purchase, :error => true, :error_message => @result.message
      end
      return :failure
    end
    
    private
    
    def void_duplicate_braintree_transaction(braintree_transaction)
      unless braintree_transaction.id == @daily_deal_purchase.payment_gateway_id
        result = ::Braintree::Transaction.void(braintree_transaction.id)
        if result.success?
          logger.info "Braintree TXN #{braintree_transaction.id} voided"
        else
          logger.warn "Error voiding Braintree TXN #{braintree_transaction.id}: #{result.errors}"
        end
      end
    end
  end
end
