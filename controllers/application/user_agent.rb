module Application
  module UserAgent

    def self.included(base)
      base.send :include, InstanceMethods
      base.class_eval do
        helper_method :facebook_request?
      end
    end

    module InstanceMethods

      def iphone_user_agent?
        request.user_agent =~ /(Mobile\/.+Safari)/
      end

      def bot_agent?
        request.user_agent =~ /bot/i
      end
  
      def set_format_for_iphone
        request.format = :iphone if iphone_user_agent?
      end

      def facebook_request?
        request.headers['HTTP_USER_AGENT'] =~ /^facebookexternalhit/i
      end
    
      def user_agent
        request.env['HTTP_USER_AGENT']
      end   

      def block_bots!
        render_404 and return if bot_agent?
      end

    end
  end
end
