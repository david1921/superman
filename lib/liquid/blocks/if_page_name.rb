module Liquid
  module Blocks
    class IfPageName < Liquid::Block
      def initialize(tag_name, markup, tokens)
        super
        @action_name = markup.try(:strip)
        if @action_name =~ /(\s*(==|!=)\s*)?["'](.*)["']/
          @comparator = $2
          @action_name = $3
        end
      end

      def render(context)
        page_name = "#{context.registers[:controller].controller_name}##{context.registers[:controller].action_name.to_s}"

        case @comparator
        when '!='
          satisfied = page_name != @action_name
        else
          satisfied = page_name == @action_name
        end

        if satisfied
          super
        else
          ''
        end
      end
    end
  end
end
