require File.dirname(__FILE__) + "/../../test_helper"

# hydra class BaseDailyDealPurchases::NamedScopesTest

class BaseDailyDealPurchases::NamedScopesTest < ActiveSupport::TestCase

  context "executed_after_or_on" do

    should "include only purchases with executed_at on or after given date" do
      Timecop.freeze(Time.zone.parse("2012 Apr 26 12:45"))
      purchase1 = Factory(:captured_daily_deal_purchase)
      Timecop.freeze(Time.zone.parse("2012 Apr 26 14:41"))
      purchase2 = Factory(:captured_daily_deal_purchase)
      Timecop.freeze(Time.zone.parse("2012 Apr 26 15:01"))
      purchase3 = Factory(:captured_daily_deal_purchase)
      Timecop.return

      purchases = BaseDailyDealPurchase.executed_after_or_on(Time.zone.parse("2012 Apr 26 14:41"))

      assert_same_elements [purchase2.id, purchase3.id], purchases.map(&:id)
    end

  end

  context "with_billed_payment_status" do

    should "include only purchases with payment_status of authorized, captured, or refunded" do
      BaseDailyDealPurchase.destroy_all

      purchase1 = Factory(:refunded_daily_deal_purchase)
      purchase2 = Factory(:pending_daily_deal_purchase)
      purchase3 = Factory(:captured_daily_deal_purchase)
      purchase4 = Factory(:authorized_daily_deal_purchase)
      purchase5 = Factory(:voided_daily_deal_purchase)

      purchases = BaseDailyDealPurchase.with_billed_payment_status

      assert_same_elements [purchase1.id, purchase3.id, purchase4.id], purchases.map(&:id)
    end

  end

  context "with_positive_actual_purchase_price" do

    should "only include purchases with a positive value for actual_purchase_price" do
      daily_deal = Factory(:daily_deal, :price => 0.0, :min_quantity => 1)
      purchase1 = Factory(:captured_daily_deal_purchase)
      purchase2 = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :quantity => 1)

      purchases = BaseDailyDealPurchase.with_positive_actual_purchase_price

      assert_equal [purchase1.id], purchases.map(&:id)
    end

  end

end
