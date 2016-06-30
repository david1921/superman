require File.dirname(__FILE__) + "/../test_helper"

class DailyDealPurchaseTest < ActiveSupport::TestCase

  should "require a consumer" do
    purchase = DailyDealPurchase.new(:consumer_id => nil)
    purchase.valid?
    assert_not_nil purchase.errors[:consumer]
  end

  context "has_one :daily_deal_payment" do
    should "have a deal payment" do
      base_purchase = Factory(:daily_deal_purchase)
      payment = Factory(:braintree_payment, :daily_deal_purchase => base_purchase)
      assert_equal payment, base_purchase.daily_deal_payment
    end
  end

  context "has_one :travelsavers_booking" do
    should "have a booking" do
      purchase = Factory(:daily_deal_purchase)
      booking = Factory(:travelsavers_booking, :daily_deal_purchase => purchase)
      assert_equal booking, purchase.travelsavers_booking
    end
  end

  context ".with_no_vouchers" do
    
    should "return only purchases with no vouchers associated" do
      pending_purchase = Factory :pending_daily_deal_purchase
      captured_purchase = Factory :captured_daily_deal_purchase
      captured_purchase_no_certs = Factory :captured_daily_deal_purchase_no_certs
      refunded_purchase = Factory :refunded_daily_deal_purchase
      refunded_purchase_no_certs = Factory :refunded_daily_deal_purchase_no_certs
      
      assert_same_elements [pending_purchase, captured_purchase_no_certs, refunded_purchase_no_certs],
                           DailyDealPurchase.with_no_vouchers
    end

  end

  context "#maximum_purchase_limit" do

    should "be called when a non-executed purchase is saved" do
      purchase = Factory :pending_daily_deal_purchase
      assert !purchase.executed?
      purchase.expects(:maximum_purchase_limit)
      purchase.save!
    end

    should "not be called on a purchase that is already executed" do
      purchase = Factory :captured_daily_deal_purchase
      assert purchase.executed?
      purchase.expects(:maximum_purchase_limit).never
      purchase.save!
    end

    should "NOT be called on a purchase that is transitioning from a non-executed state, to an executed state, " +
           "to allow our internal purchase status to accurately reflect its status in the outside world" do
      purchase = Factory :pending_daily_deal_purchase
      assert !purchase.executed?
      purchase.expects(:maximum_purchase_limit).never
      Factory :daily_deal_payment, :daily_deal_purchase => purchase
      purchase.set_payment_status!("authorized")
    end
    
  end
end
