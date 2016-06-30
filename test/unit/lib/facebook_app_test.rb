require File.dirname(__FILE__) + "/../../test_helper"
require File.dirname(__FILE__) + "/../../../lib/facebook_auth"

class FacebookAppTest < ActiveSupport::TestCase

  context "publishers" do
    setup do
      @publisher = Factory(:publisher, :facebook_app_id => "fb-id-1", :facebook_api_key => "123", :facebook_app_secret => "abc")
    end
    should "use publisher's app_id, apikey and apisecret for production" do
      facebook_credentials = FacebookApp.facebook_credentials(@publisher, "production")
      assert_equal "fb-id-1", facebook_credentials[:app_id]
      assert_equal "123", facebook_credentials[:api_key]
      assert_equal "abc", facebook_credentials[:app_secret]
    end
    should "use staging app_id, apikey and apisecret for staging" do
      facebook_credentials = FacebookApp.facebook_credentials(@publisher, "staging")
      assert_equal "115577455178934", facebook_credentials[:app_id]
      assert_equal "85fd0030ec90d0cdb9b9d702f39c24ba", facebook_credentials[:api_key]
      assert_equal "b04b8063860eed74b839176c33658ea2", facebook_credentials[:app_secret]
    end
    should "use sandbox id/key/secret for development and test environments" do
      %w( development test ).each do |env|
        facebook_credentials = FacebookApp.facebook_credentials(@publisher, env)
        assert_equal "136197326425095", facebook_credentials[:app_id]
        assert_equal "d037226862befdaf3d377f47eb1ec37c", facebook_credentials[:api_key]
        assert_equal "3b2df3a7e2589a30da5bb1bcca4d3290", facebook_credentials[:app_secret]
      end
    end
    should "use sandbox id/key/secret as default when running a test" do
      facebook_credentials = FacebookApp.facebook_credentials(@publisher)
      assert_equal "136197326425095", facebook_credentials[:app_id]
      assert_equal "d037226862befdaf3d377f47eb1ec37c", facebook_credentials[:api_key]
      assert_equal "3b2df3a7e2589a30da5bb1bcca4d3290", facebook_credentials[:app_secret]
    end
    should "use publishing_group id/key/secret if publisher has none of its own" do
      publishing_group = Factory(:publishing_group, :facebook_app_id => "pg1-id", :facebook_api_key => "publishing-group-123", :facebook_app_secret => "publishing-group-abc")
      publisher_with_no_key_or_secret = Factory(:publisher, :publishing_group => publishing_group)
      facebook_credentials = FacebookApp.facebook_credentials(publisher_with_no_key_or_secret, "production")
      assert_equal "pg1-id", facebook_credentials[:app_id]
      assert_equal "publishing-group-123", facebook_credentials[:api_key]
      assert_equal "publishing-group-abc", facebook_credentials[:app_secret]
    end
    should "use publishing_group id/key/secret if publisher's blank (empty string)" do
      publishing_group = Factory(:publishing_group, :facebook_app_id => "pg1-id", :facebook_api_key => "publishing-group-123", :facebook_app_secret => "publishing-group-abc")
      publisher_with_no_key_or_secret = Factory(:publisher, :publishing_group => publishing_group, :facebook_app_id => "", :facebook_api_key => "", :facebook_app_secret => "")
      facebook_credentials = FacebookApp.facebook_credentials(publisher_with_no_key_or_secret, "production")
      assert_equal "pg1-id", facebook_credentials[:app_id]
      assert_equal "publishing-group-123", facebook_credentials[:api_key]
      assert_equal "publishing-group-abc", facebook_credentials[:app_secret]
    end
  end

  context "publishing_groups" do
    should "have app_id, apikey and apisecret" do
      publishing_group = Factory(:publishing_group, :facebook_app_id => "pg1-id", :facebook_api_key => "123", :facebook_app_secret => "abc")
      facebook_credentials = FacebookApp.facebook_credentials(publishing_group, "production")
      assert_equal "pg1-id", facebook_credentials[:app_id]
      assert_equal "123", facebook_credentials[:api_key]
      assert_equal "abc", facebook_credentials[:app_secret]
    end
  end

end
