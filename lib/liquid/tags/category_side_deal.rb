module Liquid
  module Tags
    class CategorySideDeal < Liquid::Tag                                             
      def initialize(tag_name, markup, tokens)
         super
         args = markup.split(" ")
         @publisher_label = args.first.strip
         @category_name = args.second.strip
      end

      def render(context)
        publisher = Publisher.find_by_label(@publisher_label)
        if publisher && @category_name.present?
          context["daily_deal"] = publisher.daily_deals.with_publishers_category_name(@category_name).side.active.in_order.last
        end
        nil
      end
    end
  end
end
