require File.dirname(__FILE__) + "/../../test_helper"

class Publishers::DailyDealWithMarketsTest < ActionController::TestCase
  tests PublishersController

  context "accessing a deal of the day for a market with deals" do
    setup do
      @publisher = Factory.create(:publisher)
      @market = Factory.create(:market, :name => "Boston", :publisher_id => @publisher.id)
      @daily_deal = Factory(:daily_deal, :publisher_id => @publisher.id)
      @daily_deal.markets << @market
    end

    should "find the market when the market label in the request is all lowercase" do
      get :deal_of_the_day, :label => @publisher.label, :market_label => 'boston'
      assert_response :success
      assert_equal @market, assigns(:market), "@market assignment"
    end

    should "find the market when the market label in the request is title-capped" do
      get :deal_of_the_day, :label => @publisher.label, :market_label => 'Boston'
      assert_response :success
      assert_equal @market, assigns(:market), "@market assignment"
    end

  end

  context "accessing a deal of the day for a market with no deals" do

    setup do
      @publisher = Factory.create(:publisher)
    end

    should "redirect to the national market if there is no deal to render in requested market" do
      market = Factory.create(:market, :name => "Boston", :publisher_id => @publisher.id)
      national_market = Factory.create(:market, :name => "National", :publisher_id => @publisher.id)

      get :deal_of_the_day, :label => @publisher.label, :market_label => market.label

      assert_redirected_to public_deal_of_day_for_market_path( :label => @publisher.label, :market_label => national_market.label )
    end

    should "render a 404 if there is no deal to render and no national market to redirect to" do
      market = Factory.create(:market, :name => "Boston", :publisher_id => @publisher.id)

      assert_raise ActiveRecord::RecordNotFound do
        get :deal_of_the_day, :label => @publisher.label, :market_label => market.label
      end
    end

    should "render a 404 if there are no deals in the national market" do
      national_market = Factory.create(:market, :name => "National", :publisher_id => @publisher.id)

      assert_raise ActiveRecord::RecordNotFound do
        get :deal_of_the_day, :label => @publisher.label, :market_label => national_market.label
      end
    end

  end
end