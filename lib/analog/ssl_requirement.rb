module Analog #:nodoc:
  
  # This is a patch to the default SslRequirement plugin, to
  # allow us to define formats to allow_ssl.
  module SslRequirement
    
    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
      base.class_eval do 
        alias_method :ssl_allowed_without_format?, :ssl_allowed?
        alias_method :ssl_allowed?, :ssl_allowed_with_format?        
      end

    end

    module ClassMethods

      # overwriting the default SslRequirement behaviour to use
      # inheritable hash instead of array, so we can supply a 
      # a with_format hash.
      def ssl_allowed(*actions)
        format_definition   = actions.last.is_a?(Hash) ? actions.pop : {}
        ssl_allowed_actions = read_inheritable_attribute(:ssl_allowed_actions) || {}
        actions.each do |action|
          ssl_allowed_actions[action.to_sym] = format_definition          
        end
        write_inheritable_hash(:ssl_allowed_actions, ssl_allowed_actions)
      end
            
    end
    
    module InstanceMethods
      
      protected
      
      def ssl_allowed?
        return true if HttpsOnlyHost.exists?(:host => request.host)

        ssl_allowed_actions = self.class.read_inheritable_attribute(:ssl_allowed_actions) || {}
        ssl_allowed_action  = ssl_allowed_actions.is_a?(Hash) && ssl_allowed_actions[action_name.to_sym]
        return false unless ssl_allowed_action
        return true  unless ssl_allowed_action.values.present?
        with_formats = ssl_allowed_action[:with_format]
        return true unless with_formats.present?
        with_formats.include?( request.format )
      end
      
      def ssl_allowed_with_format?
        ssl_allowed_without_format?
      end
      
      def ssl_required_for_hosts_that_require_https
        return unless ssl_rails_environment?

        if HttpsOnlyHost.exists?(:host => request.host) && !request.ssl?
          redirect_to "https://" + request.host + request.request_uri
          flash.keep
        end
      end

    end
    
  end
end
