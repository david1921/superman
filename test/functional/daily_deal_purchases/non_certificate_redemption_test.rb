require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::CreateWithVoucherRedemptionTest < ActionController::TestCase
  tests DailyDealPurchasesController

  context "non_voucher_redemption" do
    setup do
      @publisher = Factory(:publisher, :allow_registration_during_purchase => false)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher,
                            :non_voucher_deal => true,
                            :price => 0,
                            :min_quantity => 1,
                            :max_quantity => 1,
                            :redemption_page_description => "dummy redemption description")
      @daily_deal_purchase = Factory(:non_voucher_daily_deal_purchase, :daily_deal => @daily_deal)
    end

    context "when logged in as the owning consumer" do
      setup do
        login_as @daily_deal_purchase.consumer
        get :non_voucher_redemption, :id => @daily_deal_purchase.uuid
      end

      should "render the template" do
        assert_template :non_voucher_redemption
      end

      should "display redemption_page_description" do
        assert_select "#redemption_page_description", "dummy redemption description"
      end
    end

    should "not be accessible by a consumer who didn't purchase the deal" do
      consumer = Factory(:consumer, :publisher => @publisher)
      login_as consumer
      get :non_voucher_redemption, :id => @daily_deal_purchase.uuid
      assert_redirected_to new_publisher_daily_deal_session_path(@publisher)
    end

  end

end
