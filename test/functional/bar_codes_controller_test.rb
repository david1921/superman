require File.dirname(__FILE__) + "/../test_helper"

class BarCodesControllerTest < ActionController::TestCase

  context "GET to :show, format jpg" do
    
    setup do
      @daily_deal_purchase = Factory :captured_daily_deal_purchase
    end
    
    should "return a 404 Not Found when no matching serial number exists" do
      get :show, :daily_deal_purchase_id => @daily_deal_purchase.to_param,
          :id => "doesnt-exist", :format => "jpg"
      assert_response :not_found
    end
    
    should "return a 200 Ok when a barcode exists" do
      voucher = @daily_deal_purchase.daily_deal_certificates.first
      voucher.update_attribute :bar_code, "1234"
      get :show, :daily_deal_purchase_id => @daily_deal_purchase.to_param,
          :id => voucher.serial_number, :format => "jpg"
      assert_response :success
    end
    
    should "set Content-Type to image/jpeg" do
      voucher = @daily_deal_purchase.daily_deal_certificates.first
      voucher.update_attribute :bar_code, "1234"
      get :show, :daily_deal_purchase_id => @daily_deal_purchase.to_param,
          :id => voucher.serial_number, :format => "jpg"
      assert_response :success
      assert "image/jpeg", @response.headers["Content-Type"]
    end
    
  end

  context "show with format jpg and voucher_has_qr_code set" do
    setup do
      @daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => Factory(:daily_deal, :voucher_has_qr_code => true))
    end

   should "set Content-Type to image/jpeg" do
     voucher = @daily_deal_purchase.daily_deal_certificates.first
     get :show, :daily_deal_purchase_id => @daily_deal_purchase.to_param, :id => voucher.serial_number, :format => "jpg"
     assert_response :success
     assert "image/jpeg", @response.headers["Content-Type"]
   end
  end

end
