module ActionView
  
  module Helpers
    
    module NumberHelper

      alias _original_number_to_currency number_to_currency

      def number_to_currency(number, options = {})
        unless options.has_key?(:unit)
          warn "WARNING: number_to_currency called without :unit (i.e. the publisher's currency code), at #{caller[0]}"
        end
        _original_number_to_currency(number, options)
      end

    end

  end

end