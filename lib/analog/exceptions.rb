module Analog
  module Exceptions
    class SubclassesMustImplementException < Exception
      def initialize(msg=nil)
        super(msg || "subclasses must implement")
      end
    end
  end
end
