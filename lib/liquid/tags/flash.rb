module Liquid
  module Tags
    class Flash < Liquid::Tag                                             
      def initialize(tag_name, key, tokens)
         super
         # strip is important because params usually have whitespace
         @key = key.try(:strip).try(:to_sym)
      end

      def render(context)
        if @key.present? && 
           (context.registers[:controller].session && 
            context.registers[:controller].session["flash"] && 
            context.registers[:controller].session["flash"][@key])
           
          value = context.registers[:controller].session["flash"][@key]
          context.registers[:controller].session["flash"].delete(@key)
          value
        else
          nil
        end
      end
    end
  end
end
