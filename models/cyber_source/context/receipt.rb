module CyberSource
  module Context
    class Receipt < CyberSource::Context::Base
      def call
        raise "Unexpected call to CyberSource receipt context with failed order: #{self}, #{@cyber_source_order}" if @cyber_source_order.failure?
        create_gateway_result
        
        @daily_deal_purchase.handle_cyber_source_sale! @cyber_source_order
        if @daily_deal_purchase.previously_executed
          void_duplicate_sale
        end
        [@daily_deal_purchase, @cyber_source_order]
      end
      
      private
      
      def create_gateway_result
        CyberSourceGatewayResult.create :daily_deal_purchase => @daily_deal_purchase, :error => false
      end
      
      def void_duplicate_sale
        unless @daily_deal_purchase.executed_by_cyber_source_order?(@cyber_source_order)
          merchant_reference = @daily_deal_purchase.cyber_source_merchant_reference(@cyber_source_order)
          CyberSource::Gateway.void @cyber_source_credentials, @cyber_source_order.request_id, merchant_reference
        end
      rescue CyberSource::Gateway::Error => e
        raise "Failed to void duplicate sale for purchase #{@daily_deal_purchase.id} via CyberSource: #{e}"
      end
    end
  end
end
