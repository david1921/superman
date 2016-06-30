require File.dirname(__FILE__) + "/../../test_helper"

# hydra class SessionExpiration::DailyDealsControllerTest

module SessionExpiration

  class DailyDealsControllerTest < ActionController::TestCase

    tests DailyDealsController

    context "GET to :show" do

      setup do
        @consumer = Factory :consumer
        @deal = Factory :daily_deal, :publisher => @consumer.publisher
      end

      should "render the deal show page when a consumer session with no active session token is provided " +
             "if the consumer's active_session_token is nil in the DB" do
        assert_nil @consumer.active_session_token
        get :show, { :id => @deal.to_param }, { :user_id => @consumer.id }
        assert_response :success
        assert_template "daily_deals/show"
        assert_equal @consumer.id, session[:user_id]
        assert_nil session[:active_session_token]
      end

      should "render the deal show page, authenticated, when a consumer session includes the correct active session token" do
        @consumer.active_session_token = "sekrittoken"
        @consumer.save!
        get :show, { :id => @deal.to_param }, { :user_id => @consumer.id, :active_session_token => "sekrittoken" }
        assert_response :success
        assert_template "daily_deals/show"
        assert_select "a", :text => "Sign In", :count => 0
        assert_select "a", "Sign Out"
        assert_equal @consumer.id, session[:user_id]
        assert_equal "sekrittoken", session[:active_session_token]
        assert_equal "sekrittoken", @consumer.reload.active_session_token
      end

      should "not set the session user_id when the active session token in the request does not " +
             "match the one in the database, and show the unauthenticated view of the deal page" do
        @consumer.active_session_token = "sekrittoken"
        @consumer.save!
        get :show, { :id => @deal.to_param }, { :user_id => @consumer.id, :active_session_token => "wrongtoken" }
        assert_response :success
        assert_template "daily_deals/show"
        assert_select "a", "Sign In"
        assert_select "a", :text => "Sign Out", :count => 0
        assert_nil session[:user_id]
        assert_equal "wrongtoken", session[:active_session_token]
        assert_equal "sekrittoken", @consumer.reload.active_session_token
      end

    end
    
  end
  
end
