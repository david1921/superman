module Api
  module Authentication
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      AUTHENTICATION_REALM = "Analog Analytics API"
      
      def perform_http_basic_authentication
        auth_result = authenticate_with_http_basic do |login, password|
          User.authenticate(login, password)
        end
        if auth_result.is_a?(User)
          @user = auth_result
        else
          @user = nil
          request_http_basic_authentication(AUTHENTICATION_REALM)
        end
      end 
      
    end
  end
end
