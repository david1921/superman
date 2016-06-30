require File.dirname(__FILE__) + "/../../test_helper"

class SyndicationApplicationControllerTest < ActionController::TestCase
  class StubController < Syndication::ApplicationController
    skip_before_filter :user_required, :require_syndication_ui_access, :only => :login_not_required

    def index
      render :text => 'anything', :layout => true
    end

    def login_not_required
      render :text => 'anything', :layout => true
    end

    def action_with_publisher
      @publisher = current_user.publisher
      render :text => 'anything', :layout => true
    end
  end

  tests SyndicationApplicationControllerTest::StubController

  fast_context "require_syndication_ui_access" do
    fast_context "user without syndication access" do
      setup do
        @user = Factory(:syndication_user, :allow_syndication_access => false)
        login_as(@user)
        get :index
      end

      should "redirect to the syndication login page" do
        assert_redirected_to syndication_login_path
      end

      should "set a flash notice" do
        assert_equal 'Unauthorized access', flash[:notice]
      end
    end

    should "return success for authenticated syndication user" do
      @user = Factory(:syndication_user)
      login_as(@user)
      get :index
      assert_response :ok
    end
  end

  context "require that the user's publisher is in network" do

    should "allow access for a user if their associated publisher is in the syndication network" do
      login_as(Factory(:syndication_user))
      get :index
      assert_response :ok
    end

    should "prevent access for a user if their associated publisher is not in the syndication network" do
      user = Factory(:syndication_user)
      user.publisher.in_syndication_network = false
      user.publisher.save!
      login_as(user)
      get :index
      assert_equal 'Unauthorized access', flash[:notice]
      assert_redirected_to syndication_login_path
    end
  end

  fast_context "layout" do
    should "not include nav when not signed in" do
      get :login_not_required
      assert_response :success
      assert_layout :syndication
      assert_select "ul#site_nav", 0
    end

    should "include nav when signed in" do
      @user = Factory(:syndication_user)
      login_as(@user)
      get :action_with_publisher
      assert_response :success
      assert_layout :syndication
      assert_select "ul#site_nav"
    end
  end
end
