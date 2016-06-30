require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::BraintreeCredentialsTest
module Publishers
  module PublisherModel
    class BraintreeCredentialsTest < ActiveSupport::TestCase
      test "find_braintree_credentials for publisher not in group" do
        publisher = Factory.build(:publisher, :label => "8newsnow")

        BraintreeCredentials.expects(:find).with("8newsnow", nil)
        publisher.find_braintree_credentials!
      end

      test "find_braintree_credentials for publisher in group with label" do
        publishing_group = Factory.build(:publishing_group, :label => "villagevoicemedia")
        publisher = Factory.build(:publisher, :label => "houstonpress", :publishing_group => publishing_group)

        BraintreeCredentials.expects(:find).with("houstonpress", "villagevoicemedia")
        publisher.find_braintree_credentials!
      end

      test "find_braintree_credentials for publisher in group without label" do
        publishing_group = Factory.build(:publishing_group, :label => nil)
        publisher = Factory.build(:publisher, :label => "houstonpress", :publishing_group => publishing_group)

        BraintreeCredentials.expects(:find).with("houstonpress", nil)
        publisher.find_braintree_credentials!
      end
    end
  end
end