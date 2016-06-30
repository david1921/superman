module Consumers
  module AfterUpdate

    def execute_after_update_strategy
      after_update_strategy.execute(updated_consumer)
    end

    def after_update_strategy
      return if publisher.nil?
      self.class.consumer_strategy(Consumers::AfterUpdateStrategy, publisher.consumer_after_update_strategy)
    end

    def updated_consumer
      self
    end

  end
end
