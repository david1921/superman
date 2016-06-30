require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::ShareTest < ActionController::TestCase
  tests DailyDealsController

  context "#facebook" do

    setup do
      @daily_deal = Factory(:daily_deal)
    end

    should "redirect to facebook with correct url with no referral_code" do
      get :facebook, :id => @daily_deal.id
      query_string_hash = CGI.parse(CGI.unescape(URI.parse(@response.redirected_to).query))
      assert_equal ["#{daily_deal_url(@daily_deal)}?v=#{@daily_deal.updated_at.to_i}"], query_string_hash["u"]
    end

    should "include referral_code if referrer_code is passed in" do
      get :facebook, :id => @daily_deal.id, :referral_code => "abcdef"
      query_string_hash = CGI.parse(URI.parse(@response.redirected_to).query)
      assert_equal ["#{daily_deal_url(@daily_deal)}?v=#{@daily_deal.updated_at.to_i}&referral_code=abcdef"], query_string_hash["u"]
    end

  end

  context "#twitter" do

    setup do
      @daily_deal = Factory(:daily_deal)
    end

    should "use the bit_ly_url of the daily_deal" do
      get :twitter, :id => @daily_deal.id
      assert_match %r{^http://twitter.com}, @response.redirected_to
      assert_match /#{@daily_deal.bit_ly_url}$/, @response.redirected_to
    end

  end

end
