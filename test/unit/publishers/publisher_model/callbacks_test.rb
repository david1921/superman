require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::CallbacksTest
module Publishers
  module PublisherModel
    class CallbacksTest < ActiveSupport::TestCase
      context "#make_current_and_future_deals_available_for_syndication" do
        setup do
          @publisher = Factory(:publisher, :in_syndication_network => false)
          @advertiser = Factory(:advertiser, :publisher => @publisher)
          2.times{Factory(:side_daily_deal, :advertiser => @advertiser )}
        end

        should "make it so" do
          @publisher.daily_deals.each do |deal|
            assert !deal.available_for_syndication?
          end
          @publisher.update_attribute(:in_syndication_network, true)
          @publisher.make_current_and_future_deals_available_for_syndication
          @publisher.daily_deals(true).each do |deal|
            assert deal.available_for_syndication?
          end
        end

        should "should not make deals available for syndication when in_syndication_network is set to false" do
          @publisher.daily_deals.each do |deal|
            assert !deal.available_for_syndication?
          end
          assert_raises RuntimeError do
            @publisher.make_current_and_future_deals_available_for_syndication
          end
        end

        should "ignore past deals when updating syndication availability" do
          past_deal = @publisher.daily_deals.first
          past_deal.side_end_at = 1.day.ago
          past_deal.hide_at = 1.day.ago
          past_deal.save!
          @publisher.daily_deals.each do |deal|
            assert !deal.available_for_syndication?
          end
          @publisher.in_syndication_network = true
          @publisher.save!
          @publisher.make_current_and_future_deals_available_for_syndication
          (@publisher.daily_deals(true) - [past_deal]).each do |deal|
            assert deal.available_for_syndication?
          end
          past_deal.reload
          assert !past_deal.available_for_syndication?
        end

        should "not attempt to make deals that are themselves syndicated from another deal available for syndication" do
          first_deal = @publisher.daily_deals.first
          source_publisher = Factory(:publisher, :in_syndication_network => true)
          source_advertiser = Factory(:advertiser, :publisher => source_publisher)
          source_deal = Factory(:daily_deal_for_syndication, :advertiser => source_advertiser)
          syndicated_deal = Factory(:daily_deal, :advertiser => @advertiser, :source => source_deal)
          assert_equal @publisher, syndicated_deal.publisher
          assert_equal true, syndicated_deal.syndicated?
          assert_equal false, first_deal.available_for_syndication?
          assert_equal false, syndicated_deal.available_for_syndication?
          @publisher.in_syndication_network = true
          @publisher.save!
          @publisher.make_current_and_future_deals_available_for_syndication
          first_deal.reload
          assert_equal true, first_deal.available_for_syndication?
          assert_equal false, syndicated_deal.available_for_syndication?
        end

      end
    end
  end
end
