module Analog
  module ThemeHelper

    def find_template(publisher_or_group, template_path)
      find_generic_templates = lambda do
        view_paths.find_template(template_path, theme_template_format)
      end

      return find_generic_templates.call unless publisher_or_group

      find_custom_templates = lambda do
        view_paths.find_template("themes/#{publisher_or_group.label}/#{template_path}", theme_template_format, false) rescue
        view_paths.find_template("themes/#{publisher_or_group.theme}/#{template_path}", theme_template_format) rescue
        view_paths.find_template("themes/#{publisher_or_group.publishing_group.try(:label)}/#{template_path}", theme_template_format, false)
      end

      find_custom_templates_for_publishing_group_ignoring_format = lambda do
        if (publisher_or_group.is_a?( PublishingGroup ) )
          view_paths.find_template("themes/#{publisher_or_group.label}/#{template_path}", default_template_format)
        else
          raise TypeError, "expected a publishing group"
        end
      end

      # NOTE: I (graeme) added false to the end of find template for ready_made template lookups for publishers
      # and publishing groups, because I didn't want it to default to an html version if there was one.
      # This was breaking the deal javascript for any publisher with a parent theme (ready made), since 
      # it would find a show.html.liquid file in the ready made theme directory and return that instead
      # of the default daily_deals/show.js.erb.
      
      find_ready_made_publisher_templates = lambda do
        view_paths.find_template("themes/#{publisher_or_group.parent_theme}/#{template_path}", theme_template_format, false)
      end
      
      find_ready_made_pub_group_templates = lambda do
        view_paths.find_template("themes/#{publisher_or_group.publishing_group.try(:parent_theme)}/#{template_path}", theme_template_format, false)
      end

      if publisher_or_group.uses_a_ready_made_theme? ||
        (publisher_or_group.respond_to?(:publishing_group) && publisher_or_group.publishing_group.try(:uses_a_ready_made_theme?))
        find_custom_templates.call rescue
        find_ready_made_publisher_templates.call rescue
        find_ready_made_pub_group_templates.call rescue
        find_generic_templates.call
      else
        find_custom_templates.call rescue
        find_custom_templates_for_publishing_group_ignoring_format.call rescue
        find_generic_templates.call
      end
    end

    def theme_template_format
      @theme_template_format ||= respond_to?(:request) && request ? request.template_format.to_sym : :html
    end

  end
end

