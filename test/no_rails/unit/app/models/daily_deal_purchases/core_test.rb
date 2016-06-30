require File.dirname(__FILE__) + "/../../models_helper"

class DailyDealPurchases::CoreTest < Test::Unit::TestCase
  def setup
    @purchase = Object.new.extend(DailyDealPurchases::Core)
  end

  context "#travelsavers_product_code" do
    should "return the variation's product code" do
      mock_variation = mock('variation', :travelsavers_product_code => "VAR-CODE")
      @purchase.stubs(:daily_deal_variation).returns(mock_variation)
      assert_equal "VAR-CODE", @purchase.travelsavers_product_code
    end

    should "return the deal's' product code" do
      mock_deal = mock('daily deal', :travelsavers_product_code => "DEAL-CODE")
      @purchase.stubs(:daily_deal).returns(mock_deal)
      @purchase.stubs(:daily_deal_variation).returns(nil)
      assert_equal "DEAL-CODE", @purchase.travelsavers_product_code
    end
  end
end
