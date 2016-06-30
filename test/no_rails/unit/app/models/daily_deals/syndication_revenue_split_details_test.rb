require File.dirname(__FILE__) + "/../../models_helper"

class SyndicationRevenueSplitDetailsTest < Test::Unit::TestCase
  
  class MockSyndicationRevenueSplit
    include DailyDeals::SyndicationRevenueSplitDetails
  end
  
  def setup
    @split = MockSyndicationRevenueSplit.new
  end
  
  context "gross" do
    should "validate gross percentages" do
      @split.expects(:revenue_split_type).returns('gross')
      @split.expects(:source_gross_percentage).returns(10)
      @split.expects(:merchant_gross_percentage).returns(20)
      @split.expects(:distributor_gross_percentage).returns(40)
      assert_equal "[Gross: Source 10% Merchant 20% Distributor 40%]", @split.details
    end
  end
  
  
  context "net" do
    should "validate gross percentages" do
      @split.expects(:revenue_split_type).returns('net')
      @split.expects(:merchant_net_percentage).returns(50)
      @split.expects(:source_net_percentage_of_remaining).returns(33)
      @split.expects(:distributor_net_percentage_of_remaining).returns(47)
      assert_equal "Merchant 50% of Net [Source 33% Distributor 47% of Remainder]", @split.details
    end
  end
  
end