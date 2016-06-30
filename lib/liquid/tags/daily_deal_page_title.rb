module Liquid
  module Tags
    class DailyDealPageTitle < Liquid::Tag
      
      def initialize(tag_name, style, tokens)
        style  = "default" if style.blank?
        @style = style.try(:strip).try(:to_sym)
      end  
      
      def render(context)
        context.registers[:action_view].daily_deal_page_title( @style )
      end
    end
  end
end
