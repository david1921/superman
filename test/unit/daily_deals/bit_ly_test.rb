require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::BitLyTest
module DailyDeals
  class BitLyTest < ActiveSupport::TestCase

    context "#url_for_bit_ly" do

      setup do
        @publisher = Factory(:publisher, :production_daily_deal_host => "www.worthlesscrap.com")
        @daily_deal = Factory(:daily_deal, :publisher => @publisher)
      end

      should "use the daily deal host" do
        assert_equal "http://www.worthlesscrap.com/daily_deals/#{@daily_deal.id}", @daily_deal.url_for_bit_ly
      end

    end
  end
end

