module HasConfigurableProperties
  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods
    def configurable_property(*props)
      props.each do |prop|
        instance_variable = "@cached_#{prop}"
        class_eval %Q{
          def #{prop}
            #{instance_variable} = value_from_config_file("#{prop}") if #{instance_variable}.nil?
            #{instance_variable}
          end
        }
      end
    end

    attr_accessor :configurable_property_parent_association

    def configurable_property_parent(parent)
      @configurable_property_parent_association = parent
    end
  end

  module InstanceMethods
    def display_text_for(key, default_value = nil)
      if key && display_text && display_text[key.to_s]
        return display_text[key.to_s]
      else
        return default_value || ""
      end
    rescue => e
      warn "Error looking up text #{key} for #{self.class} #{label}: #{e}"
      ""
    end
  end

  private

  def value_from_config_file(configurable_property_name)
    potential_config_files = []
    potential_config_files << File.join(Rails.root, "config/themes/#{label}/#{configurable_property_name}.yml")

    parent_association = self.class.configurable_property_parent_association
    parent = self.send(parent_association) if parent_association

    if parent && parent.respond_to?(:label) && parent.label
      potential_config_files << File.join(Rails.root, "config/themes/#{parent.label}/#{configurable_property_name}.yml")
    end

    potential_config_files << File.join(Rails.root, "config/themes/default/#{configurable_property_name}.yml")

    most_specific_config_file = potential_config_files.find { |file_name| File.exists? file_name }
    most_specific_config_file.present? ? YAML::load(ERB.new(File.read(most_specific_config_file)).result) : nil
  end

end
