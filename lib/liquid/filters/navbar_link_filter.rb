module Liquid
  module Filters
    module NavbarLinkFilter
      def navbar_link_to(text, url_or_path)
        unless is_on_page?(url_or_path)
          %(<a href="#{url_or_path}">#{text}</a>)
        else
          %(<span id="current_navbar_link">#{text}</span>).html_safe
        end
      end

      def is_on_page?(url_or_path)
        request = @context.registers[:controller].request

        request_uri = url_or_path.index("?") ? request.request_uri : request.request_uri.split('?').first
        if url_or_path =~ /^\w+:\/\//
          url_or_path == "#{request.protocol}#{request.host_with_port}#{request_uri}"
        else
          url_or_path == request_uri
        end
      end
    end
  end
end
