module Liquid
  module Blocks
    class Http < Liquid::Block                                             
      def initialize(tag_name, markup, tokens)
         super 
         @markup = markup
      end

      def render(context)
        if context.registers[:controller].request.protocol == "http://"
           super
        end
      end    
    end
  end
end
