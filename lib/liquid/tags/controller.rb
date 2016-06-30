module Liquid
  module Tags
    class Controller < Liquid::Tag

      def initialize(tag_name, method, tokens)
        @method = method.try(:strip).try(:to_sym)
      end

      def render(context)
        if @method
          context.registers[:controller].send(@method)
        else
          nil
        end
      end

    end
  end
end
