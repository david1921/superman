require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::PreviewNonVoucherRedemptionTest < ActionController::TestCase
  tests DailyDealsController
  include DailyDealHelper



  context "preview non voucher redemption" do
    setup do
      @publisher  = Factory(:publisher)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher, :redemption_page_description => "redemption description")
    end

    should "allow admin to view preview non voucher redemption html for daily deal" do
      login_as Factory(:admin)
      get :preview_non_voucher_redemption, :id => @daily_deal.to_param
      assert_response :success
    end

    should "not allow non admin users to preview non voucher redemption html for daily deal" do
      login_as Factory(:consumer)
      get :preview_non_voucher_redemption, :id => @daily_deal.to_param
      assert_response 302
    end
  end


  context "non voucher redemption view" do
    setup do
      login_as Factory(:admin)
      @publisher  = Factory(:publisher)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher, :redemption_page_description => "redemption description")
      get :preview_non_voucher_redemption, :id => @daily_deal.to_param
    end
    should "render the template" do
      assert_template :non_voucher_redemption
    end

    should "display redemption_page_description" do
      assert_select "#redemption_page_description", "redemption description"
    end
  end
end
