require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::CreateWithMarketsTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  test "create with new consumer and market" do
    daily_deal = Factory(:daily_deal)
    market = Factory(:market, :publisher => daily_deal.publisher)
    daily_deal.markets << market

    @request.cookies["daily_deal_market_id"] = market.to_param
    assert_difference "DailyDealPurchase.count" do
      post_create_with_consumer_params(
        daily_deal,
        :name => "Joseph Blow",
        :email => "joe@blow.com",
        :password => "secret",
        :password_confirmation => "secret",
        :agree_to_terms => "1"
      )
      daily_deal_purchase = assigns(:daily_deal_purchase)
      assert_not_nil daily_deal_purchase, "Assignment of daily_deal_purchase"
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)

      consumer = daily_deal_purchase.consumer
      assert_not_nil consumer, "Daily deal purchase should have a consumer"
      assert_equal market, daily_deal_purchase.market
      assert_nil session[:user_id], "Consumer should not be logged in"

      assert_equal daily_deal.publisher, consumer.publisher, "New consumer should belong to daily-deal publisher"
      assert_not_nil daily_deal_purchase.ip_address
      assert_equal "Joseph Blow", consumer.name
      assert_equal "joe@blow.com", consumer.email
      assert !consumer.active?, "New consumer should not be active before purchase is complete"
    end
  end

  test "create as logged in consumer with market" do
    daily_deal = Factory(:daily_deal)
    market = Factory(:market, :publisher => daily_deal.publisher)
    daily_deal.markets << market
    consumer = Factory(:consumer, :publisher => daily_deal.publisher)

    assert_difference "DailyDealPurchase.count" do
      login_as consumer
      @request.cookies["daily_deal_market_id"] = market.to_param
      post_create_with_consumer_params daily_deal

      daily_deal_purchase = assigns(:daily_deal_purchase)
      assert_no_errors daily_deal_purchase
      assert !daily_deal_purchase.new_record?, "Should have saved new purchase"
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)

      assert_equal consumer, daily_deal_purchase.consumer
      assert_equal market, daily_deal_purchase.market
      assert_equal consumer.id, session[:user_id], "Consumer should still be logged in"
      assert daily_deal_purchase.consumer.active?, "Existing consumer should still be active"
    end
  end

  test "create do not assign market market that does not belong to deal" do
    daily_deal = Factory(:daily_deal)
    other_deal = Factory(:daily_deal)
    market = Factory(:market, :publisher => other_deal.publisher)
    other_deal.markets << market
    consumer = Factory(:consumer, :publisher => daily_deal.publisher)

    assert_difference "DailyDealPurchase.count" do
      login_as consumer
      @request.cookies["daily_deal_market_id"] = market.to_param
      post_create_with_consumer_params daily_deal

      daily_deal_purchase = assigns(:daily_deal_purchase)
      assert_no_errors daily_deal_purchase
      assert !daily_deal_purchase.new_record?, "Should have saved new purchase"
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)

      assert_equal consumer, daily_deal_purchase.consumer
      assert_equal nil, daily_deal_purchase.market
      assert_equal consumer.id, session[:user_id], "Consumer should still be logged in"
      assert daily_deal_purchase.consumer.active?, "Existing consumer should still be active"
    end
  end

  test "create with active consumer and market" do
    daily_deal = Factory(:daily_deal)
    market = Factory(:market, :publisher => daily_deal.publisher)
    daily_deal.markets << market
    consumer = Factory(:consumer, :publisher => daily_deal.publisher)

    assert_difference "DailyDealPurchase.count" do
      @request.cookies["daily_deal_market_id"] = market.to_param
      post_create_with_consumer_params(
        daily_deal,
        :name => "JP",
        :email => consumer.email,
        :password => "monkey",
        :password_confirmation => "monkey",
        :agree_to_terms => "1"
      )
      daily_deal_purchase = assigns(:daily_deal_purchase)
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)

      assert_equal consumer, daily_deal_purchase.consumer
      assert_equal market, daily_deal_purchase.market
      assert_not_nil daily_deal_purchase.ip_address
      assert_equal consumer.id, session[:user_id], "Consumer should be logged in"
      assert_equal "John Public", consumer.reload.name, "Consumer name should not change"
      assert consumer.active?, "New consumer should still be active"
    end
  end

end
