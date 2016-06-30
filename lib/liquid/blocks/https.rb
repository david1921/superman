module Liquid
  module Blocks
    class Https < Liquid::Block                                             
      def initialize(tag_name, markup, tokens)
         super 
         @markup = markup
      end

      def render(context)
        if context.registers[:controller].request.protocol == "https://"
           super
        end
      end    
    end
  end
end
