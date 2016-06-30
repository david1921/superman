require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Publishers::DelegateAttrubteToPublishingGroupIfNilTest
module Publishers
  class DelegateAttrubteToPublishingGroupIfNilTest < ActiveSupport::TestCase

    context "consumer_authentication_strategy" do

      should "use publisher value if not nil" do
        p = Factory(:publisher, :consumer_authentication_strategy => "cool")
        assert_equal "cool", p.consumer_authentication_strategy
      end

      should "delegate to publishing_group if is nil" do
        pg = Factory(:publishing_group, :consumer_authentication_strategy => "cool-pg")
        p = Factory(:publisher, :publishing_group => pg, :consumer_authentication_strategy => nil)
        assert_equal "cool-pg", p.consumer_authentication_strategy
      end

    end

    context "consumer_after_create_strategy" do

      should "use publisher value if not nil" do
        p = Factory(:publisher, :consumer_after_create_strategy => "cool")
        assert_equal "cool", p.consumer_after_create_strategy
      end

      should "delegate to publishing_group if is nil" do
        pg = Factory(:publishing_group, :consumer_after_create_strategy => "cool-pg")
        p = Factory(:publisher, :publishing_group => pg, :consumer_after_create_strategy => nil)
        assert_equal "cool-pg", p.consumer_after_create_strategy
      end

    end

  end
end

