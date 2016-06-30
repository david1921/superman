require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::FeaturedSchedulingTest

module DailyDeals
  class FeaturedSchedulingTest < ActiveSupport::TestCase
    context "daily deals" do
      should "be considered featured and 'featured during lifespan' if no side-deal dates are set" do
        featured_deal = Factory(:featured_daily_deal)
        assert_nil featured_deal.side_start_at
        assert_nil featured_deal.side_end_at
        assert_equal true, featured_deal.featured?
        assert_equal true, featured_deal.featured_during_lifespan?
      end

      should "be considered featured and 'featured during lifespan' if the current date is before the side-deal window" do
        Timecop.freeze(Time.zone.now) do
          featured_deal = Factory(:featured_daily_deal)
          featured_deal.side_start_at = Time.zone.now + 1.day
          featured_deal.side_end_at = Time.zone.now + 2.days
          assert_equal true, featured_deal.featured?
          assert_equal true, featured_deal.featured_during_lifespan?
        end
      end

      should "be considered featured and 'featured during lifespan' if the current date is after the side-deal window" do
        Timecop.freeze(Time.zone.now) do
          featured_deal = Factory(:featured_daily_deal)
          featured_deal.side_start_at = Time.zone.now - 2.days
          featured_deal.side_end_at = Time.zone.now - 1.day
          assert_equal true, featured_deal.featured?
          assert_equal true, featured_deal.featured_during_lifespan?
        end
      end

      should "not be considered featured if the current date is in the side-deal window" do
        Timecop.freeze(Time.zone.now) do
          featured_deal = Factory(:featured_daily_deal)
          featured_deal.side_start_at = Time.zone.now - 2.days
          featured_deal.side_end_at = Time.zone.now + 2.days
          assert_equal false, featured_deal.featured?
        end
      end

      should "be considered 'featured during lifespan' if the current date is in the side-deal window" do
        Timecop.freeze(Time.zone.now) do
          featured_deal = Factory(:featured_daily_deal)
          featured_deal.side_start_at = Time.zone.now - 2.days
          featured_deal.side_end_at = Time.zone.now + 2.days
          assert_equal true, featured_deal.featured_during_lifespan?
        end
      end

      should "not be considered featured or 'featured during lifespan' if it has been deleted" do
        Timecop.freeze(Time.zone.now) do
          featured_deal = Factory(:featured_daily_deal)
          featured_deal.deleted_at = Time.zone.now - 1.day
          featured_deal.side_start_at = Time.zone.now - 2.days
          featured_deal.side_end_at = Time.zone.now + 2.days
          assert_equal false, featured_deal.featured?
          assert_equal false, featured_deal.featured_during_lifespan?
        end
      end

      context "daily deal validation" do
        setup do
          @deal = Factory.build(:daily_deal)
          @deal.start_at = 2.weeks.ago
          @deal.hide_at = 2.weeks.from_now
          assert @deal.valid?
        end

        should "not allow a side-start-at date without a side-end-at date" do
          @deal.side_start_at = DateTime.now + 1.day
          assert @deal.invalid?
          assert @deal.errors[:side_end_at]
        end

        should "not allow a side-end-at date to come before a side-start-at date" do
          @deal.side_start_at = 1.day.from_now
          @deal.side_end_at = 1.day.ago
          assert @deal.invalid?
          assert @deal.errors[:side_end_at]
        end

        should "not allow a side-end-at date without a side-start-at date" do
          @deal.side_end_at = DateTime.now + 1.day
          assert @deal.invalid?
          assert @deal.errors[:side_start_at]
        end

        should "not allow a side-start-at date to come before the deal start-at date" do
          @deal.side_start_at = 4.weeks.ago
          @deal.side_end_at = 3.weeks.ago
          assert @deal.invalid?
          assert @deal.errors[:side_start_at]
        end

        should "not allow a side-start-at date to come after the deal hide-at date" do
          @deal.side_start_at = 3.weeks.from_now
          @deal.side_end_at = 4.weeks.from_now
          assert @deal.invalid?
          assert @deal.errors[:side_start_at]
        end

        should "not allow a side-end-at date to come before the deal start-at date" do
          @deal.side_start_at = 4.weeks.ago
          @deal.side_end_at = 3.weeks.ago
          assert @deal.invalid?
          assert @deal.errors[:side_end_at]
        end

        should "not allow a side-end-at date to come after the deal hide-at date" do
          @deal.side_start_at = 1.day.ago
          @deal.side_end_at = 3.weeks.from_now
          assert @deal.invalid?
          assert @deal.errors[:side_end_at]
        end

        should "not fail if the start-at is nil and there are side-deal dates in an update" do
          assert_nothing_raised do
            @deal.update_attributes({"start_at"=>"", "side_start_at"=> 1.week.ago.to_s, "side_end_at"=> 1.week.from_now.to_s})
          end
        end

        should "not fail if the hide-at is nil and there are side-deal dates in an update" do
          assert_nothing_raised do
            @deal.update_attributes({"hide_at"=>"", "side_start_at"=> 1.week.ago.to_s, "side_end_at"=> 1.week.from_now.to_s})
          end
        end
      end

      context "DailyDeal.todays with scheduled side deals" do
        #            |========|
        #  |--------------------------|
        should "return a deal that is featured its entire lifespan" do
          Timecop.freeze(Time.zone.local(2011, 4, 14, 12, 00, 00)) do
            deal = Factory(:featured_daily_deal, :start_at => 1.week.ago, :hide_at => 1.week.from_now)
            assert_equal true, DailyDeal.todays.include?(deal)
          end
        end

        #            |========|
        #  |            side          |
        should "not return a deal that is a side deal for its whole lifespan" do
          Timecop.freeze(Time.zone.local(2011, 4, 14, 12, 00, 00)) do
            deal = Factory(:side_daily_deal, :start_at => 1.week.ago, :hide_at => 1.week.from_now)
            assert_equal true, DailyDeal.todays.empty?
          end
        end

        #              |========|
        #  |--| side |-------------------|
        should "return a deal when its featured window includes all of today" do
          Timecop.freeze(Time.zone.local(2011, 4, 14, 12, 00, 00)) do
            deal = Factory(:featured_daily_deal, :start_at => 1.week.ago, :hide_at => 1.week.from_now,
                           :side_start_at => 3.days.ago, :side_end_at => 2.days.ago)
            assert_equal true, DailyDeal.todays.include?(deal)
          end
        end

        #            |========|
        #  |-------|   side     |-----------|
        should "not return one of today's deals that was previously featured and will be featured again, but is a side deal today" do
          Timecop.freeze(Time.zone.local(2011, 4, 14, 12, 00, 00)) do
            deal = Factory(:featured_daily_deal, :start_at => 1.week.ago, :hide_at => 1.week.from_now,
                           :side_start_at => 1.day.ago, :side_end_at => 1.day.from_now)
            assert_equal true, DailyDeal.todays.empty?
          end
        end

        #            |========|
        #  |-------| side |-----------|
        should "return one of today's deals that starts the day as a side deal but becomes featured" do
          Timecop.freeze(Time.zone.local(2011, 4, 14, 12, 00, 00)) do
            deal = Factory(:featured_daily_deal, :start_at => 1.week.ago, :hide_at => 1.week.from_now,
                           :side_start_at => 1.day.ago, :side_end_at => 1.hour.from_now)
            assert_equal true, DailyDeal.todays.include?(deal)
          end
        end

        #            |========|
        #  |-------------| side |-----------|
        should "return one of today's deals that starts the day as a featured deal but becomes side" do
          Timecop.freeze(Time.zone.local(2011, 4, 14, 12, 00, 00)) do
            deal = Factory(:featured_daily_deal, :start_at => 1.week.ago, :hide_at => 1.week.from_now,
                           :side_start_at => 1.hour.from_now, :side_end_at => 2.days.from_now)
            assert_equal true, DailyDeal.todays.include?(deal)
          end
        end
      end

      context "DailyDeal.tomorrow with scheduled side deals" do
        # |=======================|
        #         |--------------------------|         Featured all the way through (side fields null)
        should "return a deal that starts tomorrow and is featured all of tomorrow" do
          Timecop.freeze(Time.zone.local(2011, 4, 14, 12, 00, 00)) do
            deal = Factory(:featured_daily_deal, :start_at => 1.day.from_now, :hide_at => 1.week.from_now)
            assert_equal deal, deal.publisher.daily_deals.tomorrow
          end
        end

        # |=======================|
        # <---------------------------|               Doesn't start tomorrow
        should "not return a deal that starts today, runs through tomorrow, and is featured throughout" do
          Timecop.freeze(Time.zone.local(2011, 4, 14, 12, 00, 00)) do
            deal = Factory(:featured_daily_deal, :start_at => Time.zone.now, :hide_at => 1.week.from_now)
            assert_equal nil, deal.publisher.daily_deals.tomorrow
          end
        end

        # |=========================|
        #         |--------------|
        should "return a deal that starts and ends tomorrow and is a featured deal the whole time" do
          Timecop.freeze(Time.zone.local(2011, 4, 14, 12, 00, 00)) do
            deal = Factory(:featured_daily_deal, :start_at => 1.day.from_now, :hide_at => 1.day.from_now + 3.hours)
            assert_equal deal, deal.publisher.daily_deals.tomorrow
          end
        end
        
        # |======================|
        #         |---------|   side   |-------|
        should "return a deal that starts tomorrow, starts featured, and becomes a side deal" do
          Timecop.freeze(Time.zone.local(2011, 4, 14, 12, 00, 00)) do
            deal = Factory(:featured_daily_deal, :start_at => 1.day.from_now, :hide_at => 1.week.from_now,
                           :side_start_at => 1.day.from_now + 1.hour, :side_end_at => 3.days.from_now)
            assert_equal deal, deal.publisher.daily_deals.tomorrow
          end
        end

        # |==================|
        #         |      side        |
        should "not return a deal that starts tomorrow and is a side deal for its whole lifetime" do
          Timecop.freeze(Time.zone.local(2011, 4, 14, 12, 00, 00)) do
            deal = Factory(:side_daily_deal, :start_at => 1.day.from_now, :hide_at => 1.week.from_now)
            assert_equal nil, deal.publisher.daily_deals.tomorrow
          end
        end

        # |=========================|
        #     |     side      |---------------|
        should "return a deal that starts tomorrow, starts as a side deal, and becomes a featured deal later in the day" do
          Timecop.freeze(Time.zone.local(2011, 4, 14, 12, 00, 00)) do
            deal = Factory(:featured_daily_deal, :start_at => 1.day.from_now, :hide_at => 1.week.from_now,
                           :side_start_at => 1.day.from_now, :side_end_at => 1.day.from_now + 1.hour)
            assert_equal deal, deal.publisher.daily_deals.tomorrow
          end
        end

        # |==========================|
        #      |     side      |
        should "not return a deal that starts and ends tomorrow and is a side deal the whole time" do
          Timecop.freeze(Time.zone.local(2011, 4, 14, 12, 00, 00)) do
            deal = Factory(:featured_daily_deal, :start_at => 1.day.from_now, :hide_at => 1.day.from_now + 3.hours,
                           :side_start_at => 1.day.from_now, :side_end_at => 1.day.from_now + 3.hours)
            assert_equal nil, deal.publisher.daily_deals.tomorrow
          end
        end
      end

      context "DailyDeal.current_or_previous with scheduled side deals" do
        context "with two featured deals, one starting later than the other, for which the featured window has passed" do
          setup do
            @now = Time.zone.now

            @newer_active_deal_out_of_featured_window = Factory(:featured_daily_deal, :start_at => @now - 1.week, :hide_at => @now + 1.week)
            @newer_active_deal_out_of_featured_window.side_start_at = @now - 1.day
            @newer_active_deal_out_of_featured_window.side_end_at = @newer_active_deal_out_of_featured_window.hide_at
            @newer_active_deal_out_of_featured_window.save!

            @older_active_deal_in_featured_window = Factory(:daily_deal, :start_at => @now - 12.week, :hide_at => @now + 1.week)
            @older_active_deal_in_featured_window.side_start_at = @older_active_deal_in_featured_window.start_at
            @older_active_deal_in_featured_window.side_end_at = @now - 1.day
            @older_active_deal_in_featured_window.save!
          end

          should "return the deal that is featured right now even if it is older" do
            deal = DailyDeal.current_or_previous
            assert_equal @older_active_deal_in_featured_window, deal
          end

          should "return the newer active deal if neither it nor the older deal are no longer featured" do
            @older_active_deal_in_featured_window.side_end_at = @now + 1.day
            @older_active_deal_in_featured_window.save!
            deal = DailyDeal.current_or_previous
            assert_equal @newer_active_deal_out_of_featured_window, deal
          end
        end
      end

    end
  end
end