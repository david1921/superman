require File.dirname(__FILE__) + "/../test_helper"

class BraintreeCredentialsTest < ActiveSupport::TestCase
  test "find after init" do
    BraintreeCredentials.init({
      "default" => {
        :merchant_id => "aaaaaaaaaaaaaaaa",
        :public_key  => "bbbbbbbbbbbbbbbb",
        :private_key => "cccccccccccccccc"
      }
    })
    BraintreeCredentials.find "unknown1", "unknown2"
    assert_equal "aaaaaaaaaaaaaaaa", Braintree::Configuration.merchant_id
    assert_equal "bbbbbbbbbbbbbbbb", Braintree::Configuration.public_key
    assert_equal "cccccccccccccccc", Braintree::Configuration.private_key
  end

  test "find with one known label and one nil label after load uses known label" do
    BraintreeCredentials.load File.expand_path("test/config/braintree", Rails.root)
    BraintreeCredentials.find "entertainment", nil
    assert_equal "1111111111111111", Braintree::Configuration.merchant_id
    assert_equal "2222222222222222", Braintree::Configuration.public_key
    assert_equal "3333333333333333", Braintree::Configuration.private_key
  end

  test "find with one known and one unknown label after load uses known label" do
    BraintreeCredentials.load File.expand_path("test/config/braintree", Rails.root)
    BraintreeCredentials.find "entertainment", "uknown"
    assert_equal "1111111111111111", Braintree::Configuration.merchant_id
    assert_equal "2222222222222222", Braintree::Configuration.public_key
    assert_equal "3333333333333333", Braintree::Configuration.private_key
  end

  test "find with one unknown and one known label after load uses known label" do
    BraintreeCredentials.load File.expand_path("test/config/braintree", Rails.root)
    BraintreeCredentials.find "unknown", "entertainment"
    assert_equal "1111111111111111", Braintree::Configuration.merchant_id
    assert_equal "2222222222222222", Braintree::Configuration.public_key
    assert_equal "3333333333333333", Braintree::Configuration.private_key
  end

  test "find with one unknown label and one nil label after load uses default" do
    BraintreeCredentials.load File.expand_path("test/config/braintree", Rails.root)
    BraintreeCredentials.find "unknown", nil
    assert_equal "aaaaaaaaaaaaaaaa", Braintree::Configuration.merchant_id
    assert_equal "bbbbbbbbbbbbbbbb", Braintree::Configuration.public_key
    assert_equal "cccccccccccccccc", Braintree::Configuration.private_key
  end

  test "find with two unknown labels after load uses default" do
    BraintreeCredentials.load File.expand_path("test/config/braintree", Rails.root)
    BraintreeCredentials.find "unknown1", "unknown2"
    assert_equal "aaaaaaaaaaaaaaaa", Braintree::Configuration.merchant_id
    assert_equal "bbbbbbbbbbbbbbbb", Braintree::Configuration.public_key
    assert_equal "cccccccccccccccc", Braintree::Configuration.private_key
  end
end
