require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class ManageablePublishers::Reports::PublishersControllerTest

module ManageablePublishers
  
  module Reports
    
    class PublishersControllerTest < ActionController::TestCase
      
      tests ::Reports::PublishersController
      
      def setup
        @publishing_group = Factory :publishing_group
        @publisher = Factory :publisher, :publishing_group => @publishing_group
        @user = Factory :user_without_company
        Factory :user_company, :user => @user, :company => @publisher
        login_as @user
      end
      
      context "GET to :purchased_daily_deals" do
        
        should "call Publisher.observable_by, passing in the current user" do
          mock_finder = mock()
          mock_finder.stubs(:find).returns(@publisher)
          Publisher.expects(:observable_by).with(@user).returns(mock_finder)
          get :purchased_daily_deals, :dates_begin => "2011-07-01", :dates_end => "2011-08-01"
          assert_response :success
        end
        
      end
      
    end
    
  end
  
end