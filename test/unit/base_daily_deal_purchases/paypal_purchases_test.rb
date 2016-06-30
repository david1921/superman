require File.dirname(__FILE__) + "/../../test_helper"

class BaseDailyDealPurchases::PaypalPurchasesTest < ActiveSupport::TestCase
  include DailyDealPurchasesTestHelper

  def setup
    @valid_attributes = { :daily_deal => (dd = Factory(:daily_deal)), :consumer => Factory(:consumer, :publisher => dd.publisher), :quantity => 2 }
    @valid_gift_attributes = @valid_attributes.merge({
      :quantity => 2,
      :gift => true,
      :recipient_names => ["Bess Rackham", "Harry Kidd"]
    })
    ActionMailer::Base.deliveries.clear
    super
  end
  
  test "handle buy now" do
    daily_deal_purchase = Factory(:daily_deal_purchase,
                                  :quantity => @valid_attributes[:quantity],
                                  :daily_deal => @valid_attributes[:daily_deal],
                                  :consumer => @valid_attributes[:consumer])
    Factory(:pending_paypal_payment, :daily_deal_purchase => daily_deal_purchase)
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.count
  
    ipn_params = buy_now_ipn_params("invoice" => daily_deal_purchase.analog_purchase_id, "item_number" => daily_deal_purchase.paypal_item)
    DailyDealPurchase.handle_buy_now(ipn_params)
  
    assert_equal "captured", daily_deal_purchase.reload.payment_status
    assert_equal DateTime.parse("Jan 01, 2010 12:34:56 PST"), daily_deal_purchase.executed_at
  
    assert daily_deal_purchase.daily_deal_payment.present?
    assert_equal ipn_params["txn_id"], daily_deal_purchase.payment_gateway_id
    assert_equal ipn_params["receipt_id"], daily_deal_purchase.payment_gateway_receipt_id
    assert_equal ipn_params["invoice"], daily_deal_purchase.analog_purchase_id
    assert_equal ipn_params["payer_email"], daily_deal_purchase.payer_email
    assert_equal ipn_params["payer_status"], daily_deal_purchase.payer_status
    assert daily_deal_purchase.daily_deal_certificates.count > 0, "Should have some certificates after purchase"
    assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
    assert_equal 1, ActionMailer::Base.deliveries.size, "Should have sent confirmation email"
  end
  
  test "handle buy now with invalid payment gross" do
    (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
    ipn_params = buy_now_ipn_params(
        "invoice" => daily_deal_purchase.analog_purchase_id,
        "item_number" => daily_deal_purchase.paypal_item,
        "payment_gross" => "1.99"
    )
    assert_raise RuntimeError do
      DailyDealPurchase.handle_buy_now(ipn_params)
    end
    assert_equal "pending", daily_deal_purchase.reload.payment_status
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.count, "Should not create certificates"
    assert_equal 0, ActionMailer::Base.deliveries.size, "Should not send email"
  end
  
  test "handle buy now with unknown invoice" do
    (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
    ipn_params = buy_now_ipn_params(
        "invoice" => "1234",
        "item_number" => daily_deal_purchase.paypal_item
    )
    assert_raise RuntimeError do
      DailyDealPurchase.handle_buy_now ipn_params
    end
    assert_equal "pending", daily_deal_purchase.reload.payment_status
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.count, "Should not create certificates"
    assert_equal 0, ActionMailer::Base.deliveries.size, "Should not send email"
  end
  
  test "handle chargeback" do
    (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
    Factory(:pending_paypal_payment, :daily_deal_purchase => daily_deal_purchase)
  
    ipn_params = buy_now_ipn_params("invoice" => daily_deal_purchase.analog_purchase_id, "item_number" => daily_deal_purchase.paypal_item)
    DailyDealPurchase.handle_buy_now(ipn_params)
    assert_equal 1, ActionMailer::Base.deliveries.size, "Confirmation email"
  
    ipn_params = chargeback_ipn_params(daily_deal_purchase.reload)
  
    assert_no_difference "daily_deal_purchase.daily_deal_certificates.count" do
      DailyDealPurchase.handle_chargeback ipn_params
    end
    assert_equal "reversed", daily_deal_purchase.reload.payment_status
    assert_equal ipn_params["txn_id"], daily_deal_purchase.payment_status_updated_by_txn_id
    assert daily_deal_purchase.daily_deal_certificates.count > 0, "Should have certificates after purchase"
    assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
    assert_equal 1, ActionMailer::Base.deliveries.size, "Should not send additional email"
  end
  
  test "handle chargeback reversal" do
    (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
    Factory(:pending_paypal_payment, :daily_deal_purchase => daily_deal_purchase)
    ipn_params = buy_now_ipn_params("invoice" => daily_deal_purchase.analog_purchase_id, "item_number" => daily_deal_purchase.paypal_item)
    DailyDealPurchase.handle_buy_now(ipn_params)
    assert_equal 1, ActionMailer::Base.deliveries.size, "Confirmation email"
  
    daily_deal_purchase.reload.update_attributes! :payment_status => "reversed"
  
    ipn_params = chargeback_reversal_ipn_params(daily_deal_purchase)
    assert_no_difference "daily_deal_purchase.daily_deal_certificates.count" do
      DailyDealPurchase.handle_chargeback_reversal ipn_params
    end
    assert_equal "captured", daily_deal_purchase.reload.payment_status
    assert_equal ipn_params["txn_id"], daily_deal_purchase.payment_status_updated_by_txn_id
    assert daily_deal_purchase.daily_deal_certificates.count > 0, "Should have certificates after purchase"
    assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
    assert_equal 1, ActionMailer::Base.deliveries.size, "Should not send additional email"
  end
  
  test "handle refund" do
    (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
    Factory(:pending_paypal_payment, :daily_deal_purchase => daily_deal_purchase)
    ipn_params = buy_now_ipn_params("invoice" => daily_deal_purchase.analog_purchase_id, "item_number" => daily_deal_purchase.paypal_item)
    DailyDealPurchase.handle_buy_now(ipn_params)
    assert_equal 1, ActionMailer::Base.deliveries.size, "Confirmation email"
  
    ipn_params = refund_ipn_params(daily_deal_purchase.reload)
  
    assert_no_difference "daily_deal_purchase.daily_deal_certificates.count" do
      DailyDealPurchase.handle_refund ipn_params
    end
    assert_equal "refunded", daily_deal_purchase.reload.payment_status
    assert_equal ipn_params["txn_id"], daily_deal_purchase.payment_status_updated_by_txn_id
    assert daily_deal_purchase.daily_deal_certificates.count > 0, "Should have certificates after purchase"
    assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
    assert_equal 1, ActionMailer::Base.deliveries.size, "Should not send additional email"
  end
  
  test "handle refund location required" do
    (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
    Factory(:pending_paypal_payment, :daily_deal_purchase => daily_deal_purchase)
    ipn_params = buy_now_ipn_params("invoice" => daily_deal_purchase.analog_purchase_id, "item_number" => daily_deal_purchase.paypal_item)
    DailyDealPurchase.handle_buy_now(ipn_params)
  
    daily_deal = daily_deal_purchase.daily_deal
    Factory(:store, :advertiser => daily_deal.advertiser)
    Factory(:store, :advertiser => daily_deal.advertiser)
    daily_deal.reload
    daily_deal.update_attributes! :location_required => true
  
    ipn_params = refund_ipn_params(daily_deal_purchase.reload)
  
    assert_no_difference "daily_deal_purchase.daily_deal_certificates.count" do
      DailyDealPurchase.handle_refund ipn_params
    end
    assert_equal "refunded", daily_deal_purchase.reload.payment_status
    assert_equal ipn_params["txn_id"], daily_deal_purchase.payment_status_updated_by_txn_id
    assert daily_deal_purchase.daily_deal_certificates.count > 0, "Should have certificates after purchase"
    assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
    assert_equal 1, ActionMailer::Base.deliveries.size, "Should not send additional email"
  end
      
end
