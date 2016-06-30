module DailyDeals
  module Variations

    def self.included(base)
      base.send :include, InstanceMethods
      base.class_eval do
        # 
        # NOTE: we didn't used named_scopes since the front end designer would have to remember to call
        # something like: daily_deal.daily_deal_variations.available.  And it seems to make sense that
        # daily_deal.daily_deal_variations should NOT return deleted variations.
        #
        has_many :daily_deal_variations, :dependent => :destroy, :order => "price asc", :conditions => ["deleted_at is NULL"]
        has_many :daily_deal_variations_with_deleted, :dependent => :destroy, :class_name => "DailyDealVariation", :order => "price asc"
      end
    end

    module InstanceMethods

      def has_variations?
        daily_deal_variations.any?
      end

      def lowest_price
        daily_deal_variations.minimum(:price)
      end

    end
  end
end
