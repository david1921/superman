require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Publishers::LocalizationTest
module Publishers
  class LocalizationTest < ActiveSupport::TestCase
    test "locale" do
      publisher = Factory(:publisher)
      assert_equal "en", publisher.locale[:language]
      assert_equal "US", publisher.locale[:country]

      publisher = Factory(:gbp_publisher)
      assert_equal "en", publisher.locale[:language]
      assert_equal "GB", publisher.locale[:country]

      publisher = Factory(:cad_publisher)
      assert_equal "en", publisher.locale[:language]
      assert_equal "CA", publisher.locale[:country]
    end

    test "publisher should have a time_zone" do
      assert Factory.create(:publisher).respond_to?(:time_zone), "Publisher time_zone respond_to?"
    end

    test "#localize_time should correctly translate time from Pacific to local publisher time" do
      publisher = Factory(:publisher, :time_zone => "Mountain Time (US & Canada)")
      assert_equal publisher.localize_time("Jun 30, 2010 16:34:56 PST"), Time.zone.parse("Jun 30, 2010 17:34:56 MST")
    end

    test "now" do
      publisher = Factory(:publisher)
      assert_equal_dates Time.zone.now, publisher.now
    end

    test "now uses publisher time zone" do
      publisher = Factory(:publisher, :time_zone => "Eastern Time (US & Canada)")
      #
      # Test on a date when DST is not in effect.
      #
      Timecop.freeze Time.zone.local(2011, 12, 15, 12, 34, 56) do
        assert_equal Time.now.to_i, publisher.now.to_i, "Time was not now"
        assert_equal -5.hours, publisher.now.utc_offset, "Offset was not -0500"
      end
    end

    test "now uses publisher time zone with offset of a day" do
      publisher = Factory(:publisher, :time_zone => "Solomon Is.")
      #
      # Test on a date when DST is not in effect.
      #
      Timecop.freeze Time.zone.local(2011, 12, 15, 12, 34, 56) do
        assert_equal Time.now.to_i, publisher.now.to_i, "Time was not now"
        now = publisher.now
        utc_offset = now.utc_offset
        # When the tzinfo gem was installed as a dependency of resque-scheduler, new timezone definitions came with it,
        # which changed the offsets for at least some of the Asia and Pacific zones
        assert_equal +12.hours, utc_offset, "Offset was not +1200"
      end
    end
  end
end
