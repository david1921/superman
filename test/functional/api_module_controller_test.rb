require File.dirname(__FILE__) + "/../test_helper"

class ApiModuleTestController < ActionController::Base
  include Api
  
  before_filter :check_and_set_api_version_header

  self.view_paths = ["#{Rails.root}/test/views"]
  
  def test
    render with_api_version
  end

  def help
    render with_api_version(:template => "api_module_test/explicit")
  end
end

class ApiModuleControllerTest < ActionController::TestCase
  tests ApiModuleTestController
  
  test "invoking default template with no identical or lower version present should select unversioned default template" do
    @request.env["API-Version"] = "1.0.0"
    get :test, :format => "json"
    assert_response :success
    assert_match /unversioned default template for json/i, @response.body
  end

  test "invoking default template with identical version present should select that template" do
    @request.env["API-Version"] = "2.0.0"
    get :test, :format => "json"
    assert_response :success
    assert_match /default template version 2.0.0 for json/i, @response.body
  end

  test "invoking default template with lower version present should select that template" do
    @request.env["API-Version"] = "2.1.0"
    get :test, :format => "json"
    assert_response :success
    assert_match /default template version 2.0.0 for json/i, @response.body
  end
  
  test "invoking default template with no matching format should raise missing template" do
    @request.env["API-Version"] = "2.0.0"
    assert_raise ActionView::MissingTemplate do
      get :test, :format => "xml"
    end
  end

  test "invoking explicit template with no identical or lower version present should select unversioned explicit template" do
    @request.env["API-Version"] = "1.0.0"
    get :help, :format => "json"
    assert_response :success
    assert_match /unversioned explicit template for json/i, @response.body
  end

  test "invoking explicit template with identical version present should select that template" do
    @request.env["API-Version"] = "2.0.0"
    get :help, :format => "json"
    assert_response :success
    assert_match /explicit template version 2.0.0 for json/i, @response.body
  end

  test "invoking explicit template with lower version present should select that template" do
    @request.env["API-Version"] = "2.1.0"
    get :help, :format => "json"
    assert_response :success
    assert_match /explicit template version 2.0.0 for json/i, @response.body
  end

  test "invoking explicit template with no matching format should raise missing template" do
    @request.env["API-Version"] = "2.0.0"
    assert_raise ActionView::MissingTemplate do
      get :help, :format => "xml"
    end
  end
end
