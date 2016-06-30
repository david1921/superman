require File.dirname(__FILE__) + "/../test_helper"

class HomeControllerTest < ActionController::TestCase
  test "login required for index" do
    get :index
    assert_redirected_to(new_session_path)
  end

  test "default demo login for index" do
    user = create_demo_user!
    get :index
    assert_redirected_to publisher_advertisers_path(user.publisher)
  end

  test "index as publisher having self serve" do
    publishers(:my_space).update_attributes! :self_serve => true
    login_as :quentin
    get :index
    assert_redirected_to publisher_advertisers_path(publishers(:my_space))
  end

  test "index as publisher lacking self serve" do
    publishers(:my_space).update_attributes! :self_serve => false
    login_as :quentin
    get :index
    assert_redirected_to reports_path
  end

  test "index with super privilege" do
    login_as :aaron
    get :index
    assert_redirected_to publishers_path
  end

  test "index on reports server" do
    @request.stubs(:subdomains).returns(['reports'])
    login_as :aaron
    get :index
    assert_redirected_to reports_path
  end

  test "index as affiliate" do
    user = Factory(:affiliate)
    login_as user
    get :index
    assert_redirected_to affiliate_publisher_daily_deals_path(user.publisher)
  end

  test "index for publisher with admin landing page" do
    user = Factory(:bespoke_admin)
    assert user.company.self_serve?
    login_as user
    get :index
    assert_response :ok
    assert_template 'themes/bespoke/admin/index'
    assert_select 'ul' do
      assert_select 'li' do
        assert_select 'a', 'Admin'
        assert_select 'ul' do
          assert_select "li > a[href=#{new_publisher_advertiser_path(user.publisher)}]", 'Setup merchant'
          assert_select "li > a[href=#{publisher_advertisers_path(user.publisher)}]", 'Search'
          assert_select 'li > a', 'Validate'
        end
      end

      assert_select 'li > a', 'Service'
      assert_select 'li > a', 'Sales'
    end
  end

  test "txt411 homepage" do
    assert_routing "/txt411/index", :controller => "home", :action => "txt411_index", :host => "txt411.com"
    get :txt411_index
    assert_response :success
    assert_template "txt411/index"
    assert_layout "txt411/application"
  end

  test "txt411 support" do
    assert_routing "/txt411/support", :controller => "home", :action => "support", :host => "txt411.com"
    get :support
    assert_response :success
    assert_template "txt411/support"
    assert_layout "txt411/application"
  end 
end
