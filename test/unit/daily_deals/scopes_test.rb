require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::ScopesTest

class DailyDeals::ScopesTest < ActiveSupport::TestCase

  context "#ending_after" do
    setup do
      @now = Time.now
      Timecop.freeze(@now) do
        @time = 12.hours.from_now
        @hidden_before = Factory(:daily_deal, :hide_at => @time - 1.hour)
        @hidden_at = Factory(:daily_deal, :hide_at => @time)
        @hidden_after = Factory(:daily_deal, :hide_at => @time + 1.hour)
      end
    end

    should "return deals with hide_at after specified time" do
      Timecop.freeze(@now) do
        assert_equal [@hidden_after], DailyDeal.ending_after(@time)
      end
    end
  end

  context "#by_relevancy_score" do
    setup do
      publisher = Factory(:publisher)
      @daily_deal = Factory(:side_daily_deal, :publisher => publisher)
      @daily_deal2 = Factory(:side_daily_deal, :publisher => publisher)
      @daily_deal3 = Factory(:side_daily_deal, :publisher => publisher)
      @consumer = Factory(:consumer, :publisher => publisher)
      @consumer2 = Factory(:consumer, :publisher => publisher)
      ConsumerDealRelevancyScore.create!(:consumer => @consumer, :daily_deal => @daily_deal, :relevancy_score => 1)
      ConsumerDealRelevancyScore.create!(:consumer => @consumer, :daily_deal => @daily_deal2, :relevancy_score => 100)
      ConsumerDealRelevancyScore.create!(:consumer => @consumer, :daily_deal => @daily_deal3, :relevancy_score => 50)
      ConsumerDealRelevancyScore.create!(:consumer => @consumer2, :daily_deal => @daily_deal, :relevancy_score => 50)
      ConsumerDealRelevancyScore.create!(:consumer => @consumer2, :daily_deal => @daily_deal2, :relevancy_score => 1)
      ConsumerDealRelevancyScore.create!(:consumer => @consumer2, :daily_deal => @daily_deal3, :relevancy_score => 100)
    end

    should "contain daily deals for a consumer in order of relevancy desc" do
      deals = @consumer.daily_deals.by_relevancy_score
      assert_equal 3, deals.size
      assert_equal @daily_deal2, deals.first
      assert_equal @daily_deal, deals.last
    end

  end
end
