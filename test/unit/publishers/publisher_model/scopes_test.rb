require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::ScopesTest
module Publishers
  module PublisherModel
    class ScopesTest < ActiveSupport::TestCase
      test "launched scope" do
        publisher = Factory(:publisher)
        unlaunched_publisher = Factory(:publisher, :launched => false)
        assert Publisher.launched.include?(publisher), "launched Publishers"
        assert !Publisher.launched.include?(unlaunched_publisher), "should not include unlaunched Publishers"
      end

      test "allow_daily_deals scope" do
        publisher = Factory(:publisher)
        publisher_with_deals = Factory(:publisher, :allow_daily_deals => true)
        assert(Publisher.allow_daily_deals.include?(publisher_with_deals) && Publisher.allow_daily_deals.size == 1,
          "Publisher allow_daily_deals scope should find just #{publisher_with_deals}, but found:\n#{Publisher.allow_daily_deals.map(&:to_s).join("\n")}.\nIn:\n #{Publisher.all.map(&:to_s).join("\n")}.\nDeals:\n#{DailyDeal.all.map(&:to_s).join("\n")}"
        )
      end

      test "any_daily_deals scope" do
        publisher = Factory(:publisher)
        publisher_with_deals = Factory(:publisher, :allow_daily_deals => true)
        advertiser = Factory(:advertiser, :publisher => publisher_with_deals)
        Factory(:daily_deal, :advertiser => advertiser)
        assert_same_elements [publisher_with_deals, publishers(:my_space), publishers(:sdh_austin)],
                             Publisher.any_daily_deals,
                             "any_daily_deals Publishers"
      end

      test "with_active_daily_deals scope" do

        publisher1 = Factory(:publisher, :label => "foo")
        publisher2 = Factory(:publisher)
        publisher3 = Factory(:publisher)
        publisher4 = Factory(:publisher)

        DailyDeal.delete_all
        Factory(:daily_deal, :publisher => publisher1,
                :start_at => Time.parse("April 1, 2011 01:00:00 PST"),
                :hide_at => Time.parse("April 28, 2011 01:00:00 PST"))
        Factory(:daily_deal, :publisher => publisher2,
                :start_at => Time.parse("May 1, 2011 01:00:00 PST"),
                :hide_at => Time.parse("May 28, 2011 01:00:00 PST"))
        Factory(:daily_deal, :publisher => publisher3,
                :start_at => Time.parse("April 1, 2011 01:00:00 PST"),
                :hide_at => Time.parse("April 28, 2011 01:00:00 PST"),
                :deleted_at => Time.parse("April 2, 2011 01:00:00 PST"))

        Timecop.freeze(Time.zone.local(2011, 4, 25, 12, 34, 56)) do
          assert_equal ["foo"], Publisher.with_active_daily_deals.map(&:label)
        end
      end

      context "in_syndication_network" do
        should "include publisher in the syndication network" do
          p_in = Factory(:publisher, :in_syndication_network => true)
          p_out = Factory(:publisher, :in_syndication_network => false)
          assert_contains Publisher.in_syndication_network, p_in
          assert_does_not_contain Publisher.in_syndication_network, p_out
        end
      end
    end
  end
end