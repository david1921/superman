# See Liquid::Tags::IncludeWithTheme for {% include with_theme ... %}
# functionality

module Publishers::Themes
  include Analog::ThemeHelper
  include Publishers::Themes::Offers
  
  @@theme_templates_by_path = Hash.new

  def self.included(base)
    base.class_eval do
      base.send :extend, ClassMethods
      base.helper_method :theme_source
    end
  end
  
  module ClassMethods
    def with_theme(layout_path = nil, *options)
      proc { |controller| controller.theme_layout(layout_path || controller.controller_name, *options.dup) }
    end

    def with_theme_unless_admin_user(*args)
      proc { |controller|
        user = controller.send(:current_user)
        (user && user.has_admin_privilege?) ? args[0] : with_theme(*args).call(controller) }
    end
  end
    
  def with_theme(*options)
    options = options.try(:flatten).extract_options!
    options[:layout] = theme_layout(options[:layout])
    options[:template] = theme_template(options[:template])
    options
  end

  def with_theme_unless_admin_user(*options)
    user_without_admin_privilege? ? with_theme(*options) : options.try(:flatten).extract_options!
  end

  def theme_layout(layout_paths, *options)
    return nil if layout_paths.nil?
    return false if !layout_paths
        
    options = options.extract_options!
    if Array.wrap(options[:except]).include?(action_name.to_sym)
      return false
    end

    only = Array.wrap(options[:only])
    if only.present? && only.include?(action_name.to_sym)
      return false
    end
        
    Array.wrap(layout_paths).each do |layout_path|
      begin
        if Rails.configuration.action_controller.perform_caching?
          return @@theme_templates_by_path["#{theme_source.label}/#{layout_path}"] ||= find_template(theme_source, "layouts/#{layout_path}")
        else
          return find_template(theme_source, "layouts/#{layout_path}")
        end
      rescue
        next
      end
    end
    raise "Could not find theme layout for layout_path: #{Array.wrap(layout_paths).join(", ")}; theme_source: #{theme_source}; options: #{options.inspect}"
  end
  
  def theme_template(template_path, source = nil)
    source ||= theme_source
    template_path ||= "#{controller_name}/#{action_name}"
    if Rails.configuration.action_controller.perform_caching?
      @@theme_templates_by_path["#{source.label}/#{template_path}"] ||= find_template(source, template_path)
    else
      find_template(source, template_path)
    end
  end
  
  def theme_source
    case self
    when ActionMailer::Base
      self.template.assigns[:publisher] || self.template.assigns[:publishing_group]
    else
      @publisher || @publishing_group || current_user_publisher_or_publishing_group
    end
  end

  def translate_with_theme(key, options = {})
    publisher_or_group = @publisher || @publishing_group
    Analog::Themes::I18n.translate(publisher_or_group, key, options)
  end


  private

  def is_publisher_user?(current_user)
    current_user.company.is_a?(Publisher)
  end

  def is_publishing_group_user?(current_user)
    current_user.company.is_a?(::PublishingGroup)
  end

  def user_without_admin_privilege?
    current_user && !current_user.has_admin_privilege?
  end

  def theme_source_not_set?
    !(@publisher || @publishing_group)
  end

  def current_user_publisher_or_publishing_group
    company = current_user.company
    [Publisher, PublishingGroup].include?(company.class) ? company : current_user.publisher
  end
end
