module Analog
  module Middleware
    class OptionsMethodNotAllowed
      def initialize(app)
        @app = app
      end

      def call(env)
        if env['REQUEST_METHOD'] == 'OPTIONS'
          [405, {'Content-Type' => 'text/plain'}, '']
        else
          @app.call(env)
        end
      end
    end
  end
end
