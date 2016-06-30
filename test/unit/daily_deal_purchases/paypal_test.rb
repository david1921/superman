# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchase::PaypalTest < ActiveSupport::TestCase
  include DailyDealPurchasesTestHelper

  context "#buy_now" do
    setup do
      @purchase = Factory(:pending_daily_deal_purchase)
      @payment = Factory.build(:pending_paypal_payment, :daily_deal_purchase => @purchase )
      @ipn_params = {
          "tax" => "0.00", "payment_status" => "Completed", "address_name" => "Demo Buyer", "address_city" => "San Diego",
          "receiver_email" => "demo_merchant@analoganalytics.com", "invoice" => "#{@purchase.id}-BBP", "address_zip" => "92121",
          "business" => "demo_merchant@analoganalytics.com", "address_country" => "United States", "quantity" => "5",
          "receiver_id" => "96GH9L6W5QGLA", "transaction_subject" => "DAILY_DEAL_PURCHASE", "payment_gross" => "15.00",
          "notify_version" => "3.4", "payment_fee" => "3.93", "mc_currency" => "USD",
          "address_street" => "123 Main Street", "address_country_code" => "US",
          "verify_sign" => "AFcWxV21C7fd0v3bYYYRCpSSRl31AsNXocSNlTKqJfSWSsf.9VaxPId-", "txn_id" => "6J214691YC922815U",
          "item_name" => "$50.00 Deal to Bruen-Johns", "shipping" => "0.00", "txn_type" => "web_accept",
          "test_ipn" => "1", "mc_gross" => "125.00", "address_status" => "confirmed", "payer_id" => "MZRXQPPPY7TDN",
          "charset" => "windows-1252", "mc_fee" => "3.93", "last_name" => "Buyer",
          "custom" => "DAILY_DEAL_PURCHASE", "payer_status" => "verified", "address_state" => "CA",
          "protection_eligibility" => "Eligible", "payment_date" => "16:14:04 Apr 20, 2012 PDT",
          "payer_email" => "demo@analoganalytics.com", "residence_country" => "US", "handling_amount" => "0.00",
          "ipn_track_id" => "d69cca15917e8", "first_name" => "Demo", "payment_type" => "instant", "item_number" => "66690-BBD"
      }.with_indifferent_access
    end

    should "set the buyer's name and full address in the payment" do
      purchase = @payment.daily_deal_purchase
      purchase.buy_now(@payment, @ipn_params)

      assert_equal "Demo", @payment.billing_first_name
      assert_equal "Buyer", @payment.billing_last_name
      assert_equal "123 Main Street", @payment.billing_address_line_1
      assert_equal "San Diego", @payment.billing_city
      assert_equal "CA", @payment.billing_state
      assert_equal "92121", @payment.payer_postal_code
      assert_equal "US", @payment.billing_country_code

      assert @payment.valid?
    end
  end
end
