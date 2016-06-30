module Consumers
  module ReferralUrls

    def referral_url(url_publisher = nil)
      url_publisher ||= self.publisher
      consumer_referral_urls.find_or_create_by_publisher_id(url_publisher.id).bit_ly_url
    end

    def referral_url_for_bit_ly(url_publisher = nil)
      url_publisher ||= self.publisher
      host, port = url_publisher.daily_deal_host.split(":")
      uri_params = {
        :host => host,
        :path => "/publishers/#{url_publisher.label}/deal-of-the-day",
        :query => "referral_code=#{referrer_code}"
      }
      uri_params.merge!(:port => port) if port.present?
      URI::HTTP.build(uri_params).to_s
    end

  end
end
