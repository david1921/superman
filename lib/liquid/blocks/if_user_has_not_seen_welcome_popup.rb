module Liquid
  module Blocks
    class IfUserHasNotSeenWelcomePopup < Liquid::Block
      def render(context)
        super if context.registers[:controller].request.cookies["seen_welcome"].blank?
      end
    end
  end
end
