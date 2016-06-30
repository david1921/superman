require File.dirname(__FILE__) + "/../../test_helper"

class Publishers::PublisherTest < ActiveSupport::TestCase

  context "yelp_credentials" do
    context "given fully specified credentials" do
      setup do
        @publisher = Factory(:publisher_with_yelp_credentials)
      end

      should "return credentials hash" do
        assert_equal ({
          :consumer_key => "a-fake-key",
          :consumer_secret => "a-fake-secret",
          :token => "a-fake-token",
          :token_secret => "a-fake-token-secret"
        }), @publisher.yelp_credentials
      end
    end

    context "given fully specified credentials on the publishing group" do
      setup do
        @publishing_group = Factory(:publishing_group_with_yelp_credentials)
        @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      end

      should "return credentials hash from publishing group" do
        assert_equal ({
          :consumer_key => "a-fake-key",
          :consumer_secret => "a-fake-secret",
          :token => "a-fake-token",
          :token_secret => "a-fake-token-secret"
        }), @publisher.yelp_credentials
      end
    end

    context "given unspecified credentials" do
      setup do
        @publisher = Factory(:publisher_with_yelp_credentials, :yelp_consumer_secret => nil)
      end

      should "return nil" do
        assert_equal nil, @publisher.yelp_credentials
      end
    end
  end

end
