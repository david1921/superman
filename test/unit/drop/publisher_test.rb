require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Drop::PublisherTest
module Drop
  class PublisherTest < ActiveSupport::TestCase

    test "Should delegate specific methods" do
      publisher = Factory(:publisher)
      drop = Drop::Publisher.new(publisher)
      assert_equal publisher.city, drop.city, "city should be the same"
      assert_equal publisher.allow_offers, drop.allow_offers, "allow offers should be the same"
    end

    test "todays_daily_deal_email_url" do
      publisher = Factory(:publisher, :daily_deal_sharing_message_prefix => "sharing_subject")
      drop = Drop::Publisher.new(publisher)
      assert_equal "sharing_subject", drop.daily_deal_email_subject
      assert_match /subject=sharing_subject/, drop.todays_daily_deal_email_url
    end

    context "market-aware" do
      setup do
        @publisher = Factory(:publisher)
        @drop = Drop::Publisher.new(@publisher)
      end

      context "path methods" do
        should "return non-market-aware paths with no market label in the params" do
          @drop.stubs(:params).returns({})
          assert_equal "/publishers/#{@publisher.label}/deal-of-the-day", @drop.todays_daily_deal_path
          assert_equal "/publishers/#{@publisher.id}/daily_deals/how_it_works", @drop.how_it_works_path
          assert_equal "/publishers/#{@publisher.id}/consumers/new", @drop.new_consumer_path
          assert_equal "/publishers/#{@publisher.label}/affiliate/show", @drop.affiliate_show_path
          assert_equal "/publishers/#{@publisher.label}/affiliate/faqs", @drop.affiliate_faq_path
          assert_equal "/publishers/#{@publisher.id}/daily_deal/login", @drop.login_path
          assert_equal "/publishers/#{@publisher.id}/daily_deals/contact", @drop.contact_path
          assert_equal "/publishers/#{@publisher.id}/daily_deals/faqs", @drop.faq_path
          assert_equal "/publishers/#{@publisher.id}/daily_deals/about_us", @drop.about_us_path
          assert_equal "/publishers/#{@publisher.id}/daily_deals/privacy_policy", @drop.privacy_path
          assert_equal "/publishers/#{@publisher.id}/daily_deals/terms", @drop.terms_path
          assert_equal "/publishers/#{@publisher.id}/daily_deals/feature_your_business", @drop.feature_your_business_path
          assert_equal "/publishers/#{@publisher.label}/shopping_mall", @drop.shopping_mall_path
        end

        should "return market-aware paths with a market label in the params" do
          @drop.stubs(:params).returns({ :market_label => 'chicago' })
          assert_equal "/publishers/#{@publisher.label}/chicago/deal-of-the-day", @drop.todays_daily_deal_path
          assert_equal "/publishers/#{@publisher.id}/chicago/daily_deals/how_it_works", @drop.how_it_works_path
          assert_equal "/publishers/#{@publisher.id}/chicago/consumers/new", @drop.new_consumer_path
          assert_equal "/publishers/#{@publisher.label}/chicago/affiliate/show", @drop.affiliate_show_path
          assert_equal "/publishers/#{@publisher.label}/chicago/affiliate/faqs", @drop.affiliate_faq_path
          assert_equal "/publishers/#{@publisher.id}/chicago/daily_deal/login", @drop.login_path
          assert_equal "/publishers/#{@publisher.id}/chicago/daily_deals/contact", @drop.contact_path
          assert_equal "/publishers/#{@publisher.id}/chicago/daily_deals/faqs", @drop.faq_path
          assert_equal "/publishers/#{@publisher.id}/chicago/daily_deals/about_us", @drop.about_us_path
          assert_equal "/publishers/#{@publisher.id}/chicago/daily_deals/privacy_policy", @drop.privacy_path
          assert_equal "/publishers/#{@publisher.id}/chicago/daily_deals/terms", @drop.terms_path
          assert_equal "/publishers/#{@publisher.id}/chicago/daily_deals/feature_your_business", @drop.feature_your_business_path
          assert_equal "/publishers/#{@publisher.label}/chicago/shopping_mall", @drop.shopping_mall_path
        end

        should "return market-aware path with a user market associated with zip code in cookie or resulting from IP lookup" do
          @drop.stubs(:user_market_label).returns('chicago')
          assert_equal "/publishers/#{@publisher.label}/chicago/deal-of-the-day", @drop.user_market_aware_todays_daily_deal_path
        end
      end
    end
  end
end
