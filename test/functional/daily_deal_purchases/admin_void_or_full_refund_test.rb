require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::AdminVoidOrFullRefundTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  test "admin privilege required for admin_void_or_full_refund" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase)

    Braintree::Transaction.expects(:find).never
    Braintree::Transaction.expects(:void).never
    Braintree::Transaction.expects(:refund).never

    login_as :quentin
    post :admin_void_or_full_refund, :id => daily_deal_purchase.to_param,  :format => "js"
    assert_response :forbidden

    assert_equal "captured", daily_deal_purchase.reload.payment_status
  end

  test "admin_void_or_full_refund for purchase not executed" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    Factory(:pending_braintree_payment, :daily_deal_purchase => daily_deal_purchase)
    Braintree::Transaction.expects(:find).never
    Braintree::Transaction.expects(:void).never
    Braintree::Transaction.expects(:refund).never

    assert daily_deal_purchase.daily_deal_payment.present?

    login_as :aaron
    post :admin_void_or_full_refund, :id => daily_deal_purchase.to_param, :format => "js"
    assert_response :redirect
    assert_redirected_to daily_deal_purchases_consumers_admin_edit_url(daily_deal_purchase.id)
    assert_match(/error processing the void or full refund/i, flash[:warn])

    assert_equal "pending", daily_deal_purchase.reload.payment_status
  end

  test "admin_void_or_full_refund for purchase executed but not settled" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase)
    Braintree::Transaction.expects(:find).returns(braintree_sale_transaction(daily_deal_purchase))
    voided_result = braintree_transaction_voided_result(daily_deal_purchase)
    Braintree::Transaction.expects(:void).with(daily_deal_purchase.payment_gateway_id).returns(voided_result)

    login_as :aaron
    post :admin_void_or_full_refund, :id => daily_deal_purchase.to_param, :format => "js"
    assert_response :redirect
    assert_redirected_to daily_deal_purchases_consumers_admin_edit_url(daily_deal_purchase.id)
    assert_match(/purchase was refunded/i, flash[:notice])

    assert_equal daily_deal_purchase.consumer, assigns(:consumer)
    assert_equal "voided", daily_deal_purchase.reload.payment_status
    assert_equal "aaron", daily_deal_purchase.refunded_by
    assert_equal 0, daily_deal_purchase.amount
  end

  test "admin_void_or_full_refund for purchase executed and settled" do
    daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal)
    Braintree::Transaction.expects(:find).returns(braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::Settled))
    refunded_result = braintree_transaction_refunded_result(daily_deal_purchase)
    Braintree::Transaction.expects(:refund).with(daily_deal_purchase.payment_gateway_id).returns(refunded_result)

    login_as :aaron
    post :admin_void_or_full_refund, :id => daily_deal_purchase.to_param, :format => "js"
    assert_response :redirect
    assert_redirected_to daily_deal_purchases_consumers_admin_edit_url(daily_deal_purchase.id)
    assert_match(/purchase was refunded/i, flash[:notice])

    assert_equal daily_deal_purchase.consumer, assigns(:consumer)
    assert_equal "refunded", daily_deal_purchase.reload.payment_status
    assert_equal refunded_result.transaction.id, daily_deal_purchase.payment_status_updated_by_txn_id
    assert_equal "aaron", daily_deal_purchase.refunded_by
    assert_equal 30, daily_deal_purchase.amount.to_i
  end

  test "admin_void_or_full_refund for purchase already voided for braintree purchase" do
    daily_deal_purchase = Factory(:voided_braintree_daily_deal_purchase)
    Braintree::Transaction.expects(:find).never
    Braintree::Transaction.expects(:void).never
    Braintree::Transaction.expects(:refund).never


    login_as :aaron
    post :admin_void_or_full_refund, :id => daily_deal_purchase.to_param, :format => "js"
    assert_response :redirect
    assert_redirected_to daily_deal_purchases_consumers_admin_edit_url(daily_deal_purchase.id)
    assert_match(/error processing the void or full refund/i, flash[:warn])

    assert_equal "voided", daily_deal_purchase.reload.payment_status
    assert_equal 0, daily_deal_purchase.amount
  end

  test "admin_void_or_full_refund for purchase already voided for optimal payment purchase" do
    daily_deal_purchase = Factory(:voided_optimal_payment_daily_deal_purchase)
    Braintree::Transaction.expects(:find).never
    Braintree::Transaction.expects(:void).never
    Braintree::Transaction.expects(:refund).never


    login_as :aaron
    post :admin_void_or_full_refund, :id => daily_deal_purchase.to_param, :format => "js"
    assert_response :redirect
    assert_redirected_to daily_deal_purchases_consumers_admin_edit_url(daily_deal_purchase.id)
    assert_match(/error processing the void or full refund/i, flash[:warn])

    assert_equal "voided", daily_deal_purchase.reload.payment_status
    assert_equal 0, daily_deal_purchase.amount
  end

  test "admin_void_or_full_refund should not be able to fully refund or void an already refunded purchase" do
    daily_deal_purchase = Factory(:voided_braintree_daily_deal_purchase).tap do |purchase|
      purchase.payment_status = "refunded"
      purchase.save!
    end
    Braintree::Transaction.expects(:find).never
    Braintree::Transaction.expects(:void).never
    Braintree::Transaction.expects(:refund).never

    login_as :aaron
    post :admin_void_or_full_refund, :id => daily_deal_purchase.to_param, :format => "js"
    assert_response :redirect
    assert_redirected_to daily_deal_purchases_consumers_admin_edit_url(daily_deal_purchase.id)
    assert_match(/error processing the void or full refund/i, flash[:warn])

    assert_equal "refunded", daily_deal_purchase.reload.payment_status
    assert_equal 0, daily_deal_purchase.amount
  end

  test "admin_void_or_full_refund for purchase already refunded optimal payment purchase" do
    daily_deal_purchase = Factory(:voided_optimal_payment_daily_deal_purchase).tap do |purchase|
      purchase.payment_status = "refunded"
      purchase.save!
    end
    Braintree::Transaction.expects(:find).never
    Braintree::Transaction.expects(:void).never
    Braintree::Transaction.expects(:refund).never

    login_as :aaron
    post :admin_void_or_full_refund, :id => daily_deal_purchase.to_param, :format => "js"
    assert_response :redirect
    assert_redirected_to daily_deal_purchases_consumers_admin_edit_url(daily_deal_purchase.id)
    assert_match(/error processing the void or full refund/i, flash[:warn])

    assert_equal "refunded", daily_deal_purchase.reload.payment_status
    assert_equal 0, daily_deal_purchase.amount
  end

  test "admin_void_or_full_refund for purchase executed and settled with Flagship merchant account" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase)
    sale_transaction = braintree_sale_transaction(daily_deal_purchase, {
      :status => Braintree::Transaction::Status::Settled, :merchant_account_id => "AnalogAnalytics2"
    })
    Braintree::Transaction.expects(:find).returns(sale_transaction)
    Braintree::Transaction.expects(:void).never
    Braintree::Transaction.expects(:refund).never
    DailyDealPurchase.any_instance.stubs(:production_flagship_refund?).returns(true)
    login_as :aaron
    assert_no_difference 'daily_deal_purchase.reload.amount' do
      post :admin_void_or_full_refund, :id => daily_deal_purchase.to_param, :format => "js"
      assert_response :redirect
      assert_redirected_to daily_deal_purchases_consumers_admin_edit_url(daily_deal_purchase.id)
      assert_match(/error processing the void or full refund/i, flash[:warn])
    end
    assert_equal daily_deal_purchase.consumer, assigns(:consumer)
    assert_equal "captured", daily_deal_purchase.reload.payment_status
    assert_nil daily_deal_purchase.refunded_by
  end

  context "admin_void_or_full_refund for Travelsavers purchases" do
    
    setup do
      @admin = Factory :admin
    end

    should "refund a captured purchase" do
      booking = Factory :successful_travelsavers_booking
      TravelsaversBooking.any_instance.stubs(:confirmation_number).returns("424242")
      purchase = booking.daily_deal_purchase
      assert purchase.captured?
      assert_equal "booking_success_payment_success", booking.state
      login_as @admin
      post :admin_void_or_full_refund, :id => purchase.to_param, :format => "js"
      assert_response :redirect
      assert_redirected_to daily_deal_purchases_consumers_admin_edit_url(purchase.id)
      purchase.reload
      booking.reload
      assert purchase.refunded?
      assert_equal 15, purchase.refund_amount
      assert_equal "booking_canceled_payment_unknown", booking.state
      assert_equal "Changed status of booking #424242 to refunded", flash[:notice]
    end

    should "void an authorized purchase" do
      booking = Factory :successful_travelsavers_booking_with_failed_payment
      TravelsaversBooking.any_instance.stubs(:confirmation_number).returns("424242")
      purchase = booking.daily_deal_purchase
      assert purchase.authorized?
      assert_equal "booking_success_payment_fail", booking.state
      login_as @admin
      post :admin_void_or_full_refund, :id => purchase.to_param, :format => "js"
      assert_response :redirect
      assert_redirected_to daily_deal_purchases_consumers_admin_edit_url(purchase.id)
      purchase.reload
      booking.reload
      assert purchase.voided?
      assert purchase.refunded_at.present?
      assert purchase.refund_amount.zero?
      assert_equal "booking_canceled_payment_unknown", booking.state
      assert_equal "Changed status of booking #424242 to refunded", flash[:notice]
    end

    should "display an error that the purchase cannot be refunded if the purchase was pending" do
      booking = Factory :pending_travelsavers_booking
      purchase = booking.daily_deal_purchase
      assert purchase.pending?
      login_as @admin
      post :admin_void_or_full_refund, :id => purchase.to_param, :format => "js"
      assert_response :redirect
      assert_redirected_to daily_deal_purchases_consumers_admin_edit_url(purchase.id)
      purchase.reload
      assert purchase.pending?
      assert purchase.refund_amount.zero?
      assert_match(/error processing the void or full refund/i, flash[:warn])
    end

  end

  context "with an Entertainment purchase" do
    setup do
      @daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => 2)
      DailyDealPurchase.any_instance.stubs(:production_entertainment_refund? => true)
      
      sale_transaction = braintree_sale_transaction(@daily_deal_purchase, {
        :status => Braintree::Transaction::Status::Settled
      })
      @txn_id = @daily_deal_purchase.daily_deal_payment.payment_gateway_id
      assert @txn_id.present?, "Factory payment should have a transaction ID"

      login_as :aaron
    end
   
    should "not void or refund in admin_void_or_full_refund" do
      Braintree::Transaction.expects(:find).never
      Braintree::Transaction.expects(:void).never
      Braintree::Transaction.expects(:refund).never
      
      assert_no_difference '@daily_deal_purchase.reload.amount' do
        post :admin_void_or_full_refund, :id => @daily_deal_purchase.to_param, :format => "js"
        assert_response :redirect
        assert_redirected_to daily_deal_purchases_consumers_admin_edit_url(@daily_deal_purchase.id)
        assert_match(/error processing the void or full refund/i, flash[:warn])
        assert_match(/entertainment braintree transaction #{@txn_id}/i, flash[:warn])
      end
      assert_equal @daily_deal_purchase.consumer, assigns(:consumer)
      assert_equal "captured", @daily_deal_purchase.reload.payment_status
      assert_nil @daily_deal_purchase.refunded_by
    end

  end

end
