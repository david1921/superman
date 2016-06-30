module Liquid
  module Tags
    class RequestProtocol < Liquid::Tag                                             
      def render(context)
        context.registers[:controller].request.protocol
      end
    end
  end
end
