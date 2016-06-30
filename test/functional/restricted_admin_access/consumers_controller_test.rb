require File.dirname(__FILE__) + "/../../test_helper"

# hydra class RestrictedAdminAccess::ConsumersControllerTest

module RestrictedAdminAccess
  
  class ConsumersControllerTest < ActionController::TestCase
    
    tests ConsumersController
    
    def setup
      Consumer.delete_all
      
      @pg1 = Factory :publishing_group
      @pg2 = Factory :publishing_group
      
      @p1 = Factory :publisher, :publishing_group => @pg1
      @p2 = Factory :publisher, :publishing_group => @pg2
      @p3 = Factory :publisher
      
      @c1 = Factory :consumer, :publisher => @p1, :created_at => 10.seconds.ago 
      @c2 = Factory :consumer, :publisher => @p2, :created_at => 9.seconds.ago
      @c3 = Factory :consumer, :publisher => @p3, :created_at => 8.seconds.ago
      
      @admin = Factory :admin
      @restricted_admin = Factory :restricted_admin
      @restricted_admin.add_company(@pg2)
      @restricted_admin.add_company(@p3)
    end
    
    fast_context "An admin user" do
      
      setup do
        login_as @admin
      end
      
      fast_context "GET to :index" do
        
        should "assign all consumers to the @consumers instance variable" do
          get :index
          assert_response :success
          assert_equal [@c3, @c2, @c1], assigns(:consumers)
        end
        
      end
      
    end
    
    fast_context "A restricted admin user" do
      
      setup do
        login_as @restricted_admin
      end
      
      fast_context "GET to :index" do
        
        should "assign to @consumers only consumers that the restricted admin can manage" do
          get :index
          assert_response :success
          assert_equal [@c3, @c2], assigns(:consumers)          
        end
        
      end
      
    end
    
  end
  
end