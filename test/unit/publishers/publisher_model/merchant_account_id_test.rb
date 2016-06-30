require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::MerchantAccountIdTest
module Publishers
  module PublisherModel
    class MerchantAccountIdTest < ActiveSupport::TestCase
      test "merchant_account_id is versioned" do
        publisher = Factory(:publisher)
        publisher.update_attribute(:merchant_account_id, "123ABC")

        assert_equal({"merchant_account_id" => [nil, "123ABC"]}, publisher.versions.last.changes)
      end

      test "merchant_account_id can not be all integers" do
        publisher = Factory(:publisher)
        publisher.merchant_account_id = "12345"
        publisher.save
        assert publisher.errors.on(:merchant_account_id)
      end

      test "merchant_account_id can not have spaces" do
        publisher = Factory(:publisher)
        publisher.merchant_account_id = "Test Id"
        publisher.save
        assert publisher.errors.on(:merchant_account_id)
      end
    end
  end
end