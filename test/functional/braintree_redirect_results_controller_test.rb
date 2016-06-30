require File.dirname(__FILE__) + "/../test_helper"

class BraintreeRedirectResultsControllerTest < ActionController::TestCase
  def test_index_with_0_failures
    5.times do
      BraintreeRedirectResult.create! :daily_deal_purchase => Factory.create(:captured_daily_deal_purchase), :error => false
    end

    with_user_required(:guest) do
      get :index
    end
    assert_response :success
    assert (braintree_redirect_results = assigns(:braintree_redirect_results)).is_a?(Array)
    assert_equal 5, braintree_redirect_results.size
    assert_template :index
    
    assert_select "p", :text => /WARNING/,  :count => 0
    assert_select "p", :text => /CRITICAL/, :count => 0
  end

  def test_index_with_6_failures
    2.times do
      BraintreeRedirectResult.create! :daily_deal_purchase => Factory.create(:captured_daily_deal_purchase), :error => false
    end
    6.times do
      BraintreeRedirectResult.create! :daily_deal_purchase => Factory.create(:authorized_daily_deal_purchase), :error => true, :error_message => "NO"
    end
    1.times do
      BraintreeRedirectResult.create! :daily_deal_purchase => Factory.create(:captured_daily_deal_purchase), :error => false
    end
    
    with_user_required(:guest) do
      get :index
    end
    assert_response :success
    assert (braintree_redirect_results = assigns(:braintree_redirect_results)).is_a?(Array)
    assert_equal 9, braintree_redirect_results.size
    assert_template :index

    assert_select "p", :text => /WARNING/,  :count => 1
    assert_select "p", :text => /CRITICAL/, :count => 0
  end

  def test_index_with_8_failures
    1.times do
      BraintreeRedirectResult.create! :daily_deal_purchase => Factory.create(:captured_daily_deal_purchase), :error => false
    end
    8.times do
      BraintreeRedirectResult.create! :daily_deal_purchase => Factory.create(:authorized_daily_deal_purchase), :error => true, :error_message => "NO"
    end
    
    with_user_required(:guest) do
      get :index
    end
    assert_response :success
    assert (braintree_redirect_results = assigns(:braintree_redirect_results)).is_a?(Array)
    assert_equal 9, braintree_redirect_results.size
    assert_template :index
    
    assert_select "p", :text => /WARNING/,  :count => 0
    assert_select "p", :text => /CRITICAL/, :count => 1
  end
end
