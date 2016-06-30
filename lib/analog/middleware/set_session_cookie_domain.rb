module Analog
  module Middleware
    class SetSessionCookieDomain
      def initialize(app)
        @app = app
      end

      def call(env)
        cookie_domain = '.analoganalytics.com'
        if env['SERVER_NAME'] =~ /#{Regexp.escape(cookie_domain)}$/ && env["rack.session.options"]
          env["rack.session.options"][:domain] = cookie_domain
        end

        @app.call(env)
      end
    end
  end
end
