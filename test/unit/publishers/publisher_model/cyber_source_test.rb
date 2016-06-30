require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::CyberSourceTest

module Publishers
  module PublisherModel
    class CyberSourceTest < ActiveSupport::TestCase
      test "cyber_source is a valid payment method" do
        publisher = Factory.build(:publisher, :payment_method => "cyber_source", :require_billing_address => true)
        assert_equal "cyber_source", publisher.payment_method
        assert publisher.valid?, "Publisher should be valid with cyber_source payment method"
      end
    end
  end
end
