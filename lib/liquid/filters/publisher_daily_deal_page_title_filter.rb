module Liquid
  module Filters
    module PublisherDailyDealPageTitleFilter
      def publisher_daily_deal_page_title(publisher)
        return "" unless publisher.present?
        @context.registers[:action_view].daily_deal_page_title(publisher.label.to_sym)
      end
    end
  end
end