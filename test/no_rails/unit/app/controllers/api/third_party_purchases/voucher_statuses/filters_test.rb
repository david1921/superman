require File.dirname(__FILE__) + '/../../../../controllers_helper'

# hydra class Api::ThirdPartyPurchases::VoucherStatuses::FiltersTest

module Api::ThirdPartyPurchases::VoucherStatuses
  class FiltersTest < Test::Unit::TestCase

    def setup
      @obj = Object.new.extend(Api::ThirdPartyPurchases::VoucherStatuses::Filters)
    end

    context "#load_certificates" do
      should "assign @certificates from xml request serial numbers" do
        serial_numbers = mock('serial numbers')
        certs = mock('certificates')

        @obj.expects(:serial_numbers_from_request).returns(serial_numbers)
        @obj.expects(:find_certificates_by_serial_number).with(serial_numbers).returns(certs)

        @obj.load_certificates

        assert_equal certs, @obj.instance_variable_get(:@certificates)
      end
    end
  end
end