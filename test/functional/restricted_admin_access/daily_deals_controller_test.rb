require File.dirname(__FILE__) + "/../../test_helper"

# hydra class RestrictedAdminAccess::DailyDealsControllerTest

module RestrictedAdminAccess
  
  class DailyDealsControllerTest < ActionController::TestCase
    
    tests DailyDealsController
    
    fast_context "A restricted admin user" do
    
      setup do
        @publishing_group_1 = Factory :publishing_group, :label => "pg1"
        @publishing_group_2 = Factory :publishing_group, :label => "pg2"
        @publishing_group_3 = Factory :publishing_group, :label => "pg3"

        @publisher_1 = Factory :publisher, :label => "p1", :publishing_group => nil
        @publisher_2 = Factory :publisher, :label => "p2", :publishing_group => nil
        @publisher_3 = Factory :publisher, :label => "p3", :publishing_group => @publishing_group_2
        @publisher_4 = Factory :publisher, :label => "p4", :publishing_group => @publishing_group_3

        @advertiser_1 = Factory :advertiser, :publisher => @publisher_1, :name => "a1" 
        @advertiser_2 = Factory :advertiser, :publisher => @publisher_2, :name => "a2" 
        @advertiser_3 = Factory :advertiser, :publisher => @publisher_3, :name => "a3"
      
        @daily_deal_1 = Factory :daily_deal, :advertiser => @advertiser_1
        @daily_deal_2 = Factory :daily_deal, :advertiser => @advertiser_2 

        @restricted_admin = Factory :restricted_admin
        @restricted_admin.user_companies << UserCompany.new(:company => @publishing_group_2)
        @restricted_admin.user_companies << UserCompany.new(:company => @publisher_1) 
      
        login_as @restricted_admin             
      end
    
      fast_context "GET to :edit on a deal the restricted admin has permission to access" do
      
        setup do
          get :edit, :id => @daily_deal_1.to_param
        end
      
        should "render a 200 OK" do
          assert_response :success
          assert_template "daily_deals/edit"
          assert_equal @daily_deal_1, assigns(:daily_deal)
        end
      
      end
    
      fast_context "GET to :edit on a deal the restricted admin does not have permission to access" do
      
        should "raise an ActiveRecord::RecordNotFound" do
          assert_raises(ActiveRecord::RecordNotFound) do
            get :edit, :id => @daily_deal_2.to_param
          end
        end
      
      end
    
    end
    
  end
  
end