require File.dirname(__FILE__) + "/../../test_helper"

class UrlVerifierTest < ActiveSupport::TestCase

  test "ApplicationController should include UrlVerifier" do
    assert ApplicationController.include?(UrlVerifier)
  end

  context "#verify_url" do

    setup do
      @verifier_class = Class.new
      @verifier_class.send(:include, UrlVerifier)
      @verifier = @verifier_class.new
    end

    should "raise an exception when passed a URL that can't be verified, and log the exception to Exceptional" do
      expected_error_message = "'http://example.com' is not a verifiable URL. Are you rendering this URL as, e.g., a redirect_to form parameter? If so, try verifiable_url(url) instead."
      Exceptional.expects(:handle).with(instance_of(ArgumentError))
      e = assert_raises(ArgumentError) { @verifier.verify_url("http://example.com") }
      assert_equal expected_error_message, e.message
    end

    should "return an empty string, when passed an empty string" do
      assert_equal "", @verifier.verify_url("")
    end

  end

end
