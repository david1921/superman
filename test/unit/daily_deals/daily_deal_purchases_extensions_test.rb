require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeals::DailyDealPurchasesExtensionsTest < ActiveSupport::TestCase
  context "#build" do
    should "build a DailyDealPurchase for the deal" do
      deal = Factory(:daily_deal)
      purchase = deal.daily_deal_purchases.build
      assert purchase.is_a?(DailyDealPurchase)
      assert_equal deal, purchase.daily_deal
    end
  end
end