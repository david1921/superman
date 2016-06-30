require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDealPurchasesController::CreateWithCreditCardTest
        
class DailyDealPurchasesController::CreateWithCreditCardTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include Api::Consumers

  context "with a daily deal and two consumers each having a saved credit card" do
    setup do
      @daily_deal = Factory(:daily_deal)
      @consumer_1 = Factory(:consumer, :publisher => @daily_deal.publisher)
      @credit_card_1 = @consumer_1.credit_cards.create!(:token => "abc123", :card_type => "Visa", :bin => "987654", :last_4 => "1234")
      @consumer_2 = Factory(:consumer, :publisher => @daily_deal.publisher)
      @credit_card_2 = @consumer_2.credit_cards.create!(:token => "987xyz", :card_type => "Visa", :bin => "123456", :last_4 => "9876")
    end
    
    should "be able to apply the consumers own card when creating a purchase via the API" do
      @request.env["API-Version"] = "2.2.0"
      assert_difference "DailyDealPurchase.count" do
        xhr :post, :create, {
          :daily_deal_id => @daily_deal.to_param,
          :consumer => { :session => api_session_for_consumer(@consumer_1) },
          :daily_deal_purchase => { :quantity => "1", :gift => "0" },
          :credit_card => { :token => @credit_card_1.token },
          :format => "json"
        }
      end
      assert_response :success
      assert_equal @credit_card_1.token, assigns(:credit_card_token)
      json = JSON.parse(@response.body)
      assert_match /&transaction%5Bpayment_method_token%5D=#{@credit_card_1.token}&/, json['tr_data']
    end
    
    should "not be able to apply the other consumers card when creating a purchase via the API" do
      @request.env["API-Version"] = "2.2.0"
      assert_difference "DailyDealPurchase.count" do
        xhr :post, :create, {
          :daily_deal_id => @daily_deal.to_param,
          :consumer => { :session => api_session_for_consumer(@consumer_2) },
          :daily_deal_purchase => { :quantity => "1", :gift => "0" },
          :credit_card => { :token => @credit_card_1.token },
          :format => "json"
        }
      end
      assert_response :success
      assert_nil assigns(:credt_card_token)
      assert_no_match /payment_method_token/, @response.body
    end
    
    context "another consumer with no saved cards" do
      setup do
        @other = Factory(:consumer, :publisher => @daily_deal.publisher)
      end

      should "not be able to apply a saved card when creating a purchase via the API" do
        @request.env["API-Version"] = "2.2.0"
        assert_difference "DailyDealPurchase.count" do
          xhr :post, :create, {
            :daily_deal_id => @daily_deal.to_param,
            :consumer => { :session => api_session_for_consumer(@other) },
            :daily_deal_purchase => { :quantity => "1", :gift => "0" },
            :credit_card => { :token => @credit_card_1.token },
            :format => "json"
          }
        end
        assert_response :success
        assert_nil assigns(:credt_card_token)
        assert_no_match /payment_method_token/, @response.body
      end
    end
  end
end
