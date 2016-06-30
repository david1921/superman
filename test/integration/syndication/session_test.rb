require File.dirname(__FILE__) + "/../../test_helper"

class SessionTest < ActionController::IntegrationTest
  should "see login page" do
    get syndication_login_path
    assert_response :success
  end

  should "redirect to syndication after login" do
    get syndication_login_path
    user = Factory(:syndication_user)
    post '/syndication/sessions/create', :user => {:login => user.login, :password => 'test'}
    assert_redirected_to list_syndication_deals_path
  end

  should "redirect to originally requested page after login" do
    request_path = grid_syndication_deals_path
    get request_path
    assert_redirected_to syndication_login_path
    user = Factory(:syndication_user)
    post '/syndication/sessions/create', :user => {:login => user.login, :password => 'test'}
    assert_redirected_to request_path
  end
end
