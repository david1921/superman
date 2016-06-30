module Liquid
  module Tags
    class Locale < Liquid::Tag                                             
      def render(context)
        I18n.locale.to_s
      end
    end
  end
end
