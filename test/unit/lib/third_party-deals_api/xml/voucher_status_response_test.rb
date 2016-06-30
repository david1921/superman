require File.dirname(__FILE__) + "/../../../../test_helper"

# hydra class ThirdPartyDealsApi::XML::VoucherStatusResponseTest

module ThirdPartyDealsApi
  module XML

    class VoucherStatusResponseTest < ActiveSupport::TestCase
      context "parse voucher status request response" do
        
        context "multiple serial numbers" do
          setup do
            xml_response = <<-eos
            <?xml version="1.0" encoding="UTF-8"?>
              <voucher_status_response listing="123456" purchase_id="000033fd332c47cab7c050068a16efdd" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
                <status serial_number="1817-9817">ACTIVE</status>
                <status serial_number="4569-8999">REDEEMED</status>
                <status serial_number="1113-9934">REDEEMED</status>
              </voucher_status_response>
            eos
            @daily_deal = Factory(:daily_deal, :listing => "123456")
            @daily_deal_purchase = Factory(:captured_daily_deal_purchase,
                                           :daily_deal => @daily_deal,
                                           :quantity => 3)
            @response_hash = VoucherStatusResponse.new(@daily_deal_purchase, xml_response).to_voucher_status_response_hash(false)
          end
          should "be valid" do
            assert_equal Hash, @response_hash.class
            assert_equal 3, @response_hash.size ## listing, purchase_id, and hash of statuses
          end
          should "have the correct listing" do
            assert_equal "123456", @response_hash['listing']
          end
          should "have the correct purchase_id" do
            assert_equal "000033fd332c47cab7c050068a16efdd", @response_hash['purchase_id']
          end
          should "have the correct status values" do
            assert_equal "ACTIVE", @response_hash['statuses']['1817-9817']
            assert_equal "REDEEMED", @response_hash['statuses']['4569-8999']
            assert_equal "REDEEMED", @response_hash['statuses']['1113-9934']
          end
        end

        context "single serial number" do

          setup do
            xml_response = <<-eos
            <?xml version="1.0" encoding="UTF-8"?>
              <voucher_status_response listing="123456" purchase_id="000033fd332c47cab7c050068a16efdd" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
                <status serial_number="1817-9817">ACTIVE</status>
              </voucher_status_response>
            eos
            @daily_deal = Factory(:daily_deal, :listing => "123456")
            @daily_deal_purchase = Factory(:captured_daily_deal_purchase,
                                           :daily_deal => @daily_deal,
                                           :quantity => 1)
            @response_hash = VoucherStatusResponse.new(@daily_deal_purchase, xml_response).to_voucher_status_response_hash(false)
          end

          should "be valid" do
            assert_equal Hash, @response_hash.class
            assert_equal 3, @response_hash.size ## listing, purchase_id, and hash of statuses
          end

          should "have the correct listing" do
            assert_equal "123456", @response_hash['listing']
          end

          should "have the correct purchase_id" do
            assert_equal "000033fd332c47cab7c050068a16efdd", @response_hash['purchase_id']
          end

          should "have the correct status value" do
            assert_equal "ACTIVE", @response_hash['statuses']['1817-9817']
          end

        end

      end

      context "bogus responses" do

        setup do
          @deal = Factory(:daily_deal, :publisher => @publisher, :listing => "1234")
          @purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @deal, :quantity => 3)
        end

        should "be INVALID when listing in response does not match daily deal listing" do
          response_with_bad_listing = %Q{
            <?xml version="1.0" encoding="UTF-8"?>
            <voucher_status_response listing="bogus_listing"
             purchase_id="#{@purchase.uuid}"
             xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
              <status serial_number="#{@purchase.daily_deal_certificates.first.serial_number}">ACTIVE</serial_number>
              <status serial_number="#{@purchase.daily_deal_certificates.second.serial_number}">ACTIVE</serial_number>
              <status serial_number="#{@purchase.daily_deal_certificates.third.serial_number}">ACTIVE</serial_number>
            </voucher_status_request>
          }
          
          voucher_status_response = ThirdPartyDealsApi::XML::VoucherStatusResponse.new(@purchase, response_with_bad_listing)
          assert !voucher_status_response.valid?
          assert_equal 1, voucher_status_response.error_messages.length
          assert_match /response has listing \(bogus_listing\) that does not match daily_deal \(1234\)/, voucher_status_response.error_messages.first
        end

        should "be INVALID when purchase id does not match daily_deal_purchase.uuid" do
          response_with_bad_purchase_id = %Q{
            <?xml version="1.0" encoding="UTF-8"?>
            <voucher_status_response listing="1234"
             purchase_id="bad_purchase_id"
             xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
              <status serial_number="#{@purchase.daily_deal_certificates.first.serial_number}">ACTIVE</serial_number>
              <status serial_number="#{@purchase.daily_deal_certificates.second.serial_number}">ACTIVE</serial_number>
              <status serial_number="#{@purchase.daily_deal_certificates.third.serial_number}">ACTIVE</serial_number>
            </voucher_status_request>
          }
          
          voucher_status_response = ThirdPartyDealsApi::XML::VoucherStatusResponse.new(@purchase, response_with_bad_purchase_id)
          assert !voucher_status_response.valid?
          assert_equal 1, voucher_status_response.error_messages.length
          assert_match /voucher status response has purchase_id \(bad_purchase_id\) that does not match daily_deal_purchase \(#{@purchase.uuid}\)/, voucher_status_response.error_messages.first
        end

        should "be INVALID if serial number is missing from response" do
          response_with_missing_serial_number = %Q{
            <?xml version="1.0" encoding="UTF-8"?>
            <voucher_status_response listing="1234"
             purchase_id="#{@purchase.uuid}"
             xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
            </voucher_status_request>
          }
      
          voucher_status_response = ThirdPartyDealsApi::XML::VoucherStatusResponse.new(@purchase, response_with_missing_serial_number)
          assert !voucher_status_response.valid?
          assert_equal 1, voucher_status_response.error_messages.length
          assert_equal "third party voucher response contains no serial numbers", voucher_status_response.error_messages.first
        end
                
      end
      
      context "#valid_and_internal_statuses_match_external_statuses?" do

        should "return true if the return statuses are REFUNDED for certs whose status is VOIDED, " +
               "since Doubletake doesn't have a voided status" do
          voided_purchase = Factory :voided_daily_deal_purchase

          response_refunded_status = %Q{
            <?xml version="1.0" encoding="UTF-8"?>
            <voucher_status_response listing="#{voided_purchase.daily_deal.listing}"
             purchase_id="#{voided_purchase.uuid}"
             xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
              <status serial_number="#{voided_purchase.daily_deal_certificates.first.serial_number}">REFUNDED</serial_number>
            </voucher_status_request>
          }

          voucher_status_response = ThirdPartyDealsApi::XML::VoucherStatusResponse.new(voided_purchase, response_refunded_status)
          assert voucher_status_response.valid_and_internal_statuses_match_external_statuses?,
                 "expected to be valid, but got errors: #{voucher_status_response.error_messages_with_xml}"
        end

      end
      
    end
  end
end

