module Publishers
  module Localization
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
    end

    module InstanceMethods
      def locale
        case currency_code
        when "GBP"
          {
            :language => "en",
            :country  => "GB"
          }
        when 'CAD'
          {
            :language => "en",
            :country  => "CA"
          }
        else
          {
            :language => "en",
            :country  => "US"
          }      
        end
      end
  
      def localize_time(timestamp)
        timestamp = Time.zone.parse(timestamp) if timestamp.kind_of?(String)
        timestamp.in_time_zone(self.time_zone)
      end

      def localize_date(timestamp)
        localize_time(timestamp).to_date
      end
  
      def now
        localize_time(Time.now)
      end

      def currency_symbol
        self.class.currency_symbol_for(currency_code) || "$"
      end
    end
  end
end
