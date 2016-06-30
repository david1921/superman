module Liquid
  module Filters
    module Date
      include ActionView::Helpers::DateHelper
      def in_time_zone(datetime)s
        dt = Time.zone.parse(datetime)
        #expects a gmt timestamp and will return given time converted to the given timezone
        dt.in_time_zone("Europe/London")
      end
    end
  end
end
