require File.dirname(__FILE__) + "/../test_helper"

class OneClickPurchasesControllerTest < ActionController::TestCase

  include ActionView::Helpers::TextHelper
  include OneClickPurchasesHelper

  context "new" do
    setup do
      @daily_deal = Factory(:daily_deal)
    end

    should "render purchase form" do
      get :new, :daily_deal_id => @daily_deal.to_param
      assert_response :success
      assert_new_consumer_fields
      assert_billing_fields
      assert_select '#transaction_custom_fields_use_shipping_address_as_billing_address', false, "This page must contain no shipping addr opts"
      assert_select "button", "Buy Now"
    end

    should "render purchase form that requires a shipping address" do
      @daily_deal = Factory(:daily_deal, :requires_shipping_address => true)
      get :new, :daily_deal_id => @daily_deal.to_param
      assert_response :success
      assert_new_consumer_fields
      assert_billing_fields
      assert_select '#transaction_custom_fields_use_shipping_address_as_billing_address'
      assert_select "button", "Buy Now"
    end

    context "with a daily deal requiring a shipping address" do
      setup do
        @daily_deal.update_attributes(:requires_shipping_address => true)
      end

      context "new consumer" do
        should "render shipping fields" do
          get :new, :daily_deal_id => @daily_deal.to_param
          assert_response :success
          assert_shipping_fields
        end
      end

      context "an existing consumer with a save recipient" do
        setup do
          @consumer   = Factory(:consumer, :publisher => @daily_deal.publisher)
          @recipients = [Factory(:recipient, :addressable => @consumer), Factory(:recipient, :addressable => @consumer)]
          login_as(@consumer)
          get :new, :daily_deal_id => @daily_deal.to_param
        end

        should "render select list with saved recipients" do
          assert_select "select#consumer_recipient" do
            @recipients.each do |recipient|
              assert_select "option[value=#{recipient.id}]", text_for_recipient_select_option(recipient)
            end
          end
        end
      end
    end

    context "with a daily deal not requiring a shipping address" do
      setup do
        @daily_deal.update_attributes(:requires_shipping_address => false)
      end

      should "not render shipping fields" do
        get :new, :daily_deal_id => @daily_deal.to_param
        assert_response :success
        assert_shipping_fields(false)
      end
    end

  end

  context "create" do
    setup do
      @daily_deal = Factory(:daily_deal, :requires_shipping_address => true)
    end

    should "save a new recipient for new consumer" do
      post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_purchase => {
          :quantity => "1",
          :gift => "0",
          :recipients_attributes => {
            "0" => {
              :city => "Beverly Hills",
              :name => "John Smith",
              :zip => "12345",
              :address_line_1 => "123 Main Street",
              :address_line_2 => "#123",
              :state => "CA"
            }
          }
      }, :consumer => {
          :name => "Michael Mouse",
          :email => "mickey@disney.com",
          :password => "minnieme",
          :password_confirmation => "minnieme",
          :agree_to_terms => "1"
      },
      :consumer_store_recipient => 1
      assert_response :success
      assert_select "form[id=transparent_redirect_form]" # This asserts that the braintree redirect form got rendered
      assert_billing_fields
      assert_select "#transaction_custom_fields_use_shipping_address_as_billing_address"

      daily_deal_purchase = assigns(:daily_deal_purchase)
      assert_equal 1, daily_deal_purchase.consumer.recipients.size
      consumer_recipient = daily_deal_purchase.consumer.recipients.first

      assert_equal "Beverly Hills", consumer_recipient.city
      assert_equal "John Smith", consumer_recipient.name
      assert_equal "12345", consumer_recipient.zip
      assert_equal "123 Main Street", consumer_recipient.address_line_1
      assert_equal "#123", consumer_recipient.address_line_2
      assert_equal "CA", consumer_recipient.state
    end

    context "with a logged in user with a saved recipient" do
      setup do
        @consumer = Factory(:consumer, :publisher => @daily_deal.publisher)
        @recipient = Factory(:recipient, :addressable => @consumer)
        login_as @consumer
      end

      should "create a daily deal purchase recipient from consumer recipient" do
        post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_purchase => {
          :quantity => "1",
          :gift => "0"
        },
        :consumer_recipient => @recipient.id

        assert_response :success
        daily_deal_purchase = assigns(:daily_deal_purchase)
        daily_deal_purchase_recipient = daily_deal_purchase.recipients.first
        assert_equal 1, daily_deal_purchase.recipients.size
        assert_equal @recipient.city, daily_deal_purchase_recipient.city
        assert_equal @recipient.name, daily_deal_purchase_recipient.name
        assert_equal @recipient.zip, daily_deal_purchase_recipient.zip
        assert_equal @recipient.address_line_1, daily_deal_purchase_recipient.address_line_1
        assert_equal @recipient.address_line_2, daily_deal_purchase_recipient.address_line_2
        assert_equal @recipient.state, daily_deal_purchase_recipient.state
      end
    end
  end

  private

  def assert_shipping_fields(exists = true)
    assert_select "#daily_deal_purchase_recipients_attributes_0_name", exists
    assert_select "#daily_deal_purchase_recipients_attributes_0_address_line_1", exists
    assert_select "#daily_deal_purchase_recipients_attributes_0_address_line_2", exists
    assert_select "#daily_deal_purchase_recipients_attributes_0_city", exists
    assert_select "#daily_deal_purchase_recipients_attributes_0_state", exists
    assert_select "#daily_deal_purchase_recipients_attributes_0_zip", exists
  end

  def assert_billing_fields
    assert_select "#transaction_billing_street_address"
    assert_select "#transaction_billing_extended_address"
    assert_select "#transaction_billing_locality"
    assert_select "#transaction_billing_region"
    assert_select "#transaction_billing_postal_code"
    assert_select "#transaction_billing_country_code_alpha2"

    assert_select "#transaction_credit_card_cardholder_name"
    assert_select "#transaction_credit_card_number"
    assert_select "#transaction_credit_card_expiration_month"
    assert_select "#transaction_credit_card_expiration_year"
    assert_select "#transaction_billing_postal_code"
    assert_select "#transaction_credit_card_cvv"
  end

  def assert_new_consumer_fields
    assert_select "#consumer_name"
    assert_select "#consumer_email"
    assert_select "#consumer_password"
    assert_select "#consumer_password_confirmation"
    assert_select "#consumer_agree_to_terms"
  end

end
