module CyberSource
  module Context
    class Decline < CyberSource::Context::Base
      def call
        raise "Unexpected call to CyberSource decline context with successful order: #{self}, #{@cyber_source_order}" if @cyber_source_order.success?
        create_gateway_result
        
        @cyber_source_order.clear_card_attributes
        [@daily_deal_purchase, @cyber_source_order]
      end
      
      private

      def create_gateway_result
        messages = @cyber_source_order.error_messages.join(", ")
        CyberSourceGatewayResult.create :daily_deal_purchase => @daily_deal_purchase, :error => true, :error_message => messages
        Rails.logger.warn "No error messages for CyberSource order #{@cyber_source_order}" unless messages.present?
      end
    end
  end
end
