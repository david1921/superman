require File.dirname(__FILE__) + "/../test_helper"

class SignupsTest < ActionController::IntegrationTest
  test "email recipient should be able to create unactivated consumer account and then purchase deal with discount" do
    daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
    publisher = daily_deal.publisher
    discount = Factory(:discount, :code => "SIGNUP_CREDIT", :publisher => publisher)
    
    get "/publishers/#{publisher.label}/signups/create?email=chih.chow@example.com"
    consumer = assigns(:consumer)
    assert_not_nil consumer, "@consumer"
    assert_nil consumer.activated_at, "Should not be activated"
    assert_not_nil consumer.signup_discount , "Should have signup_discount"
    assert_not_nil consumer.crypted_password, "Should have random password"
    random_password = consumer.crypted_password
    assert_redirected_to thank_you_publisher_signups_path(publisher.label, :email => "chih.chow@example.com", :discount => "10.0")

    follow_redirect!
    assert_response :success
    
    get "/publishers/#{publisher.label}/deal-of-the-day"
    assert_response :success
    get new_daily_deal_daily_deal_purchase_path(daily_deal)
    assert_response :success
    assert_select "form[action='#{daily_deal_daily_deal_purchases_path(daily_deal)}'][method=post]", 1
    
    post daily_deal_daily_deal_purchases_path(daily_deal), :daily_deal_purchase => {
      :quantity => "1",
      :gift => "0"
    }, :consumer => {
      :name => "Chih Chow",
      :email => "chih.chow@example.com",
      :password => "sandiego",
      :password_confirmation => "sandiego",
      :agree_to_terms => "1"
    }
    assert_response :redirect
    assert_not_nil(daily_deal_purchase = assigns(:daily_deal_purchase), "Assignment of @daily_deal_purchase")
    assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)
    assert_equal consumer, daily_deal_purchase.consumer, "Should match consumer by email address"
    assert_not_nil daily_deal_purchase.discount, "Purchase should have a daily-deal discount"
    assert_equal 10.00, daily_deal_purchase.discount_amount
    assert_match /credit has been applied/i, flash[:notice]
    assert consumer.reload.crypted_password != random_password, "Should overwrite assigned random password"
  end
end
