require File.join(File.dirname(__FILE__), "../test_helper")
require 'base64'

class OptimalPaymentsTest < ActiveSupport::TestCase

  context ".ensure_valid_callback_message!" do
    should "raise an exception when the callback message is invalid" do
      assert_raise OptimalPayments::InvalidCallbackMessage do
        OptimalPayments.ensure_valid_callback_message! :encoded_message => Base64.encode64("foobar"),
                                                       :signature => "somefakesig"
      end
    end

    should "not raise an exception when the callback message is valid" do
      assert_nothing_raised do
        OptimalPayments.ensure_valid_callback_message! :encoded_message => "PHByb2ZpbGVDaGVja291dFJlc3BvbnNlIHhtbG5zPSJ3d3cub3B0aW1hbHBheW1lbnRzLmNvbS9j\naGVja291dCI+CiAgPGNvbmZpcm1hdGlvbk51bWJlcj4xMjgzOTkzMjM8L2NvbmZpcm1hdGlvbk51\nbWJlcj4KICA8bWVyY2hhbnRSZWZOdW0+NjU5YjMxYTctOGRjYi00NWYwLWIxMDgtZDA5MTk3NWVh\nNzQwPC9tZXJjaGFudFJlZk51bT4KICA8Y3VzdG9tZXJFbWFpbD5ncmFlbWVAZ3JhZW1lbmVsc29u\ncGR4LmNvbTwvY3VzdG9tZXJFbWFpbD4KICA8YWNjb3VudE51bT44OTk5NzAxNTwvYWNjb3VudE51\nbT4KICA8Y2FyZFR5cGU+TUM8L2NhcmRUeXBlPgogIDxkZWNpc2lvbj5BQ0NFUFRFRDwvZGVjaXNp\nb24+CiAgPGNvZGU+MDwvY29kZT4KICA8ZGVzY3JpcHRpb24+Tm8gRXJyb3I8L2Rlc2NyaXB0aW9u\nPgogIDx0eG5UaW1lPjIwMTEtMDItMjhUMTM6NDM6NDcuNjg0LTA1OjAwPC90eG5UaW1lPgogIDxw\nYXltZW50TWV0aG9kPkNDPC9wYXltZW50TWV0aG9kPgogIDxsYXN0Rm91ckRpZ2l0cz4wMDUwPC9s\nYXN0Rm91ckRpZ2l0cz4KICA8cGF5bWVudE1ldGhvZENvbmZpcm1hdGlvbk51bWJlcj4xMjgzOTkz\nMjM8L3BheW1lbnRNZXRob2RDb25maXJtYXRpb25OdW1iZXI+CjwvcHJvZmlsZUNoZWNrb3V0UmVz\ncG9uc2U+",
                                                       :signature => "fG0MYfvebjoPbiCMwTRfyuKfBGQ="
      end
    end
  end

  context "Checkout API" do

    context "OptimalPayments::ProfileCheckoutResponse#process!" do

      context "on a successful purchase" do

        setup do
          ActionMailer::Base.deliveries = []

          daily_deal = Factory :daily_deal, :price => 5, :value => 15, :min_quantity => 1
          @daily_deal_purchase = Factory :pending_daily_deal_purchase, :daily_deal => daily_deal, :uuid => "1f139847-dadf-460c-a12e-d4d5698a2f1e"
          @successful_checkout = OptimalPayments::ProfileCheckoutResponse.new :encoded_message => "PHByb2ZpbGVDaGVja291dFJlc3BvbnNlIHhtbG5zPSJ3d3cub3B0aW1hbHBheW1lbnRzLmNvbS9j\naGVja291dCI+CiAgPGNvbmZpcm1hdGlvbk51bWJlcj4xMjg0MDU4MTI8L2NvbmZpcm1hdGlvbk51\nbWJlcj4KICA8bWVyY2hhbnRSZWZOdW0+MWYxMzk4NDctZGFkZi00NjBjLWExMmUtZDRkNTY5OGEy\nZjFlPC9tZXJjaGFudFJlZk51bT4KICA8Y3VzdG9tZXJFbWFpbD5icmFkYkAzMHNsZWVwcy5jb208\nL2N1c3RvbWVyRW1haWw+CiAgPGFjY291bnROdW0+ODk5OTcwMTU8L2FjY291bnROdW0+CiAgPGNh\ncmRUeXBlPlZJPC9jYXJkVHlwZT4KICA8ZGVjaXNpb24+QUNDRVBURUQ8L2RlY2lzaW9uPgogIDxj\nb2RlPjA8L2NvZGU+CiAgPGRlc2NyaXB0aW9uPk5vIEVycm9yPC9kZXNjcmlwdGlvbj4KICA8dHhu\nVGltZT4yMDExLTAzLTAyVDE3OjMxOjIxLjkxMS0wNTowMDwvdHhuVGltZT4KICA8cGF5bWVudE1l\ndGhvZD5DQzwvcGF5bWVudE1ldGhvZD4KICA8bGFzdEZvdXJEaWdpdHM+MDAwMjwvbGFzdEZvdXJE\naWdpdHM+CiAgPHBheW1lbnRNZXRob2RDb25maXJtYXRpb25OdW1iZXI+MTI4NDA1ODEyPC9wYXlt\nZW50TWV0aG9kQ29uZmlybWF0aW9uTnVtYmVyPgo8L3Byb2ZpbGVDaGVja291dFJlc3BvbnNlPg==",
                                                                              :signature => "VPpfSLrE8FU8F74U85ZyhdesYlY="
        end

        should "update the related DailyDealPurchase to be 'captured'" do
          assert !@daily_deal_purchase.captured?
          @successful_checkout.process!
          @daily_deal_purchase.reload
          assert @daily_deal_purchase.captured?
        end

        should "update the DailyDealPurchase#executed_at to the current time" do
          assert_nil @daily_deal_purchase.executed_at
          @successful_checkout.process!
          @daily_deal_purchase.reload
          assert @daily_deal_purchase.executed_at.is_a? ActiveSupport::TimeWithZone
          assert_equal Time.parse("2011-03-02 17:31:21 -0500"), @daily_deal_purchase.executed_at
        end

        should "create a corresponding DailyDealPayment for the DailyDealPurchase, if one doesn't already exist" do
          assert_nil @daily_deal_purchase.daily_deal_payment
          @successful_checkout.process!
          @daily_deal_purchase.reload
          assert @daily_deal_purchase.daily_deal_payment.present?
          assert @daily_deal_purchase.daily_deal_payment.is_a?(OptimalPayment)
        end

        should "*not* try to create the DailyDealPayment for the DailyDealPurchase, if the DailyDealPayment already exists" do
          optimal_payment = Factory :optimal_payment, :daily_deal_purchase => @daily_deal_purchase
          assert @daily_deal_purchase.daily_deal_payment.present?
          prev_num_of_payments = OptimalPayment.count
          @successful_checkout.process!
          assert_equal prev_num_of_payments, OptimalPayment.count
        end

        should "set the DailyDealPayment#payment_at to the txnTime in the response" do
          assert_nil @daily_deal_purchase.daily_deal_payment
          @successful_checkout.process!
          @daily_deal_purchase.reload
          assert @daily_deal_purchase.daily_deal_payment.payment_at.is_a?(ActiveSupport::TimeWithZone)
        end

        should "set the DailyDealPayment#credit_card_last_4 to the last four digits in the response" do
          assert_nil @daily_deal_purchase.daily_deal_payment
          @successful_checkout.process!
          @daily_deal_purchase.reload
          assert_equal "0002", @daily_deal_purchase.daily_deal_payment.credit_card_last_4
        end

        should "set the DailyDealPayment#payment_gateway_receipt_id to the confirmationNumber in the response" do
          assert_nil @daily_deal_purchase.daily_deal_payment
          @successful_checkout.process!
          @daily_deal_purchase.reload
          assert_equal "128405812", @daily_deal_purchase.daily_deal_payment.payment_gateway_receipt_id
        end

        should "set the DailyDealPayment#amount to the actual purchase price of the deal" do
          assert_nil @daily_deal_purchase.daily_deal_payment
          @successful_checkout.process!
          @daily_deal_purchase.reload
          assert_equal 5, @daily_deal_purchase.daily_deal_payment.amount
        end

        should "create the vouchers for the purchase" do
          assert !@daily_deal_purchase.daily_deal_certificates.present?
          @successful_checkout.process!
          @daily_deal_purchase.reload
          assert @daily_deal_purchase.daily_deal_certificates.present?
          assert_equal 1, @daily_deal_purchase.daily_deal_certificates.size
        end

        should "email the vouchers to the consumer" do
          assert ActionMailer::Base.deliveries.blank?
          @successful_checkout.process!
          @daily_deal_purchase.reload
          assert ActionMailer::Base.deliveries.present?
          assert_equal 1, ActionMailer::Base.deliveries.size
        end

      end

      context "on a failed purchase" do

        setup do
          ActionMailer::Base.deliveries = []

          @daily_deal_purchase = Factory :pending_daily_deal_purchase, :uuid => "081f3358-34e8-4050-b644-1f6689617c6f"
          @failed_checkout = OptimalPayments::ProfileCheckoutResponse.new :encoded_message => "PHByb2ZpbGVDaGVja291dFJlc3BvbnNlIHhtbG5zPSJ3d3cub3B0aW1hbHBheW1lbnRzLmNvbS9j\naGVja291dCI+CiAgPGNvbmZpcm1hdGlvbk51bWJlcj4xMjg0MDgwMzk8L2NvbmZpcm1hdGlvbk51\nbWJlcj4KICA8bWVyY2hhbnRSZWZOdW0+MDgxZjMzNTgtMzRlOC00MDUwLWI2NDQtMWY2Njg5NjE3\nYzZmPC9tZXJjaGFudFJlZk51bT4KICA8Y3VzdG9tZXJFbWFpbD5icmFkYkAzMHNsZWVwcy5jb208\nL2N1c3RvbWVyRW1haWw+CiAgPGFjY291bnROdW0+ODk5OTcwMTU8L2FjY291bnROdW0+CiAgPGNh\ncmRUeXBlPlZJPC9jYXJkVHlwZT4KICA8ZGVjaXNpb24+REVDTElORUQ8L2RlY2lzaW9uPgogIDxj\nb2RlPjMwMTU8L2NvZGU+CiAgPGFjdGlvbkNvZGU+RDwvYWN0aW9uQ29kZT4KICA8ZGVzY3JpcHRp\nb24+VGhlIGJhbmsgaGFzIHJlcXVlc3RlZCB0aGF0IHlvdSBwcm9jZXNzIHRoZSB0cmFuc2FjdGlv\nbiBtYW51YWxseSBieSBjYWxsaW5nIHRoZSBjYXJkaG9sZGVyJ3MgY3JlZGl0IGNhcmQgY29tcGFu\neS48L2Rlc2NyaXB0aW9uPgogIDx0eG5UaW1lPjIwMTEtMDMtMDNUMTc6MjA6NDYuMDkzLTA1OjAw\nPC90eG5UaW1lPgogIDxwYXltZW50TWV0aG9kPkNDPC9wYXltZW50TWV0aG9kPgogIDxsYXN0Rm91\nckRpZ2l0cz4wODIxPC9sYXN0Rm91ckRpZ2l0cz4KICA8cGF5bWVudE1ldGhvZENvbmZpcm1hdGlv\nbk51bWJlcj4xMjg0MDgwMzk8L3BheW1lbnRNZXRob2RDb25maXJtYXRpb25OdW1iZXI+CjwvcHJv\nZmlsZUNoZWNrb3V0UmVzcG9uc2U+",
                                                                          :signature => "dmtXhv6hvq9XErS3fee0gfvnuxA="
        end

        should "*not* create a corresponding DailyDealPayment for the DailyDealPurchase" do
          assert_nil @daily_deal_purchase.daily_deal_payment
          @failed_checkout.process!
          @daily_deal_purchase.reload
          assert @daily_deal_purchase.daily_deal_payment.blank?
        end

        should "*not* create the vouchers for the purchase" do
          assert !@daily_deal_purchase.daily_deal_certificates.present?
          @failed_checkout.process!
          @daily_deal_purchase.reload
          assert @daily_deal_purchase.daily_deal_certificates.blank?
        end

        should "email the vouchers to the consumer" do
          assert ActionMailer::Base.deliveries.blank?
          @failed_checkout.process!
          @daily_deal_purchase.reload
          assert ActionMailer::Base.deliveries.blank?
        end

      end

    end

    context "ProfileCheckoutRequest" do

      context 'self.encoded_message_and_signature' do

        setup do
          @valid_attributes = {
            :merchant_ref_num => "hell0",
            :return_url => "http://localhost/return/here",
            :cancel_url => "http://localhost/cancel/here",
            :payment_method => "CC",
            :currency_code => "USD",
            :shopping_cart => [
              {
                :description => "item description",
                :amount      => "12.00",
                :quantity    => "1"
              }
            ],
            :total_amount => "12.00",
            :customer_profile => {
              :merchant_customer_id => "123",
              :is_new_customer => false
            },
            :locale => {
              :language => "en",
              :country  => "US"
            }
          }
        end

        context "with valid attributes" do
          setup do
            @xml = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><profileCheckoutRequest xmlns=\"www.optimalpayments.com/checkout\"><merchantRefNum>hell0</merchantRefNum><returnUrl page=\"http://localhost/return/here\"/><cancelUrl page=\"http://localhost/cancel/here\"/><paymentMethod>CC</paymentMethod><currencyCode>USD</currencyCode><shoppingCart><description>item description</description><quantity>1</quantity><amount>12.00</amount></shoppingCart><totalAmount>12.00</totalAmount><customerProfile><merchantCustomerId>123</merchantCustomerId><isNewCustomer>false</isNewCustomer></customerProfile><locale><language>en</language><country>US</country></locale></profileCheckoutRequest>"
            @expected_encoded_message = Base64.encode64(@xml)
            @expected_signature       = OptimalPayments.hmac_sha1_signature( @xml, OptimalPayments::Configuration.private_key )
            @encoded_message, @signature = OptimalPayments::ProfileCheckoutRequest.encoded_message_and_signature( @valid_attributes )
          end

          should "set the encoded message" do
            assert_equal @expected_encoded_message, @encoded_message
          end

          should "set the signature" do
            assert_equal @expected_signature, @signature
          end
        end

        context "with invalid attributes" do

          context "with missing shop_id" do
            setup do
              OptimalPayments::Configuration.expects(:shop_id).returns(nil)
            end
            should "raise ArgumentError" do
              assert_raise ArgumentError do
                OptimalPayments::ProfileCheckoutRequest.encoded_message_and_signature( @valid_attributes )
              end
            end
          end

          context "with missing private_key" do
            setup do
              OptimalPayments::Configuration.expects(:private_key).returns(nil)
            end
            should "raise ArgumentError" do
              assert_raise ArgumentError do
                OptimalPayments::ProfileCheckoutRequest.encoded_message_and_signature( @valid_attributes )
              end
            end
          end

          context "with missing merchant_ref_num" do
            should "raise ArgumentError" do
              assert_raise ArgumentError do
                OptimalPayments::ProfileCheckoutRequest.encoded_message_and_signature( @valid_attributes.merge(:merchant_ref_num => "") )
              end
            end
          end

          context "with missing return_url" do
            should "raise ArgumentError" do
              assert_raise ArgumentError do
                OptimalPayments::ProfileCheckoutRequest.encoded_message_and_signature( @valid_attributes.merge(:return_url => "") )
              end
            end
          end

          context "with missing cancel_url" do
            should "raise ArgumentError" do
              assert_raise ArgumentError do
                OptimalPayments::ProfileCheckoutRequest.encoded_message_and_signature( @valid_attributes.merge(:cancel_url => "") )
              end
            end
          end

          context "with missing currency_code" do
            should "raise ArgumentError" do
              assert_raise ArgumentError do
                OptimalPayments::ProfileCheckoutRequest.encoded_message_and_signature( @valid_attributes.merge(:currency_code => "") )
              end
            end
          end

          context "with missing total_amount" do
            should "raise ArgumentError" do
              assert_raise ArgumentError do
                OptimalPayments::ProfileCheckoutRequest.encoded_message_and_signature( @valid_attributes.merge(:total_amount => "") )
              end
            end
          end
        end
      end
    end
  end


  context "WebService API" do
    
    setup do
      @successful_xml = <<-SAMPLE
