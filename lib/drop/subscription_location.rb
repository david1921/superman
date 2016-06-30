module Drop
  class SubscriptionLocation < Liquid::Drop
    delegate :id,
             :name,
             :to => :subscription_location

    def initialize(subscription_location)
      @subscription_location = subscription_location
    end

    private

    def subscription_location
      @subscription_location
    end
  end
end

