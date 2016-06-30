module Liquid
  module Blocks
    class LocaleIsDefault < Liquid::Block
      def initialize(tag_name, markup, tokens)
        super
      end

      def render(context)
        if I18n.locale == I18n.default_locale
          super
        else
          ''
        end
      end
    end
  end
end

