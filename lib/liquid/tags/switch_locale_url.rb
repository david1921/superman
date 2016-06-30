module Liquid
  module Tags
    class SwitchLocaleUrl < Liquid::Tag
      def initialize(tag_name, key, tokens)
         super
         # strip is important because params usually have whitespace
         @locale = key.try(:strip).try(:to_sym)
      end

      def render(context)
        # Note: @locale must be in I18n.available_locales or it will not be
        # included in the URL.  See RoutingFilter::Locale for more details
        controller = context.registers[:controller]
        controller.url_for(:only_path => true, :params => controller.params.merge(:locale => @locale))
      end
    end
  end
end
