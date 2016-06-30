require File.dirname(__FILE__) + "/../../../models_helper"

# hydra class DailyDealCertificates::DailyDealCertificateTest
module DailyDealCertificates
  class DailyDealCertificateTest < Test::Unit::TestCase

    context "#hide_serial_number" do

      setup do
        @cert = stub
        @cert.extend(DailyDealCertificates::Core)
      end

      should "not hide serial number if flag not set" do
        @cert.stubs(:hide_serial_number_if_bar_code_is_present? => false)
        @cert.stubs(:bar_code => "I am here")
        assert_equal false, @cert.hide_serial_number?
      end

      should "hide serial number when flag is set" do
        @cert.stubs(:hide_serial_number_if_bar_code_is_present? => true)
        @cert.stubs(:bar_code => "I am here")
        assert_equal true, @cert.hide_serial_number?
      end

      should "not hide serial number if there is no bar_code" do
        @cert.stubs(:hide_serial_number_if_bar_code_is_present? => false)
        @cert.stubs(:bar_code => nil)
      end

    end

    context "#as_json" do

      setup do
        @cert = stub
        @cert.extend(DailyDealCertificates::Core)
      end

      should "include serial_number if hide_serial_number is false" do
        @cert.stub_everything
        @cert.stubs(:hide_serial_number? => false)
        @cert.stubs(:serial_number => "123456")
        result = @cert.as_json
        assert_equal "123456", result[:serial_number]
      end

      should "blank out serial_number if hid_serial_number is true" do
        @cert.stub_everything
        @cert.stubs(:hide_serial_number? => true)
        @cert.stubs(:serial_number => "123456")
        result = @cert.as_json
        assert_equal "", result[:serial_number]
      end

    end

  end
end
