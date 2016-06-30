module ThirdPartyDealsApi
  module XML
    class VoucherStatusRequest

      include Helper

      def initialize(daily_deal_purchase)
        @daily_deal_purchase = daily_deal_purchase
      end

      def create_voucher_status_request
        result = ""
        xml = Builder::XmlMarkup.new(:target => result)
        xml.instruct! :xml, :version => '1.0'
        xml.voucher_status_request(purchase_root_node_attributes) do
          @daily_deal_purchase.daily_deal_certificates.each do |daily_deal_certificate|
            xml.serial_number daily_deal_certificate.serial_number
          end
        end
        result
      end

    end
  end
end