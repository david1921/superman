# This is also used by Liquid::Tags::Translate
module ActionView
  module Helpers
    module TranslationHelper

      def translate_with_theming(key, options = {})
        template_path = template.try(:path_without_format_and_extension) if defined?(template)
        publisher_translation(@publisher, key, options, template_path)
      end

      # also called by Liquid::Tags::Translate
      def publisher_translation(publisher, key, options, template_path)
        lazy_keys = key.to_s.first == '.'

        key = scope_key!(key, options, template_path)

        final_options = options.dup

        options[:default] = nil
        options[:raise] = true

        (Analog::Themes::I18n.translate(publisher, key, options) rescue nil) ||
          translate_without_theming(key, options.merge(final_options))
      end

      alias_method_chain :translate, :theming
      alias :t :translate

      private

      # side effect: modifies options
      def scope_key!(key, options, template_path)
        if key.to_s.first == "."

          key = key.to_s[1..-1]

          scope = template_path.split(%r{/_?})
          scope = scope[2..-1] if scope[0] == "themes"

          options[:scope] = scope
        end

        key
      end
    end
  end
end
