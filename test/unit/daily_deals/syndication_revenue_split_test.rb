require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeals::SyndicationRevenueSplitTest < ActiveSupport::TestCase
  context "associations" do
    should "return syndication_revenue_split" do
      split = Factory(:syndication_net_revenue_split)
      daily_deal = Factory(:daily_deal, :syndication_revenue_split => split)
      assert_equal daily_deal.reload.syndication_revenue_split, split
    end
  end
  
  context "validations" do
    should "return require a revenue split type" do
      split = Factory.build(:syndication_net_revenue_split, :revenue_split_type => 'foo')
      assert split.invalid?
      assert split.errors.on(:revenue_split_type)
    end
    
    should "not allow a blank revenue split type" do
      split = Factory.build(:syndication_net_revenue_split, :revenue_split_type => '')
      assert split.invalid?
      assert split.errors.on(:revenue_split_type)
    end
    
    should "not allow a nil revenue split type" do
      split = Factory.build(:syndication_net_revenue_split, :revenue_split_type => nil)
      assert split.invalid?
      assert split.errors.on(:revenue_split_type)
    end
    
    should "validate presence of merchant_net_percentage" do
      split = Factory.build(:syndication_net_revenue_split, :merchant_net_percentage => nil)
      assert split.invalid?
      assert split.errors.on(:merchant_net_percentage)
    end
    
    should "validate gross percentages" do
      split = Factory.build(:syndication_gross_revenue_split, :source_gross_percentage => 101)
      assert split.invalid?
      assert_equal DailyDeals::SyndicationRevenueSplitConstants::GROSS_REVENUE_SPLIT_SUM_MESSAGE, split.errors.on(:base)
    end
    
    should "validate net percentages" do
      split = Factory.build(:syndication_net_revenue_split, :merchant_net_percentage => 999, :source_net_percentage_of_remaining => 0)
      assert split.invalid?
      assert split.errors.on(:merchant_net_percentage)
      assert_equal DailyDeals::SyndicationRevenueSplitConstants::NET_REVENUE_SPLIT_REMAINING_SUM_MESSAGE, split.errors.on(:base)
    end
    
    #remaining validation tests in test/no_rails/unit/app/models/daily_deals/syndication_revenue_split_validation_test.rb
  end
end