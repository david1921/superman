require File.dirname(__FILE__) + "/../../models_helper"

class DailyDeals::FeaturedTest < Test::Unit::TestCase
  def setup
    @deal = Object.new.extend(DailyDeals::Featured)
  end

  context "#featured_at" do
      should "return true when deal is featured at the specified time" do
        Timecop.freeze do
          @deal.stubs(:featured_date_ranges).returns([(1.hour.ago..1.hour.from_now)])
          assert @deal.featured_at?(Time.now)
        end
      end

      should "return false when deal is not featured at the specified time" do
        Timecop.freeze do
          @deal.stubs(:featured_date_ranges).returns([(1.day.ago..1.hour.ago), (1.hour.from_now..1.day.from_now)])
          assert !@deal.featured_at?(Time.now)
        end
      end
  end

  context "#became_featured_within_interval_of?" do
    should "return true when deal became featured within specified interval" do
      Timecop.freeze do
        @deal.stubs(:featured_date_ranges).returns([(1.day.ago..1.hour.ago), (1.hour.from_now..1.day.from_now)])
        assert @deal.became_featured_within_interval_of?(24.hours, 10.hours.from_now)
      end
    end

    should "return false when deal did not become featured within specified interval" do
      @deal.stubs(:featured_date_ranges).returns([(25.hours.ago..1.hour.ago)])
      assert !@deal.became_featured_within_interval_of?(24.hours, Time.now)
    end
  end

  context "#current_featured_window" do
    should "return featured date range including current time" do
      Timecop.freeze do
        window = (12.hours.ago..12.hours.from_now)
        @deal.stubs(:featured_date_ranges).returns([(2.days.ago..1.day.ago), window])
        assert_equal window, @deal.current_featured_window
      end
    end

    should "return nil when date isn't featured" do
      Timecop.freeze do
        window = [12.hours.ago..12.hours.from_now]
        @deal.stubs(:featured_date_ranges).returns([])
        assert_equal nil, @deal.current_featured_window
      end
    end
  end
end