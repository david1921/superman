module Users
  module Core
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def successful_login!; end
      def failed_login!; end
    end
  end
end
