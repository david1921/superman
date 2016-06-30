module Travelsavers
  module BookingRequest

    URI = "https://bookingservices.travelsavers.com/ProductService.svc/REST/AnalogQuickSell"

    def hmac_signature(key, data)
      Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('SHA256'), key, data)).chomp
    end

    module_function :hmac_signature
  end
end