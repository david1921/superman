module Liquid
  module Tags
    class IncludeWithTheme < Liquid::Include
      Syntax = /(with_theme)?\s*(#{QuotedFragment}+)(\s+(?:with|for)\s+(#{QuotedFragment}+))?/

      def initialize(tag_name, markup, tokens)
        if markup =~ Syntax
          if $1 == "with_theme"
            @with_theme = true
            markup = markup.gsub(/^with_theme /, '')
          end
        else
          raise SyntaxError.new("Error in tag 'include' - Valid syntax: include (with_theme) '[template]' (with|for) [object|collection]")
        end

        super tag_name, markup, tokens
      end

      def render(context)
        @file_system = context.registers[:file_system] || Liquid::Template.file_system

        # @template_name assigned from super's initialize
        template_name = context[@template_name]

        template_path = get_theme_template(context, template_name) ||
                        get_localized_template(template_name) ||
                        template_name

        old_template_path_register = context.registers[:template_path]
        context.registers[:template_path] = template_path                        
        output = parse_and_render_template(context, template_name, template_path)
        context.registers[:template_path] = old_template_path_register        
        output
      end
      
      private
      
      def parse_and_render_template(context, template_name, template_path)
        source  = @file_system.read_template_file(template_path, context)
        partial = Liquid::Template.parse(source)

        variable = context[@variable_name || template_name]

        output = nil
        context.stack do
          @attributes.each do |key, value|
            context[key] = context[value]
          end

          if variable.is_a?(Array)
            variable.collect do |variable|            
              context[template_name] = variable
              output = render_with_env(partial,context)
            end
          else
              context[template_name] = variable
              output = render_with_env(partial,context)
           end
        end
        output        
      end
      
      def render_with_env(partial, context)
        if !Rails.env.production? && !Rails.env.staging?
          output = partial.render!(context)
        else
          output = partial.render(context)
        end
        output
      end
       
      
      def get_localized_template(template_name)
        [I18n.locale, I18n.default_locale].each do |locale|
          path = "#{template_name}.#{locale}"
          return path if @file_system.template_exists? path
        end
        nil
      end

      def get_theme_template(context, template_name)
        if @with_theme
          publisher = context['publisher']
          
          return unless publisher.present?
          
          return_if_template_exists = Proc.new do |template_path|
            localized_path = get_localized_template(template_path)
            return localized_path if localized_path

            return template_path if @file_system.template_exists?(template_path)
          end
          
          return_if_template_exists.call "themes/#{publisher.label}/#{template_name}"

          if publisher.publishing_group
            return_if_template_exists.call "themes/#{publisher.publishing_group.label}/#{template_name}"
          end
          
          if publisher.uses_a_ready_made_theme?
            return_if_template_exists.call "themes/#{publisher.parent_theme}/#{template_name}"
          end
          
          if publisher.publishing_group.try(:uses_a_ready_made_theme?)
            return_if_template_exists.call "themes/#{publisher.publishing_group.parent_theme}/#{template_name}"
          end
        end
      end

    end
  end
end

