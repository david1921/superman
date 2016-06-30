require File.dirname(__FILE__) + "/../../test_helper"

# hydra class SessionExpiration::DailyDealSessionsControllerTest

module SessionExpiration
  
  class DailyDealSessionsControllerTest < ActionController::TestCase

    tests DailyDealSessionsController

    context "POST to :create" do

      should "set the active_session_token to nil when it is nil in the database" do
        consumer = Factory :consumer, :email => "moxie@example.com", :password => "foobar", :password_confirmation => "foobar"
        assert_nil consumer.active_session_token
        post :create, :session => { :email => "moxie@example.com", :password => "foobar" }, :publisher_id => consumer.publisher_id
        assert_redirected_to public_deal_of_day_path(consumer.publisher.label)
        assert_equal consumer.id, session[:user_id]
        assert session.has_key?("active_session_token")
        assert_nil session[:active_session_token]
        assert_nil consumer.reload.active_session_token
      end

      should "set the active_session_token to the user's active_session_token in the database, when it is present" do
        consumer = Factory :consumer, :email => "moxie@example.com", :password => "foobar", :password_confirmation => "foobar", :active_session_token => "mysekrittoken"
        post :create, :session => { :email => "moxie@example.com", :password => "foobar" }, :publisher_id => consumer.publisher_id
        assert_redirected_to public_deal_of_day_path(consumer.publisher.label)
        assert_equal consumer.id, session[:user_id]
        assert_equal "mysekrittoken", session[:active_session_token]
        assert_equal "mysekrittoken", consumer.reload.active_session_token
      end
      
    end

    context "GET to :destroy" do

      setup do
        @consumer = Factory :consumer
      end
      
      should "reset the logged-in user's active_session_token" do
        @consumer.active_session_token = "beforetoken"
        @consumer.save!
        Consumer.any_instance.expects(:generate_new_active_session_token).returns("aftertoken")
        login_as @consumer
        assert_equal "beforetoken", session[:active_session_token]
        get :destroy, :publisher_id => @consumer.publisher_id
        assert_redirected_to public_deal_of_day_path(@consumer.publisher.label)
        assert_nil session[:user_id]
        assert_nil session[:active_session_token]
        assert_equal "aftertoken", @consumer.reload.active_session_token
      end

      should "reset the logged-in user's active_session_token - example when the session has no active_session_token set" do
        assert_nil @consumer.active_session_token
        Consumer.any_instance.expects(:generate_new_active_session_token).returns("mynewtoken")
        login_as @consumer
        assert_nil session[:active_session_token]
        get :destroy, :publisher_id => @consumer.publisher_id
        assert_redirected_to public_deal_of_day_path(@consumer.publisher.label)
        assert_nil session[:user_id]
        assert_nil session[:active_session_token]
        assert_equal "mynewtoken", @consumer.reload.active_session_token
      end

    end

  end

end
