require File.dirname(__FILE__) + "/../../test_helper"

# hydra class CyberSource::GatewayTest

module CyberSource
  class GatewayTest < ActiveSupport::TestCase
    context "with valid input arguments for void" do
      setup do
        init_cyber_source_credentials_for_tests("entertainment")
        @credentials = CyberSource::Credentials.find("entertainment")
        @request_id = "3308772944980176056442"
        @merchant_reference = "1234-BBP-20120204123456"
      end
      
      context "and when the SOAP processor expects a void request and returns decision REJECT" do
        setup do
          @processor = mock()
          @processor.expects(:runTransaction).with do |request|
            @request_id == request.voidService.voidRequestID && @merchant_reference == request.merchantReferenceCode
          end.returns(stub(:decision => "REJECT", :voidReply => stub(:reasonCode => "246")))
        end
        
        should "raise a gateway error in void" do
          assert_raise CyberSource::Gateway::Error do
            CyberSource::Gateway.void(@credentials, @request_id, @merchant_reference, @processor)
          end
        end
      end
      
      context "and when the SOAP processor expects a void request and returns decision ACCEPT" do
        setup do
          @processor = mock()
          @processor.expects(:runTransaction).with do |request|
            @request_id == request.voidService.voidRequestID &&
            @merchant_reference == request.merchantReferenceCode
          end.returns(stub(:decision => "ACCEPT"))
        end
        
        should "return nil from void" do
          assert_nil CyberSource::Gateway.void(@credentials, @request_id, @merchant_reference, @processor)
        end
      end
    end

    context "with valid input arguments for credit" do
      setup do
        init_cyber_source_credentials_for_tests("entertainment")
        @credentials = CyberSource::Credentials.find("entertainment")
        @request_id = "3308772944980176056442"
        @merchant_reference = "1234-BBP-20120204123456"
        @options = {
          :billing => {
            :first_name => "John",
            :last_name => "Public",
            :address_line_1 => "123 Main Street",
            :address_line_2 => "Unit 4",
            :city => "Los Angeles",
            :state => "CA",
            :postal_code => "90210",
            :country => "us",
            :email => "john@example.com"
          },
          :merchant_defined => {
            :field_1 => "foo",
            :field_2 => "bar",
            :field_3 => "baz",
            :field_4 => "bif"
          }
        }
      end
      
      context "and when the SOAP processor expects a credit request and returns decision REJECT" do
        setup do
          @processor = mock()
          @processor.expects(:runTransaction).with do |request|
            @request_id == request.ccCreditService.captureRequestID &&
            @merchant_reference == request.merchantReferenceCode &&
            "14.00" == request.purchaseTotals.grandTotalAmount &&
            "usd" == request.purchaseTotals.currency &&
            "John" == request.billTo.firstName &&
            "Public" == request.billTo.lastName &&
            "123 Main Street" == request.billTo.street1 &&
            "Unit 4" == request.billTo.street2 &&
            "Los Angeles" == request.billTo.city &&
            "CA" == request.billTo.state &&
            "90210" == request.billTo.postalCode &&
            "john@example.com" == request.billTo.email &&
            "foo" == request.merchantDefinedData.field1 &&
            "bar" == request.merchantDefinedData.field2 &&
            "baz" == request.merchantDefinedData.field3 &&
            "bif" == request.merchantDefinedData.field4
          end.returns(stub(:decision => "REJECT", :ccCreditReply => stub(:reasonCode => "247")))
        end
        
        should "raise a gateway error in credit" do
          assert_raise CyberSource::Gateway::Error do
            CyberSource::Gateway.credit(@credentials, @request_id, 14.0, "usd", @merchant_reference, @options, @processor)
          end
        end
      end

      context "and when the SOAP processor expects a credit request and returns decision ACCEPT" do
        setup do
          @processor = mock()
          @processor.expects(:runTransaction).with do |request|
            @request_id == request.ccCreditService.captureRequestID &&
            @merchant_reference == request.merchantReferenceCode &&
            "14.00" == request.purchaseTotals.grandTotalAmount &&
            "usd" == request.purchaseTotals.currency &&
            "John" == request.billTo.firstName &&
            "Public" == request.billTo.lastName &&
            "123 Main Street" == request.billTo.street1 &&
            "Unit 4" == request.billTo.street2 &&
            "Los Angeles" == request.billTo.city &&
            "CA" == request.billTo.state &&
            "90210" == request.billTo.postalCode &&
            "john@example.com" == request.billTo.email &&
            "foo" == request.merchantDefinedData.field1 &&
            "bar" == request.merchantDefinedData.field2 &&
            "baz" == request.merchantDefinedData.field3 &&
            "bif" == request.merchantDefinedData.field4
          end.returns(stub(
            :decision => "ACCEPT",
            :requestID => "3308768036750178147616",
            :ccCreditReply => stub(:requestDateTime => "2012-03-04T16:08:14Z", :reconciliationID => "2723076652")
          ))
        end
        
        should "return a credit object from credit" do
          credit = CyberSource::Gateway.credit(@credentials, @request_id, 14.0, "usd", @merchant_reference, @options, @processor)
          assert_equal "3308768036750178147616", credit.request_id
          assert_equal "2723076652", credit.reconciliation_id
          assert_equal Time.parse("Mar 04, 2012 16:08:14 UTC"), credit.created_at
        end
      end
    end
  end
end
