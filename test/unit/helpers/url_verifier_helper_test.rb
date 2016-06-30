require File.dirname(__FILE__) + "/../../test_helper"

class UrlVerifierHelperTest < ActionView::TestCase

  context "verifiable_url" do

    setup do
      @verifier_class = Class.new
      @verifier_class.send(:include, UrlVerifier)
      @verifier = @verifier_class.new
    end

    should "generate a URL that can be verified with UrlVerifier#verify_url" do
      original_url = "http://example.com"
      signed_url = verifiable_url(original_url)
      assert_not_equal original_url, signed_url
      assert_equal original_url, @verifier.verify_url(signed_url)
    end

  end

end
