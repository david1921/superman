require File.dirname(__FILE__) + "/../../test_helper"

class CreditCardsController::HtmlTest < ActionController::TestCase
  tests CreditCardsController

  context "a consumer" do
    setup do
      @consumer = Factory(:consumer)
      login_as @consumer
    end

    context "with one credit card" do
      setup do
        @card = @consumer.credit_cards.create!(
                :token => "abc123",
                :card_type => "Visa",
                :bin => "123456",
                :last_4 => "9876",
                :expiration_date => "05/2014")
      end

      should "render one credit card with options" do
        get :index, :consumer_id => @consumer.to_param, :format => "html"
        assert_response :success

        assert_select ".saved_cards .card_info", :count => 1
        assert_select ".saved_cards .card_type", "Visa"
        assert_select ".saved_cards .card_number", "Visa ending in 9876"
        assert_select ".saved_cards .expiration", "Expires 05/14"
      end

      should "destroy card and update card list when destroy is called" do
        get :index, :consumer_id => @consumer.to_param, :format => "html"
        assert_select "#credit_card_#{@card.id}", :count => 1

        delete :destroy, :consumer_id => @consumer.to_param, :id => @card.to_param, :format => "js"
        puts @response.body
        assert_select "#credit_card_#{@card.id}", :count => 0
      end

      # should "show no card message if card is removed" do

      # end
    end

    context "with two or more cards" do

      should "list all cards" do
        card1 = Factory(:credit_card, :consumer => @consumer, :card_type => "Visa")
        card2 = Factory(:credit_card, :consumer => @consumer, :card_type => "Discover", :token => "xyz123")
        get :index, :consumer_id => @consumer.to_param, :format => "html"

        assert_select "#credit_card_#{card1.id}"
        assert_select "#credit_card_#{card2.id}"
      end
    end
  end

end