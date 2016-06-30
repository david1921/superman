module DailyDeals
  
  module LoyaltyProgram
    
    def self.included(base)
      base.send :include, InstanceMethods
      base.class_eval do
        validates_numericality_of :referrals_required_for_loyalty_credit, :greater_than => 0, :if => :enable_loyalty_program?,
                                  :message => "%{attribute} must be >= 1 when the loyalty program is enabled"
      end
    end
    
    module InstanceMethods
      
      def set_enable_loyalty_program_from_publisher_default
        self.enable_loyalty_program = publisher.enable_loyalty_program_for_new_deals
        return true
      end
      
      def set_loyalty_program_defaults_for_new_deals_from_publisher
        return unless publisher
        self.enable_loyalty_program = publisher.enable_loyalty_program_for_new_deals
        self.referrals_required_for_loyalty_credit = publisher.referrals_required_for_loyalty_credit_for_new_deals
      end
      
      def set_referrals_required_for_loyalty_credit_from_publisher_default
        self.referrals_required_for_loyalty_credit = publisher.referrals_required_for_loyalty_credit_for_new_deals
        return true
      end

    end
    
  end
  
end