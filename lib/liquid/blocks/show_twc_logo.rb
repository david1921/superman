module Liquid
  module Blocks
    class ShowTwcLogo < Liquid::Block
      def render(context)        
        if context.registers[:controller].show_twc_logo?
          super
        else
          ''
        end
      end
    end
  end
end