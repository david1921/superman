require File.dirname(__FILE__) + "/../../../../test_helper"

# hydra class ThirdPartyDealsApi::XML::VoucherStatusRequestTest

module ThirdPartyDealsApi
  module XML

    class VoucherStatusRequestTest < ActiveSupport::TestCase

      context "create voucher status request" do

        context "multiple third-party serial numbers" do
          setup do
            @daily_deal = Factory(:daily_deal, :listing => "special_123")
            @daily_deal_purchase = Factory(:captured_daily_deal_purchase,
                                           :daily_deal => @daily_deal,
                                           :quantity => 3)
            @actual = Hash.from_xml(VoucherStatusRequest.new(@daily_deal_purchase).create_voucher_status_request)
          end
          should "have the correct setup" do
            assert_equal 3, @daily_deal_purchase.daily_deal_certificates.size
            @daily_deal_purchase.daily_deal_certificates.each do |cert|
              assert_not_nil cert.serial_number
            end
            assert_equal "special_123", @daily_deal.listing
          end
          should "have the correct listing" do
            assert_not_nil @actual
            assert_not_nil @actual["voucher_status_request"]
            assert_equal "special_123", @actual["voucher_status_request"]["listing"]
          end
          should "have correct purchase id" do
            assert_equal @daily_deal_purchase.uuid, @actual["voucher_status_request"]["purchase_id"]
          end
          should "have correct xml name space attribute" do
            assert_equal "http://analoganalytics.com/api/third_party_deals/purchases", @actual["voucher_status_request"]["xmlns"]
          end
          should "have correct number of third party serial numbers" do
            assert_equal 3, @actual["voucher_status_request"]["serial_number"].size
          end
          should "have correct third party serial numbers" do
            expected_serial_numbers = @daily_deal_purchase.daily_deal_certificates.map(&:serial_number).sort
            actual_serial_numbers = @actual["voucher_status_request"]["serial_number"].sort
            assert_equal expected_serial_numbers, actual_serial_numbers
          end
        end

        context "one third-party serial number" do
          setup do
            @daily_deal = Factory(:daily_deal, :listing => "special_123")
            @daily_deal_purchase = Factory(:captured_daily_deal_purchase,
                                           :daily_deal => @daily_deal,
                                           :quantity => 1)
            @actual = Hash.from_xml(VoucherStatusRequest.new(@daily_deal_purchase).create_voucher_status_request)
          end
          should "have the correct setup" do
            assert_equal 1, @daily_deal_purchase.daily_deal_certificates.size
          end
          should "have the correct listing" do
            assert_not_nil @actual
            assert_not_nil @actual["voucher_status_request"]
            assert_equal "special_123", @actual["voucher_status_request"]["listing"]
          end
          should "have correct purchase id" do
            assert_equal @daily_deal_purchase.uuid, @actual["voucher_status_request"]["purchase_id"]
          end
          should "have correct xml name space attribute" do
            assert_equal "http://analoganalytics.com/api/third_party_deals/purchases", @actual["voucher_status_request"]["xmlns"]
          end
          should "have correct third party serial number" do
            assert_equal @daily_deal_purchase.daily_deal_certificates.first.serial_number, @actual["voucher_status_request"]["serial_number"]
          end
        end
      
      end
      
    end
  end
end
