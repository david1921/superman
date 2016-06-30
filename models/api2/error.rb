module Api2
  class Error
    attr_reader :messages
    
    def initialize(messages)
      @messages = messages
    end
  end
  
  module ErrorAttribute
    def error
      if invalid? && errors.present?
        Api2::Error.new(errors.full_messages)
      else
        nil
      end
    end
  end
end
