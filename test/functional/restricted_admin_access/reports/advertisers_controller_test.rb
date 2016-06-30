require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class RestrictedAdminAccess::Reports::AdvertisersControllerTest

module RestrictedAdminAccess
  
  module Reports
    
    class AdvertisersControllerTest < ActionController::TestCase
      
      tests ::Reports::AdvertisersController
      
      context "A restricted admin user" do
        
        setup do
          Timecop.freeze(Time.zone.parse("2011-10-14 00:00:00 ")) do
            @publisher_1 = Factory :publisher
            @publisher_2 = Factory :publisher
            @publisher_3 = Factory :publisher

            @advertiser_1 = Factory :advertiser, :publisher => @publisher_1
            @advertiser_2 = Factory :advertiser, :publisher => @publisher_2

            @daily_deal_1 = Factory :daily_deal, :advertiser => @advertiser_1
            @daily_deal_2 = Factory :daily_deal, :advertiser => @advertiser_2

            @ddp_1 = Factory :captured_daily_deal_purchase, :daily_deal => @daily_deal_1, :executed_at => Time.zone.now
            @ddp_2 = Factory :captured_daily_deal_purchase, :daily_deal => @daily_deal_2, :executed_at => Time.zone.now

            @restricted_admin = Factory :restricted_admin
            @restricted_admin.add_company(@publisher_3)
            @restricted_admin.add_company(@publisher_2)
          end
        end
        
        context "GET to :purchased_daily_deals with format HTML" do
          
          setup do
            login_as @restricted_admin
            get :purchased_daily_deals, :id => @advertiser_2.to_param, :dates_begin => "2011-10-01", :dates_end => "2011-10-31"
            assert_response :success
          end
          
          should "NOT assign to @daily_deal_certificates" do
            assert_nil assigns(:daily_deal_certificates)
          end
          
        end
        
        context "GET to :purchased_daily_deals with format XML" do
          
          setup do
            login_as @restricted_admin
            get :purchased_daily_deals, :id => @advertiser_2.to_param, :dates_begin => "2011-10-01", :dates_end => "2011-10-31", :format => "xml"
            assert_response :success
          end
          
          should "assign to @daily_deal_certificates" do
            ddcs = assigns(:daily_deal_certificates)
            assert_equal 1, ddcs.length
            assert_equal @ddp_2, ddcs.first.daily_deal_purchase
          end
          
        end
        
      end
      
    end
    
  end
  
end