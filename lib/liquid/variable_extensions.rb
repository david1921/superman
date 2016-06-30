module Liquid
  class Variable
    def render_with_html_escape(context)
      output = render_without_html_escape(context)
      if context.registers[:html_escape] && !output.html_safe?
        ERB::Util::html_escape(output)
      else
        output
      end
    end

    alias_method_chain :render, :html_escape
  end
end
