module Liquid
  module Tags
    class ShowUnlessHttps < Liquid::Block                                             
      def initialize(tag_name, markup, tokens)
         super 
      end

      def render(context)
        if request_protocol(context).starts_with?("https")
           ''
        else
           super
        end
      end   
  
      private
  
      def request_protocol(context)
        context.registers[:controller].request.protocol
      end 
    end
  end
end
