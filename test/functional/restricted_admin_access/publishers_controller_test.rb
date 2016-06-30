require File.dirname(__FILE__) + "/../../test_helper"

# hydra class RestrictedAdminAccess::PublishersControllerTest

module RestrictedAdminAccess
  
  class PublishersControllerTest < ActionController::TestCase
    
    tests PublishersController
    
    fast_context "A restricted admin user" do
    
      setup do
        @publishing_group_1 = Factory :publishing_group, :label => "pg1"
        @publishing_group_2 = Factory :publishing_group, :label => "pg2"
      
        @publisher_1 = Factory :publisher, :label => "p1", :publishing_group => nil
        @publisher_2 = Factory :publisher, :label => "p2", :publishing_group => nil
        @publisher_3 = Factory :publisher, :label => "p3", :publishing_group => @publishing_group_1
        @publisher_4 = Factory :publisher, :label => "p4", :publishing_group => @publishing_group_2
      
        @restricted_admin = Factory :restricted_admin
        @restricted_admin.user_companies << UserCompany.new(:company => @publisher_1)
        @restricted_admin.user_companies << UserCompany.new(:company => @publishing_group_1)
      
        login_as @restricted_admin
      end

      fast_context "GET to #index" do
      
        setup do
          get :index
        end

        should "assign to @publishers only the publisher visible to the restricted admin" do
          assert_equal [], assigns(:publishers).map(&:label)
        end
      
        should "assign to @publishing_groups only the publishing groups visible to the restricted admin" do
          assert_equal [], assigns(:publishing_groups).map(&:label)
        end
      
      end

      fast_context "GET to #index with search" do
      
        setup do
          get :index, :text => "*"
        end

        should "assign to @publishers only the publisher visible to the restricted admin" do
          assert_equal [ "p1" ], assigns(:publishers).map(&:label)
        end
      
        should "assign to @publishing_groups only the publishing groups visible to the restricted admin" do
          assert_equal [ "pg1" ], assigns(:publishing_groups).map(&:label)
        end
      
      end
    
      fast_context "GET to #edit on a publisher the restricted admin has permission to edit" do
      
        setup do
          get :edit, :id => @publisher_1.to_param
        end
        
        should "render the edit page" do
          assert_response :success
          assert_template "publishers/edit"
        end
        
      end
      
      fast_context "GET to #edit on a publisher the restricted admin does not have permission to edit" do
      
        should "raise an ActiveRecord::RecordNotFound exception" do
          assert_raises(ActiveRecord::RecordNotFound) do
            get :edit, :id => @publisher_2.to_param
          end
        end
        
      end
      
      fast_context "PUT to #update on a publisher the restricted admin has permission to edit" do
        
        setup do
          put :update, :id => @publisher_3.to_param
        end
        
        should "redirect to the edit publisher path and assign to flash" do
          assert_redirected_to edit_publisher_path(@publisher_3)
          assert_match /updated/i, flash[:notice]
        end
        
      end
      
      fast_context "PUT to #update on a publisher the restricted admin does NOT have permission to edit" do
        
        should "raise an ActiveRecord::RecordNotFound" do
          
          assert_raises(ActiveRecord::RecordNotFound) do
            put :update, :id => @publisher_2.to_param
          end
          
        end
        
      end
      
      fast_context "POST to #create" do
        
        should "create the publisher and redirect to the publisher edit page" do
          assert_difference "Publisher.count", 1 do
            assert_difference "UserCompany.count", 1 do
              post :create, :publisher => { :label => "mytestpub", :state => "AL", :name => "My Test Pub", :address_line_1 => "100 Test Road", :city => "Testville", :zip => "90210", :country_id => Country::US.id }
            end
          end
          mytestpub = Publisher.find_by_label!("mytestpub")
          assert @restricted_admin.can_manage?(mytestpub)
          assert_redirected_to edit_publisher_url(:id => mytestpub.to_param)
          assert_equal mytestpub, assigns(:publisher)
        end
        
      end
      
    end
    
  end
  
end
