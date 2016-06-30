module DailyDeals

  class MissingVariationException < StandardError; end
  class MissingDailyDealSequenceIDException < StandardError; end

  module Core

    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def featured_after(time)
        candidates = ending_after(time)
        deals_with_featured_start = []

        candidates.each do |deal|
          earliest_featured_start = nil
          is_featured_after = false

          deal.featured_date_ranges.each do |featured_range|
            is_featured_after ||= featured_range.begin > time

            if earliest_featured_start.nil? || featured_range.begin < earliest_featured_start
              earliest_featured_start = featured_range.begin
            end
          end

          deals_with_featured_start << [deal, earliest_featured_start] if is_featured_after
        end

        deals_with_featured_start.sort{|a,b| a[1] <=> b[1]}.map(&:first)
      end
    end

    module InstanceMethods
      def bar_code_symbology
        symbologies_and_formats = self.class.try(:allowed_bar_code_encoding_formats)
        match = symbologies_and_formats.select { |s, f| f == bar_code_encoding_format }.first
        match.try(:first)
      end

      def pay_using?(payment_method_arg)
        payment_method_arg.to_s == self.payment_method.to_s
      end

      def payment_method
        if syndicated? && source_publisher.pay_using?(:travelsavers)
          "travelsavers"
        else
          publisher.payment_method
        end
      end

      def accounting_id
        "#{id}"
      end

      def accounting_id_for_variation(variation)
        raise MissingVariationException unless variation
        raise MissingDailyDealSequenceIDException unless variation.try(:daily_deal_sequence_id).present?
        "#{self.id}-#{variation.daily_deal_sequence_id}"
      end
      
    end
  end
end
