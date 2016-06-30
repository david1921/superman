module Liquid
  module Blocks
    class AnalyticsTag < Liquid::Block                                             
      def initialize(tag_name, markup, tokens)
         super 
         @query = markup.try(:strip).try(:concat, "?").try(:to_sym)
      end

      def render(context)
        if @query && (tag = context.registers[:controller].analytics_tag) && tag.respond_to?(@query) && tag.send(@query)
          super
        end
      end    
    end
  end
end
