module Paypal
  module Helpers
    private
    
    alias :old_valid_setup_options :valid_setup_options
    
    def valid_setup_options
      old_valid_setup_options.tap do |array|
        [:discount_amount].each do |option|
          array << option unless array.include?(option)
        end
      end
    end
  end
end
