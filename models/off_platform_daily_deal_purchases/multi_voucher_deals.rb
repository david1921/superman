module OffPlatformDailyDealPurchases
  
  module MultiVoucherDeals
    
    def self.included(base)
      base.send :include, InstanceMethods
      base.extend ClassMethods
      base.validate :deal_must_have_certificates_to_generate_per_unit_quantity_equal_to_1
    end
    
    module InstanceMethods
      
      def deal_must_have_certificates_to_generate_per_unit_quantity_equal_to_1
        unless daily_deal.certificates_to_generate_per_unit_quantity == 1
          errors.add(:daily_deal, "%{attribute} must have a certificates_to_generate_per_unit_quantity of 1, but is #{daily_deal.certificates_to_generate_per_unit_quantity}")
        end
      end
      
    end
    
    module ClassMethods
      
    end
    
  end
  
end