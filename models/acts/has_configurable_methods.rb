module HasConfigurableMethods
  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods
    def configurable_method(*args)
      options = args.extract_options!
      options.assert_has_keys [:key], [:parent]
      
      key_name = ":#{options[:key].to_s.strip}"
      parent_association_name = options[:parent].present? ? ":#{options[:parent].to_s.strip}" : "nil"
      
      args.each do |method|
        in_method_ivar = "@in_method_#{method}"
        
        class_eval %Q{
          def #{method}(*args)
            unless #{in_method_ivar}
              #{in_method_ivar} = true
              install_configurable_methods! #{key_name}, #{parent_association_name}
              send(:#{method}, *args)
            end
          ensure
            #{in_method_ivar} = false
          end
        }
      end
    end
    
    def configurable_methods_for(key, &proc)
      (configurable_procs[key.to_s.strip] ||= []) << proc
    end
    
    private

    def find_configurable_procs(*keys)
      configurable_procs.values_at(*keys).compact.flatten
    end

    def configurable_procs
      @configurable_procs ||= {}
    end
  end
  
  module InstanceMethods
    private
    
    def install_configurable_methods!(key_name, parent_association_name)
      if !@configurable_methods_installed && (keys = configurable_method_keys(key_name, parent_association_name)).present?
        self.class.send(:find_configurable_procs, *keys).each { |proc| instance_eval &proc }
        @configurable_methods_installed = true
      end
    end

    def configurable_method_keys(key_name, parent_association_name)
      [configurable_method_parent(parent_association_name).if_present, self].compact.map do |candidate|
        candidate.send(key_name).to_s.strip if key_name.present? && candidate.respond_to?(key_name)
      end.compact
    end
    
    def configurable_method_parent(parent_association_name)
      self.send(parent_association_name) if parent_association_name.present? && self.respond_to?(parent_association_name)
    end
  end
end
