require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeals::QrCodeTest < ActionController::TestCase
  
  tests DailyDealsController
  
  def setup
    @daily_deal = Factory :daily_deal
  end
  
  context "GET to :qr_code, format eps" do
    
    should "render the raw qr code eps file" do
      get :qr_code, :id => @daily_deal.to_param, :format => "eps"
      assert_equal "application/postscript", @response.content_type
      assert @response.body.is_a?(Proc)
    end
        
  end
  
end
