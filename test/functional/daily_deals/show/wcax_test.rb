require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class DailyDealsController::Show::WcaxTest

module DailyDealsController::Show
  class WcaxTest < ActionController::TestCase
    tests DailyDealsController

    context "as a registered WCAX user" do
      setup do
        @publisher = Factory(:publisher, :label => "wcax")
        @consumer = Factory(:consumer, :publisher => @publisher)
        @deal = Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => @publisher))
        login_as @consumer
      end

      should "include the referral code in the twitter, facebook and mailto sharing links" do
        get :show, :id => @deal.to_param

        assert_response :ok
        doc = Nokogiri::HTML(@response.body)
        referral_code_param_regexp = Regexp.escape("referral_code=#{@consumer.referrer_code}")

        link = doc.search("a.share_link_twitter").first
        assert link.present?
        assert_match /#{referral_code_param_regexp}/, link["href"]

        fb_link = doc.search("a#facebook_link").first
        assert fb_link.present?
        assert_match /#{referral_code_param_regexp}/, fb_link["href"]
        assert_match /#{referral_code_param_regexp}#{Regexp.escape "&popup=true"}/, fb_link["onclick"]

        mailto_link = doc.search("a.share_link_mail").first
        assert mailto_link.present?
        assert_match /#{referral_code_param_regexp}/, mailto_link["href"]
      end
    end
  end
end
