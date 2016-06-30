module Analog
  module ThirdPartyApi
    module Coolsavings
      class ErrorResponse < RuntimeError

        attr_reader :errors

        def initialize(errors=[])
          @errors = errors
          super create_msg
        end

        def create_msg
          "Coolsavings errors: " + @errors.join(",")
        end

      end
    end
  end
end
