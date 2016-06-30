require File.dirname(__FILE__) + "/../lib_helper"

# hydra class Travelsavers::BookingRequestTest

module Travelsavers
  class BookingRequestTest < Test::Unit::TestCase
    context "#hmac_signature" do
      should "return a Base64 encoded, HMAC-encrypted string using SHA256 digest" do
        key, data = "GG49B304-EBB6-4661-B0D0-430451B0B948", "a=1&b=2&c=3"
        expected_signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('SHA256'), key, data)).chomp
        assert_equal expected_signature, Travelsavers::BookingRequest.hmac_signature(key, data), "Unexpected signature"
      end
    end
  end
end
