require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchases::CallbacksTest < ActiveSupport::TestCase
  context "before_validation" do
    should "clear the mailing address when not required" do
      purchase = Factory.build(:daily_deal_purchase, :mailing_address => Factory.build(:address), :fulfillment_method => "email")
      purchase.valid?
      assert_nil purchase.mailing_address
    end
  end
end
