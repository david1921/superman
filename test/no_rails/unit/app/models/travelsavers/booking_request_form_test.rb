require File.dirname(__FILE__) + "/../../models_helper"

class Travelsavers::BookingRequestFormTest < Test::Unit::TestCase
  def setup
    @daily_deal_purchase = mock('daily deal')
    @redirect_url = mock('redirect url')
    @booking_request_form = Travelsavers::BookingRequestForm.new(@daily_deal_purchase, @redirect_url)
  end

  context "self.key" do
    should "return the contents of the key file" do
      assert_equal File.read(Travelsavers::BookingRequestForm::KEY_FILENAME), Travelsavers::BookingRequestForm.key, "Key did not match expected value"
    end

    should "cache the key to a class variable" do
      key = File.read(Travelsavers::BookingRequestForm::KEY_FILENAME)
      Travelsavers::BookingRequestForm.send(:class_variable_set, :@@key, nil)
      File.expects(:read).once.returns(key)
      2.times{ Travelsavers::BookingRequestForm.key }
      assert Travelsavers::BookingRequestForm.class_variable_defined?(:@@key)
      assert_equal Travelsavers::BookingRequestForm.key, Travelsavers::BookingRequestForm.send(:class_variable_get, :@@key)
    end
  end

  context "#transaction_data" do
    setup do
      @data = {:secure => "parameters"}
      @booking_request_form.stubs(:secure_parameters).returns(@data)
    end

    should "return a hash of the secure parameters for the specified pending purchase" do
      signature = Travelsavers::BookingRequest.hmac_signature(Travelsavers::BookingRequestForm.key, @data.to_query)
      expected_transaction_data = [signature, @data.to_query].join('|')
      assert_equal expected_transaction_data, @booking_request_form.transaction_data, "Unexpected transaction data"
    end
  end

  context "#secure_parameters" do
    setup do
      @booking_request_form.stubs(:ts_product_id).returns("CXP-0")
      @booking_request_form.stubs(:purchase_price).returns(1000.00)
      @redirect_url.stubs(:to_s).returns("http://analoganalytics.com/travelsavers_booking_response")
    end

    should "return a hash of the travelsavers product id, redirect url, purchase price and purchase UUID" do
      @booking_request_form.instance_variable_set(:@daily_deal_purchase, mock('purchase', :uuid => "12345"))
      expected = {
          :ts_product_id => "CXP-0",
          :redirect_url => @redirect_url,
          :purchase_price => "1000.0",
          :aa_purchase_id => "12345"
      }
      assert_equal expected, @booking_request_form.send(:secure_parameters)
    end
  end

  context "#ts_product_id" do
    should "return the purchase's travelsavers_product_code" do
      @daily_deal_purchase.expects(:travelsavers_product_code).returns("PRODUCT_CODE")
      assert_equal "PRODUCT_CODE", @booking_request_form.send(:ts_product_id)
    end
  end
end
