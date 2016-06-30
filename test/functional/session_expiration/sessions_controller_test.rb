require File.dirname(__FILE__) + "/../../test_helper"

# hydra class SessionExpiration::SessionsControllerTest

module SessionExpiration
  
  class SessionsControllerTest < ActionController::TestCase

    tests SessionsController

    context "POST to :create" do

      should "set the active_session_token to nil when it is nil in the database" do
        admin = Factory :admin, :login => "moxie", :password => "foobar", :password_confirmation => "foobar"
        assert_nil admin.active_session_token
        post :create, :user => { :login => "moxie", :password => "foobar" }
        assert_redirected_to "/"
        assert_equal admin.id, session[:user_id]
        assert session.has_key?("active_session_token")
        assert_nil session[:active_session_token]
        assert_nil admin.reload.active_session_token
      end

      should "set the active_session_token to the user's active_session_token in the database, when it is present" do
        admin = Factory :admin, :login => "moxie", :password => "foobar", :password_confirmation => "foobar", :active_session_token => "mysekrittoken"
        post :create, :user => { :login => "moxie", :password => "foobar" }
        assert_redirected_to "/"
        assert_equal admin.id, session[:user_id]
        assert_equal "mysekrittoken", session[:active_session_token]
        assert_equal "mysekrittoken", admin.reload.active_session_token
      end
      
    end
    
    context "POST to :create when a user enters the wrong password and crosses the Users::Lockable::MAXIMUM_FAILED_ATTEMPTS threshold" do

      setup do
        @admin = Factory :admin
        @admin.failed_login_attempts = Users::Lockable::MAXIMUM_FAILED_ATTEMPTS - 1
        @admin.save!
      end

      should "lock the user's account and set a flash warning telling them what happened" do
        post :create, :user => { :login => @admin.login, :password => "wrongpassword" }
        @admin.reload
        assert @admin.access_locked?, "user account should be locked"
        assert_response :success
        assert_equal "Sorry, your account has been temporarily locked due to too many failed login attempts. Please contact your Analog Analytics account manager directly, or contact us at (858) 509-4796 or bbdsupport@analoganalytics.com to unlock your account.",
                     flash[:warn]
      end

      context "with a locked account" do

        should "set the locked account response with an incorrect password" do
          @admin.lock_access!
          post :create, :user => { :login => @admin.login, :password => "wrongpassword" }
          assert_response :success
          assert_equal "Sorry, your account has been temporarily locked due to too many failed login attempts. Please contact your Analog Analytics account manager directly, or contact us at (858) 509-4796 or bbdsupport@analoganalytics.com to unlock your account.",
                       flash[:warn]
        end

        should "set the locked account response with the correct password" do
          @admin.lock_access!
          post :create, :user => { :login => @admin.login, :password => "monkey" }
          assert_response :success
          assert_equal "Sorry, your account has been temporarily locked due to too many failed login attempts. Please contact your Analog Analytics account manager directly, or contact us at (858) 509-4796 or bbdsupport@analoganalytics.com to unlock your account.",
                       flash[:warn]
        end

      end

    end

    context "GET to :destroy" do

      setup do
        @admin = Factory :admin
      end
      
      should "reset the logged-in user's active_session_token" do
        @admin.active_session_token = "beforetoken"
        @admin.save!
        User.any_instance.expects(:generate_new_active_session_token).returns("aftertoken")
        login_as @admin
        assert_equal "beforetoken", session[:active_session_token]
        get :destroy
        assert_redirected_to login_path
        assert_nil session[:user_id]
        assert_nil session[:active_session_token]
        assert_equal "aftertoken", @admin.reload.active_session_token
      end

      should "reset the logged-in user's active_session_token - example when the session has no active_session_token set" do
        assert_nil @admin.active_session_token
        User.any_instance.expects(:generate_new_active_session_token).returns("mynewtoken")
        login_as @admin
        assert_nil session[:active_session_token]
        get :destroy
        assert_redirected_to login_path
        assert_nil session[:user_id]
        assert_nil session[:active_session_token]
        assert_equal "mynewtoken", @admin.reload.active_session_token
      end

    end

  end

end
