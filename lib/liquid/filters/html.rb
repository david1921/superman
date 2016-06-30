module Liquid
  module Filters
    module HTML

      def truncate_html_to_first_paragraph_only(input)
        if input =~ /<p>(.*?)<\/p>/
          result_without_ellipsis = "<p>#{$1}</p>"
          if result_without_ellipsis.size == input.size
            input
          else
            "<p>#{$1}...</p>"
          end
        else
          input
        end
      end

    end
  end
end