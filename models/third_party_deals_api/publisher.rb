require 'net/http'

module ThirdPartyDealsApi

  module Publisher

    def self.included(base)
      base.send :include, InstanceMethods
      base.extend ClassMethods

      base.has_one :third_party_deals_api_config, :class_name => "ThirdPartyDealsApi::Config"
      base.accepts_nested_attributes_for :third_party_deals_api_config, :reject_if => :third_party_config_blank?
      base.delegate :api_username, :api_password, :voucher_serial_numbers_url, :voucher_status_request_url,
                    :voucher_status_change_url, :to => :third_party_deals_api_config, :allow_nil => true
    end

    module InstanceMethods
      
      def third_party_config_blank?(attrs)
        attrs.values.all? { |v| v.blank? }
      end

      def third_party_deals_api_get(url, options = {})
        api_name = options.fetch(:api_name, "unknown")
        api_activity_label = options.fetch(:api_activity_label, "unknown")
        loggable = options.fetch(:loggable, nil)

        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.path)
        if url.starts_with?("https")
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          add_third_party_deals_auth_to_request(request)
        end
        response = nil
        logger.debug("[Third Party Deals] Sending GET to #{url}...")
        ms = Benchmark.measure { response = http.request(request) }
        logger.debug("[Third Party Deals] GET to #{url} completed (#{"%.3f" % ms.real}s)")
          
        activity_log =  ApiActivityLog.log :api_name => api_name,
                                          :api_activity_label => api_activity_label,
                                          :request_url => url, 
                                          :request => request,
                                          :response => response,
                                          :request_initiated_by_us => true,
                                          :response_time => ms.real,
                                          :loggable => loggable

        [response, activity_log]
      end

      def third_party_deals_api_post(url, body, options = {})
        api_name = options.fetch(:api_name, "unknown")
        api_activity_label = options.fetch(:api_activity_label, "unknown")
        loggable = options.fetch(:loggable, nil)
        
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri.path)
        request.body = body
        if url.starts_with?("https")
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          add_third_party_deals_auth_to_request(request)
        end
        response = nil
        logger.debug("[Third Party Deals] Sending POST to #{url}...")
        ms = Benchmark.measure { response = http.request(request) }
        logger.debug("[Third Party Deals] POST to #{url} completed (#{"%.3f" % ms.real}s)")
          
        activity_log = ApiActivityLog.log :api_name => api_name,
                                          :api_activity_label => api_activity_label,
                                          :request_url => url, 
                                          :request => request,
                                          :response => response,
                                          :request_initiated_by_us => true,
                                          :response_time => ms.real,
                                          :loggable => loggable

        [response, activity_log]
      end

      private

      def add_third_party_deals_auth_to_request(request)
        request.basic_auth third_party_deals_api_config.api_username, third_party_deals_api_config.api_password
      end

    end

    module ClassMethods

    end

  end

end
