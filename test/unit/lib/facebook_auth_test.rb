require File.dirname(__FILE__) + "/../../test_helper"
require File.dirname(__FILE__) + "/../../../lib/facebook_auth"

class FacebookAuthTest < ActiveSupport::TestCase

  context "facebook_auth" do
    setup do
      @publisher = Factory(:publisher, :facebook_api_key => "123", :facebook_app_secret => "abc")
    end
    should "work in the simple case" do
      client = FacebookAuth.oauth2_client(@publisher, "production")
      assert_equal "123", client.id
      assert_equal "abc", client.secret
    end
    should "raise when asking for client if no api_key" do
      publisher_with_no_key = Factory(:publisher)
      assert_raise FacebookAuth::NoFacebookApiKeyConfiguredForPublisher do
        FacebookAuth.oauth2_client(publisher_with_no_key, "production")
      end
    end
  end

end
