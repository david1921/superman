module DailyDeals
  module VariationsPricing

      def self.included(base)
        base.send :include, InstanceMethods
      end

      module InstanceMethods

        def price_to_display
          if has_variations?
            lowest_price
          else
            price
          end
        end

        def value_to_display
          if has_variations?
            variation = daily_deal_variations.min { |x, y|  x.price <=> y.price }
            variation.value
          else
            value
          end
        end

        def savings_to_display
          value_to_display - price_to_display
        end

        def savings_to_display_as_percentage
          value = value_to_display
          savings = savings_to_display
          return 0 if value.zero?
          (savings / value) * 100
        end
    end
  end
end