require File.dirname(__FILE__) + "/../test_helper"

class HttpOptionsNotAllowed < ActionController::IntegrationTest
  test "OPTIONS request method should return 405" do
    get '/', {}, :REQUEST_METHOD => 'OPTIONS'
    assert_response(405)
  end
end
