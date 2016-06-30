module Users
  module Loggable

    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods

      def log_action(action, ip_address)
        user_logs.create(:action => action, :ip_address => ip_address)
      end

    end

  end
end
