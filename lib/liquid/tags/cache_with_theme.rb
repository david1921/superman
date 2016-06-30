module Liquid
  module Tags
    
    # Adds caching support to liquid.
    #
    # The very basic usage is:
    #
    # {% cache 'shared/footer' %}
    #
    # You can also use with theme support like:
    #
    # {% cache with_theme 'shared/footer' %}
    #
    # You can also supply expiry and key for the cache, like so:
    #
    # {% cache with_theme 'shared/footer' | expiry: 30.seconds | key: cache_key %}
    # 
    # When you supply a key, it's append to the template path.  For example, say
    # you have a daily deal with an id of 1000, and a set up like:
    #
    # {% assign cache_key = daily_deal.id %}
    # {% cache 'shared/footer' | key: cache_key %}
    #
    # then the full cache key becomes 'shared/footer/1000'
    class CacheWithTheme < IncludeWithTheme
      
      DEFAULT_EXPIRY = 30.seconds
      
      @@cache_views = Rails.configuration.action_controller.perform_caching
      
      # {% cache with_theme 'shared/footer' %}
      def initialize(tag_name, markup, tokens)        
        if markup =~ Syntax
          if $1 == "with_theme"
            @with_theme = true
            markup = markup.gsub(/^with_theme /, '')
          end
          
          # we want to extract only the expiry and key, we don't need the template path in this case, thus [1..2]
          # on the array after splitting on |
          set_cache_key_and_expiry(markup.split(/\s*\|\s*/)[1..2]) if @@cache_views
        else
          raise SyntaxError.new("Error in tag 'include' - Valid syntax: include (with_theme) '[template]' (with|for) [object|collection]")
        end

        super tag_name, markup, tokens
      end
      
      def parse_and_render_template(context, template_name, template_path)
        unless @@cache_views
          super
        else
          Rails.cache.fetch(key(context), :expires_in => expiry) do
            super
          end          
        end
      end
      
      private
      
      def set_cache_key_and_expiry(attributes)
        settings      = extract_key_and_values_from_attributes(attributes)
        @cache_key    = extract_key_from_settings(settings)
        @cache_expiry = extract_expiry_from_settings(settings)
      end      
      
      def key(context)
        template_path    = context.registers[:template_path]
        key_from_context = cache_key_from_context(context)
        key_from_context ? "#{template_path}/#{key_from_context}" : template_path
      end
      
      def expiry
        return DEFAULT_EXPIRY unless @cache_expiry
        begin
          eval(@cache_expiry)
        rescue
          DEFAULT_EXPIRY
        end
      end
      
      def extract_key_and_values_from_attributes(attributes)
        key_and_values = {}
        attributes.each do |key_and_value|
          key, value = key_and_value.split(/\s*:\s*/)
          key_and_values[key] = value
        end
        key_and_values
      end
      
      def extract_key_from_settings(settings)
        settings["key"]
      end
      
      def extract_expiry_from_settings(settings)
        settings["expiry"]
      end
      
      def cache_key_from_context(context)
        return nil unless @cache_key
        context[@cache_key]
      end
      
      
    end
  end
end