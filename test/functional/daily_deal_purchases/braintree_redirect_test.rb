require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::BraintreeRedirectTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  test "braintree redirect" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    Braintree::TransparentRedirect.expects(:confirm).returns(braintree_transaction_submitted_result(daily_deal_purchase))
    get :braintree_redirect, :id => daily_deal_purchase.to_param

    daily_deal_purchase.reload
    assert_not_nil daily_deal_purchase.daily_deal_payment
    assert_equal "captured", daily_deal_purchase.payment_status
    assert_equal daily_deal_purchase.gross_price, daily_deal_purchase.daily_deal_payment.amount
    assert_redirected_to thank_you_daily_deal_purchase_path(daily_deal_purchase)
  end

  test "braintree redirect with a daily deal variation" do
    daily_deal = Factory(:daily_deal, :publisher => Factory(:publisher, :enable_daily_deal_variations => true))
    daily_deal_variation = Factory(:daily_deal_variation, :daily_deal => daily_deal, :value => 600.00, :price => 300.00)
    daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal, :daily_deal_variation => daily_deal_variation)

    Braintree::TransparentRedirect.expects(:confirm).returns(braintree_transaction_submitted_result(daily_deal_purchase))
    get :braintree_redirect, :id => daily_deal_purchase.to_param

    daily_deal_purchase.reload
    assert_not_nil daily_deal_purchase.daily_deal_payment
    assert_equal "captured", daily_deal_purchase.payment_status
    assert_equal 300.00, daily_deal_purchase.gross_price
    assert_equal daily_deal_purchase.gross_price, daily_deal_purchase.daily_deal_payment.amount
    assert_redirected_to thank_you_daily_deal_purchase_path(daily_deal_purchase)    
  end

  test "braintree redirect execution allowed" do
    daily_deal_purchase = Factory(:voided_daily_deal_purchase, :allow_execution => true)
    Braintree::TransparentRedirect.expects(:confirm).returns(braintree_transaction_submitted_result(daily_deal_purchase))
    get :braintree_redirect, :id => daily_deal_purchase.to_param
    assert_redirected_to thank_you_daily_deal_purchase_path(daily_deal_purchase)
  end

  test "braintree redirect with not found error and purchase not executed" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    Braintree::TransparentRedirect.expects(:confirm).raises(Braintree::NotFoundError)
    get :braintree_redirect, :id => daily_deal_purchase.to_param
    assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)
  end

  test "braintree redirect with not found error and purchase executed and logged in" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase)
    Braintree::TransparentRedirect.expects(:confirm).raises(Braintree::NotFoundError)
    login_as daily_deal_purchase.consumer
    get :braintree_redirect, :id => daily_deal_purchase.to_param
    assert_redirected_to thank_you_daily_deal_purchase_path(daily_deal_purchase)
  end

  test "braintree redirect with not found error and purchase executed but not logged in" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase)
    Braintree::TransparentRedirect.expects(:confirm).raises(Braintree::NotFoundError)
    get :braintree_redirect, :id => daily_deal_purchase.to_param
    assert_redirected_to public_deal_of_day_path(daily_deal_purchase.publisher.label)
  end

  test "braintree redirect with purchase already executed and logged in" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase)

    submitted_result = braintree_transaction_submitted_result(daily_deal_purchase, :id => "dupe01")
    Braintree::TransparentRedirect.expects(:confirm).returns(submitted_result)
    voided_result = braintree_transaction_voided_result(daily_deal_purchase, :id => submitted_result.transaction.id)
    Braintree::Transaction.expects(:void).with(submitted_result.transaction.id).returns(voided_result)

    login_as daily_deal_purchase.consumer
    get :braintree_redirect, :id => daily_deal_purchase.to_param
    assert_redirected_to thank_you_daily_deal_purchase_path(daily_deal_purchase)
  end

  test "braintree redirect with purchase already executed but not logged in" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase)

    submitted_result = braintree_transaction_submitted_result(daily_deal_purchase, :id => "dupe01")
    Braintree::TransparentRedirect.expects(:confirm).returns(submitted_result)
    voided_result = braintree_transaction_voided_result(daily_deal_purchase, :id => submitted_result.transaction.id)
    Braintree::Transaction.expects(:void).with(submitted_result.transaction.id).returns(voided_result)

    get :braintree_redirect, :id => daily_deal_purchase.to_param
    assert_redirected_to public_deal_of_day_path(daily_deal_purchase.publisher.label)
  end

  test "braintree redirect with api version 1.0.0 with missing api header" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    get :braintree_redirect, :id => daily_deal_purchase.to_param, :format => "json"
    assert_response :not_acceptable
  end

  test "braintree redirect with api version 1.0.0 with invalid api header" do
    @request.env['API-Version'] = "9.9.9"
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    get :braintree_redirect, :id => daily_deal_purchase.to_param, :format => "json"
    assert_response :not_acceptable
  end

  test "braintree redirect with api version 1.0.0" do
    @request.env['API-Version'] = '1.0.0'
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    consumer            = daily_deal_purchase.consumer
    session             = @controller.send(:verifier).generate({:user_id => consumer.id, :active_session_token => consumer.active_session_token})
    Braintree::TransparentRedirect.expects(:confirm).returns(braintree_transaction_submitted_result(daily_deal_purchase))
    get :braintree_redirect, :id => daily_deal_purchase.to_param, :format => "json"
    assert_response :success
    json = JSON.parse( @response.body )
    assert_equal "true", json["captured"]
    assert_equal session, json["session"]
    assert_equal status_daily_deal_purchase_url( daily_deal_purchase.uuid, :host => AppConfig.api_host, :protocol => "http", :format => "json" ), json["status"]
  end

  test "braintree redirect with api version 3.0.0" do
    @request.env['API-Version'] = '3.0.0'
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    consumer = daily_deal_purchase.consumer
    session  = @controller.send(:verifier).generate({ :user_id => consumer.id, :active_session_token => consumer.active_session_token })
    Braintree::TransparentRedirect.expects(:confirm).returns(braintree_transaction_submitted_result(daily_deal_purchase))
    
    get :braintree_redirect, :id => daily_deal_purchase.to_param, :format => "json"
    assert_response :success
    json = JSON.parse(@response.body)
    
    assert_equal consumer.name, json['consumer']['name']
    assert_equal session, json['consumer']['session']
    assert_equal consumer.credit_available, json['consumer']['credit_available']
    assert_equal "https://test.host/consumers/#{consumer.id}/daily_deal_purchases.json", json['consumer']['connections']['purchases']
    assert_equal "https://test.host/consumers/#{consumer.id}/credit_cards.json", json['consumer']['connections']['credit_cards']
    assert_equal "https://test.host/consumers/#{consumer.id}/credit_cards.json", json['consumer']['methods']['save_credit_card']
    assert_equal "https://test.host/daily_deal_purchases/#{daily_deal_purchase.uuid}/status.json", json['connections']['details']
  end

  test "braintree redirect with not found error and purchase not executed for api version 1.0.0" do
    @request.env['API-Version'] = '1.0.0'
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    Braintree::TransparentRedirect.expects(:confirm).raises(Braintree::NotFoundError)
    get :braintree_redirect, :id => daily_deal_purchase.to_param, :format => "json"
    assert_response :not_acceptable
  end

  test "braintree redirect enqueues email job and leaves certificates in proper state" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    Braintree::TransparentRedirect.expects(:confirm).returns(braintree_transaction_submitted_result(daily_deal_purchase))
    SendCertificates.expects(:perform).with(daily_deal_purchase.id)
    get :braintree_redirect, :id => daily_deal_purchase.to_param
  end

  test "creates or updates consumer's credit card when token is present" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)

    DailyDealPurchase.stubs(:find_by_uuid! => daily_deal_purchase)

    daily_deal_purchase.consumer.expects(:create_or_update_credit_card)
    Braintree::TransparentRedirect.expects(:confirm).returns(braintree_transaction_submitted_result(daily_deal_purchase))
    get :braintree_redirect, :id => daily_deal_purchase.to_param
  end

  test "does not update credit card if token is not present" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)

    DailyDealPurchase.stubs(:find_by_uuid! => daily_deal_purchase)

    daily_deal_purchase.consumer.expects(:create_or_update_credit_card).never
    Braintree::TransparentRedirect.expects(:confirm).
      returns(braintree_transaction_submitted_result(daily_deal_purchase,
        {:credit_card_details => mock.tap { |ccd|
            ccd.stubs(:last_4 => "4545")
            ccd.stubs(:cardholder_name => "Scott Willson")
            ccd.stubs(:bin => "411111")
            ccd.stubs(:token => nil)
            ccd.stubs(:card_type => "Visa")
          }}))
    get :braintree_redirect, :id => daily_deal_purchase.to_param
  end

end
