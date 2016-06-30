require File.dirname(__FILE__) + "/../test_helper"

class DailyDealPurchaseChecksControllerTest < ActionController::TestCase

  context "GET to :ensure_all_captured_and_refunded_purchases_have_vouchers" do
    
    should "respond with OK if all captured and refunded purchases have vouchers" do
      captured_purchase = Factory :captured_daily_deal_purchase
      refunded_purchase = Factory :refunded_daily_deal_purchase
      assert captured_purchase.daily_deal_certificates.present?
      assert refunded_purchase.daily_deal_certificates.present?

      get :ensure_all_captured_and_refunded_purchases_have_vouchers
      assert_match /^OK /, @response.body
    end

    should "respond with OK if there are captured purchases that do not have " +
           "vouchers, but they are only a few minutes old" do
      now = Time.now
      Timecop.freeze(now - 5.minutes) { Factory :captured_daily_deal_purchase_no_certs }
      Timecop.freeze(now) { get :ensure_all_captured_and_refunded_purchases_have_vouchers }
      assert_match /^OK /, @response.body
    end

    should "respond with OK if there are refunded purchases that do not have " +
           "vouchers, but they are only a few minutes old" do
      now = Time.now
      Timecop.freeze(now - 5.minutes) { Factory :refunded_daily_deal_purchase_no_certs }
      Timecop.freeze(now) { get :ensure_all_captured_and_refunded_purchases_have_vouchers }
      assert_match /^OK /, @response.body
    end

    should "respond with CRITICAL if there is a captured purchase with no certs " +
           "that is only 5 minutes old, but has an executed_at that is nil" do
      now = Time.now
      Timecop.freeze(now - 5.minutes) do
        purchase = Factory :captured_daily_deal_purchase_no_certs
        purchase.executed_at = nil
        purchase.save!
        assert_nil purchase.executed_at
      end

      Timecop.freeze(now) { get :ensure_all_captured_and_refunded_purchases_have_vouchers }
      assert_match /^CRITICAL .*'rake debug:purchases_missing_vouchers' \*\* on util1 \*\*.*/, @response.body
    end


    should "respond with CRITICAL if there are captured that do not have " +
           "vouchers, and they are at least 10 minutes old" do
      now = Time.now
      Timecop.freeze(now - 10.minutes) { Factory :captured_daily_deal_purchase_no_certs }
      Timecop.freeze(now) { get :ensure_all_captured_and_refunded_purchases_have_vouchers }
      assert_match /^CRITICAL .*'rake debug:purchases_missing_vouchers' \*\* on util1 \*\*.*/, @response.body
    end

    should "respond with CRITICAL if there are refunded that do not have " +
           "vouchers, and they are more than 10 minutes old" do
      now = Time.now
      Timecop.freeze(now - 10.minutes) { Factory :refunded_daily_deal_purchase_no_certs }
      Timecop.freeze(now) { get :ensure_all_captured_and_refunded_purchases_have_vouchers }
      assert_match /^CRITICAL .*'rake debug:purchases_missing_vouchers' \*\* on util1 \*\*.*/, @response.body
    end

  end
  
end
