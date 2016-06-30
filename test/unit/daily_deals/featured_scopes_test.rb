require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeals::FeaturedScopeTest < ActiveSupport::TestCase

  context "daily_deals" do
    setup do
      Timecop.freeze(Time.zone.local(2011, 11, 25)) do
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
    end

    context "featured_during_lifespan scope" do
      should "return deals that are featured at some point in their lifespan" do
        Timecop.freeze(Time.zone.local(2011, 11, 25)) do
          featured_deals = DailyDeal.featured_during_lifespan
          assert_equal true, featured_deals.include?(@past_featured_deal)
          assert_equal false, featured_deals.include?(@past_side_deal)
          assert_equal true, featured_deals.include?(@current_featured_deal)
          assert_equal false, featured_deals.include?(@current_side_deal)
          assert_equal true, featured_deals.include?(@current_deleted_deal)
          assert_equal true, featured_deals.include?(@future_featured_deal)
          assert_equal false, featured_deals.include?(@future_side_deal)
          assert_equal true, featured_deals.include?(@deal_with_a_side_window_at_the_beginning)
          assert_equal true, featured_deals.include?(@deal_with_a_side_window_at_the_end)
          assert_equal true, featured_deals.include?(@deal_with_a_side_window_in_the_middle)
        end
      end
    end

    context "featured scope" do
      should "only return daily deals that are featured right now and not deleted" do
        Timecop.freeze(Time.zone.local(2011, 11, 25)) do
          featured_deals = DailyDeal.featured
          assert_equal false, featured_deals.include?(@past_featured_deal)
          assert_equal false, featured_deals.include?(@past_side_deal)
          assert_equal true, featured_deals.include?(@current_featured_deal)
          assert_equal false, featured_deals.include?(@current_side_deal)
          assert_equal false, featured_deals.include?(@current_deleted_deal)
          assert_equal false, featured_deals.include?(@future_featured_deal)
          assert_equal false, featured_deals.include?(@future_side_deal)
          assert_equal true, featured_deals.include?(@deal_with_a_side_window_at_the_beginning)
          assert_equal true, featured_deals.include?(@deal_with_a_side_window_at_the_end)
          assert_equal false, featured_deals.include?(@deal_with_a_side_window_in_the_middle)
        end
      end
    end

    context "featured_at scope" do
      should "only return deals that are featred at the given time" do
        Timecop.freeze(Time.zone.local(2011, 11, 25)) do
          featured_deals = DailyDeal.featured_at(13.days.ago)
          assert_equal true, featured_deals.include?(@past_featured_deal)
          assert_equal 1, featured_deals.size

          featured_deals = DailyDeal.featured_at(1.day.ago)
          assert_equal true, featured_deals.include?(@current_featured_deal)
          assert_equal true, featured_deals.include?(@deal_with_a_side_window_at_the_beginning)
          assert_equal true, featured_deals.include?(@deal_with_a_side_window_at_the_end)
          assert_equal 3, featured_deals.size

          featured_deals = DailyDeal.featured_at(13.days.from_now)
          assert_equal true, featured_deals.include?(@future_featured_deal)
          assert_equal 1, featured_deals.size
        end
      end
    end

  end
end
