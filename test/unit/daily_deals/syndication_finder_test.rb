require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::SyndicationFinderTest

module DailyDeals
  class SyndicationFinderTest < ActiveSupport::TestCase
    
    context "find" do
      
      setup do
        DailyDeal.delete_all
        @distributing_publisher = Factory(:publisher)
        @future_deal = Factory(:daily_deal, 
                            :start_at => 20.days.from_now,
                            :hide_at => 22.days.from_now,
                            :expires_on => 30.days.from_now)
        @past_deal = Factory(:daily_deal, 
                             :start_at => 22.days.ago,
                             :hide_at => 20.days.ago,
                             :expires_on => 16.days.ago)
        @source_deal = Factory(:daily_deal_for_syndication,
                              :start_at => 2.days.ago,
                              :hide_at => 2.days.from_now,
                              :expires_on => 14.days.from_now,
                              :upcoming => true)
        @syndicated_deal = syndicate(@source_deal, @distributing_publisher)
      end
      
      context "active" do
        should "include active source and syndicated deals" do
          deals = DailyDeal.active
          assert_equal false, deals.include?(@past_deal), "Should NOT include past deal"
          assert_equal false, deals.include?(@future_deal), "Should NOT include future deal"
          assert_equal true, deals.include?(@source_deal), "Should include source deal"
          assert_equal true, deals.include?(@syndicated_deal), "Should include syndicated deal"
          assert_equal 2, deals.count
        end
      
        should "NOT include syndicated deal with different date in active" do
          @syndicated_deal.start_at = 12.days.from_now
          @syndicated_deal.hide_at = 13.days.from_now
          @syndicated_deal.save!
          deals = DailyDeal.active
          assert_equal false, deals.include?(@past_deal), "Should NOT include past deal"
          assert_equal false, deals.include?(@future_deal), "Should NOT include future deal"
          assert_equal true, deals.include?(@source_deal), "Should include source deal"
          assert_equal false, deals.include?(@syndicated_deal), "Should NOT include syndicated deal"
          assert_equal 1, deals.count
        end
      end
      
      context "active_at" do
        should "include source and syndicated deals active at date" do
          deals = DailyDeal.active_at(Time.zone.now)
          assert_equal false, deals.include?(@past_deal), "Should NOT include past deal"
          assert_equal false, deals.include?(@future_deal), "Should NOT include future deal"
          assert_equal true, deals.include?(@source_deal), "Should include source deal"
          assert_equal true, deals.include?(@syndicated_deal), "Should include syndicated deal"
          assert_equal 2, deals.count
        end
      end
      
      context "active_tomorrow" do
        should "include source and syndicated deals active tomorrow" do
          deals = DailyDeal.active_tomorrow(Time.zone.now)
          assert_equal false, deals.include?(@past_deal), "Should NOT include past deal"
          assert_equal false, deals.include?(@future_deal), "Should NOT include future deal"
          assert_equal true, deals.include?(@source_deal), "Should include source deal"
          assert_equal true, deals.include?(@syndicated_deal), "Should include syndicated deal"
          assert_equal 2, deals.count
        end
      end
      
      context "starting_in_future" do
        should "include source and syndicated deals starting in future" do
          deals = DailyDeal.starting_in_future
          assert_equal false, deals.include?(@past_deal), "Should NOT include past deal"
          assert_equal true, deals.include?(@future_deal), "Should include future deal"
          assert_equal false, deals.include?(@source_deal), "Should NOT include source deal"
          assert_equal false, deals.include?(@syndicated_deal), "Should NOT include syndicated deal"
          assert_equal 1, deals.count
        end
      end
      
      context "active_between" do
        should "include source and syndicated deals active between dates" do
          deals = DailyDeal.active_between([Time.zone.now, 1.days.from_now])
          assert_equal false, deals.include?(@past_deal), "Should NOT include past deal"
          assert_equal false, deals.include?(@future_deal), "Should NOT include future deal"
          assert_equal true, deals.include?(@source_deal), "Should include source deal"
          assert_equal true, deals.include?(@syndicated_deal), "Should include syndicated deal"
          assert_equal 2, deals.count
        end
      end
      
      context "upcoming" do
        should "include upcoming source and syndicated deals" do
          Timecop.freeze(3.days.ago) do
            deals = DailyDeal.upcoming
            assert_equal false, deals.include?(@past_deal), "Should NOT include past deal"
            assert_equal false, deals.include?(@future_deal), "Should NOT include future deal"
            assert_equal true, deals.include?(@source_deal), "Should include source deal"
            assert_equal true, deals.include?(@syndicated_deal), "Should include syndicated deal"
            assert_equal 2, deals.count
          end
        end
      end
      
      context "current_or_previous" do
        should "include current or previous source and syndicated deals" do
          daily_deal_publisher = @source_deal.publisher
          assert_equal @source_deal, daily_deal_publisher.daily_deals.current_or_previous, "Should be source deal"
          assert_equal @syndicated_deal, @distributing_publisher.daily_deals.current_or_previous, "Should be syndicated deal"
          Timecop.freeze(3.days.ago) do
            assert_equal @past_deal, DailyDeal.current_or_previous, "Should be past deal"
          end
        end
      end
      
      context "todays" do
        should "include todays source and syndicated deals" do
          deals = DailyDeal.todays
          assert_equal false, deals.include?(@past_deal), "Should NOT include past deal"
          assert_equal false, deals.include?(@future_deal), "Should NOT include future deal"
          assert_equal true, deals.include?(@source_deal), "Should include source deal"
          assert_equal true, deals.include?(@syndicated_deal), "Should include syndicated deal"
          assert_equal 2, deals.count
        end
      end
      
      context "today" do
        should "include todays source and syndicated deals" do
          daily_deal_publisher = @source_deal.publisher
          assert_equal @source_deal, daily_deal_publisher.daily_deals.today, "Should be source deal"
          assert_equal @syndicated_deal, @distributing_publisher.daily_deals.today, "Should be syndicated deal"
        end
      end
      
      context "tomorrow" do
        should "include tomorrows source and syndicated deals" do
          daily_deal_publisher = @source_deal.publisher
          Timecop.freeze(3.days.ago) do
            assert_equal @source_deal, daily_deal_publisher.daily_deals.tomorrow, "Should be source deal"
            assert_equal @syndicated_deal, @distributing_publisher.daily_deals.tomorrow, "Should be syndicated deal"
          end
        end
      end
      
    end
    
  end
  
end
