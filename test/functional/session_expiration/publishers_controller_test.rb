require File.dirname(__FILE__) + "/../../test_helper"

# hydra class SessionExpiration::PublishersControllerTest

module SessionExpiration

  class PublishersControllerTest < ActionController::TestCase

    tests PublishersController

    context "GET to :index" do

      setup do
        @admin = Factory :admin
      end

      should "render the index page when an admin session with no active session token is provided " +
             "if the admin's active_session_token is nil in the DB" do
        assert_nil @admin.active_session_token
        get :index, nil, { :user_id => @admin.id }
        assert_response :success
        assert_template "publishers/index"
        assert_equal @admin.id, session[:user_id]
        assert_nil session[:active_session_token]
      end

      should "render the index page when an admin session includes the correct active session token" do
        @admin.active_session_token = "sekrittoken"
        @admin.save!
        get :index, nil, { :user_id => @admin.id, :active_session_token => "sekrittoken" }
        assert_response :success
        assert_template "publishers/index"
        assert_equal @admin.id, session[:user_id]
        assert_equal "sekrittoken", session[:active_session_token]
        assert_equal "sekrittoken", @admin.reload.active_session_token
      end

      should "not set the session user_id when the active session token in the request does not " +
             "match the one in the database, and then redirect the user to the login page" do
        @admin.active_session_token = "sekrittoken"
        @admin.save!
        get :index, nil, { :user_id => @admin.id, :active_session_token => "wrongtoken" }
        assert_redirected_to new_session_path
        assert_nil session[:user_id]
        assert_equal "wrongtoken", session[:active_session_token]
        assert_equal "sekrittoken", @admin.reload.active_session_token
      end

    end
    
  end
  
end
