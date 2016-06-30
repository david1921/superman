module Liquid
  module Tags
    class AnalyticsTagData < Liquid::Tag                                             
      def initialize(tag_name, markup, tokens)
         super
         @item = markup.try(:strip).try(:to_sym)
      end

      def render(context)
        if @item && (data = context.registers[:controller].analytics_tag.data) && data.respond_to?(@item)
          data.send(@item)
        end
      end
    end
  end
end
