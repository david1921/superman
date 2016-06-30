module Liquid
  module Blocks
    class FirstTimeVisitor < Liquid::Block
      def render(context)
        if context.registers[:controller].first_time_visitor?
          super
        else
          ''
        end
      end
    end
  end
end