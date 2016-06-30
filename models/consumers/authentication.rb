module Consumers
  module Authentication

    def authenticate(publisher, email, password)
      auth_strategy = authentication_strategy(publisher)
      auth_strategy.before_authentication(publisher, email, password)
      consumer = auth_strategy.find_for_authentication(publisher, email)
      return :locked if consumer.try(:access_locked?)
      return nil if consumer.nil? || !consumer.active? || consumer.force_password_reset?
      if (result = auth_strategy.authenticate(consumer, password)) == true
        consumer
      else
        result.is_a?(Symbol) ? result : nil
      end
    end

    def authentication_strategy(publisher)
      raise ArgumentError if publisher.nil?
      consumer_strategy(Consumers::AuthenticationStrategy, publisher.consumer_authentication_strategy)
    end

  end
end
