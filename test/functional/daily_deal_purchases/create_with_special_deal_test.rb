require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::CreateWithSpecialDealTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  test "create as new consumer for publisher with special deal" do
    publisher = Factory(:publisher, :label => "oaoa", :show_special_deal => true)
    assert publisher.show_special_deal?
    Factory(:discount, :publisher => publisher, :code => "SIGNUP_CREDIT", :amount => 10.00)
    daily_deal = Factory(:daily_deal, :publisher => publisher)

    assert_difference 'DailyDealPurchase.count' do
      post :create, :daily_deal_id => daily_deal.to_param, :consumer => {
        :name => "Joseph Blow",
        :email => "joe@blow.com",
        :password => "secret",
        :password_confirmation => "secret",
        :agree_to_terms => "1"
      },
      :daily_deal_purchase => { :quantity => "1", :gift => "0" }
    end
    daily_deal_purchase = assigns(:daily_deal_purchase)
    assert_not_nil daily_deal_purchase, "Assignment of @daily_deal_purchase"
    assert_equal daily_deal.price - 10.0, daily_deal_purchase.total_price

    consumer = daily_deal_purchase.consumer
    assert_not_nil consumer, "Daily deal purchase should have a consumer"
    assert_nil session[:user_id], "Consumer should not be logged in"
    assert_not_nil consumer.signup_discount, "Consumer should have a signup discount"

    assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)
    assert_match(/credit has been applied/i, flash[:notice])
  end

  test "currency display in signup credit flash notice when signing up to make a 'special deal' purchase in USD" do
    publisher = Factory(:publisher, :show_special_deal => true, :currency_code => "USD")
    Factory(:discount, :publisher => publisher, :code => "SIGNUP_CREDIT", :amount => 10.00)
    daily_deal = Factory(:daily_deal, :publisher => publisher)

    post_create_with_consumer_params(
      daily_deal,
      :name => "Joseph Blow",
      :email => "joe@blow.com",
      :password => "secret",
      :password_confirmation => "secret",
      :agree_to_terms => "1"
    )

    assert_redirected_to confirm_daily_deal_purchase_path(assigns(:daily_deal_purchase))
    assert_match %r{\$\d+\.\d+ deal credit has been applied}i, flash[:notice]
  end

  test "currency display in signup credit flash notice when signing up to make a 'special deal' purchase in GBP" do
    publisher = Factory(:publisher, :show_special_deal => true, :currency_code => "GBP")
    Factory(:discount, :publisher => publisher, :code => "SIGNUP_CREDIT", :amount => 10.00)
    daily_deal = Factory(:daily_deal, :publisher => publisher)

    post_create_with_consumer_params(
      daily_deal,
      :name => "Joseph Blow",
      :email => "joe@blow.com",
      :password => "secret",
      :password_confirmation => "secret",
      :agree_to_terms => "1"
    )

    assert_redirected_to confirm_daily_deal_purchase_path(assigns(:daily_deal_purchase))
    assert_match %r{\£\d+\.\d+ deal credit has been applied}i, flash[:notice]
  end
end
