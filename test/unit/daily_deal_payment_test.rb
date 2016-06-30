require File.dirname(__FILE__) + "/../test_helper"

class DailyDealPaymentTest < ActiveSupport::TestCase

  context "save" do
    setup do
      @payment = Factory.build(:braintree_payment, :billing_first_name => nil, :billing_last_name => nil, :name_on_card => "Fred Smith")
    end

    should "set billing_first_name and billing_last_name from name on card" do
      @payment.save!
      assert_equal "Fred", @payment.billing_first_name
      assert_equal "Smith", @payment.billing_last_name
    end
  end

  context "use shipping address as billing address" do
    setup do
      @daily_deal_purchase = Factory.build(:daily_deal_purchase)
      @daily_deal_purchase.save!
      @daily_deal_purchase.recipients.create({
      :name => "Steve Man",
      :address_line_1 => "123 Alberta St",
      :address_line_2 => "Room 4",
      :city => "Portland",
      :state => "OR",
      :zip => "97211"
      })

      @payment = Factory.build(:braintree_payment, :daily_deal_purchase => @daily_deal_purchase)
    end

    should "return false if there are multiple recipients" do
      @payment.daily_deal_purchase.recipients.create({
      :name => "Sue Man",
      :address_line_1 => "123 Hawthorne St",
      :address_line_2 => "Room 4",
      :city => "Portland",
      :state => "OR",
      :zip => "97211"
       })

      assert !@payment.populate_billing_address_from_shipping_address
    end

    should "populate billing address from purchase's recipient address" do
      @payment.populate_billing_address_from_shipping_address

      recipient = @payment.daily_deal_purchase.recipients.first

      assert_equal recipient.address_line_1, @payment.billing_address_line_1
      assert_equal recipient.address_line_2, @payment.billing_address_line_2
      assert_equal recipient.city, @payment.billing_city 
      assert_equal recipient.state, @payment.billing_state
      assert_equal recipient.country.code, @payment.billing_country_code
      assert_equal recipient.zip, @payment.payer_postal_code
    end
  end

  context "populate_billing_first_and_billing_last_from_name_on_card" do

    setup do
      @payment = Factory.build(:braintree_payment)
    end

    should "do nothing if billing_first_name and billing_last_name are already set" do
      @payment.billing_first_name = "Joseph"
      @payment.billing_last_name = "Blow"
      @payment.name_on_card = "Fred Smith"
      @payment.populate_billing_first_and_billing_last_from_name_on_card
      assert_equal "Joseph", @payment.billing_first_name
      assert_equal "Blow", @payment.billing_last_name
    end

    should "set billing_first_name and billing_last_name from name_on_card if billing_first_name is blank" do
      @payment.billing_first_name = ""
      @payment.billing_last_name = "Blow"
      @payment.name_on_card = "Fred Smith"
      @payment.populate_billing_first_and_billing_last_from_name_on_card
      assert_equal "Fred", @payment.billing_first_name
      assert_equal "Smith", @payment.billing_last_name
    end

    should "set billing_first_name and billing_last_name from name_on_card if billing_last_name is blank" do
      @payment.billing_first_name = "Jerry"
      @payment.billing_last_name = ""
      @payment.name_on_card = "Fred Smith"
      @payment.populate_billing_first_and_billing_last_from_name_on_card
      assert_equal "Fred", @payment.billing_first_name
      assert_equal "Smith", @payment.billing_last_name
    end

    should "set billing_first_name and billing_last_name from name_on_card if both billing_first_name and billing_last_name are blank" do
      @payment.billing_first_name = ""
      @payment.billing_last_name = ""
      @payment.name_on_card = "Fred Smith"
      @payment.populate_billing_first_and_billing_last_from_name_on_card
      assert_equal "Fred", @payment.billing_first_name
      assert_equal "Smith", @payment.billing_last_name
    end

    context "more difficult name_on_card cases" do

      should "handle nil name_on_card" do
        @payment.billing_first_name = ""
        @payment.billing_last_name = ""
        @payment.name_on_card = nil
        @payment.populate_billing_first_and_billing_last_from_name_on_card
        assert_equal "", @payment.billing_first_name
        assert_equal "", @payment.billing_last_name
      end

      should "handle blank name_on_card" do
        @payment.billing_first_name = ""
        @payment.billing_last_name = ""
        @payment.name_on_card = ""
        @payment.populate_billing_first_and_billing_last_from_name_on_card
        assert_equal "", @payment.billing_first_name
        assert_equal "", @payment.billing_last_name
      end

      should "ignore middle initial" do
        @payment.billing_first_name = ""
        @payment.billing_last_name = ""
        @payment.name_on_card = "Fred W. Smith"
        @payment.populate_billing_first_and_billing_last_from_name_on_card
        assert_equal "Fred", @payment.billing_first_name
        assert_equal "Smith", @payment.billing_last_name
      end

      should "handle arbitrary number of bits in the name" do
        @payment.billing_first_name = ""
        @payment.billing_last_name = ""
        @payment.name_on_card = "Fred Leonard Seymour Jeremiah Smith"
        @payment.populate_billing_first_and_billing_last_from_name_on_card
        assert_equal "Fred", @payment.billing_first_name
        assert_equal "Smith", @payment.billing_last_name
      end

    end

  end

  context "missing_sanctions_data" do

    should "find billing_first_name is null" do
      payment = Factory(:braintree_payment, :billing_first_name => nil, :billing_last_name => "Blow")
      assert DailyDealPayment.missing_sanctions_data.include?(payment)
    end

    should "find billing_first_name is ''" do
      payment = Factory(:braintree_payment, :billing_first_name => '', :billing_last_name => "Blow")
      assert DailyDealPayment.missing_sanctions_data.include?(payment)
    end

    should "find billing_last_name is null" do
      payment = Factory(:braintree_payment, :billing_first_name => 'Fred', :billing_last_name => nil)
      assert DailyDealPayment.missing_sanctions_data.include?(payment)
    end

    should "find billing_last_name is ''" do
      payment = Factory(:braintree_payment, :billing_first_name => 'Fred', :billing_last_name => '')
      assert DailyDealPayment.missing_sanctions_data.include?(payment)
    end

    should "find multiple records" do
      payment1 = Factory(:braintree_payment, :billing_first_name => '', :billing_last_name => '')
      payment2 = Factory(:braintree_payment, :billing_first_name => 'Sam', :billing_last_name => nil)
      payment3 = Factory(:braintree_payment, :billing_first_name => '', :billing_last_name => nil)
      results = DailyDealPayment.missing_sanctions_data
      assert results.include?(payment1)
      assert results.include?(payment2)
      assert results.include?(payment3)
    end

  end

  context "has_name_on_card" do
    should "find record with name on card" do
      payment1 = Factory(:braintree_payment, :name_on_card => "Fritz Heinzworth")
      payment2 = Factory(:braintree_payment, :name_on_card => "")
      payment3 = Factory(:braintree_payment, :name_on_card => nil)
      results = DailyDealPayment.has_name_on_card
      assert results.include?(payment1)
      assert !results.include?(payment2)
      assert !results.include?(payment3)
    end
  end

  context "DailyDealPayments for Travelsavers purchases" do

    should "not be allowed" do
      purchase = Factory :travelsavers_captured_daily_deal_purchase
      assert purchase.daily_deal_payment.blank?
      payment = Factory.build :daily_deal_payment, :daily_deal_purchase => purchase
      assert payment.invalid?
      assert_equal ["cannot create a payment for a Travelsavers purchase: funds from these purchases are not captured by Analog"],
                   payment.errors.full_messages
    end

  end

end
