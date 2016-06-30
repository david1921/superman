module Liquid
  module Tags
    class AllFlash < Liquid::Tag                                             
      def render(context)
        if context.registers[:controller].session && context.registers[:controller].session["flash"]
          context.registers[:controller].session["flash"].keys.map(&:to_s)
        else
          []
        end
      end
    end
  end
end
