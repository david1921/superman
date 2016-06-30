# Based off the following example provided by Yelp:
# https://github.com/Yelp/yelp-api/blob/master/v2/ruby/example.rb

module Yelp
  class Client
    API_HOST = "api.yelp.com"

    BUSINESS_API_PATH = "/v2/business"

    def initialize(credentials)
      consumer = OAuth::Consumer.new(credentials[:consumer_key],
                                     credentials[:consumer_secret],
                                     {:site => "http://#{API_HOST}"})

      @access_token = OAuth::AccessToken.new(consumer,
                                             credentials[:token],
                                             credentials[:token_secret])
    end

    def find_business(business_id)
      path = "#{BUSINESS_API_PATH}/#{business_id}"
      response = @access_token.get(path)

      if response.is_a?(Net::HTTPOK)
        JSON.parse(response.body).with_indifferent_access rescue nil
      end
    end
  end
end
