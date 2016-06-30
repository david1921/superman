require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::SessionsControllerTest

class Syndication::SessionsControllerTest < ActionController::TestCase
  context "#new" do
    should "render a login form using the syndication layout" do
      get :new
      assert_response :success
      assert_layout :syndication

      assert_select "form[action=/syndication/sessions/create][method=post]" do
        assert_select "input[name='user[login]'][type=text]"
        assert_select "input[name='user[password]'][type=password]"
        assert_select "input[type=submit]"
      end
    end
  end
end