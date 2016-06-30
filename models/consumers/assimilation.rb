module Consumers
  module Assimilation

    def self.included(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods

      def assimilate!(other_consumer)
        assimilate_daily_deal_purchases(other_consumer.daily_deal_purchases)
        assimilate_all(other_consumer.daily_deal_orders)
        assimilate_all(other_consumer.credits)
        assimilate_all(other_consumer.sweepstake_entries)
        assimilate_daily_deal_categories(other_consumer.daily_deal_categories)
      end

      def assimilate_daily_deal_categories(cats)
        self.daily_deal_categories += cats
        save!
      end

      def assimilate_daily_deal_purchases(purchases)
        purchases.each do |purchase|
          # we have to update_attribute without validation here, unfortunately
          # because otherwise executed purchases can't have their consumer_ids changed
          purchase.update_attribute(:consumer_id, self.id)
        end
      end

      def assimilate_all(things)
        things.each do |thing|
          thing.consumer = self
          thing.save!
        end
      end
    end

  end
end
