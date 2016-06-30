module DailyDeals
  module Filtering

    def find_available_daily_deals(options = {})
      if @publisher.default_daily_deal_zip_radius > 0
        options[:zip_code] = current_radius_filter_zip_code
      end

      @publisher.available_daily_deals(options)
    end
    
    def find_available_and_recently_finished_daily_deals(options = {})
      if @publisher.default_daily_deal_zip_radius > 0
        options[:zip_code] = current_radius_filter_zip_code
      end
      
      @publisher.available_and_recently_finished_deals(options)
    end

    def current_radius_filter_zip_code
      cookies["zip_code"] || current_user.try(:zip_code)
    end

  end
end
