require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::SideDealScopeTest

module DailyDeals
  class SideDealScopeTest < ActiveSupport::TestCase

    context "daily deals" do
      setup do
        @past_featured_deal = Factory(:featured_daily_deal, :start_at => 2.weeks.ago, :hide_at => 1.week.ago)
        @past_side_deal = Factory(:side_daily_deal, :start_at => 2.weeks.ago, :hide_at => 1.week.ago)
        @current_featured_deal = Factory(:featured_daily_deal, :start_at => 1.week.ago, :hide_at => 1.week.from_now)
        @current_side_deal = Factory(:side_daily_deal, :start_at => 1.week.ago, :hide_at => 1.week.from_now)
        @current_deleted_deal = Factory(:featured_daily_deal, :start_at => 1.week.ago, :hide_at => 1.week.from_now, :deleted_at => 1.day.ago)
        @future_featured_deal = Factory(:featured_daily_deal, :start_at => 1.week.from_now, :hide_at => 2.weeks.from_now)
        @future_side_deal = Factory(:side_daily_deal, :start_at => 1.week.from_now, :hide_at => 2.weeks.from_now)

        @deal_with_a_side_window_at_the_beginning = Factory(:side_daily_deal, :start_at => 1.week.ago, :hide_at => 1.week.from_now)
        @deal_with_a_side_window_at_the_beginning.side_end_at = @deal_with_a_side_window_at_the_beginning.start_at + 1.day
        @deal_with_a_side_window_at_the_beginning.save!

        @deal_with_a_side_window_at_the_end = Factory(:side_daily_deal, :start_at => 1.week.ago, :hide_at => 1.week.from_now)
        @deal_with_a_side_window_at_the_end.side_start_at = @deal_with_a_side_window_at_the_end.hide_at - 1.day
        @deal_with_a_side_window_at_the_end.save!

        @deal_with_a_side_window_in_the_middle = Factory(:side_daily_deal, :start_at => 1.week.ago, :hide_at => 1.week.from_now)
        @deal_with_a_side_window_in_the_middle.side_start_at = Time.zone.now - 2.days
        @deal_with_a_side_window_in_the_middle.side_end_at = Time.zone.now + 2.days
        @deal_with_a_side_window_in_the_middle.save!
      end

      context "side_during_lifespan scope" do
        should "return deals that are side at some point in their lifespan" do
          side_deals = DailyDeal.side_during_lifespan
          assert_equal false, side_deals.include?(@past_featured_deal)
          assert_equal true, side_deals.include?(@past_side_deal)
          assert_equal false, side_deals.include?(@current_featured_deal)
          assert_equal true, side_deals.include?(@current_side_deal)
          assert_equal false, side_deals.include?(@current_deleted_deal)
          assert_equal false, side_deals.include?(@future_featured_deal)
          assert_equal true, side_deals.include?(@future_side_deal)
          assert_equal true, side_deals.include?(@deal_with_a_side_window_at_the_beginning)
          assert_equal true, side_deals.include?(@deal_with_a_side_window_at_the_end)
          assert_equal true, side_deals.include?(@deal_with_a_side_window_in_the_middle)
        end
      end

      context "side scope" do
        should "only return daily deals that are side right now and not deleted" do
          now_side_deals = DailyDeal.side
          assert_equal false, now_side_deals.include?(@past_featured_deal)
          assert_equal false, now_side_deals.include?(@past_side_deal)
          assert_equal false, now_side_deals.include?(@current_featured_deal)
          assert_equal true, now_side_deals.include?(@current_side_deal)
          assert_equal false, now_side_deals.include?(@current_deleted_deal)
          assert_equal false, now_side_deals.include?(@future_featured_deal)
          assert_equal false, now_side_deals.include?(@future_side_deal)
          assert_equal false, now_side_deals.include?(@deal_with_a_side_window_at_the_beginning)
          assert_equal false, now_side_deals.include?(@deal_with_a_side_window_at_the_end)
          assert_equal true, now_side_deals.include?(@deal_with_a_side_window_in_the_middle)
        end
      end
    end

  end
end