require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::SideDealTest

module DailyDeals
  class SideDealTest < ActiveSupport::TestCase

    context "side deals" do

      should "side deals without markets" do
        daily_deal = Factory(:side_daily_deal)
        assert_equal [], daily_deal.side_deals, "Side deals"

        daily_deal = Factory(:side_daily_deal)
        same_publisher_deal = Factory(:side_daily_deal, :advertiser => daily_deal.advertiser, :publisher => daily_deal.publisher,
                                      :start_at => Time.zone.now.yesterday, :hide_at => Time.zone.now.tomorrow)
        other_publisher_deal = publishers(:sdreader).advertisers.create!.daily_deals.create!(Factory.attributes_for(:daily_deal))

        assert_equal [ same_publisher_deal ], daily_deal.side_deals, "Side deals"
        assert_equal [ daily_deal ], same_publisher_deal.side_deals, "Side deals"
      end

      should "side deals with markets" do
        @publisher = Factory.create(:publisher)
        @market = Factory.create(:market, :publisher => @publisher)
        @elsewhere_market = Factory.create(:market, :publisher => @publisher)

        @featured_deal = Factory.create(:daily_deal,
                                        :publisher => @publisher)
        @featured_deal.markets << @market

        @side_deal_1 = Factory.create(:side_daily_deal, :publisher => @publisher)
        @side_deal_1.markets << @market
        @side_deal_2 = Factory.create(:side_daily_deal, :publisher => @publisher)
        @side_deal_2.markets << @market
        
        @featured_deal_elsewhere = Factory.build(:daily_deal,
                                                  :publisher => @publisher)

        @featured_deal_elsewhere.markets << @elsewhere_market
        @featured_deal_elsewhere.save!

        @side_deal_elsewhere = Factory.create(:side_daily_deal, :publisher => @publisher)
        @side_deal_elsewhere.markets << @elsewhere_market

        @side_deal_no_market = Factory.create(:side_daily_deal, :publisher => @publisher)

        @featured_deal_another_publisher = Factory.create(:daily_deal)
        @side_deal_another_publisher = Factory.create(:side_daily_deal)

        side_deals = @featured_deal.side_deals

        assert_equal false, side_deals.include?(@featured_deal)
        assert_equal true, side_deals.include?(@side_deal_1)
        assert_equal true, side_deals.include?(@side_deal_2)

        assert_equal false, side_deals.include?(@featured_deal_elsewhere)
        assert_equal false, side_deals.include?(@side_deal_elsewhere)

        assert_equal false, side_deals.include?(@side_deal_no_market)
        assert_equal false, side_deals.include?(@featured_deal_another_publisher)
        assert_equal false, side_deals.include?(@side_deal_another_publisher)
      end
    end
    
    context "side deals sorting" do
      setup do
        @featured_deal = Factory(:daily_deal,
                                :value_proposition => "featured",
                                :start_at => 3.days.ago,
                                :hide_at => 7.days.from_now)
        @side_deal_1 = Factory(:side_daily_deal,
                              :value_proposition => "side_deal_1",
                              :publisher => @featured_deal.publisher, 
                              :start_at => 2.days.ago,
                              :hide_at => 4.days.from_now)
        @side_deal_2 = Factory(:side_daily_deal,
                              :value_proposition => "side_deal_2",
                              :publisher => @featured_deal.publisher, 
                              :start_at => 5.days.ago,
                              :hide_at => 1.days.from_now)
        @side_deal_3 = Factory(:side_daily_deal,
                              :value_proposition => "side_deal_3",
                              :publisher => @featured_deal.publisher, 
                              :start_at => 5.days.ago,
                              :hide_at => 10.days.from_now)
      end
      
      should "order by hide at" do 
        sorted_deals = @featured_deal.side_deals { |deal| deal.hide_at }
        assert_equal ["side_deal_2", "side_deal_1", "side_deal_3"], sorted_deals.map(&:value_proposition), "should be ordered by hide at"
      end
      
    end
  end
end
