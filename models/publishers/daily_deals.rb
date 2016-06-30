module Publishers
  module DailyDeals

    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods

      def available_daily_deals(options = {})
        deals = daily_deals.active
        deals = deals.in_publishers_categories(options[:categories]) if options[:categories].present?

        if default_daily_deal_zip_radius > 0
          deals = deals.national_or_within_zip_radius(options[:zip_code], default_daily_deal_zip_radius)
        end

        deals
      end
      
      def available_and_recently_finished_deals(options = {})
        deals = daily_deals
        
        if options[:categories].present?
          deals = deals.in_publishers_categories(options[:categories])
        end
        
        if options[:zip_code].present?
          deals = deals.national_or_within_zip_radius(options[:zip_code], default_daily_deal_zip_radius)
        end
        
        deals.
          active_and_recently_finished.
          include_advertiser.
          include_publisher.
          order_by_finishing_soon_then_most_recently_finished
      end

    end

  end
end
