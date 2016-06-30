require File.dirname(__FILE__) + "/../../models_helper"

class SyndicationRevenueSplitValidationTest < Test::Unit::TestCase
  
  class MockSyndicationRevenueSplit
    include DailyDeals::SyndicationRevenueSplitValidation
  end
  
  def setup
    @split = MockSyndicationRevenueSplit.new
  end
  
  context "validate_revenue_split_percentages" do
    should "validate gross percentages" do
      @split.expects(:revenue_split_type).returns('gross')
      @split.expects(:validate_gross_revenue_split_percentages)
      @split.validate_revenue_split_percentages
    end
    
    should "validate net percentages" do
      @split.expects(:revenue_split_type).returns('net')
      @split.expects(:validate_net_revenue_split_percentages)
      @split.validate_revenue_split_percentages
    end
  end
  
  context "validate_gross_revenue_split_percentages" do
    should "validate sum of percentages" do
      @split.expects(:validate_sum).with(DailyDeals::SyndicationRevenueSplitConstants::GROSS_REVENUE_SPLIT_ATTRIBUTES,
                                         100,
                                         DailyDeals::SyndicationRevenueSplitConstants::GROSS_REVENUE_SPLIT_SUM_MESSAGE)
      @split.validate_gross_revenue_split_percentages
    end
  end
  
  context "validate_net_revenue_split_percentages" do
    should "validate merchant_net_percentage and sum of remaining percentages" do
      @split.expects(:validate_percentage).with(:merchant_net_percentage)
      @split.expects(:validate_sum).with(DailyDeals::SyndicationRevenueSplitConstants::NET_REVENUE_SPLIT_REMAINING_ATTRIBUTES, 
                                         100,
                                         DailyDeals::SyndicationRevenueSplitConstants::NET_REVENUE_SPLIT_REMAINING_SUM_MESSAGE)
      @split.validate_net_revenue_split_percentages
    end
  end
  
end