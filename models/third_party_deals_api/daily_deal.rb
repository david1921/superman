module ThirdPartyDealsApi
  
  module DailyDeal
    
    def self.included(base)
      base.send :include, InstanceMethods
      base.extend ClassMethods
      base.validate :sold_out_via_third_party_must_be_nil_on_syndicated_deals
    end
    
    module InstanceMethods
      
      def sold_out_via_third_party_must_be_nil_on_syndicated_deals
        return unless syndicated?
        unless read_attribute(:sold_out_via_third_party).nil?
          errors.add(:sold_out_via_third_party, "%{attribute} must be nil (this value can only be set on the syndication source deal)")
        end
      end
      
      def using_internal_serial_numbers?
        !using_third_party_serial_numbers?
      end

      def using_third_party_serial_numbers?
        voucher_serial_numbers_url.present?
      end
      
      def voucher_serial_numbers_url
        syndicated? ? source.publisher.voucher_serial_numbers_url : publisher.voucher_serial_numbers_url
      end
      
      def voucher_status_request_url
        syndicated? ? source.publisher.voucher_status_request_url : publisher.voucher_status_request_url
      end
      
      def voucher_status_change_url
        syndicated? ? source.publisher.voucher_status_change_url : publisher.voucher_status_change_url
      end
      
      def sold_out_via_third_party?
        syndicated? ? source.sold_out_via_third_party? : read_attribute(:sold_out_via_third_party)
      end
      alias_method :sold_out_via_third_party, :sold_out_via_third_party?
      
      def sold_out_via_third_party!
        if syndicated?
          source.update_attributes! :sold_out_via_third_party => true
        else
          update_attributes! :sold_out_via_third_party => true
        end
      end
      
      def publisher_for_third_party_api_calls
        syndicated? ? source.publisher : publisher
      end
      
    end
    
    module ClassMethods
      
    end
    
  end
  
end
