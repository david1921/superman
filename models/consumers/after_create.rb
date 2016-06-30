module Consumers
  module AfterCreate

    def execute_after_create_strategy
      after_create_strategy.execute(after_create_consumer)
    end

    def after_create_strategy
      return if publisher.nil?
      self.class.consumer_strategy(Consumers::AfterCreateStrategy, publisher.consumer_after_create_strategy)
    end

    def after_create_consumer
      self
    end

  end
end
