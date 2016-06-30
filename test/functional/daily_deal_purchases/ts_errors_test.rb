require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::ErrorTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  context "GET to error, when the purchase has 'unknown' errors" do
    
    setup do
      @publisher = Factory :publisher, :label => "travelsavers", :payment_method => "travelsavers"
      @advertiser = Factory :advertiser, :publisher => @publisher
      @daily_deal = Factory :daily_deal, :advertiser => @advertiser, :travelsavers_product_code => "CXP-TEST"
      @purchase = Factory :pending_daily_deal_purchase
    end
    
    should "display to the user that an error occurred and that they should not resubmit " +
           "the transaction" do
      get :ts_errors, { :id => @purchase.to_param }, {}, { :travelsavers_errors_user_cannot_fix => ["a strange error", "an even stranger error"] }
      assert_response :success
      assert_select "div#errorExplanation.travelsavers" do
        assert_select "ul" do
          assert_select "li", "a strange error"
          assert_select "li", "an even stranger error"
        end
      end
    end
    
  end

end