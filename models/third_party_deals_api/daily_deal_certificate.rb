module ThirdPartyDealsApi
  
  module DailyDealCertificate
    
    def self.included(base)
      base.send :include, InstanceMethods
      base.extend ClassMethods
      
      base.validate :third_party_serial_flag_must_be_true_if_publisher_using_third_party_serials
      base.named_scope :generated_by_third_party, :conditions => "serial_number_generated_by_third_party = 1"
    end
    
    module InstanceMethods
      
      def skip_serial_number_uniqueness_check?
        serial_number_generated_by_third_party?
      end
      
      def third_party_serial_flag_must_be_true_if_publisher_using_third_party_serials
        if daily_deal_purchase.present? &&
           daily_deal_purchase.using_third_party_serial_numbers? &&
           !serial_number_generated_by_third_party?
          errors.add(:serial_number_generated_by_third_party, "%{attribute} must be true (this publisher uses third party serial numbers)")
        end
      end
      
    end
    
    module ClassMethods
      
    end
    
  end
  
end