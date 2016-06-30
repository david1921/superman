require File.dirname(__FILE__) + "/../../../models_helper"

# hydra class Consumers::AfterCreateTest

module Consumers
  module AfterCreateStrategy
    class Crazy
    end
  end
end

class Consumers::AfterCreateTest < Test::Unit::TestCase

  context "after_create_strategy" do

    should "do nothing publisher is nil" do
      consumer = stub("consumer").extend(Consumers::AfterCreate)
      consumer.stubs(:publisher => nil)
      consumer.after_create_strategy
    end

    should "return default strategy if publisher has none" do
      consumer = stub("consumer")
      consumer.extend(Consumers::AfterCreate)
      publisher = stub("publisher")
      publisher.stubs(:consumer_after_create_strategy).returns(nil)
      consumer.stubs(:publisher => publisher)
      consumer.class.expects(:consumer_strategy).with(Consumers::AfterCreateStrategy, nil).returns(Consumers::AfterCreateStrategy::Default.new)
      assert_equal Consumers::AfterCreateStrategy::Default, consumer.after_create_strategy.class
    end

    should "return strategy based on publisher attribute if it exists" do
      consumer = stub("consumer")
      consumer.extend(Consumers::AfterCreate)
      publisher = stub("publisher")
      publisher.stubs(:consumer_after_create_strategy).returns("crazy")
      consumer.stubs(:publisher => publisher)
      consumer.class.expects(:consumer_strategy).with(Consumers::AfterCreateStrategy, "crazy").returns(Consumers::AfterCreateStrategy::Crazy.new)
      assert_equal Consumers::AfterCreateStrategy::Crazy, consumer.after_create_strategy.class
    end

  end

  context "execute_after_create_strategy" do

    should "execute the strategy returned by after_create_strategy" do
      consumer = stub("consumer")
      consumer.extend(Consumers::AfterCreate)
      strategy = mock("after_create_strategy")
      strategy.expects(:execute)
      consumer.stubs(:after_create_strategy => strategy)
      consumer.execute_after_create_strategy
    end

  end

end
