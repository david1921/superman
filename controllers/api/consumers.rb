module Api
  module Consumers
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def consumer_for_api(consumer, api_version)        
        url_options = { :protocol => "https", :host => AppConfig.api_host, :format => "json" }
        
        case api_version
        when "1.0.0"
          {
            :name => consumer.name,
            :credit_available => consumer.credit_available,
            :session => api_session_for_consumer(consumer)
          }
        when "2.0.0", "2.1.0"
          {
            :name => consumer.name,
            :credit_available => consumer.credit_available,
            :session => api_session_for_consumer(consumer),
            :connections => {
              :purchases => daily_deal_purchases_consumer_url(consumer, url_options)
            }
          }
        when "2.2.0", "3.0.0"
          {
            :name => consumer.name,
            :credit_available => consumer.credit_available,
            :session => api_session_for_consumer(consumer),
            :connections => {
              :purchases => daily_deal_purchases_consumer_url(consumer, url_options),
              :credit_cards => consumer_credit_cards_url(consumer, url_options)
            },
            :methods => {
              :save_credit_card => consumer_credit_cards_url(consumer, url_options)
            }
          } 
        else
          raise "unsupported API version for consumer export: #{api_version}"
        end
      end
      
      def consumer_json_for_api(consumer, api_version)        
        consumer_for_api(consumer, api_version).to_json
      end
      
      def api_session_for_user(user)
        verifier.generate(:user_id => user.id, :active_session_token => user.active_session_token)
      end
      
      def api_session_for_consumer(consumer)
        api_session_for_user(consumer)
      end
      
      def login_via_session_for_json_request!   
        load_consumer_from_session_for_json_request(true)
        unless current_consumer.present?
          render :nothing => true, :status => :forbidden
          return false          
        end
      end
      
      # if the request is json, then we try and load the consumer from the session or consumer[session]
      # parameter in the request.
      #
      # if you pass in true, then the current session consumer will be forced to be nil if any exceptions
      # arise...like not having a session or consumer[session] in the request. Added this behaviour for
      # integration testing to make sure we pass in those parameters on a request, otherwise the integration
      # tests would be happy to use the current session which may have a current user already.
      def load_consumer_from_session_for_json_request(require_from_session_parameter = false)
        if request.format.json?
          begin
            session = verifier.verify(params[:session] || params[:consumer][:session]) 
            set_up_session(::Consumer.find(session[:user_id]), false)
          rescue
            if require_from_session_parameter
              self.current_user = nil
            end
          end          
        end
      end
                 
      def ensure_user_for_json_request
        login_user_for_json_request
        unless current_user.present?
          render :nothing => true, :status => :forbidden
          return false          
        end
      end
      
      def login_user_for_json_request
        if request.format.json?
          session = verifier.verify(params[:session]) 
          set_up_session(::User.find_by_id_and_active_session_token(session[:user_id], session[:active_session_token]), false)
        end          
      rescue
        nil
      end
      
      def secret_key
        @secret_key ||= ActionController::Base.session_options[:secret]        
      end
      
      def verifier
        @verifier ||= ActiveSupport::MessageVerifier.new(secret_key)
      end
    end
  end
end
