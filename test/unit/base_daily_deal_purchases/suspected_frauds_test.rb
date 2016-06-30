require File.dirname(__FILE__) + "/../../test_helper"

# hydra class BaseDailyDealPurchases::SuspectedFraudsTest

module BaseDailyDealPurchases
  
  class SuspectedFraudsTest < ActiveSupport::TestCase

    def setup
      @deal = Factory :daily_deal
      
      @p1 = Factory :captured_daily_deal_purchase, :daily_deal => @deal, :executed_at => 10.minutes.ago
      @p2 = Factory :captured_daily_deal_purchase, :daily_deal => @deal, :executed_at => 20.minutes.ago
      @p3 = Factory :captured_daily_deal_purchase, :daily_deal => @deal, :executed_at => 30.minutes.ago
      @p4 = Factory :captured_daily_deal_purchase, :daily_deal => @deal, :executed_at => 40.minutes.ago
      
      @sf1 = Factory :suspected_fraud, :suspect_daily_deal_purchase => @p1, :matched_daily_deal_purchase => @p2
      @sf2 = Factory :suspected_fraud, :suspect_daily_deal_purchase => @p2, :matched_daily_deal_purchase => @p3
    end
    

    context "the suspected_frauds named scope" do

      should "return only purchases that exist in the suspected_frauds table" do
        assert_equal [@p1.id, @p2.id], DailyDealPurchase.suspected_frauds.map(&:id)
      end
    
    end
  
  
    context "the for_deal named scope" do
      
      setup do
        @sf3 = Factory :suspected_fraud
      end
   
      should "return the suspected frauds for a given deal" do
        assert_same_elements [@sf1.id, @sf2.id], SuspectedFraud.for_deal(@deal).map(&:id)
      end
    
    end

    context "the for_publisher named scope" do
      setup do
        @sf3 = Factory :suspected_fraud
      end
   
      should "return the suspected frauds for a given publisher" do
        assert_same_elements [@sf1.id, @sf2.id], SuspectedFraud.for_publisher(@deal.publisher).map(&:id)
      end
    end
    
  end
  
end
