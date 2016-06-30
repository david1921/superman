module Liquid
  module Blocks
    class PageContextIs < Liquid::Block
      def initialize(tag_name, markup, tokens)
        super
        @page_context = markup.try(:strip)
      end

      def render(context)
        controller    = context.registers[:controller]
        page_context  = controller.instance_variable_get("@page_context")
        page_name     = controller.controller_name        
        if @page_context == page_context || page_name == @page_context
          super
        else
          ''
        end
      end
    end
  end
end