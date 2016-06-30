require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ManageablePublishers::ReportsControllerTest

module ManageablePublishers
  
  class ReportsControllerTest < ActionController::TestCase
    
    tests ReportsController
    
    def setup
      @publishing_group = Factory :publishing_group
      @user = Factory :user, :company => @publishing_group
      login_as @user
    end
    
    context "GET to :purchased_daily_deals with HTML format" do
      
      should "call Publisher.observable_by, with the current user" do
        Publisher.expects(:observable_by).never
        get :purchased_daily_deals, :dates_begin => "2011-07-01", :dates_end => "2011-07-15"
        assert_response :success
      end
      
    end

    context "GET to :purchased_daily_deals with XML format" do
      
      should "call Publisher.observable_by, with the current user" do
        Publisher.expects(:observable_by).with(@user).returns(nil)
        get :purchased_daily_deals, :dates_begin => "2011-07-01", :dates_end => "2011-07-15", :format => "xml"
        assert_response :success
      end
      
    end

    
  end
  
end

