require File.dirname(__FILE__) + "/../../models_helper"

# hydra class ConsumerTest
module FacebookAuth; end
module ActsAsShareable; end
module Consumers::AuthenticationStrategy
  class CrazyAuth; end
end

class ConsumerTest < Test::Unit::TestCase

  context "#authentication_strategy" do

    setup do
      @consumer = stub
      @consumer.extend(Consumers::Core)
      @consumer.extend(Consumers::Authentication)
    end

    should "raise error if publisher is nil" do
      assert_raise ArgumentError do
        @consumer.authentication_strategy(nil)
      end
    end

    should "return default authentication strategy if passed a publisher without an authentication strategy" do
      publisher = stub("publisher", :consumer_authentication_strategy => nil)
      strategy = @consumer.authentication_strategy(publisher)
      assert_equal Consumers::AuthenticationStrategy::Default, strategy.class
    end

    should "try create an authentication strategy based on publisher's consumer_authentication_strategy" do
      publisher = stub("publisher", :consumer_authentication_strategy => "crazy_auth")
      strategy = @consumer.authentication_strategy(publisher)
      assert_equal Consumers::AuthenticationStrategy::CrazyAuth, strategy.class
    end

  end

  context "#authenticate" do

    setup do
      @consumer = stub
      @consumer.extend(Consumers::Core)
      @consumer.extend(Consumers::Authentication)
    end

    should "return nil if find results in no consumer" do
      publisher = stub("publisher", :id => 5, :consumer_authentication_strategy => nil)
      strategy = stub
      strategy.stub_everything
      strategy.stubs(:find_for_authentication => nil)
      @consumer.stubs(:authentication_strategy).returns(strategy)
      assert_nil @consumer.authenticate(publisher, stub, stub)
    end

    should "return nil if consumer found is inactive" do
      publisher = stub("publisher", :id => 5, :consumer_authentication_strategy => nil)
      consumer = stub("consumer", :active? => false)
      strategy = stub
      strategy.stub_everything
      strategy.stubs(:find_for_authentication => consumer)
      @consumer.stubs(:authentication_strategy).returns(strategy)
      consumer.stubs(:access_locked?).returns(false)
      assert_nil @consumer.authenticate(publisher, stub, stub)
    end

    context "successful and unsuccessful" do

      setup do
        @publisher = stub("publisher", :id => 123)
        @consumer = stub
        @consumer.extend(Consumers::Authentication)
        @sam = stub("sam", :active? => true)
        @authentication_strategy = mock("authentication_strategy")
        @authentication_strategy.expects(:find_for_authentication).with(@publisher, "sam@example.com").returns(@sam)
        @consumer.expects(:authentication_strategy).with(@publisher).returns(@authentication_strategy)
      end

      should "successful authentication" do
        @sam.stubs(:force_password_reset? => false, :locked_at => nil, :access_locked? => false)
        @authentication_strategy.expects(:before_authentication).with(@publisher, "sam@example.com", "mypassword")
        @authentication_strategy.expects(:authenticate).with(@sam, "mypassword").returns(true)
        assert_equal @sam, @consumer.authenticate(@publisher, "sam@example.com", "mypassword")
      end

      should "return nil with unsuccessful authentication" do
        @sam.stubs(:force_password_reset? => false, :locked_at => nil, :access_locked? => false)
        @authentication_strategy.expects(:before_authentication).with(@publisher, "sam@example.com", "mypassword")
        @authentication_strategy.expects(:authenticate).with(@sam, "mypassword").returns(false)
        assert_nil @consumer.authenticate(@publisher, "sam@example.com", "mypassword")
      end

      should "return nil if consumer has force_password_reset flag set" do
        @sam.stubs(:force_password_reset? => true, :access_locked? => false)
        @authentication_strategy.expects(:before_authentication).with(@publisher, "sam@example.com", "mypassword")
        assert_nil @consumer.authenticate(@publisher, "sam@example.com", "mypassword")
      end

    end

  end

end
