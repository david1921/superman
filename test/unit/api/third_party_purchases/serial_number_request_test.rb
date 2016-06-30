require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Api::ThirdPartyPurchases::SerialNumberRequestTest

module Api::ThirdPartyPurchases
  class SerialNumberRequestTest < ActiveSupport::TestCase
    context "#before_validation" do
      should "set doc from xml" do
        xml = valid_xml
        req = SerialNumberRequest.new(:xml => xml)
        assert_nil req.doc
        req.valid?
        assert req.doc.kind_of?(Nokogiri::XML::Document)
      end
    end

    private

    def valid_xml
      File.read(Rails.root + "test/data/api/third_party_purchases/serial_number_request.xml")
    end
  end
end