<ccTxnResponseV1 xmlns="http://wwww.payments.com/creditcard/xmlschema/v1">
<confirmationNumber>110351743</confirmationNumber>
<decision>ACCEPTED</decision>
<code>0</code>
<description>No Error</description>
<detail>
<tag>InternalResponseCode</tag>
<value>0</value>
</detail>
<detail>
<tag>SubErrorCode</tag>
<value>0</value>
</detail>
<detail>
<tag>InternalResponseDescription</tag>
<value>no_error</value>
</detail>
<txnTime>2006-05-15T14:24:01.464-04:00</txnTime>
<duplicateFound>false</duplicateFound>
</ccTxnResponseV1>
SAMPLE
      @error_xml = <<-SAMPLE
<ccTxnResponseV1 xmlns="http://wwww.payments.com/creditcard/xmlschema/v1">
<confirmationNumber>-1</confirmationNumber>
<decision>ERROR</decision>
<code>1000</code>
<actionCode>R</actionCode>
<description>Invalid txnMode: ccccAuthorize</description>
<detail>
<tag>InternalResponseCode</tag>
<value>14</value>
</detail>
<detail>
<tag>SubErrorCode</tag>
<value>0</value>
</detail>
<detail>
<tag>InternalResponseDescription</tag>
<value>invalid operation mode</value>
</detail>
<txnTime>2006-05-15T14:24:01.464-04:00</txnTime>
<duplicateFound>false</duplicateFound>
</ccTxnResponseV1>
SAMPLE
    end

    context "responses" do

      context "error response" do

        setup do
          @error_response = OptimalPayments::WebService::Response.new(@error_xml)
        end

        should "not be successful" do
          assert !@error_response.success?
        end

        should "have a response code" do
          assert_equal 1000, @error_response.code
        end

        should "have an action code" do
          assert_equal 'R', @error_response.action_code
        end

        should "should have the correct description" do
          assert_equal "Invalid txnMode: ccccAuthorize", @error_response.description
        end

      end

      context "successful response" do

        setup do
          @successful_response = OptimalPayments::WebService::Response.new(@successful_xml)
        end

        should "be successful" do
          assert @successful_response.success?
        end

        should "have a response code" do
          assert_equal 0, @successful_response.code
        end

        should "have not have an action code" do
          assert_equal nil, @successful_response.action_code
        end

        should "should have the correct description" do
          assert_equal "No Error", @successful_response.description
        end
      end

    end

    context "refund" do
      setup do
        @confirmation_number  = "123123"
        @daily_deal_purchase  = Factory(:daily_deal_purchase)
        @daily_deal_payment   = Factory(:optimal_payment, :daily_deal_purchase => @daily_deal_purchase, :payment_gateway_receipt_id => @confirmation_number)
      end

      context "with missing credentials" do

        context "with missing accountNum" do
          setup do
            OptimalPayments::Configuration.expects(:accountNum).returns(nil)
          end
          should "raise an ArgumentError" do
            assert_raise ArgumentError do
              OptimalPayments::WebService.refund({:confirmation_number => @confirmation_number, :merchant_ref_num => @daily_deal_purchase.uuid})
            end
          end
        end

        context "with missing storeID" do
          setup do
            OptimalPayments::Configuration.expects(:storeID).returns(nil)
          end
          should "raise an ArgumentError" do
            assert_raise ArgumentError do
              OptimalPayments::WebService.refund({:confirmation_number => @confirmation_number, :merchant_ref_num => @daily_deal_purchase.uuid})
            end
          end
        end

        context "with missing storePwd" do
          setup do
            OptimalPayments::Configuration.expects(:storePwd).returns(nil)
          end
          should "raise an ArgumentError" do
            assert_raise ArgumentError do
              OptimalPayments::WebService.refund( {:confirmation_number => @confirmation_number, :merchant_ref_num => @daily_deal_purchase.uuid} )
            end
          end
        end
      end

        context "with missing confirmationNumber" do
          should "should raise ArgumentError" do
            assert_raise ArgumentError do
              OptimalPayments::WebService.refund( {} )
            end
          end
        end

        context "with a successful request" do
          should "result in a successful RefundResponse when making" do
            request = OptimalPayments::WebService::RefundRequest.new({})
            assert @successful_xml.present?
            request.stubs(:post_request_and_return_xml_body).returns(@successful_xml)
            assert_equal request.send(:post_request_and_return_xml_body), @successful_xml
            response = request.perform
            assert response.success?
            assert_equal 0, response.code
            assert_equal [], response.errors
          end
        end

        context "with an unsuccessful request" do
          should "result in an unsuccesful RefundResponse" do
            request = OptimalPayments::WebService::RefundRequest.new({})
            request.stubs(:post_request_and_return_xml_body).returns(@error_xml)
            response = request.perform
            assert !response.success?
          end
        end

    end

    context "void" do

      context "voidable" do
        setup do
          @now = Time.utc(2011, 3, 10, 12, 30).in_time_zone('Eastern Time (US & Canada)')
        end
        should "NOT be voidable if it the payment happened just before window" do
          Timecop.freeze @now do
            just_before_window = @now.beginning_of_day - 1.minute
            assert !OptimalPayments::WebService.voidable?(:payment_at => just_before_window)
          end
        end
        should "NOT be voidable if it the payment happened just after window" do
          Timecop.freeze @now do
            just_after_window = @now.end_of_day + 1.minute
            assert !OptimalPayments::WebService.voidable?(:payment_at => just_after_window)
          end
        end
        should "be voidable if it the payment happened just at start of window" do
          Timecop.freeze @now do
            at_start_of_window = @now.beginning_of_day
            assert OptimalPayments::WebService.voidable?(:payment_at => at_start_of_window)
          end
        end
        should "be voidable if it the payment happened just at end of window" do
          Timecop.freeze @now do
            at_end_of_window = @now.end_of_day
            assert OptimalPayments::WebService.voidable?(:payment_at => at_end_of_window)
          end
        end
      end
    end

    context "with a successful request" do
      should "result in a successful VoidResponse" do
        request = OptimalPayments::WebService::VoidRequest.new({})
        request.stubs(:post_request_and_return_xml_body).returns(@successful_xml)
        response = request.perform
        assert response.success?
        assert_equal 0, response.code
      end
    end

  end
end