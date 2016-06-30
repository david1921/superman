require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ThirdPartyDealsApi::DailyDealPurchaseTest

module ThirdPartyDealsApi

  class DailyDealPurchaseTest < ActiveSupport::TestCase

    context "what kind of serial numbers is the purchase using" do

      context "using internal serial numbers" do
        setup do
          @publisher = Factory(:publisher)
          @deal = Factory(:daily_deal, :publisher => @publisher)
          @purchase = Factory(:daily_deal_purchase, :daily_deal => @deal)
        end
        should "be using internal serial numbers" do
          assert @purchase.using_internal_serial_numbers?
        end
        should "not be using third party serial numbers" do
          assert !@purchase.using_third_party_serial_numbers?
        end
      end

      context "using third party serial numbers" do
        setup do
          @config = Factory(:third_party_deals_api_config, :voucher_serial_numbers_url => "https://example.com/serial_numbers")
          @publisher = Factory(:publisher, :third_party_deals_api_config => @config)
          @deal = Factory(:daily_deal, :publisher => @publisher)
          @purchase = Factory(:daily_deal_purchase, :daily_deal => @deal)
        end
        should "have correct setup" do
          assert_not_nil @publisher.voucher_serial_numbers_url
        end
        should "not be using internal serial numbers" do
          assert !@purchase.using_internal_serial_numbers?
        end
        should "be using third party serial numbers" do
          assert @purchase.using_third_party_serial_numbers?
        end
      end
    end

    context "third party serial number request XML" do

      should "be generated with a call to DailyDealPurchase#create_serial_number_request_xml" do
        daily_deal = Factory :daily_deal, :listing => "SERIAL-NUM-XML"
        consumer = Factory :consumer, :first_name => "John", :last_name => "Galt", :publisher => daily_deal.publisher
        daily_deal_purchase = Factory :daily_deal_purchase, :consumer => consumer, :daily_deal => daily_deal, :quantity => 1
        serial_number_request_xml = %Q{\
<?xml version="1.0" encoding="UTF-8"?>
<serial_number_request listing="SERIAL-NUM-XML" purchase_id="#{daily_deal_purchase.uuid}" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
  <purchaser_name>John Galt</purchaser_name>
  <recipient_names>
    <recipient_name>John Galt</recipient_name>
  </recipient_names>
  <location>
    <listing></listing>
  </location>
  <quantity>1</quantity>
</serial_number_request>}
        assert_equal serial_number_request_xml, ThirdPartyDealsApi::XML::SerialNumberRequest.new(daily_deal_purchase).create_serial_number_request_xml
      end

    end

    context "a third party serial number request" do

      setup do
        @serial_number_response_xml = %Q{\
<?xml version="1.0" encoding="UTF-8"?>
<serial_numbers listing="SERIAL-TEST" purchase_id="000033fd332c47cab7c050068a16efdd" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
  <serial_number>1817-9817</serial_number>
  <serial_number>1113-9934</serial_number>
</serial_numbers>}
        FakeWeb.register_uri(:post, "https://test-api-username:test-api-password@test.url:443/generate_serials", :body => @serial_number_response_xml)
      end

      should "NOT be made when a purchase is captured, for a publisher that doesn't " +
                     " use third party serials" do
        daily_deal_purchase = Factory :daily_deal_purchase
        assert daily_deal_purchase.using_internal_serial_numbers?
        daily_deal_purchase.publisher.expects(:third_party_deals_api_post).never
        braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
        daily_deal_purchase.handle_braintree_sale! braintree_transaction
      end

      should "be made when a purchase is captured and the publisher uses third party serials" do
        daily_deal = Factory :daily_deal, :listing => "SERIAL-TEST", :uuid => "000033fd332c47cab7c050068a16efdd"
        consumer = Factory :consumer, :first_name => "Bob", :last_name => "Jones", :publisher => daily_deal.publisher
        daily_deal_purchase = Factory :daily_deal_purchase, :gift => true, :consumer => consumer, :recipient_names => ["Bob Jones", "Alice Fry"], :quantity => 2, :daily_deal => daily_deal
        Factory :third_party_deals_api_config,
                :publisher => daily_deal_purchase.publisher,
                :voucher_serial_numbers_url => "https://test.url/generate_serials"
        assert daily_deal_purchase.using_third_party_serial_numbers?
        serial_number_request_xml = %Q{\
<?xml version="1.0" encoding="UTF-8"?>
<serial_number_request listing="SERIAL-TEST" purchase_id="#{daily_deal_purchase.uuid}" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
  <purchaser_name>Bob Jones</purchaser_name>
  <recipient_names>
    <recipient_name>Bob Jones</recipient_name><recipient_name>Alice Fry</recipient_name>
  </recipient_names>
  <location>
    <listing></listing>
  </location>
  <quantity>2</quantity>
</serial_number_request>}
        daily_deal_purchase.publisher.
          expects(:third_party_deals_api_post).once.
          with { |*args| args.first == "https://test.url/generate_serials" && args.second == serial_number_request_xml}.
          returns(OpenStruct.new(:body => @serial_number_response_xml))
        braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
        daily_deal_purchase.handle_braintree_sale! braintree_transaction
      end

      context "a purchase captured, which uses third party serial numbers" do

        context "a successful serial number request" do

          setup do
            @serial_number_response_xml = %Q{\
<?xml version="1.0" encoding="UTF-8"?>
<serial_numbers listing="SERIAL-TEST" purchase_id="000033fd332c47cab7c050068a16efdd" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
  <serial_number>1817-9817</serial_number>
  <serial_number>1113-9934</serial_number>
</serial_numbers>}

            @daily_deal = Factory :daily_deal, :listing => "SERIAL-TEST", :uuid => "000033fd332c47cab7c050068a16efdd"
            @consumer = Factory :consumer, :first_name => "Doug", :last_name => "Jones", :publisher => @daily_deal.publisher
            @daily_deal_purchase = Factory :daily_deal_purchase, :gift => true, :consumer => @consumer, :quantity => 2, :recipient_names => ["Steve Smith", "John Doe"], :daily_deal => @daily_deal
            Factory :third_party_deals_api_config,
                    :publisher => @daily_deal_purchase.publisher,
                    :voucher_serial_numbers_url => "https://test.url/generate_serials"
            @serial_number_request_xml = %Q{\
<?xml version="1.0" encoding="UTF-8"?>
<serial_number_request listing="SERIAL-TEST" purchase_id="#{@daily_deal_purchase.uuid}" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
  <purchaser_name>Doug Jones</purchaser_name>
  <recipient_names>
    <recipient_name>Steve Smith</recipient_name><recipient_name>John Doe</recipient_name>
  </recipient_names>
  <location>
    <listing></listing>
  </location>
  <quantity>2</quantity>
</serial_number_request>}
            @braintree_transaction = braintree_sale_transaction(@daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
            FakeWeb.register_uri(:post, "https://test-api-username:test-api-password@test.url:443/generate_serials", :body => @serial_number_response_xml)
          end

          should "create N daily deal certificates for N serial numbers requested" do
            assert @daily_deal_purchase.daily_deal_certificates.blank?
            @daily_deal_purchase.handle_braintree_sale! @braintree_transaction
            assert_equal 2, @daily_deal_purchase.daily_deal_certificates.length
          end

          should "store each third party serial number returned with an associated certificate" do
            assert @daily_deal_purchase.daily_deal_certificates.blank?
            @daily_deal_purchase.handle_braintree_sale! @braintree_transaction
            assert_equal ["1113-9934", "1817-9817"], @daily_deal_purchase.daily_deal_certificates.map(&:serial_number).sort
          end
          
          should "log the api request type, request XML, response XML, response status, " +
                 "associated purchase, and the amount of time the request took to get a response" do
            assert ApiActivityLog.all.blank?
            assert_difference "ApiActivityLog.count", 1 do
              @daily_deal_purchase.handle_braintree_sale! @braintree_transaction
            end
            log_entry = ApiActivityLog.first
            assert_equal "third_party_deals", log_entry.api_name
            assert_equal "serial_number_request", log_entry.api_activity_label
            assert_equal @daily_deal_purchase, log_entry.loggable
            assert_equal @serial_number_request_xml, log_entry.request_body
            assert_equal @serial_number_response_xml, log_entry.response_body
            assert_equal "200", log_entry.http_status_code
            assert log_entry.request_initiated_by_us?
            assert log_entry.response_time.present?
            assert log_entry.api_status_code.blank?
            assert log_entry.api_status_message.blank?
          end
          
        end

        context "when a serial number response fails" do
          
          setup do
            @daily_deal = Factory :daily_deal_for_syndication, :listing => "SERIAL-FAIL", :uuid => "000033fd332c47cab7c050068a16efdd"
            @source_publisher = @daily_deal.publisher
            @publisher = Factory :publisher
            @syndicated_deal = syndicate(@daily_deal, @publisher)
            @daily_deal_purchase = Factory :daily_deal_purchase, :quantity => 2, :daily_deal => @syndicated_deal
            Factory :third_party_deals_api_config,
                    :publisher => @source_publisher,
                    :voucher_serial_numbers_url => "https://test.url/generate_serials"

            @serial_number_response_xml = %Q{\
<?xml version="1.0" encoding="UTF-8"?>
<serial_numbers listing="SERIAL-FAIL" purchase_id="000033fd332c47cab7c050068a16efdd" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
<serial_number>1817-9817</serial_number>
</serial_numbers>}
            @braintree_transaction = braintree_sale_transaction(@daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
          end

          context "by returning an invalid number of serial numbers" do
            
            setup do
              FakeWeb.register_uri(:post, "https://test-api-username:test-api-password@test.url:443/generate_serials", :body => @serial_number_response_xml)
            end
            
            should "log the XML request, response, and response status" do
              assert_difference 'ApiActivityLog.count', 1 do
                assert_raises(ThirdPartyDealsApi::XML::InvalidSerialNumberResponse) do
                  @daily_deal_purchase.handle_braintree_sale! @braintree_transaction
                end
              end
              
              log_entry = ApiActivityLog.last
              assert_equal @daily_deal_purchase, log_entry.loggable
              assert_equal "third_party_deals", log_entry.api_name
              assert_equal "serial_number_request", log_entry.api_activity_label
              assert_equal "https://test.url/generate_serials", log_entry.request_url
              assert_equal XML::SerialNumberRequest.new(@daily_deal_purchase).create_serial_number_request_xml, log_entry.request_body
              assert_equal @serial_number_response_xml, log_entry.response_body
              assert_equal "200", log_entry.http_status_code
              assert_match /wrong number of serial numbers returned by api call/i, log_entry.internal_status_message
              assert log_entry.api_status_code.blank?
              assert log_entry.api_status_message.blank?
              assert log_entry.response_time.present?
              assert log_entry.request_initiated_by_us?
            end
            
            should "not create any daily deal certificates" do
              assert_no_difference '::DailyDealCertificate.count' do
                assert_raises(ThirdPartyDealsApi::XML::InvalidSerialNumberResponse) do
                  @daily_deal_purchase.handle_braintree_sale! @braintree_transaction
                end
              end
            end
            
          end
          
          context "by returning an invalid number of serial numbers and error code 2 (SOLD OUT)" do
            
            setup do
              @serial_number_response_xml = %Q{\
<?xml version="1.0" encoding="UTF-8"?>
<serial_numbers listing="123456" purchase_id="000033fd332c47cab7c050068a16efdd" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
  <serial_number>1817-9817</serial_number>
  <errors>
    <error code="2">SOLD OUT</error>
  </errors>
</serial_numbers>}
              FakeWeb.register_uri(:post, "https://test-api-username:test-api-password@test.url:443/generate_serials", :body => @serial_number_response_xml)
            end
            
            should "not create any vouchers" do
              assert_no_difference '::DailyDealCertificate.count' do
                assert_raises(ThirdPartyDealsApi::XML::InvalidSerialNumberResponse) do
                  @daily_deal_purchase.handle_braintree_sale! @braintree_transaction
                end
              end
            end
            
            should "set the deal's status to sold out" do
              assert !@syndicated_deal.sold_out?
              assert_raises(ThirdPartyDealsApi::XML::InvalidSerialNumberResponse) do
                @daily_deal_purchase.handle_braintree_sale! @braintree_transaction
              end
              @syndicated_deal.reload
              assert @syndicated_deal.sold_out?
            end
            
          end
          
          context "by returning a valid number of serial numbers and error code 2 (SOLD OUT)" do
            
            setup do
              @serial_number_response_xml = %Q{\
<?xml version="1.0" encoding="UTF-8"?>
<serial_numbers listing="123456" purchase_id="000033fd332c47cab7c050068a16efdd" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
  <serial_number>1817-9817</serial_number>
  <serial_number>9181-9176</serial_number>
  <errors>
    <error code="2">SOLD OUT</error>
  </errors>
</serial_numbers>}
              FakeWeb.register_uri(:post, "https://test-api-username:test-api-password@test.url:443/generate_serials", :body => @serial_number_response_xml)
            end

            should "create the vouchers" do
              assert_difference '::DailyDealCertificate.count', 2 do
                @daily_deal_purchase.handle_braintree_sale! @braintree_transaction
              end              
            end
            
            should "set the deal's status to sold out" do
              assert !@syndicated_deal.sold_out?
              @daily_deal_purchase.handle_braintree_sale! @braintree_transaction
              @syndicated_deal.reload
              assert @syndicated_deal.sold_out?
            end
            
          end
          
          context "by returning no serial numbers and error code 4 (CLOSED)" do
            
            setup do
              @serial_number_response_xml = %Q{\
<?xml version="1.0" encoding="UTF-8"?>
<serial_numbers listing="123456" purchase_id="000033fd332c47cab7c050068a16efdd" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
<errors>
  <error code="4">CLOSED</error>
</errors>
</serial_numbers>}
              FakeWeb.register_uri(:post, "https://test-api-username:test-api-password@test.url:443/generate_serials", :body => @serial_number_response_xml)
            end
            
            should "raise an ThirdPartyDealsApi::DealForceClosed" do
              assert_raises(ThirdPartyDealsApi::DealForceClosed) do
                @daily_deal_purchase.handle_braintree_sale! @braintree_transaction
              end              
            end

            should "NOT create any vouchers" do
              assert_no_difference '::DailyDealCertificate.count' do
                assert_raises(ThirdPartyDealsApi::DealForceClosed) do
                  @daily_deal_purchase.handle_braintree_sale! @braintree_transaction
                end
              end              
            end

            should "set the deal's status to sold out" do
              assert !@syndicated_deal.sold_out?
              assert_raises(ThirdPartyDealsApi::DealForceClosed) do
                @daily_deal_purchase.handle_braintree_sale! @braintree_transaction
              end
              @syndicated_deal.reload
              assert @syndicated_deal.sold_out?
            end
            
          end
          
          context "by returning a response that is not a well-formed, valid " +
                  "<serial_numbers> response (e.g. a 500 server error message)" do
            
            setup do
              FakeWeb.register_uri(:post, "https://test-api-username:test-api-password@test.url:443/generate_serials",
                                   :body => "Whoops, something went totally wrong!",
                                   :status => ["500", "Internal Server Error"])
            end

            should "log the XML request, response, and response status" do
              braintree_transaction = braintree_sale_transaction(@daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)            
              assert_difference 'ApiActivityLog.count', 1 do
                assert_raises(ThirdPartyDealsApi::XML::InvalidSerialNumberResponse) do
                  @daily_deal_purchase.handle_braintree_sale! braintree_transaction
                end
              end
              
              log_entry = ApiActivityLog.last
              assert_equal @daily_deal_purchase, log_entry.loggable
              assert_equal "third_party_deals", log_entry.api_name
              assert_equal "serial_number_request", log_entry.api_activity_label
              assert_equal "https://test.url/generate_serials", log_entry.request_url
              assert_equal XML::SerialNumberRequest.new(@daily_deal_purchase).create_serial_number_request_xml, log_entry.request_body
              assert_equal "Whoops, something went totally wrong!", log_entry.response_body
              assert_equal "500", log_entry.http_status_code
              assert log_entry.api_status_code.blank?
              assert log_entry.api_status_message.blank?
              assert log_entry.response_time.present?
              assert log_entry.request_initiated_by_us?
            end
            
          end

        end

      end

    end

    context "updating certificate statuses" do

      context "internal serial number publisher" do

        setup do
          @deal = Factory :daily_deal_for_syndication
          @syndicated_publisher = Factory(:publisher)
          @syndicated_deal = syndicate(@deal, @syndicated_publisher)
          @purchase = Factory(:daily_deal_purchase, :daily_deal => @syndicated_deal)
        end

        should "not try to update status as if serial numbers were generated by third party" do
          @purchase.expects(:get_third_party_voucher_status_response!).never
          @purchase.sync_voucher_status_with_third_party!
        end

      end

      context "when the serial numbers were generated by a third party" do

        setup do
          @publisher = Factory(:publisher)
          @config = Factory(:third_party_deals_api_config,
                            :voucher_serial_numbers_url => "https://test.url/serial_numbers",
                            :voucher_status_request_url => "https://test.url/voucher_status",
                            :publisher => @publisher)
          @deal = Factory(:daily_deal_for_syndication, :publisher => @publisher, :listing => "1234")
          @syndicated_publisher = Factory :publisher
          @syndicated_deal = syndicate(@deal, @syndicated_publisher)
          test_serials = OpenStruct.new(:serial_numbers => ["TEST-1", "TEST-2", "TEST-3"])
          ::DailyDealPurchase.any_instance.stubs(:get_third_party_serial_numbers_and_possibly_mark_deal_soldout!).returns(test_serials)
          @purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @syndicated_deal, :quantity => 3)
          @purchase.stubs(:has_vouchers_generated_by_third_party?).returns(true)
          @purchase.daily_deal_certificates.each do |cert|
            assert_equal "active", cert.status
            assert cert.serial_number.present?
          end
          assert_equal 3, @purchase.daily_deal_certificates.size
        end

        context "all active response" do

          setup do
            certs = @purchase.daily_deal_certificates
            voucher_status_response_xml = %Q{
<?xml version="1.0" encoding="UTF-8"?>
<voucher_status_response listing="1234" purchase_id="#{@purchase.uuid}" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
  <status serial_number="#{certs[0].serial_number}">ACTIVE</status>
  <status serial_number="#{certs[1].serial_number}">ACTIVE</status>
  <status serial_number="#{certs[2].serial_number}">ACTIVE</status>
</voucher_status_response>}
            FakeWeb.register_uri(:post, "https://test-api-username:test-api-password@test.url:443/voucher_status",
                                 :body => voucher_status_response_xml)
            assert_equal "ACTIVE", @purchase.get_third_party_voucher_status_response!.to_voucher_status_response_hash["statuses"][@purchase.daily_deal_certificates[0].serial_number]
          end

          should "not update status when they don't need to be updated" do
            @purchase.sync_voucher_status_with_third_party!
            assert @purchase.daily_deal_certificates.all? { |c| c.status == "active" }
          end

          context "purchase has redeemed and refunded certificates" do
            setup do
              @purchase.daily_deal_certificates[1].update_attributes(:status => "redeemed")
              @purchase.daily_deal_certificates[2].update_attributes(:status => "refunded")
              @purchase.sync_voucher_status_with_third_party!
            end

            should "ignore status change to move from redeemed to active" do
              assert_equal "redeemed", @purchase.daily_deal_certificates[1].status
            end

            should "ignore status change to move from refunded to active" do
              assert_equal "refunded", @purchase.daily_deal_certificates[2].status
            end

          end

        end

        context "all redeemed response" do

          setup do
            certs = @purchase.daily_deal_certificates
            voucher_status_response_xml = %Q{
<?xml version="1.0" encoding="UTF-8"?>
<voucher_status_response listing="1234" purchase_id="#{@purchase.uuid}" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
  <status serial_number="#{certs[0].serial_number}">REDEEMED</status>
  <status serial_number="#{certs[1].serial_number}">REDEEMED</status>
  <status serial_number="#{certs[2].serial_number}">REDEEMED</status>
</voucher_status_response>}
            FakeWeb.register_uri(:post, "https://test-api-username:test-api-password@test.url:443/voucher_status",
                                 :body => voucher_status_response_xml)
          end

          should "have correct setup" do
            assert_equal "REDEEMED", @purchase.get_third_party_voucher_status_response!.to_voucher_status_response_hash["statuses"][@purchase.daily_deal_certificates[0].serial_number]
          end

          should "redeem all certificates" do
            @purchase.sync_voucher_status_with_third_party!
            assert @purchase.daily_deal_certificates.all? { |c| c.status == "redeemed" }
          end
   
        end

      end
   
    end
    
    context "third party serial numbers void and refunds" do

      setup do
        @admin = Factory :admin
        @captured_purchase = Factory(:captured_daily_deal_purchase, :quantity => 2)
        
        Factory :third_party_deals_api_config, :publisher => @captured_purchase.publisher
        @captured_purchase.daily_deal_certificates.each { |c| c.update_attributes :serial_number_generated_by_third_party => true }
        @captured_purchase.reload
        @captured_purchase.stubs(:has_vouchers_generated_by_third_party?).returns(true)
      end

      should "update third party voucher statuses before full refund or void" do
        expect_braintree_full_refund(@captured_purchase)
        @captured_purchase.expects(:sync_voucher_status_with_third_party!).once
        @captured_purchase.expects(:send_third_party_voucher_change_notification_as_needed!).once
        @captured_purchase.void_or_full_refund!(@admin)
      end

      should "update third party voucher statuses before partial refund" do
        expect_braintree_partial_refund(@captured_purchase, @captured_purchase.daily_deal_certificates.first.actual_purchase_price)
        @captured_purchase.expects(:sync_voucher_status_with_third_party!).once
        @captured_purchase.expects(:send_third_party_voucher_change_notification_as_needed!).once
        @captured_purchase.partial_refund!(@admin, [@captured_purchase.daily_deal_certificates.first.id])
      end
      
      context "#send_third_party_voucher_change_notification_as_needed!" do
        
        should "send a voucher status change request to change all vouchers to REFUNDED on a full refund" do
          certs = @captured_purchase.daily_deal_certificates
          stub_xml_response = %Q{
            <?xml version="1.0" encoding="UTF-8"?>
            <voucher_status_response listing="#{@captured_purchase.daily_deal.listing}" purchase_id="#{@captured_purchase.uuid}" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
              <status serial_number="#{certs[0].serial_number}">REFUNDED</status>
              <status serial_number="#{certs[1].serial_number}">REFUNDED</status>
            </voucher_status_response>
          }
          expect_braintree_full_refund(@captured_purchase)
          @captured_purchase.stubs(:sync_voucher_status_with_third_party!).returns(nil)
          ::Publisher.any_instance.expects(:third_party_deals_api_post).with do |*args|
            change_notification_xml = args.second
            change_notification_xml.scan(/<status serial_number=[^>]+>REFUNDED<\/status>/i).length == 2
          end.returns(OpenStruct.new(:body => stub_xml_response))
          @captured_purchase.void_or_full_refund!(@admin)
        end
        
        should "send a voucher status change request to change only some vouchers to REFUNDED on a partial refund request"  do
          certs = @captured_purchase.daily_deal_certificates
          stub_xml_response = %Q{
            <?xml version="1.0" encoding="UTF-8"?>
            <voucher_status_response listing="#{@captured_purchase.daily_deal.listing}" purchase_id="#{@captured_purchase.uuid}" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
              <status serial_number="#{certs[0].serial_number}">REFUNDED</status>
              <status serial_number="#{certs[1].serial_number}">ACTIVE</status>
            </voucher_status_response>
          }
          expect_braintree_partial_refund(@captured_purchase, @captured_purchase.daily_deal_certificates.first.actual_purchase_price)
          @captured_purchase.stubs(:sync_voucher_status_with_third_party!).returns(nil)
          ::Publisher.any_instance.expects(:third_party_deals_api_post).with do |*args|
            change_notification_xml = args.second
            change_notification_xml.scan(/<status serial_number=[^>]+>REFUNDED<\/status>/i).length == 1 &&
            change_notification_xml.scan(/<status serial_number=[^>]+>ACTIVE<\/status>/i).length == 1
          end.returns(OpenStruct.new(:body => stub_xml_response))
          @captured_purchase.partial_refund!(@admin, [@captured_purchase.daily_deal_certificates.first.id])
        end
        
        should "send a voucher status change request to change all vouchers to REFUNDED on a void " +
               "(because Doubletake doesn't have a VOIDED status), but leave the vouchers as voided" do
          certs = @captured_purchase.daily_deal_certificates
          stub_xml_response = %Q{
            <?xml version="1.0" encoding="UTF-8"?>
            <voucher_status_response listing="#{@captured_purchase.daily_deal.listing}" purchase_id="#{@captured_purchase.uuid}" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
              <status serial_number="#{certs[0].serial_number}">refunded</status>
              <status serial_number="#{certs[1].serial_number}">refunded</status>
            </voucher_status_response>
          }
          expect_braintree_void(@captured_purchase)
          @captured_purchase.stubs(:sync_voucher_status_with_third_party!).returns(nil)
          ::Publisher.any_instance.expects(:third_party_deals_api_post).with do |*args|
            change_notification_xml = args.second
            change_notification_xml.scan(/<status serial_number=[^>]+>refunded<\/status>/i).length == 2
          end.returns(OpenStruct.new(:body => stub_xml_response))
          @captured_purchase.void_or_full_refund!(@admin)
          
          @captured_purchase.reload
          @captured_purchase.daily_deal_certificates.each do |c|
            assert c.voided?
          end
        end
        
        should "successfully process a voucher status response that has the expected voucher statuses" do
          FakeWeb.register_uri(:post, "https://test-api-username:test-api-password@test.url:443/voucher_status_change",
                               :body => %Q{
                               <?xml version="1.0" encoding="UTF-8"?>
                               <voucher_status_response listing="#{@captured_purchase.daily_deal.listing}"
                                purchase_id="#{@captured_purchase.uuid}"
                                xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
                                 <status serial_number="#{@captured_purchase.daily_deal_certificates.first.serial_number}">REFUNDED</serial_number>
                                 <status serial_number="#{@captured_purchase.daily_deal_certificates.second.serial_number}">REFUNDED</serial_number>
                               </voucher_status_request>
                               })

          expect_braintree_full_refund(@captured_purchase)
          @captured_purchase.expects(:sync_voucher_status_with_third_party!).once
          assert_nothing_raised { @captured_purchase.void_or_full_refund!(@admin) }
        end

        should "raise an exception when the voucher status response looks nothing like a voucher status " +
               "response (e.g. 500 Internal Server Error)" do
          FakeWeb.register_uri(:post, "https://test-api-username:test-api-password@test.url:443/voucher_status_change",
                               :body => "Something went completely wrong",
                               :status => [500, "Internal Server Error"])
          expect_braintree_full_refund(@captured_purchase)
          @captured_purchase.expects(:sync_voucher_status_with_third_party!).once
          assert_raises(::ThirdPartyDealsApi::XML::InvalidVoucherStatusResponse) do
            @captured_purchase.void_or_full_refund!(@admin)
          end
        end
        
      end
      
    end


  end

end
