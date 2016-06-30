require File.dirname(__FILE__) + "/../test_helper"

class ApiRequestTest < ActiveSupport::TestCase
  def test_invalid_mobile_number_error
    error = ApiRequest::InvalidPhoneNumberError.new
    assert_not_nil error, "Should create an error object"
    assert_equal ApiRequest::INVALID_PHONE_NUMBER[0], error.code, "Error code"
    assert_equal ApiRequest::INVALID_PHONE_NUMBER[1], error.text, "Error text"
  end
end
