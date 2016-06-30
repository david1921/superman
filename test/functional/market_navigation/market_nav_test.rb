require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDealsController::MarketNavTest

class DailyDealsController::MarketNavTest < ActionController::TestCase
  tests DailyDealsController

  context "market nav" do
    setup do
      @publisher = Factory(:publisher, :name => "Kowabunga", :label => "kowabunga")

      @ny_market = Factory(:market, :name => "New York", :publisher_id => @publisher.id)
      @ny_zip = Factory(:market_zip_code, :market_id => @ny_market.id, :zip_code => "10001", :state_code => "NY")

      @rochester_market = Factory(:market, :name => "Rochester", :publisher_id => @publisher.id)
      @rochester_zip = Factory(:market_zip_code, :market_id => @rochester_market.id, :zip_code => "12345", :state_code => "NY")

      @la_market = Factory(:market, :name => "Los Angeles", :publisher_id => @publisher.id)
      @la_zip = Factory(:market_zip_code, :market_id => @la_market.id, :zip_code => "55555", :state_code => "CA")

      @sd_market = Factory(:market, :name => "San Diego", :publisher_id => @publisher.id)
      @sd_zip = Factory(:market_zip_code, :market_id => @sd_market.id, :zip_code => "66666", :state_code => "CA")

      @ny_deal = Factory(:daily_deal, :publisher_id => @publisher.id)
      @ny_deal.markets << @ny_market
      @la_deal = Factory(:daily_deal, :publisher_id => @publisher.id)
      @la_deal.markets << @la_market

      assert_equal 4, @publisher.markets.size
      assert_equal 1, @ny_deal.markets.size
      assert_equal 1, @la_deal.markets.size

      get :show, :id => @ny_deal.id
    end

    should "contain the market nav" do
      assert_select "#market_nav"
    end

    should "render the letter-based nav for states" do
      assert_select "#states_letter_nav"
    end

    should "put the New York market in the ny_markets div, but not the Rochester market as it has no deals" do
      assert_select "#N_states" do
        assert_select "#ny_markets" do
          assert_select "a", :text => "New York", :count => 1
          assert_select "a", :text => "Rochester", :count => 0

          assert_select "a", :text => "Los Angeles", :count => 0
          assert_select "a", :text => "San Diego", :count => 0
        end
      end
    end

    should "put the Los Angeles in the ca_markets div, but not the San Diego market as it has no deals" do
      assert_select "#C_states" do
        assert_select "#ca_markets" do
          assert_select "a", :text => "New York", :count => 0
          assert_select "a", :text => "Rochester", :count => 0

          assert_select "a", :text => "Los Angeles", :count => 1
          assert_select "a", :text => "San Diego", :count => 0
        end
      end
    end

    should "not include the *_markets div if the state has no markets" do
      assert_select "#V_states", :count => 1 do
        assert_select "#va_markets", :count => 0
      end
    end

    should "include a link to the deal of the day page for each market" do
      assert_select "#N_states" do
        assert_select "#ny_markets" do
          assert_select "a[href='#{public_deal_of_day_for_market_path(:label => @publisher.label, :market_label => @ny_market.label)}']", :text => "New York", :count => 1
        end
      end
    end

  end
end