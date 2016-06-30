module Liquid
  module Tags
    class SetDailyDealPageTitleSlug < Liquid::Tag
      def initialize(tag_name, title_slug, tokens)
        @title_slug = title_slug
      end
      
      def render(context)
        context.registers[:action_view].set_daily_deal_page_title_slug(@title_slug)
        return nil
      end
    end
  end
end
