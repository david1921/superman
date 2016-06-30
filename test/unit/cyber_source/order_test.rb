require File.dirname(__FILE__) + "/../../test_helper"

# hydra class CyberSource::OrderTest

module CyberSource
  class OrderTest < ActiveSupport::TestCase
    context "when initialized with an attributes hash" do
      setup do
        @attributes = { 
          :billing_first_name => "John",
          :billing_last_name => "Public",
          :billing_address_line_1 => "123 Main Street",
          :billing_address_line_2 => "Apartment X",
          :billing_city => "Solana Beach",
          :billing_state => "CA",
          :billing_postal_code => "92075",
          :billing_country => "us",
          :billing_email => "john.public@example.com"
        }
        @order = CyberSource::Order.new(@attributes)
      end
      
      should "set created_at from the create time" do
        instant = Time.zone.local(2011, 1, 2, 12, 34, 56)
        Timecop.freeze instant do
          order = CyberSource::Order.new(@attributes)
          Timecop.return
          assert_equal instant, order.created_at
        end
      end

      should "set instance attributes present in the initialization hash" do
        @attributes.each_pair do |key, val|
          assert_equal val, @order.send(key), "Attribute #{key}"
        end
      end
      
      should "not have error messages" do
        assert_equal [], @order.error_messages
      end
    end

    context "when initialized with a parameters hash" do
      setup do
        @parameters = {
          "billTo_firstName" => "John",
          "billTo_lastName" => "Public",
          "billTo_street1" => "123 Main Street",
          "billTo_street2" => "Unit Y",
          "billTo_city" => "",
          "billTo_state" => "CA",
          "billTo_postalCode" => "92075",
          "billTo_country" => "us",
          "billTo_email" => "jane.public@example.com",
          "card_cardType" => "01",
          "card_accountNumber" => "411111**********111",
          "card_expirationMonth" => "02",
          "card_expirationYear" => "2010",
          "card_cvNumber" => "123",
          "orderAmount" => "10.00",
          "orderCurrency" => "usd",
          "decision" => "ERROR"
        }
        @order = CyberSource::Order.new(@parameters)
      end
      
      should "set created_at from the create time" do
        instant = Time.zone.local(2011, 1, 2, 12, 34, 56)
        Timecop.freeze instant do
          order = CyberSource::Order.new(@parameters)
          Timecop.return
          assert_equal instant, order.created_at
        end
      end

      should "set instance attributes present in the initialization hash" do
        assert_equal "John", @order.billing_first_name
        assert_equal "Public", @order.billing_last_name
        assert_equal "123 Main Street", @order.billing_address_line_1
        assert_equal "Unit Y", @order.billing_address_line_2
        assert_equal "", @order.billing_city
        assert_equal "CA", @order.billing_state
        assert_equal "92075", @order.billing_postal_code
        assert_equal "us", @order.billing_country
        assert_equal "jane.public@example.com", @order.billing_email
        assert_equal "10.00", @order.amount
        assert_equal "usd", @order.currency
        assert @order.failure?, "Should have failure status"
      end
      
      should "set card-related attributes from the initialization hash" do
        assert_equal "01", @order.card_type
        assert_equal "02", @order.card_expiration_month
        assert_equal "2010", @order.card_expiration_year
        assert_equal "411111**********111", @order.card_number
        assert_equal "123", @order.card_cvv
      end
      
      should "set instance errors from error parameters when the reason code is 101 or 102" do
        %w{ 101 102 }.each do |reason_code|
          @order = CyberSource::Order.new(@parameters.merge!(
            "reasonCode" => reason_code,
            "MissingField0" => "billTo_city",
            "InvalidField0" => "card_expirationYear"
          ))
          assert_equal_arrays ["City was missing", "Expiration Year was invalid"], @order.error_messages
          assert_equal :missing, @order.errors.on(:billing_city)
          assert_equal :invalid, @order.errors.on(:card_expiration_year)
        end
      end
      
      should  "set a specific instance error when the reason code is 104" do
        @order = CyberSource::Order.new(@parameters.merge!(
          "reasonCode" => "104"
        ))
        assert_equal_arrays ["Your deal transaction was processed successfully. In order to prevent a duplicate charge on your credit card, our system has stopped a second transaction from occurring. If you want to purchase an additional deal voucher, please restart the purchase process."], @order.error_messages
      end

      should "set instance errors from the reason code when it is recognized" do
        @order = CyberSource::Order.new(@parameters.merge!(
          "reasonCode" => "203"
        ))
        assert_equal_arrays ["The card was declined by the issuing bank"], @order.error_messages
      end
      
      should "set instance errors to a default value when the reason code is not recognized" do
        @order = CyberSource::Order.new(@parameters.merge!(
          "reasonCode" => "999"
        ))
        assert_equal_arrays ["An unrecognized error occurred"], @order.error_messages
      end
      
      should "clear card attributes in clear_card_attributes" do
        order = CyberSource::Order.new(@parameters)
        order.clear_card_attributes
        
        assert_nil order.card_type
        assert_nil order.card_number
        assert_nil order.card_expiration_month
        assert_nil order.card_expiration_year
        assert_nil order.card_cvv
      end
    end
  end
end
