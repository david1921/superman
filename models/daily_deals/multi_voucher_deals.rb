module DailyDeals
  
  module MultiVoucherDeals
    
    def self.included(base)
      base.send :include, InstanceMethods
      base.extend(ClassMethods)
      base.validate :certificates_to_generate_per_unit_quantity_cant_be_changed_after_purchases_made
      base.validates_numericality_of :certificates_to_generate_per_unit_quantity, :greater_than_or_equal_to => 1
    end
    
    module ClassMethods
      
    end
    
    module InstanceMethods

      def certificates_to_generate_per_unit_quantity_cant_be_changed_after_purchases_made
        if certificates_to_generate_per_unit_quantity_changed? && daily_deal_purchases.present?
          errors.add(:certificates_to_generate_per_unit_quantity, "%{attribute} cannot be changed after a purchase has been made")
        end
      end
      
      def certificates_to_generate_per_unit_quantity_can_be_edited?
        not (bar_coded? || syndicated? || daily_deal_purchases.present?)
      end
      
    end
    
  end
  
end