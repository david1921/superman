require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Advertisers::MarketTest
class Advertisers::MarketTest < ActiveSupport::TestCase

  context "#deal_markets" do
    setup do
      @publisher = Factory(:publisher)
      @advertiser = Factory(:advertiser, :publisher_id => @publisher.id)
    end

    context "for an advertiser whose publisher doesn't use markets" do
      should "return an empty collection" do
        assert_equal true, @advertiser.deal_markets.empty?
      end
    end

    context "for an advertiser whose publisher uses markets" do
      setup do
        # A couple markets and deals to add them to later
        @san_francisco = Factory(:market, :name => "San Francisco", :publisher_id => @publisher.id)
        @new_york = Factory(:market, :name => "New York", :publisher_id => @publisher.id)
        @sf_dd = Factory(:side_daily_deal, :publisher_id => @publisher.id, :advertiser_id => @advertiser.id)
        @ny_dd = Factory(:side_daily_deal, :publisher_id => @publisher.id, :advertiser_id => @advertiser.id)

        # A market and deal for another publisher
        @tupelo = Factory(:market, :name => "Tupelo")
        @tup_dd = Factory(:side_daily_deal, :publisher_id => @tupelo.publisher.id)
        @tup_dd.markets << @tupelo

        assert_equal 2, @publisher.markets.size
      end

      should "return an empty collection if the advertiser doesn't have any deals with markets" do
        assert_equal true, @advertiser.deal_markets.empty?
      end

      should "return only the markets in which the advertiser has deals" do
        @sf_dd.markets << @san_francisco
        @ny_dd.markets << @new_york

        deal_market_ids = @advertiser.deal_markets.map { |m| m.id }
        assert_equal 2, deal_market_ids.size
        assert deal_market_ids.include?(@san_francisco.id)
        assert deal_market_ids.include?(@new_york.id)
        assert !deal_market_ids.include?(@tupelo.id)
      end
    end
  end
end
