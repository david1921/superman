require File.dirname(__FILE__) + "/../../models_helper"

class BaseDailyDealPurchases::TotalsTest < Test::Unit::TestCase
  def setup
    @obj = Object.new.extend(BaseDailyDealPurchases::Totals)
  end

  context "#total_price" do
    should "include voucher shipping amount" do
      @obj.stubs(:total_price_with_discount).returns(10)
      @obj.stubs(:credit_used).returns(5)
      @obj.stubs(:voucher_shipping_amount).returns(3)
      assert_equal 8, @obj.total_price
    end

    should "not raise an exception when voucher shipping amount is nil" do
      @obj.stubs(:total_price_with_discount).returns(10)
      @obj.stubs(:credit_used).returns(5)
      @obj.stubs(:voucher_shipping_amount).returns(nil)
      assert @obj.total_price
    end
  end
end
