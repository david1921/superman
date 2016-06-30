require File.dirname(__FILE__) + "/../../test_helper"

# hydra class RestrictedAdminAccess::PublishingGroupsControllerTest

module RestrictedAdminAccess
  
  class PublishingGroupsControllerTest < ActionController::TestCase
    
    tests PublishingGroupsController
    
    fast_context "A restricted admin user" do
      
      setup do
        @publishing_group_1 = Factory :publishing_group, :label => "pg1"
        @publishing_group_2 = Factory :publishing_group, :label => "pg2"
        
        @restricted_admin = Factory :restricted_admin
        @restricted_admin.user_companies << UserCompany.new(:company => @publishing_group_1)
        
        login_as @restricted_admin
      end
      
      fast_context "GET to :edit with a pub group the user has permission to access" do
        
        setup do
          get :edit, :id => @publishing_group_1.to_param
        end

        should "render a 200 OK" do
          assert_response :success
          assert_template "publishing_groups/edit"
          assert_equal @publishing_group_1, assigns(:publishing_group)
        end

      end
      
      fast_context "GET to :edit with a pub group the user does not have permission to access" do
        
        should "raise an ActiveRecord::RecordNotFound" do
          assert_raises(ActiveRecord::RecordNotFound) do
            get :edit, :id => @publishing_group_2.to_param
          end
        end
        
      end
      
    end
    
  end
  
end