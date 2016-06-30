require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDealPurchase::CyberSourceTest

class DailyDealPurchase::CyberSourceTest < ActiveSupport::TestCase
  context "a daily deal purchase" do
    setup do
      FakeWeb.allow_net_connect = false
      daily_deal = Factory(:daily_deal, :value => 25.00, :price => 12.00, :publisher => Factory(:publisher, :label => "test"))
      @daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal, :quantity => 1)
    end
    
    should "have correct cyber_source attributes" do
      assert_equal "sale", @daily_deal_purchase.cyber_source_order_type
      assert_equal "#{@daily_deal_purchase.id}-BBP", @daily_deal_purchase.cyber_source_order_number
      assert_equal "12.00", @daily_deal_purchase.cyber_source_order_amount
      assert_equal "usd", @daily_deal_purchase.cyber_source_order_currency
      assert_equal_arrays [:visa, :master_card, :amex, :discover], @daily_deal_purchase.cyber_source_card_types
    end
    
    should "generate a merchant reference using the order timestamp when given an order" do
      instant = Time.zone.parse("Jan 02, 2012 12:34:56 UTC")
      Timecop.freeze instant do
        order = CyberSource::Order.new
        Timecop.return
        assert_equal "#{@daily_deal_purchase.id}-BBP-20120102123456", @daily_deal_purchase.cyber_source_merchant_reference(order)
      end
    end
    
    should "generate a merchant reference using the current time when not given an order" do
      instant = Time.zone.parse("Jan 02, 2012 12:34:56 UTC")
      Timecop.freeze instant do
        assert_equal "#{@daily_deal_purchase.id}-BBP-20120102123456", @daily_deal_purchase.cyber_source_merchant_reference
      end
    end
    
    context "with two matching CyberSource credentials" do
      setup do
        @instant = "Jan 15, 2012 00:00:00 UTC"
        CyberSource::Credentials.init({
          :label => "test",
          :merchant_id => "test",
          :shared_secret => "secret_1",
          :serial_number => "serial_number_1",
          :soap_username => "test",
          :soap_password => "soap_password_1",
          :stopped_at => @instant
        }, {
          :label => "test",
          :merchant_id => "test",
          :shared_secret => "secret_2",
          :serial_number => "serial_number_2",
          :soap_username => "test",
          :soap_password => "soap_password_2",
          :started_at => @instant
        })
      end
      
      should "select the currently active credentials if there is no payment record" do
        Timecop.freeze Time.parse(@instant) - 1.second do
          credentials = @daily_deal_purchase.cyber_source_credentials
          assert_equal "serial_number_1", credentials.serial_number
        end
        Timecop.freeze Time.parse(@instant) + 1.second do
          credentials = @daily_deal_purchase.cyber_source_credentials
          assert_equal "serial_number_2", credentials.serial_number
        end
      end
      
      context "and a payment record" do
        setup do
          Factory(:cyber_source_payment, :daily_deal_purchase => @daily_deal_purchase, :payment_at => Time.parse(@instant) - 1.second)
          @daily_deal_purchase.payment_status = "captured"
          @daily_deal_purchase.save!
        end
        
        should "select the credentials active at the time of payment" do
          Timecop.freeze Time.parse(@instant) + 1.second do
            credentials = @daily_deal_purchase.cyber_source_credentials
            assert_equal "serial_number_1", credentials.serial_number
          end
        end
      end
    end
  end

  context "a captured CyberSource daily deal purchase" do
    setup do
      init_cyber_source_credentials_for_tests("entertainment")
      publisher = Factory(:publisher, :label => "entertainment")
      daily_deal = Factory(:daily_deal, :publisher => publisher, :value => 25.00, :price => 14.00, :listing => "123456")
      consumer = Factory(:consumer, :publisher => publisher, :email => "john@public.com")
      @request_id = "3308155091680178147615"
      @daily_deal_purchase = Factory(:pending_daily_deal_purchase, :consumer => consumer, :daily_deal => daily_deal, :quantity => 1)
      @daily_deal_payment = Factory(:cyber_source_payment, :daily_deal_purchase => @daily_deal_purchase, :payment_gateway_id => @request_id)
      @daily_deal_purchase.payment_status = "captured"
      @daily_deal_purchase.save!
      @credentials = @daily_deal_purchase.cyber_source_credentials
      @admin = Factory(:admin)
    end
    
    should "invoke gateway void and not credit in cyber_source_void_or_full_refund if the void succeeds" do
      reference = "#{@daily_deal_purchase.analog_purchase_id}-20120102123456"
      CyberSource::Gateway.expects(:void).with(@credentials, @request_id, reference).returns(nil)
      CyberSource::Gateway.expects(:credit).never

      instant = Time.zone.parse("Jan 02, 2012 12:34:56 UTC")
      Timecop.freeze instant do
        @daily_deal_purchase.cyber_source_void_or_full_refund! @admin
      end
      
      assert_equal 0.0, @daily_deal_payment.reload.amount
      assert_equal instant, @daily_deal_purchase.reload.refunded_at
      assert_equal "new_aaron", @daily_deal_purchase.refunded_by
      assert_equal "voided", @daily_deal_purchase.payment_status
    end

    should "invoke gateway credit in cyber_source_void_or_full_refund if the void raises" do
      instant_1 = Time.zone.parse("Jan 02, 2012 12:34:56 UTC")
      instant_2 = instant_1 + 5.seconds

      reference = "#{@daily_deal_purchase.analog_purchase_id}-20120102123456"
      CyberSource::Gateway.expects(:void).with(@credentials, @request_id, reference).raises(CyberSource::Gateway::Error, "void")
      expect_cyber_source_credit(reference, instant_2)
      Timecop.freeze instant_1 do
        @daily_deal_purchase.cyber_source_void_or_full_refund! @admin
      end
      assert_equal 14.0, @daily_deal_purchase.reload.refund_amount
      assert_equal "3308768036750178147616", @daily_deal_purchase.payment_status_updated_by_txn_id
      assert_equal instant_2, @daily_deal_purchase.refunded_at
      assert_equal "new_aaron", @daily_deal_purchase.refunded_by
      assert_equal "refunded", @daily_deal_purchase.payment_status
    end

    should "invoke gateway credit in cyber_source_void_or_full_refund if the void raises - example where voidReply is nil" do
      instant_1 = Time.zone.parse("Jan 02, 2012 12:34:56 UTC")
      instant_2 = instant_1 + 5.seconds
      fake_cs_response = stub(:decision => "REJECT", :reasonCode => 102, :voidReply => nil)

      reference = "#{@daily_deal_purchase.analog_purchase_id}-20120102123456"
      CyberSource::Gateway.expects(:run_transaction).returns(fake_cs_response)
      expect_cyber_source_credit(reference, instant_2)
      Timecop.freeze instant_1 do
        @daily_deal_purchase.cyber_source_void_or_full_refund! @admin
      end
      assert_equal 14.0, @daily_deal_purchase.reload.refund_amount
      assert_equal "3308768036750178147616", @daily_deal_purchase.payment_status_updated_by_txn_id
      assert_equal instant_2, @daily_deal_purchase.refunded_at
      assert_equal "new_aaron", @daily_deal_purchase.refunded_by
      assert_equal "refunded", @daily_deal_purchase.payment_status
    end
   
    should "raise in cyber_source_void_or_full_refund if the void and credit both raise" do
      instant_1 = Time.zone.parse("Jan 02, 2012 12:34:56 UTC")
      instant_2 = instant_1 + 5.seconds

      reference = "#{@daily_deal_purchase.analog_purchase_id}-20120102123456"
      CyberSource::Gateway.expects(:void).with(@credentials, @request_id, reference).raises(CyberSource::Gateway::Error, "void")
      CyberSource::Gateway.expects(:credit).with do |credentials, request_id, amount, currency, merchant_reference, options|
        @credentials == credentials &&
        @request_id == request_id &&
        14.0 == amount &&
        "usd" == currency &&
        reference == merchant_reference &&
        "john@public.com" == options[:billing][:email] &&
        "52278" == options[:merchant_defined][:field_1] &&
        "entertainment" == options[:merchant_defined][:field_2] &&
        "123456" == options[:merchant_defined][:field_3]
      end.raises(CyberSource::Gateway::Error, "credit")

      Timecop.freeze instant_1 do
        assert_raise CyberSource::Gateway::Error do
          @daily_deal_purchase.cyber_source_void_or_full_refund! @admin
        end
      end
    end

    should "refund the requested amount in cyber_source_partial_refund" do
      instant_1 = Time.zone.parse("Jan 02, 2012 12:34:56 UTC")
      instant_2 = instant_1 + 5.seconds

      reference = "#{@daily_deal_purchase.analog_purchase_id}-20120102123456"
      CyberSource::Gateway.expects(:credit).with do |credentials, request_id, amount, currency, merchant_reference, options|
        @credentials == credentials &&
        @request_id == request_id &&
        10.0 == amount &&
        "usd" == currency &&
        reference == merchant_reference &&
        "john@public.com" == options[:billing][:email] &&
        "52278" == options[:merchant_defined][:field_1] &&
        "entertainment" == options[:merchant_defined][:field_2] &&
        "123456" == options[:merchant_defined][:field_3]
      end.returns(stub(
        :request_id => "3308768036750178147616",
        :reconciliation_id => "2723076652",
        :created_at => instant_2
      ))
      Timecop.freeze instant_1 do
        @daily_deal_purchase.cyber_source_partial_refund! @admin, 10.0
      end
      assert_equal 10.0, @daily_deal_purchase.reload.refund_amount
      assert_equal "3308768036750178147616", @daily_deal_purchase.payment_status_updated_by_txn_id
      assert_equal instant_2, @daily_deal_purchase.refunded_at
      assert_equal "new_aaron", @daily_deal_purchase.refunded_by
      assert_equal "refunded", @daily_deal_purchase.payment_status
    end
    
    should "raise in cyber_source_partial_refund if the refund amount is greater than the total price of a captured purchase" do
      assert_raise RuntimeError do
        @daily_deal_purchase.cyber_source_partial_refund! @admin, 15.00
      end
    end

    should "raise in cyber_source_partial_refund if the refund amount is greater than the remaining amount on a refunded purchase" do
      @daily_deal_purchase.refund_amount = 10.00
      @daily_deal_purchase.payment_status = "refunded"
      @daily_deal_purchase.save!
      
      assert_raise RuntimeError do
        @daily_deal_purchase.cyber_source_partial_refund! @admin, 5.00
      end
    end
  end

  context "a captured CyberSource daily deal purchase with two certificates" do
    setup do
      init_cyber_source_credentials_for_tests("entertainment")
      publisher = Factory(:publisher, :label => "entertainment")
      daily_deal = Factory(:daily_deal, :publisher => publisher, :value => 25.00, :price => 14.00, :listing => "123456")
      consumer = Factory(:consumer, :publisher => publisher, :email => "john@public.com")
      @request_id = "3308155091680178147615"
      @daily_deal_purchase = Factory(:pending_daily_deal_purchase, :consumer => consumer, :daily_deal => daily_deal, :quantity => 2)
      @daily_deal_payment = Factory(:cyber_source_payment, :daily_deal_purchase => @daily_deal_purchase, :payment_gateway_id => @request_id)
      @daily_deal_certificates = []
      @daily_deal_certificates << Factory(:daily_deal_certificate, :daily_deal_purchase => @daily_deal_purchase, :actual_purchase_price => 14.00)
      @daily_deal_certificates << Factory(:daily_deal_certificate, :daily_deal_purchase => @daily_deal_purchase, :actual_purchase_price => 14.00)

      @daily_deal_purchase.payment_status = "captured"
      @daily_deal_purchase.save!
      @daily_deal_purchase.reload
      
      @credentials = @daily_deal_purchase.cyber_source_credentials
      @admin = Factory(:admin)
    end
    
    should "refund the requested certificate in partial_refund" do
      instant_1 = Time.zone.parse("Jan 02, 2012 12:34:56 UTC")
      instant_2 = instant_1 + 5.seconds

      reference = "#{@daily_deal_purchase.analog_purchase_id}-20120102123456"
      CyberSource::Gateway.expects(:credit).with do |credentials, request_id, amount, currency, merchant_reference, options|
        @credentials == credentials &&
        @request_id == request_id &&
        14.0 == amount &&
        "usd" == currency &&
        reference == merchant_reference &&
        "john@public.com" == options[:billing][:email] &&
        "52278" == options[:merchant_defined][:field_1] &&
        "entertainment" == options[:merchant_defined][:field_2] &&
        "123456" == options[:merchant_defined][:field_3]
      end.returns(stub(
        :request_id => "3308768036750178147616",
        :reconciliation_id => "2723076652",
        :created_at => instant_2
      ))
      Timecop.freeze instant_1 do
        @daily_deal_purchase.partial_refund! @admin, @daily_deal_certificates[0, 1].map(&:id).map(&:to_s)
      end
      assert_equal 14.0, @daily_deal_purchase.reload.refund_amount
      assert_equal "3308768036750178147616", @daily_deal_purchase.payment_status_updated_by_txn_id
      assert_equal instant_2, @daily_deal_purchase.refunded_at
      assert_equal "new_aaron", @daily_deal_purchase.refunded_by
      assert_equal "refunded", @daily_deal_purchase.payment_status
      
      assert_equal ["refunded", "active"], @daily_deal_certificates.map(&:reload).map(&:status)
    end
  end

  def expect_cyber_source_credit(reference, created_at_instant)
    CyberSource::Gateway.expects(:credit).with do |credentials, request_id, amount, currency, merchant_reference, options|
      @credentials == credentials &&
      @request_id == request_id &&
      14.0 == amount &&
      "usd" == currency &&
      reference == merchant_reference &&
      "john@public.com" == options[:billing][:email] &&
      "52278" == options[:merchant_defined][:field_1] &&
      "entertainment" == options[:merchant_defined][:field_2] &&
      "123456" == options[:merchant_defined][:field_3]
    end.returns(stub(
      :request_id => "3308768036750178147616",
      :reconciliation_id => "2723076652",
      :created_at => created_at_instant
    ))
  end
end
