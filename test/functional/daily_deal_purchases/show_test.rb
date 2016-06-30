require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::ShowTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  test "show pdf" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase)

    login_as daily_deal_purchase.consumer
    get :show,
        :publisher_id => daily_deal_purchase.publisher.to_param,
        :consumer_id => daily_deal_purchase.consumer.to_param,
        :id => daily_deal_purchase.to_param,
        :format => "pdf"
    assert_response :success
  end

  test "show pdf for partially refunded deal" do
    daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
    purchase = partially_refunded_purchase(daily_deal, 2, 30)

    login_as purchase.consumer
    get :show,
        :publisher_id => purchase.publisher.to_param,
        :consumer_id => purchase.consumer.to_param,
        :id => purchase.to_param,
        :format => "pdf"
    assert_response :success
  end

  test "show pdf admin" do
    login_as Factory(:admin)

    daily_deal_purchase = Factory(:captured_daily_deal_purchase)
    get :show,
      :publisher_id => daily_deal_purchase.publisher.to_param,
      :consumer_id => daily_deal_purchase.consumer.to_param,
      :id => daily_deal_purchase.to_param,
        :format => "pdf"
    assert_response :success
  end

  test "show pdf admin for partially refunded deal" do
    daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
    purchase = partially_refunded_purchase(daily_deal, 2, 30)

    login_as purchase.consumer
    get :show,
        :publisher_id => purchase.publisher.to_param,
        :consumer_id => purchase.consumer.to_param,
        :id => purchase.to_param,
        :format => "pdf"
    assert_response :success
  end

  test "show pdf for custom template" do
    publisher = Factory(:publisher, :label => "doubletakedeals")
    deal = Factory(:daily_deal, :publisher => publisher)
    store = Factory(:store)
    purchase = Factory(:captured_daily_deal_purchase, :daily_deal => deal, :store => store)

    login_as purchase.consumer

    get :show,
        :publisher_id => purchase.publisher.to_param,
        :consumer_id => purchase.consumer.to_param,
        :id => purchase.to_param,
        :format => "pdf"

    assert_response :success
  end

  should "render 404 without publisher_id" do
    get :show
    assert_response 404
  end

  context "can_manage_consumers" do

    context "with self serve publisher" do

      setup do
        @purchase  = Factory(:captured_daily_deal_purchase)
        @publisher = @purchase.daily_deal.publisher
        @user      = Factory(:user, :company => @publisher)
        @consumer  = @purchase.consumer
      end

      should "be able to print the daily deal certificates if user can manage consumers" do
        @user.update_attribute(:can_manage_consumers, true)
        login_as @user
        get :show, :publisher_id => @publisher.to_param, :consumer_id => @consumer.to_param, :id => @purchase.to_param, :format => "pdf"
        assert_response :success
      end

      should "NOT be able to print the daily deal certificates if user can NOT manage consumers" do
        @user.update_attribute(:can_manage_consumers, false)
        login_as @user
        get :show, :publisher_id => @publisher.to_param, :consumer_id => @consumer.to_param, :id => @purchase.to_param, :format => "pdf"
        assert_redirected_to daily_deal_login_path(@publisher)
      end
    end
  end
end
