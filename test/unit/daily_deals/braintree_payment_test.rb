require File.dirname(__FILE__) + "/../../test_helper"

class BraintreePaymentTest < ActiveSupport::TestCase

  test "can make a pending payments" do
    Factory :pending_braintree_payment
  end

  test "can create a daily deal payment simplest case with analog_purchase_id in sync" do
    purchase = Factory(:daily_deal_purchase)
    payment = BraintreePayment.new
    payment.daily_deal_purchase = purchase
    payment.save!
    assert_equal "#{payment.daily_deal_purchase.id}-BBP", payment.analog_purchase_id
  end

  test "can create a payment on its own with analog_purchase_id in synch" do
    payment = Factory(:braintree_payment)
    assert_equal "#{payment.daily_deal_purchase.id}-BBP", payment.analog_purchase_id
  end

  test "can create an authorized purchase with a payment attached simple case with analog_purchase_id in sync" do
    purchase = Factory(:authorized_daily_deal_purchase)
    assert_equal "#{purchase.id}-BBP", purchase.daily_deal_payment.analog_purchase_id
  end

  test "exception when saving with unsaved daily_deal_purchase" do
    purchase = Factory.build(:authorized_daily_deal_purchase)
    assert_raise ActiveRecord::RecordInvalid do
      Factory(:braintree_payment, :daily_deal_purchase => purchase)
    end
  end

  test "when you make a voided purchase, the amount on the payment gets set properly" do
    purchase = Factory(:voided_daily_deal_purchase)
    assert_equal 0, purchase.daily_deal_payment.amount, "was #{purchase.daily_deal_payment.amount.to_s}"
  end

  test "make sure a captured purchase has a daily_deal_payment" do
    purchase = Factory(:captured_daily_deal_purchase)
    assert_not_nil purchase.daily_deal_payment
  end

  test "can change analog_id before save" do
    payment = BraintreePayment.new
    payment.analog_purchase_id = "123"
    payment.analog_purchase_id = "456"
  end

  context "new_from_braintree_transaction" do

    setup do
      @purchase = Factory.build(:daily_deal_purchase)
      @purchase.save
      @purchase.recipients.create({
      :name => "Steve Man",
      :address_line_1 => "123 Alberta St",
      :address_line_2 => "Room 4",
      :city => "Portland",
      :state => "OR",
      :zip => "97211"
      })
      @created_at = Time.zone.now
      @braintree_transaction = stub("braintree_transaction")
      @braintree_transaction.stubs(:custom_fields => nil) # there are no custom_fields by default
      @braintree_transaction.stubs(:id => "789")
      @braintree_transaction.stubs(:created_at => @created_at)
      @braintree_transaction.stubs(:amount => 10.45)
      credit_card_details = stub("credit_card_details")
      credit_card_details.stubs(:cardholder_name => "Foo Barinski")
      credit_card_details.stubs(:last_4 => "9089")
      credit_card_details.stubs(:bin => "411111" )
      @braintree_transaction.stubs(:credit_card_details => credit_card_details)
      billing_details = stub("billing_details")
      billing_details.stubs(:first_name => "John")
      billing_details.stubs(:last_name => "Doe")
      billing_details.stubs(:street_address => "3440 SE Sherman St")
      billing_details.stubs(:extended_address => "Apt 100")
      billing_details.stubs(:locality => "Portland")
      billing_details.stubs(:region => "OR")
      billing_details.stubs(:country_code_alpha2 => "US")
      billing_details.stubs(:postal_code => "97214")
      @braintree_transaction.stubs(:billing_details => billing_details)
    end

    should "work with existing fields" do
      @braintree_transaction.stubs(:custom_fields => { :use_shipping_address_as_billing_address => false })
      payment = BraintreePayment.new_from_braintree_transaction(@purchase, @braintree_transaction)
      assert_equal @purchase, payment.daily_deal_purchase
      assert_equal "789", payment.payment_gateway_id
      assert_equal @created_at, payment.payment_at
      assert_equal 10.45, payment.amount
      assert_equal "9089", payment.credit_card_last_4
      assert_equal "97214", payment.payer_postal_code
      assert_equal "John", payment.billing_first_name
      assert_equal "Doe", payment.billing_last_name
      assert_equal "3440 SE Sherman St", payment.billing_address_line_1
      assert_equal "Apt 100", payment.billing_address_line_2
      assert_equal "Portland", payment.billing_city
      assert_equal "OR", payment.billing_state
      assert_equal "US", payment.billing_country_code
      assert_equal "Foo Barinski", payment.name_on_card
      assert_equal "411111", payment.credit_card_bin      
    end

    should "work with existing fields when the braintree transaction does not have any custom_fields" do
      payment = BraintreePayment.new_from_braintree_transaction(@purchase, @braintree_transaction)
      assert_equal @purchase, payment.daily_deal_purchase
      assert_equal "789", payment.payment_gateway_id
      assert_equal @created_at, payment.payment_at
      assert_equal 10.45, payment.amount
      assert_equal "9089", payment.credit_card_last_4
      assert_equal "97214", payment.payer_postal_code
      assert_equal "John", payment.billing_first_name
      assert_equal "Doe", payment.billing_last_name
      assert_equal "3440 SE Sherman St", payment.billing_address_line_1
      assert_equal "Apt 100", payment.billing_address_line_2
      assert_equal "Portland", payment.billing_city
      assert_equal "OR", payment.billing_state
      assert_equal "US", payment.billing_country_code
      assert_equal "Foo Barinski", payment.name_on_card
      assert_equal "411111", payment.credit_card_bin
    end

    should "populate the billing address from shipping address if use shipping address is true" do
      @braintree_transaction.stubs(:custom_fields => { :use_shipping_address_as_billing_address => true })
      payment = BraintreePayment.new_from_braintree_transaction(@purchase, @braintree_transaction)

      recipient = @purchase.recipients.first

      assert_equal recipient.zip , payment.payer_postal_code
      assert_equal recipient.address_line_1, payment.billing_address_line_1
      assert_equal recipient.address_line_2, payment.billing_address_line_2
      assert_equal recipient.city, payment.billing_city
      assert_equal recipient.state, payment.billing_state
      assert_equal recipient.country.code, payment.billing_country_code
    end
  end
end
