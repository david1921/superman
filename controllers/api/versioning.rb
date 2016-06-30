module Api
  module Versioning 
    VALID_API_VERSIONS = %w{ 1.0.0 2.0.0 2.1.0 2.2.0 3.0.0 3.5.0 }
        
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def valid_api_version?(version)
        VALID_API_VERSIONS.include?(version)
      end
      
      def default_api_version
        @@default_api_version ||= VALID_API_VERSIONS.sort.last
      end
      
      private
      
      def require_api_version(options = {})
        options = options.dup
        minimum_version_required = options.delete(:minimum)
        raise ArgumentError, "missing required argument :minimum" unless minimum_version_required.present?
        
        before_filter(options) do |controller|
          @api_version = controller.request.headers["API-Version"]

          unless @api_version.present? && valid_api_version?(@api_version) && @api_version >= minimum_version_required
            @api_version = default_api_version
            @errors = [{ "API-Version" => "is not valid" }]
            controller.send :render, "api/failure", :layout => false, :status => :not_acceptable
            controller.response.headers['API-Version'] = @api_version
          end
        end
      end
    end
    
    module InstanceMethods
      attr_reader :api_version
      
      def check_and_set_api_version_header
        @api_version = request.headers['API-Version']
        unless self.class.valid_api_version?(@api_version)
          @api_version = self.class.default_api_version
          @errors = [{ "API-Version" => "is not valid" }]
          render "api/failure", :layout => false, :status => :not_acceptable
        end
        response.headers['API-Version'] = @api_version
        !performed?
      end
      
      def check_and_set_api_version_header_for_json_requests
        if request.format.json?
          check_and_set_api_version_header
        end
      end
      
      def with_api_version(*options)
        options = options.flatten.extract_options!
        options[:layout] = false
        options[:template] = api_versioned_template(options[:template], @api_version)
        options
      end
      
      private
      
      def api_versioned_template(template_path, version)
        template_path ||= "#{controller_name}/#{action_name}"
        template_format = respond_to?(:request) && request ? request.template_format : :xml
        if Rails.configuration.action_controller.perform_caching?
          @@api_templates_by_path["#{template_path}:#{version}.#{template_format}"] ||= find_versioned_template(template_path, version, template_format)
        else
          find_versioned_template(template_path, version, template_format)
        end
      end
      
      def find_versioned_template(template_path, version, template_format)
        sorted_api_versions_less_than_or_equal_to(version).each do |possible_version|
          if (path = find_template_version(template_path, possible_version, template_format))
            return path
          end
        end
        view_paths.find_template(template_path, template_format, false)
      end
      
      def sorted_api_versions_less_than_or_equal_to(version)
        VALID_API_VERSIONS.select { |valid_version| valid_version <= version }.sort.reverse
      end
      
      def find_template_version(template_path, api_version, template_format)
        view_paths.find_template("#{template_path}:#{api_version}", template_format, false) rescue nil
      end
    end
  end
end
