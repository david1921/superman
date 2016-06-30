require File.dirname(__FILE__) + "/../../test_helper"

# hydra class RestrictedAdminAccess::AdminsControllerTest

module RestrictedAdminAccess
  
  class AdminsControllerTest < ActionController::TestCase
    
    tests AdminsController

    def setup
      User.delete_all
      @publisher = Factory :publisher
      @admin = Factory :admin
      @restricted_admin = Factory :restricted_admin, :name => "Bob"
      @publisher_1 = Factory :publisher, :label => "p1" 
      @publisher_2 = Factory :publisher, :label => "p2" 
      @publishing_group_1 = Factory :publishing_group, :label => "pg1"
      @publishing_group_2 = Factory :publishing_group, :label => "pg2"
      
      @other_restricted_admin = Factory :restricted_admin, :login => "otherresadmin", :name => nil
      @other_restricted_admin.add_company(@publisher_2)
      @other_restricted_admin.add_company(@publishing_group_1)
    end

    fast_context "An admin user" do
      
      setup do
        login_as @admin
      end
      
      fast_context "GET to :index" do
        
        should "return all users with admin privileges, sorted by admin privilege type, then name" do
          get :index
          assert_response :success
          assert_equal [@admin, @other_restricted_admin, @restricted_admin], assigns(:users)
        end
        
      end
      
      fast_context "GET to :new" do
      
        should "show the Access Privileges options" do
          get :new
          assert_response :success
          assert_select "input[name='user[admin_privilege]']", :count => 2
        end
      
      end
      
      fast_context "POST to :create" do

        fast_context "when full admin privileges are selected" do

          should "create a user that has full admin privileges" do
            assert_difference "User.count", 1 do
              post :create, :user => { :login => "foobar", :password => "foobar42", :password_confirmation => "foobar42", :admin_privilege => User::FULL_ADMIN }
            end
            
            foobar_user = User.find_by_login("foobar")
            assert !foobar_user.has_restricted_admin_privileges?
            assert foobar_user.has_full_admin_privileges?            
          end

        end

        fast_context "when restricted admin privileges are selected, no companies" do

          should "create a user that has restricted admin privileges" do
            assert_difference "User.count", 1 do
              post :create, :user => { :login => "restricted123", :password => "foobar42", :password_confirmation => "foobar42", :admin_privilege => User::RESTRICTED_ADMIN }
            end
            
            restricted123_user = User.find_by_login("restricted123")
            assert restricted123_user.has_restricted_admin_privileges?
            assert !restricted123_user.has_full_admin_privileges?
          end

        end
        
        fast_context "when restricted admin privileges are selected, with companies" do

          should "create a user that has restricted admin privileges, and create the appropriate user_companies" do
            assert_difference "User.count", 1 do
              assert_difference "UserCompany.count", 2 do
                post :create, {
                  :user => {
                    :login => "misteradmin", :password => "foobar42",
                    :password_confirmation => "foobar42",
                    :admin_privilege => User::RESTRICTED_ADMIN
                  },
                  :manageable_publisher_ids => [@publisher_1.id],
                  :manageable_publishing_group_ids => [@publishing_group_1.id] 
                }
              end
            end
            
            misteradmin_user = User.find_by_login("misteradmin")
            assert misteradmin_user.has_restricted_admin_privileges?
            assert !misteradmin_user.has_full_admin_privileges?
            assert_equal ["p1", "pg1"], misteradmin_user.companies.map(&:label).sort
          end
          
        end

      end

    end
    
    fast_context "A restricted admin user" do
      
      setup do
        login_as @restricted_admin
      end
      
      fast_context "GET to :index" do
        should "redirect to root" do
          get :index
          assert_redirected_to "/"
        end
      end
      fast_context "GET to :new" do
        should "redirect to root" do
          get :new
          assert_redirected_to "/"
        end
      end
      fast_context "GET to :edit" do
        should "redirect to root" do
          get :edit, :id => @other_restricted_admin
          assert_redirected_to "/"
        end
      end
      fast_context "POST to :update" do
        should "redirect to root" do
          post :update, :user => @other_restricted_admin.attributes
          assert_redirected_to "/"
        end
      end

      fast_context "POST to :create" do
        should "redirect to root" do
          assert_difference "User.count", 0 do
            post :create, :user => { :login => "foobar", :password => "foobar42", :password_confirmation => "foobar42", :admin_privilege => User::FULL_ADMIN }
          end
          assert_redirected_to "/"
        end
      end

    end    
  end
  
end