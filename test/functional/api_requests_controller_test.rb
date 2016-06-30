require File.dirname(__FILE__) + "/../test_helper"

class ApiRequestsControllerTest < ActionController::TestCase
  def test_api_root_routing
    options = { :protocol => "https", :controller => "api_requests", :action => "root", :format => "xml" }
    assert_routing "/super-banner", options
  end
end
