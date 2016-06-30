require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::EditTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  test "edit" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    get :edit, :id => daily_deal_purchase.to_param
    assert_response :success
    assert_equal daily_deal_purchase, assigns(:daily_deal_purchase)
    assert_nil session[:user_id], "Consumer should not be logged in"
  end

  test "edit gift purchase with shipping_address_message" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase, :gift => true, :recipients_attributes => [Factory.attributes_for(:daily_deal_purchase_recipient)], :recipient_names => ['anything'])
    daily_deal_purchase.daily_deal.update_attributes!(:requires_shipping_address => true, :shipping_address_message => (sa_msg = "We need to know where to send your stuff."))
    get :edit, :id => daily_deal_purchase.to_param
    assert_response :success
    assert_select "p.shipping_address_message", :text => sa_msg
  end

  test "edit with a publisher with payment method of optimal" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    daily_deal_purchase.publisher.update_attribute(:payment_method, 'optimal')
    get :edit, :id => daily_deal_purchase.to_param
    assert_response :success
    assert_template :optimal
    assert_layout   :optimal
  end
end
