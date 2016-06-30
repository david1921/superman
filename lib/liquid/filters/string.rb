module Liquid
  module Filters
    module String
      
      def cgi_escape(value)
        CGI.escape(value) if value
      end
      
      def uri_escape(value)
        URI.escape(value) if value
      end
      
    end
  end
end
