require File.dirname(__FILE__) + "/../test_helper"

class CreditCardTest < ActiveSupport::TestCase
  context "with credit card details" do
    setup do
      @card_attributes = { :card_type => "Visa", :token => "abc123", :bin => "123456", :last_4 => "4444", :expiration_date => "05/2012" }
    end
    
    should "not be able to create a card without a consumer" do
      credit_card = CreditCard.new(@card_attributes)
      assert credit_card.invalid?, "Card should be invalid without a consumer"
      assert_match /can\'t be blank/, credit_card.errors.on(:consumer)
    end
    
    context "and with a consumer" do
      setup do
        @consumer = Factory(:consumer)
      end
      
      should "be able to create a credit card" do
        credit_card = @consumer.credit_cards.create!(@card_attributes)
        assert credit_card, "Should create a credit card"
        assert_equal "abc123", credit_card.token
        assert credit_card.hexdigest.present?, "Card hexdigest should be present"
        assert_match /Visa .* 4444/, credit_card.descriptor
        assert_equal Date.new(2012,5,1), credit_card.expiration_date
      end
      
      should "not be able to create a card with bin missing" do
        credit_card = @consumer.credit_cards.build(@card_attributes.merge!(:bin => ""))
        assert credit_card.invalid?, "Card should not be valid with invalid last_4"
        assert_match /invalid/, credit_card.errors.on(:bin)
      end
      
      should "not be able to create a card with last_4 containing a non-digit" do
        credit_card = @consumer.credit_cards.build(@card_attributes.merge!(:last_4 => "444x"))
        assert credit_card.invalid?, "Card should not be valid with invalid last_4"
        assert_match /invalid/, credit_card.errors.on(:last_4)
      end
      
      should "not be able to create a card with last_4 too short" do
        credit_card = @consumer.credit_cards.build(@card_attributes.merge!(:last_4 => "444"))
        assert credit_card.invalid?, "Card should not be valid with invalid last_4"
        assert_match /invalid/, credit_card.errors.on(:last_4)
      end
      
      should "not be able to create a card with card_type missing" do
        credit_card = @consumer.credit_cards.build(:card_type => "", :token => "abc123", :bin => "123456", :last_4 => "4444")
        assert credit_card.invalid?, "Card should not be valid with missing card_type"
        assert_match /can\'t be blank/, credit_card.errors.on(:card_type)
      end
      
      context "having a saved credit card" do
        setup do
          @saved_card = @consumer.credit_cards.create!(@card_attributes)
        end
        
        should "be able to find the card by bin and last_4" do
          credit_card = CreditCard.find_by_consumer_id_and_bin_and_last_4(@consumer.id, "123456", "4444")
          assert_equal @saved_card, credit_card
        end
      end
    end
  end
end
