require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::UpdateTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper
  include Application::PasswordReset

  test "update with new consumer" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)

    put :update, :id => daily_deal_purchase.to_param,
      :daily_deal_purchase => { :quantity => "2", :gift => "1", :recipient_names => ["Jill Blow"] * 2 },
      :consumer => { :name => "Joe Blow", :email => "joe@blow.com", :password => "simian", :password_confirmation => "simian", :agree_to_terms => "1"}

    assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)

    assert_equal 2, daily_deal_purchase.reload.quantity
    assert daily_deal_purchase.gift
    assert_equal ["Jill Blow"] * 2, daily_deal_purchase.recipient_names

    consumer = daily_deal_purchase.consumer
    assert_equal "Joe Blow", consumer.name
    assert_equal "joe@blow.com", consumer.email
    assert !consumer.active?, "New consumer should not be active before purchase is complete"
    assert_nil session[:user_id], "Consumer should not be logged in"
  end

  test "update with new consumer and referral_code cookie" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)

    @request.cookies["referral_code"] = "abcd1234"
    put :update, :id => daily_deal_purchase.to_param,
      :daily_deal_purchase => { :quantity => "2", :gift => "1", :recipient_names => ["Jill Blow"] * 2 },
      :consumer => { :name => "Joe Blow", :email => "joe@blow.com", :password => "simian", :password_confirmation => "simian", :agree_to_terms => "1"}

    assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)

    assert_equal 2, daily_deal_purchase.reload.quantity
    assert daily_deal_purchase.gift
    assert_equal ["Jill Blow"] * 2, daily_deal_purchase.recipient_names

    consumer = daily_deal_purchase.consumer
    assert_equal "Joe Blow", consumer.name
    assert_equal "joe@blow.com", consumer.email
    assert_equal "abcd1234", consumer.referral_code
    assert !consumer.active?, "New consumer should not be active before purchase is complete"
    assert_nil session[:user_id], "Consumer should not be logged in"
  end

  test "update with new consumer and publisher that has a payment method of optimal" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    daily_deal_purchase.publisher.update_attribute(:payment_method, 'optimal')

    assert daily_deal_purchase.publisher.pay_using?( :optimal )

    put :update, :id => daily_deal_purchase.to_param,
      :daily_deal_purchase => { :quantity => "2", :gift => "1", :recipient_names => ["Jill Blow"] * 2 },
      :consumer => { :name => "Joe Blow", :email => "joe@blow.com", :password => "simian", :password_confirmation => "simian", :agree_to_terms => "1"}

    assert_redirected_to optimal_confirm_daily_deal_purchase_path(daily_deal_purchase)

    assert_equal 2, daily_deal_purchase.reload.quantity
    assert daily_deal_purchase.gift
    assert_equal ["Jill Blow"] * 2, daily_deal_purchase.recipient_names

    consumer = daily_deal_purchase.consumer
    assert_equal "Joe Blow", consumer.name
    assert_equal "joe@blow.com", consumer.email
    assert !consumer.active?, "New consumer should not be active before purchase is complete"
    assert_nil session[:user_id], "Consumer should not be logged in"
  end

  test "update with invalid consumer and publisher that has a payment method of optimal" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    daily_deal_purchase.publisher.update_attribute(:payment_method, 'optimal')

    assert daily_deal_purchase.publisher.pay_using?( :optimal )

    put :update, :id => daily_deal_purchase.to_param,
      :daily_deal_purchase => { :quantity => "2", :gift => "1", :recipient_names => ["Jill Blow"] * 2 },
      :consumer => { :name => "Joe Blow", :email => "joe@blow.com", :password => "", :password_confirmation => "", :agree_to_terms => "1"}

    assert_response :success
    assert_template :optimal
    assert_layout   :optimal
  end

  test "update with shopping cart publisher" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    daily_deal_purchase.daily_deal.publisher.update_attributes!(:shopping_cart => true)
    login_as daily_deal_purchase.consumer
    put :update, :id => daily_deal_purchase.to_param, :daily_deal_purchase => {}
    assert_redirected_to publisher_cart_path(daily_deal_purchase.consumer.publisher.label)
  end

  test "update with existing consumer with force_password_reset flagged" do
    daily_deal = Factory(:daily_deal)
    consumer = Factory(:consumer, :publisher => daily_deal.publisher, :force_password_reset => true)
    daily_deal_purchase = Factory(:pending_daily_deal_purchase, :consumer => consumer, :daily_deal => daily_deal)
    login_as daily_deal_purchase.consumer
    put :update, :id => daily_deal_purchase.to_param, :daily_deal_purchase => {}
    assert_redirected_to consumer_password_reset_path_or_url(daily_deal.publisher)
  end


  should "keep selected store on invalid update" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)

    advertiser = daily_deal_purchase.daily_deal.advertiser.tap do |adv|
      Factory(:store, :advertiser => adv)
      Factory(:store, :advertiser => adv)
      adv.stores.reload
    end
    store = advertiser.stores[1]

    daily_deal_purchase.daily_deal.tap do |dd|
      dd.location_required = true
      dd.max_quantity = 1
      dd.save!
    end

    put :update, :id => daily_deal_purchase.to_param, :daily_deal_purchase => { :store_id => store.id.to_s, :quantity => '2' }

    assert_response :success
    assert_template 'new'
    assert_select "select#daily_deal_purchase_store_id option[value=#{store.id}][selected]"
  end
end
