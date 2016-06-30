module ThirdPartyDealsApi
  
  module DailyDealPurchase
    
    def self.included(base)
      base.send :include, InstanceMethods
      base.delegate :publisher_for_third_party_api_calls, :using_internal_serial_numbers?, :using_third_party_serial_numbers?, :to => :daily_deal
    end
    
    module InstanceMethods

      def sync_voucher_status_with_third_party!
        return unless has_vouchers_generated_by_third_party?
        status_response = get_third_party_voucher_status_response!
        daily_deal_certificates.each do |cert|
          new_status = status_response.status_from_response!(cert)
          if new_status == "redeemed"
            cert.status = new_status
            cert.save!
          end
        end
      end
      
      def has_vouchers_generated_by_third_party?
        daily_deal_certificates.generated_by_third_party.present?
      end

      def send_third_party_voucher_change_notification_as_needed!
        return unless has_vouchers_generated_by_third_party?
        
        # Need to reload self, to ensure the associated daily_deal_certificates have
        # the most up-to-date statuses.
        reload
        
        raw_response, log_entry = publisher_for_third_party_api_calls.third_party_deals_api_post(
          daily_deal.voucher_status_change_url,
          XML::VoucherStatusChangeNotification.new(self).create_voucher_status_change_notification,
          :api_name => "third_party_deals",
          :api_activity_label => "voucher_status_change",
          :loggable => self)
          
        voucher_status_response = XML::VoucherStatusResponse.new(self, raw_response.body)
        unless voucher_status_response.valid_and_internal_statuses_match_external_statuses?
          log_entry.update_attributes :internal_status_message => voucher_status_response.error_messages_with_xml
          raise ThirdPartyDealsApi::XML::InvalidVoucherStatusResponse, voucher_status_response.error_messages_with_xml
        end
        voucher_status_response
      end

      def get_third_party_voucher_status_response!
        raw_response, log_entry = publisher_for_third_party_api_calls.third_party_deals_api_post(
          daily_deal.voucher_status_request_url,
          XML::VoucherStatusRequest.new(self).create_voucher_status_request,
          :api_name => "third_party_deals",
          :api_activity_label => "voucher_status_request",
          :loggable => self)
        XML::VoucherStatusResponse.new(self, raw_response.body)
      end

      def get_third_party_serial_numbers_and_possibly_mark_deal_soldout!
        unless daily_deal.using_third_party_serial_numbers?
          raise "can't request third party serial numbers. this publisher uses internal serial numbers"
        end
        
        serial_number_response, log_entry = publisher_for_third_party_api_calls.third_party_deals_api_post(
          daily_deal.voucher_serial_numbers_url,
          XML::SerialNumberRequest.new(self).create_serial_number_request_xml,
          :api_name => "third_party_deals",
          :api_activity_label => "serial_number_request",
          :loggable => self)
      
        serial_number_response = XML::SerialNumberResponse.new(self, serial_number_response.body)
        if serial_number_response.sold_out_status_present? || serial_number_response.deal_force_closed_status_present?
          daily_deal.sold_out_via_third_party!
        end
        if serial_number_response.deal_force_closed_status_present?
          raise ThirdPartyDealsApi::DealForceClosed,
                "this deal was closed by the third party deal provider. " +
                "deal ID: #{daily_deal.id}. consumer email: #{consumer.email}"
        end

        unless serial_number_response.valid?
          log_entry.update_attributes :internal_status_message => serial_number_response.error_messages_with_xml
          raise ThirdPartyDealsApi::XML::InvalidSerialNumberResponse, serial_number_response.error_messages_with_xml
        end
        serial_number_response
      end

    end

  end
  
end