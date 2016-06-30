module Analog
  module DateHelper
    def date_range(a, b)
      dates_begin, dates_end = [parse_date(a), parse_date(b)]

      if Rails.env.demo? && dates_begin.nil? && dates_end.nil?
        dates_begin = Time.zone.local(2009)
        dates_end = Time.zone.now
      else
        dates_end = Time.zone.now.to_date unless dates_begin || dates_end
        dates_begin ||= dates_end - 7
        dates_end ||= dates_begin + 7
      end

      dates_begin, dates_end = [dates_end, dates_begin] if dates_end < dates_begin
      dates_begin .. dates_end
    end

    def date_or_today(date)
      parse_date(date) || Time.zone.now.to_date
    end

    def iso8601_or_nil(dt)
      return nil if dt.nil?
      dt.utc.to_formatted_s(:iso8601)
    end 

    private

    def parse_date(text)
      Time.zone.parse(text).to_date rescue nil
    end

  end
end
