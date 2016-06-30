require File.dirname(__FILE__) + '/../../../../controllers_helper'

# hydra class Api::ThirdPartyPurchases::VoucherStatuses::CoreTest

module Api::ThirdPartyPurchases::VoucherStatuses
  class CoreTest < Test::Unit::TestCase

    def setup
      @obj = Object.new.extend(Api::ThirdPartyPurchases::VoucherStatuses::Core)
    end

    context "#update_certificate_statuses(certificates)" do
      should "call #set_status! with the requested status for each certificate" do
        certs = [mock("certificate 1", :serial_number => "1111-1111"), mock("certificate 2", :serial_number => "2222-2222")]
        statuses = {'1111-1111' => 'redeemed', '2222-2222' => 'refunded'}

        xml = mock('xml')
        @obj.stubs(:request_body).returns(xml)

        certs[0].expects(:set_status!).with('redeemed')
        certs[1].expects(:set_status!).with('refunded')

        @obj.expects(:voucher_statuses_from_xml).with(xml).returns(statuses)
        @obj.update_certificate_statuses(certs)
      end

      should "log error when exception raised by #set_status!" do
        xml = mock('xml')
        @obj.stubs(:request_body).returns(xml)
        status = mock('status')
        @obj.stubs(:voucher_statuses_from_xml).returns({'1234' => status})
        cert = stub('certificate', :serial_number => '1234')
        cert.stubs(:set_status!).raises('exception')
        @obj.expects(:log_status_change_error).with(cert, status)

        @obj.update_certificate_statuses([cert])
      end
    end

    context "#voucher_statuses_from_xml(xml)" do
      should "return a hash of serial numbers and statuses from the xml" do
        xml = "<root><voucher_status serial_number='1234'>active</voucher_status><voucher_status serial_number='5678'>redeemed</voucher_status></root>"
        statuses = @obj.voucher_statuses_from_xml(xml)
        assert_equal ({"1234" => "active", "5678" => "redeemed"}), statuses
      end
    end

    context "#find_certificates_by_serial_number(serial_numbers)" do
      should "return matching certificates" do
        assert "this can't be tested by a fast test'"
      end
    end

    context "#serial_numbers_from_request" do
      should "return just the serial numbers from the voucher status info" do

      end
    end

    context "#request_body" do
      should "return the request body content" do
        xml = mock('xml')
        @obj.stubs(:request).returns(mock('request', :body => mock('body', :read => xml)))
        assert_equal xml, @obj.request_body
      end

      should "not read the body more than once (return cached value)" do
        xml = mock('xml')
        body = mock('body')
        body.expects(:read).once.returns(xml)
        @obj.stubs(:request).returns(mock('request', :body => body))
        assert_equal xml, @obj.request_body
        assert_equal xml, @obj.request_body
      end
    end
  end
end