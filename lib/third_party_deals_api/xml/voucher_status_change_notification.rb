module ThirdPartyDealsApi
  module XML
    class VoucherStatusChangeNotification

      include Helper

      def initialize(daily_deal_purchase)
        @daily_deal_purchase = daily_deal_purchase
      end

      def create_voucher_status_change_notification
        result = ""
        xml = Builder::XmlMarkup.new(:target => result)
        xml.instruct! :xml, :version => '1.0'
        xml.voucher_status_change(purchase_root_node_attributes) do
          @daily_deal_purchase.daily_deal_certificates.each do |daily_deal_certificate|
            xml.status(translate_status_from_internal_to_external(daily_deal_certificate.status), :serial_number => daily_deal_certificate.serial_number)
          end
        end
        result
      end
      
      # We could easily move this logic into ThirdPartyDealsApi::Publisher later
      # if this conversion should become pub-specific.
      def translate_status_from_internal_to_external(status)
        status.downcase == "voided" ? "refunded" : status
      end

    end
  end
end