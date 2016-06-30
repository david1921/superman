require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Consumers::Cookies::LastSeenDealTest
module Consumers
  module Cookies
    class LastSeenDealTest < ActiveSupport::TestCase
      include ::Consumers::Cookies::LastSeenDeal

      context "#set_last_seen_deal_cookie" do
        setup do
          stubs(:cookies).returns({})
        end

        should "not set a cookie if the publishing group has redirect_to_last_seen_deal_on_login disabled" do
          publishing_group = Factory(:publishing_group, :enable_redirect_to_last_seen_deal_on_login => false)
          publisher = Factory(:publisher, :publishing_group => publishing_group)
          daily_deal = Factory(:daily_deal, :publisher => publisher)
          set_last_seen_deal_cookie(daily_deal)
          assert_nil cookies["#{publishing_group.label}_last_seen_deal_id"]
        end

        should "set a cookie if the publishing group has redirect_to_last_seen_deal_on_login enabled" do
          publishing_group = Factory(:publishing_group, :enable_redirect_to_last_seen_deal_on_login => true)
          publisher = Factory(:publisher, :publishing_group => publishing_group)
          daily_deal = Factory(:daily_deal, :publisher => publisher)
          Timecop.freeze(Time.parse("Mar 15, 2010 12:35:56 UTC").in_time_zone) do
            set_last_seen_deal_cookie(daily_deal)
            assert_equal daily_deal.id, cookies["#{publishing_group.label}_last_seen_deal_id"][:value]
            assert_equal Time.zone.now + 2.hours, cookies["#{publishing_group.label}_last_seen_deal_id"][:expires]
          end
        end
      end
    end
  end
end
