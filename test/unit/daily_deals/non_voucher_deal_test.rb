require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::NonVoucherDealTest

module DailyDeals
  class NonVoucherDealTest < ActiveSupport::TestCase

    context "non-voucher deal validations" do
      setup do
        @daily_deal = Factory(:non_voucher_daily_deal)
      end

      should "not allow a price of > $0" do
        assert_good_value @daily_deal, :price, 0
        assert_bad_value @daily_deal, :price, 10
      end

      should "not allow a min_quantity or max_quantity of > 1" do
        assert_good_value @daily_deal, :min_quantity, 1
        assert_bad_value @daily_deal, :min_quantity, 5
        assert_good_value @daily_deal, :max_quantity, 1
        assert_bad_value @daily_deal, :max_quantity, 5
      end

    end

  end
end
