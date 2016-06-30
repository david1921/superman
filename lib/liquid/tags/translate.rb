require 'action_view/helpers/tag_helper'

module Liquid
  module Tags
    class Translate < Liquid::Tag
      include ActionView::Helpers::TranslationHelper
      include ActionView::Helpers::TagHelper

      def initialize(tag_name, key, tokens)
        @key = key.try(:strip)
      end
      
      def render(context)
        controller = context.registers[:controller]
        publisher = controller.current_publisher if controller.respond_to?(:current_publisher)
        publisher_translation(publisher, @key, {}, template(context))
      end

      private

      def template(context)
        context.registers[:template_path] ||
          context.registers[:action_view].template.path_without_format_and_extension
      end
    end
  end
end
