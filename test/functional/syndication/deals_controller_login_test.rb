require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::DealsControllerLoginTest

class Syndication::DealsControllerLoginTest < ActionController::TestCase
  
  def setup
    @controller = Syndication::DealsController.new
  end
  
  fast_context "login" do
    context "with no authenticated account" do
      setup do
        get :list
      end
      should redirect_to( "syndication login path" ) { syndication_login_path }
    end

    fast_context "with user that does not have syndication access" do
      setup do
        @publisher = Factory(:publisher, :self_serve => true)
        @user = Factory(:user, :company => @publisher, :allow_syndication_access => false)
        login_as @user
        get :list
      end
      should redirect_to( "syndication login path" ) { syndication_login_path }
    end
    
    fast_context "with a publisher user that has syndication access" do
      setup do
        @publisher = Factory(:publisher, :self_serve => true)
        @user = Factory(:user, :company => @publisher, :allow_syndication_access => true)
        login_as @user
        get :list
      end
      should "have success response code" do
        assert_response :success
      end
      should render_template(:list)
      should render_with_layout(:syndication)
      should assign_to(:search_request)
      should assign_to(:search_response)
      should assign_to(:categories)
      should assign_to(:publisher)
      should_not assign_to(:publishing_group)
      should "not have publisher change form" do
        assert_select "form[id='publisher_form']", :count => 0
      end
    end
    
    fast_context "with a publishing group that is not self serve" do
      setup do
        @publishing_group = Factory(:publishing_group, :self_serve => false)
        @publisher_1 = Factory(:publisher, :publishing_group => @publishing_group)
        @publisher_2 = Factory(:publisher, :publishing_group => @publishing_group)
        @user = Factory(:user, :company => @publishing_group, :allow_syndication_access => true)
        login_as @user
        get :list
      end
      should redirect_to( "syndication login path" ) { syndication_login_path }
    end
    
    fast_context "with a publishing group user without syndication access" do
      setup do
        @publishing_group = Factory(:publishing_group, :self_serve => false)
        @publisher_1 = Factory(:publisher, :publishing_group => @publishing_group)
        @publisher_2 = Factory(:publisher, :publishing_group => @publishing_group)
        @user = Factory(:user, :company => @publishing_group, :allow_syndication_access => false)
        login_as @user
        get :list
      end
      should redirect_to( "syndication login path" ) { syndication_login_path }
    end
    
    fast_context "with a publishing group user that has no publishers in syndication network" do
      setup do
        @publishing_group = Factory(:publishing_group, :self_serve => true)
        @publisher_1 = Factory(:publisher, :publishing_group => @publishing_group, :in_syndication_network => false)
        @publisher_2 = Factory(:publisher, :publishing_group => @publishing_group, :in_syndication_network => false)
        @user = Factory(:user, :company => @publishing_group, :allow_syndication_access => true)
        login_as @user
        get :list
      end
      should redirect_to( "syndication login path" ) { syndication_login_path }
    end
    
    fast_context "with a publishing group user that has syndication access" do
      setup do
        @publishing_group = Factory(:publishing_group, :self_serve => true)
        @publisher_1 = Factory(:publisher, :publishing_group => @publishing_group)
        @publisher_2 = Factory(:publisher, :publishing_group => @publishing_group)
        @user = Factory(:user, :company => @publishing_group, :allow_syndication_access => true)
        login_as @user
        get :list
      end
      should "have success response code" do
        assert_response :success
      end
      should render_template(:list)
      should render_with_layout(:syndication)
      should assign_to(:search_request)
      should assign_to(:search_response)
      should assign_to(:categories)
      should assign_to(:publisher)
      should assign_to(:publishing_group)
      should "have publisher change form" do
        assert_select "form[id='publisher_form']", :count => 1 do
          assert_select "option[value=#{@publisher_1.id}]"
          assert_select "option[value=#{@publisher_2.id}]"
        end
      end
    end
    
  end
  
end
