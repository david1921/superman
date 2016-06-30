module Liquid
  module Tags
    class FormAuthenticityToken < Liquid::Tag
      def render(context)
        context.registers[:action_view].form_authenticity_token
      end
    end
  end
end
