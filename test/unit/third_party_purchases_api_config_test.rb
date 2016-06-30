require File.dirname(__FILE__) + "/../test_helper"

class ThirdPartyPurchasesApiConfigTest < ActiveSupport::TestCase
  should "belong to a user" do
    config = Factory(:third_party_purchases_api_config)
    assert config.user.is_a?(User)
  end

  should "require a user" do
    config = ThirdPartyPurchasesApiConfig.new
    assert !config.valid?
    assert_match /can't be blank/, config.errors[:user]
  end

  should "be unique to a user" do
    user = Factory(:user)
    Factory(:third_party_purchases_api_config, :user => user)
    config = Factory.build(:third_party_purchases_api_config, :user => user)
    assert !config.valid?
    assert_not_nil config.errors[:user_id]
  end

  context "#validates_format_of :callback_url" do
    should "require an https URI" do
      config = Factory.build(:third_party_purchases_api_config, :callback_url => 'http://notsecure.com')
      assert !config.valid?
      assert_not_nil config.errors[:callback_url]
    end

    should "allow nil" do
      config = Factory.build(:third_party_purchases_api_config, :callback_url => nil)
      assert config.valid?
    end
  end

  context "named_scope :with_complete_callback_config" do
    should "not return configs without a url, username and password" do
      complete = Factory(:third_party_purchases_api_config)
      no_url = Factory(:third_party_purchases_api_config, :callback_url => nil)
      no_user = Factory(:third_party_purchases_api_config, :callback_username => nil)
      no_password = Factory(:third_party_purchases_api_config, :callback_password => nil)
      results = ThirdPartyPurchasesApiConfig.with_complete_callback_config
      assert_contains results, complete
      assert_does_not_contain results, no_url
      assert_does_not_contain results, no_user
      assert_does_not_contain results, no_password
    end
  end
end
