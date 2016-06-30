require File.dirname(__FILE__) + "/../../test_helper"

# hydra class LoyaltyProgram::PublisherTest

module LoyaltyProgram
  
  class PublisherTest < ActiveSupport::TestCase

    def setup
      @publisher = Factory :publisher
    end
    
    context "loyalty field validation" do
      
      should "require referrals_required_for_loyalty_credit_for_new_deals to be >= when enable_loyalty_program_for_new_deals is true" do
        assert !@publisher.enable_loyalty_program_for_new_deals?
        assert @publisher.referrals_required_for_loyalty_credit_for_new_deals.blank?
        assert @publisher.valid?
        
        @publisher.enable_loyalty_program_for_new_deals = true
        assert @publisher.invalid?
        assert_equal "Referrals required for loyalty credit for new deals must be >= 1 when the loyalty program is enabled for new deals", @publisher.errors.on(:referrals_required_for_loyalty_credit_for_new_deals)
        @publisher.referrals_required_for_loyalty_credit_for_new_deals = 0
        assert @publisher.invalid?
        assert_equal "Referrals required for loyalty credit for new deals must be >= 1 when the loyalty program is enabled for new deals", @publisher.errors.on(:referrals_required_for_loyalty_credit_for_new_deals)
        @publisher.referrals_required_for_loyalty_credit_for_new_deals = 1
        assert @publisher.valid?
      end
      
    end

    context "Publisher#enable_loyalty_program_for_new_deals" do
      
      should "not change DailyDeal#enable_loyalty_program for an existing deal, when the pub default changes" do
        @publisher.update_attributes :enable_loyalty_program_for_new_deals => true,
                                     :referrals_required_for_loyalty_credit_for_new_deals => 3
        deal = Factory :daily_deal, :publisher => @publisher, :enable_loyalty_program => true, :referrals_required_for_loyalty_credit => 3
        
        @publisher.update_attribute :enable_loyalty_program_for_new_deals, false
        deal.save!
        assert deal.enable_loyalty_program?
      end
      
    end
    
    context "Publisher#referrals_required_for_loyalty_credit_for_new_deals" do
      
      should "not change DailyDeal#referrals_required_for_loyalty_credit for an existing deal, when the pub default changes" do
        @publisher.update_attribute :referrals_required_for_loyalty_credit_for_new_deals, 5
        deal = Factory :daily_deal, :publisher => @publisher, :enable_loyalty_program => true, :referrals_required_for_loyalty_credit => 3
        
        @publisher.update_attribute :referrals_required_for_loyalty_credit_for_new_deals, 2
        deal.save!
        assert_equal 3, deal.referrals_required_for_loyalty_credit
      end
      
    end
    
  end
  
end