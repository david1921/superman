require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::PreviewPDFTest < ActionController::TestCase
  tests DailyDealsController
  include DailyDealHelper

   context "preview pdf" do

     setup do
       @publisher  = Factory(:publisher)
       @advertiser = Factory(:advertiser, :publisher => @publisher)
       @daily_deal = Factory(:daily_deal, :advertiser => @advertiser)
     end

     should "allow admin to view preview pdf for daily deal" do
       login_as Factory(:admin)
       get :preview_pdf, :id => @daily_deal.to_param
       assert_response :success
     end


   end
end
