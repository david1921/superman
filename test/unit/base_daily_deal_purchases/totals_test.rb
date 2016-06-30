require File.dirname(__FILE__) + "/../../test_helper"

class BaseDailyDealPurchases::TotalsTest < ActiveSupport::TestCase
  context "#total_price" do
    should "include voucher shipping amount" do
      purchase = Factory.build(:daily_deal_purchase, :voucher_shipping_amount => 3)
      assert_equal purchase.total_price_with_discount - purchase.credit_used + 3, purchase.total_price
    end

    should "not raise an exception when voucher shipping amount is nil" do
      purchase = Factory.build(:daily_deal_purchase, :voucher_shipping_amount => nil)
      assert purchase.total_price
    end
  end
end
