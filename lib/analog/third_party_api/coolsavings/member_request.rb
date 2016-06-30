require 'net/http'
require 'net/https'
require 'analog/exceptions'

module Analog
  module ThirdPartyApi
    module Coolsavings
      class MemberRequest
        include Analog::Say

        attr_reader :url

        def initialize(url)
          @url = url
        end

        def execute
          response = create_http.start { |http| http.request(create_get) }
          MemberResponse.new(response.body).parse!
        end

        def create_http
          http = Net::HTTP.new(url.host, url.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          http
        end

        def create_get
          self.class.say "Coolsavings request: #{path}"
          Net::HTTP::Get.new(path)
        end

        def path
          raise Analog::SubclassesMustImplementException.new
        end

      end
    end
  end
end
