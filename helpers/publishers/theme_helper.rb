# Unfortunate duplication of code here, but Rails 2 doesn't give us any better choices
module Publishers
  module ThemeHelper
    include Analog::ThemeHelper

    @@theme_partials_by_path = Hash.new

    def with_theme(themed_partial_path)
      partial_for_publisher(partial_path_for(themed_partial_path))
    end
    
    def partial_path_for(themed_partial_path)
      if themed_partial_path.try :include?, "/"
        File.join(File.dirname(themed_partial_path), "#{File.basename(themed_partial_path)}")
      elsif controller
        "#{controller.class.controller_path}/#{themed_partial_path}"
      else
        themed_partial_path
      end
    end

    # partial_path is a Rails' method
    def partial_for_publisher(themed_partial_path)
      if Rails.configuration.action_controller.perform_caching?
        @@theme_partials_by_path["#{theme_source.label}/#{themed_partial_path}"] ||= find_partial(theme_source, themed_partial_path)
      else
        find_partial(theme_source, themed_partial_path)
      end
    end
    
    # Assume label is not Nil
    def find_partial(theme_source, themed_partial_path)
      # We need to return the partial path without the underscore. Unfortunately
      # Rails 2 does not expose any better method of doing this than to add in
      # the underscore, search for the template, and then re-add the underscore

      file_path = themed_partial_path.split("/")
      template_name = "_" + file_path.pop
      file_path = (file_path << template_name).join("/")

      template = find_template(theme_source, file_path) rescue nil

      if template
        file_path = template.path.split("/")
        template_file = file_path.pop[1..-1]
        file_path << template_file
        file_path.join('/')
      end
    end

    # Creates a stylesheet link tag for the specified theme,
    # The first looks for the publisher's stylesheet, falls back to the
    # publishing group's stylesheet, and finally falls back to the default
    # stylesheet stored in public/stylesheets/sass
    def stylesheet_link_tag_with_theme(*sources)
      options = sources.extract_options!
      stylesheets = []
      sources.each do |source|
        if @publisher
          publisher_stylesheet_path = stylesheet_path("/themes/#{@publisher.label}/stylesheets/#{source}").gsub(/\?.*/, "")
          stylesheet = File.exists?(File.join(Rails.public_path, publisher_stylesheet_path)) ? publisher_stylesheet_path : nil
        end

        if stylesheet.blank? && @publisher && @publisher.publishing_group
          publishing_group_stylesheet_path = stylesheet_path("/themes/#{@publisher.publishing_group.label}/stylesheets/#{source}").gsub(/\?.*/, "")
          stylesheet = File.exists?(File.join(Rails.public_path, publishing_group_stylesheet_path)) ? publishing_group_stylesheet_path : nil
        end

        # Default location for stylesheets
        stylesheet ||= "sass/#{source}"

        stylesheets << stylesheet
      end

      stylesheet_link_tag(stylesheets, options)
    end

    # Returns the url for the publisher's logo if available,
    # falling back to the publishing group's logo and finally
    # the supplied default
    def logo_with_theme(default, style)
      if @publisher.logo?
        @publisher.logo.url(style)
      elsif @publisher.try(:publishing_group).try(:logo?)
        @publisher.publishing_group.logo.url(style)
      else
        default
      end
    end
  end
end
