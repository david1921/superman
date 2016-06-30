module Liquid
  module Filters
    module Number
      include ActionView::Helpers::NumberHelper

      def currency(value, precision = 0, unit = nil)
        number_to_currency value, :precision => precision, :unit => unit
      end

      def integer(value)
        number_with_precision value, :precision => 0
      end

      def number(value, precision = 0)
        number_with_precision value, :precision => precision
      end

      def percentage(value)
        number_to_percentage value, :precision => 0
      end
      
      def whole_part(value)
        num_to_parts(value).try(:first)
      end
      alias :dollars :whole_part
      
      def decimal_part(value)
        num_to_parts(value).try(:second)
      end
      alias :cents :decimal_part

      def less_than(value, compared_value, t, f = '')
        value < compared_value ? t : f
      end

      def greater_than(value, compared_value, t, f = '')
        value > compared_value ? t : f
      end
      
      private
      
      def num_to_parts(value)
        return unless value.present?
        ("%.2f" % value).split(".")
      end

    end
  end
end
