require File.dirname(__FILE__) + "/../../test_helper"

# hydra class LoyaltyProgram::DailyDealTest

module LoyaltyProgram
  
  class DailyDealTest < ActiveSupport::TestCase
    
    context "daily deal validation and the loyalty program" do
      
      setup do
        @daily_deal = Factory :daily_deal
      end
      
      should "require referrals_required_for_loyalty_credit to be >= 1 when DailyDeal#enable_loyalty_program is true" do
        assert !@daily_deal.enable_loyalty_program?
        assert @daily_deal.referrals_required_for_loyalty_credit.blank?
        assert @daily_deal.valid?
        
        @daily_deal.enable_loyalty_program = true
        assert @daily_deal.invalid?
        assert_equal "Referrals required for loyalty credit must be >= 1 when the loyalty program is enabled", @daily_deal.errors.on(:referrals_required_for_loyalty_credit)

        @daily_deal.referrals_required_for_loyalty_credit = 0
        assert @daily_deal.invalid?
        assert_equal "Referrals required for loyalty credit must be >= 1 when the loyalty program is enabled", @daily_deal.errors.on(:referrals_required_for_loyalty_credit)
        
        @daily_deal.referrals_required_for_loyalty_credit = 1
        assert @daily_deal.valid?
      end
      
    end
    
  end
  
end