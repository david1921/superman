require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::SyndicatableTest

module DailyDeals
  class SyndicatableTest < ActiveSupport::TestCase
    context "#source_listing" do
      should "delegate to the source deal" do
        deal = Factory.build(:distributed_daily_deal, :listing => "listing")
        deal.source.listing = "source_listing"
        assert_equal "listing", deal.listing
        assert_equal "source_listing", deal.source_listing
      end
    end
  end
end
