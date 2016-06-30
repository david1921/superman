module Publishers

  module LoyaltyProgram

    def self.included(base)
      base.extend(ClassMethods)
      base.send :include, InstanceMethods
      base.validates_numericality_of :referrals_required_for_loyalty_credit_for_new_deals,
                                     :greater_than => 0, :if => :enable_loyalty_program_for_new_deals?,
                                     :message => "%{attribute} must be >= 1 when the loyalty program is enabled for new deals"
      # base.named_scope :with_loyalty_program_deals,
      #                  :conditions => "publishers.id = daily_deals.publisher_id AND daily_deals.enable_loyalty_program IS TRUE",
      #                  :joins => "INNER JOIN daily_deals ON daily_deals.publisher_id = publishers.id",
      #                  :order => "publishers.name ASC"
      base.named_scope :with_loyalty_program_deals,
                       :conditions => "publishers.id IN (SELECT publisher_id FROM daily_deals WHERE enable_loyalty_program IS TRUE)",
                       :order => "publishers.name ASC"
    end

    module ClassMethods
      
      def with_purchases_eligible_for_loyalty_refund
        DailyDealPurchase.eligible_for_loyalty_program_credit.map { |ddp| ddp.daily_deal.publisher }.uniq.sort_by(&:name)
      end
      
    end
    
    module InstanceMethods
      
      def purchases_eligible_for_loyalty_refund
        DailyDealPurchase.eligible_for_loyalty_program_credit(self)
      end
      
      def purchases_with_loyalty_referrals(dates)
        DailyDealPurchase.with_loyalty_program_referrals(dates, self)
      end

    end
    
  end
  
end