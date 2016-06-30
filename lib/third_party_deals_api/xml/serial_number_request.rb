module ThirdPartyDealsApi
  module XML
    class SerialNumberRequest

      def initialize(daily_deal_purchase)
        @daily_deal_purchase = daily_deal_purchase
      end

      def create_serial_number_request_xml
        %Q{\
<?xml version="1.0" encoding="UTF-8"?>
<serial_number_request listing="#{@daily_deal_purchase.daily_deal.listing}" purchase_id="#{ @daily_deal_purchase.uuid }" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
  <purchaser_name>#{@daily_deal_purchase.consumer.name}</purchaser_name>
  <recipient_names>
    #{ generate_recipient_names }
  </recipient_names>
  <location>
    <listing>#{@daily_deal_purchase.store.try(:listing)}</listing>
  </location>
  <quantity>#{@daily_deal_purchase.quantity}</quantity>
</serial_number_request>}
      end

      private
      
      def generate_recipient_names
        if @daily_deal_purchase.gift?
          @daily_deal_purchase.recipient_names.map { |rn| "<recipient_name>#{rn}</recipient_name>" }
        else
          "<recipient_name>#{@daily_deal_purchase.consumer.name}</recipient_name>" * @daily_deal_purchase.quantity
        end
      end

    end
  end
end
