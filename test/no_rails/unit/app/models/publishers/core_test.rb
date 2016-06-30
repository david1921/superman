require File.dirname(__FILE__) + "/../../models_helper"

# hydra class Publishers::CoreTest
module Publishers
  class CoreTest < Test::Unit::TestCase

    context "allow_consumer_access?" do

      setup do
        @publisher = stub("publisher")
        @publisher.extend(::Publishers::Core::InstanceMethods)
        @consumer = stub("consumer")
      end

      should "return true if consumer pub matches" do
        @consumer.stubs(:publisher).returns(@publisher)
        assert @publisher.allow_consumer_access?(@consumer)
      end

      should "return false if consumer is nil" do
        assert !@publisher.allow_consumer_access?(nil)
      end

      should "return false if consumers pubs do not match and single sign on is not allowed" do
        @consumer.stubs(:publisher).returns(stub)
        @publisher.stubs(:allow_single_sign_on?).returns(false)
        assert !@publisher.allow_consumer_access?(@consumer)
      end

      should "return false if allows single sign on but publishing_groups do not match" do
        consumer_publisher = stub
        consumer_publisher.stubs(:publishing_group).returns(stub("publishing_group1"))
        @consumer.stubs(:publisher).returns(consumer_publisher)
        @publisher.stubs(:allow_single_sign_on?).returns(true)
        @publisher.stubs(:publishing_group).returns(stub("publishing_group2"))
        assert !@publisher.allow_consumer_access?(@consumer)
      end

      should "return true if allows single sign and publishing_groups match" do
        publishing_group = stub
        consumer_publisher = stub
        consumer_publisher.stubs(:publishing_group).returns(publishing_group)
        @consumer.stubs(:publisher).returns(consumer_publisher)
        @publisher.stubs(:allow_single_sign_on?).returns(true)
        @publisher.stubs(:publishing_group).returns(publishing_group)
        assert @publisher.allow_consumer_access?(@consumer)
      end

    end
  end
end
