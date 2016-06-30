require File.dirname(__FILE__) + "/../test_helper"

class ThirdPartyDealsApiControllerTest < ActionController::TestCase

  assert_no_angle_brackets :none

  context "GET to #activity_log" do
    
    context "when not logged in" do
      
      should "redirect to the login page when not logged in as" do
        get :activity_log
        assert_response :redirect
        assert_redirected_to new_session_url
      end

    end

    context "when logged in as an admin" do
      
      setup do
        @admin = Factory :admin
        @controller.stubs(:current_user).returns(@admin)
      end

      should "render successfully when there are no activity log records" do
        get :activity_log
        assert_response :success
        assert_template "third_party_deals_api/activity_log"
      end

      should "render successfully when there are activity log records" do
        2.times { Factory :api_activity_log }
        assert_equal 2, ApiActivityLog.count
        get :activity_log
        assert_response :success
        assert_template "third_party_deals_api/activity_log"
      end
      
    end
    
  end

end
