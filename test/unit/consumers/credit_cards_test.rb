require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Consumers::CreditCardsTest
class Consumers::CreditCardsTest < ActiveSupport::TestCase
  context "consumer" do
    setup do
      @consumer = Factory(:consumer)
      @card_attributes = { :card_type => "Visa", :token => "abc123", :bin => "123456", :last_4 => "4444", :expiration_date => "05/2012" }
      billing_attributes = {
          :first_name => "Jon",
          :last_name => "Smith",
          :street_address => "123 Main St",
          :extended_address => "Apt 100",
          :locality => "Portland",
          :region => "OR",
          :postal_code => "90210",
          :country_code_alpha2 => "US" }
      @credit_card_details = mock.tap { |object| object.stubs(@card_attributes) }
      @billing_details = mock.tap { |object| object.stubs(billing_attributes) }
    end

    should "create a credit card with the correct options hash" do

      @consumer.credit_cards.expects(:create).with(transaction_options(@credit_card_details, @billing_details))
      @consumer.create_or_update_credit_card @credit_card_details, @billing_details
    end

    should "create a credit card when create_or_update_credit_card is called with no cards saved" do
      assert_difference '@consumer.credit_cards.count' do
        credit_card = @consumer.create_or_update_credit_card @credit_card_details, @billing_details
        assert_equal @consumer.credit_cards.last, credit_card
        assert_equal "abc123", credit_card.token
        assert_equal 'Jon', credit_card.billing_first_name
        assert_equal 'OR', credit_card.billing_state
        assert_match /Visa .* 4444/, credit_card.descriptor
        assert_equal Date.new(2012,5,1), credit_card.expiration_date
      end
    end

    should "create a credit card when create_or_update_credit_card is called with a different card saved" do
      @consumer.credit_cards.create! @card_attributes
      
      assert_difference '@consumer.credit_cards.count' do
        new_card_attributes =  mock.tap { |object| object.stubs({ :card_type => "Mastercard", :token => "zyxw4321", :bin => "987654", :last_4 => "5555", :expiration_date => "05/2012" }) }
        credit_card = @consumer.create_or_update_credit_card(new_card_attributes, @billing_details)
        assert_equal @consumer.credit_cards.last, credit_card
        assert_equal "zyxw4321", credit_card.token
        assert_equal 'Jon', credit_card.billing_first_name
        assert_equal 'OR', credit_card.billing_state
        assert_match /Mastercard .* 5555/, credit_card.descriptor
        assert_equal Date.new(2012,5,1), credit_card.expiration_date
      end
    end

    should "update the credit card when create_or_update_credit_card is called with details for a saved card" do
      @consumer.credit_cards.create! @card_attributes
      
      assert_no_difference '@consumer.credit_cards.count' do
        card_attributes =  mock.tap { |object| object.stubs(@card_attributes.merge(:token => 'zyxw4321')) }
        credit_card = @consumer.create_or_update_credit_card(card_attributes, @billing_details)
        assert_equal @consumer.credit_cards.last, credit_card
        assert_equal "zyxw4321", credit_card.token
        assert_equal 'Jon', credit_card.billing_first_name
        assert_equal 'OR', credit_card.billing_state
        assert_match /Visa .* 4444/, credit_card.descriptor
        assert_equal Date.new(2012,5,1), credit_card.expiration_date
      end
    end
  end
  
  private

  def transaction_options(card_details, billing_details)
    {
        :token => card_details.token,
        :card_type => card_details.card_type,
        :bin => card_details.bin,
        :last_4 => card_details.last_4,
        :expiration_date => card_details.expiration_date,
        :billing_first_name => billing_details.first_name,
        :billing_last_name => billing_details.last_name,
        :billing_country_code => billing_details.country_code_alpha2,
        :billing_address_line_1 => billing_details.street_address,
        :billing_address_line_2 => billing_details.extended_address,
        :billing_city => billing_details.locality,
        :billing_state => billing_details.region,
        :billing_postal_code => billing_details.postal_code
    }
  end
end
