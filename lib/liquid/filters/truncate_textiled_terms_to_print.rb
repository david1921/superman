module Liquid
  module Filters
    module TruncateTextiledTermsToPrint
      
      def truncate_textiled_terms_to_print(offer)
        return "" unless offer.present?
        truncate_html(offer.terms_as_textiled, 
          :length => 200, 
          :omission => " <a href='#' id='print_#{offer.id}' onclick='clipCoupon(#{offer.id}, #{offer.publisher_id}); return false;' rel='nofollow'>more</a>")
      end
      
      # see http://vermicel.li/blog/2009/01/30/awesome-truncation-in-rails.html.
      # HtmlTruncator module didn't work very well for having an html element as the omission element, that 
      # had a lot of attributes.
      def truncate_html(text, *args)
        options = args.extract_options!

        # support either old or Rails 2.2 calling convention:
        unless args.empty?
          options[:length] = args[0] || 30
          options[:omission] = args[1] || "..."
        end
        options.reverse_merge!(:length => 30, :omission => "...")

        # support any of:
        #  * ruby 1.9 sane utf8 support
        #  * rails 2.1 workaround for crappy ruby 1.8 utf8 support
        #  * rails 2.2 workaround for crappy ruby 1.8 utf8 support
        # hooray!
        if text
          chars = if text.respond_to?(:mb_chars)
              text.mb_chars
            elsif RUBY_VERSION < '1.9'
              text.chars
            else
              text
            end

            omission = if options[:omission].respond_to?(:mb_chars)
                options[:omission].mb_chars
              elsif RUBY_VERSION < '1.9'
                options[:omission].chars
              else
                options[:omission]
              end

            l = options[:length]
            if chars.length > options[:length]
              result = (chars[/\A.{#{l}}\w*\;?/m][/.*[\w\;]/m]).to_s
              ((options[:avoid_orphans] && result =~ /\A(.*?)\n+\W*\w*\W*\Z/m) ? $1 : result) + options[:omission]
            else
              text
            end
        end
      end      
      
      
    end
  end
end