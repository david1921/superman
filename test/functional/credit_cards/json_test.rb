require File.dirname(__FILE__) + "/../../test_helper"

class CreditCardsController::JsonTest < ActionController::TestCase
  tests CreditCardsController
  include Api::Consumers
  
  context "a consumer with two credit cards" do
    setup do
      @consumer = Factory(:consumer)
      @credit_cards = [].tap do |list|
        list << @consumer.credit_cards.create!(:token => "abc123", :card_type => "Visa", :bin => "123456", :last_4 => "9876")
        list << @consumer.credit_cards.create!(:token => "987xyz", :card_type => "Visa", :bin => "987654", :last_4 => "1234")
      end
    end

    should "not be able to list cards without an API-Version header" do
      get :index, :consumer_id => @consumer.to_param, :session => api_session_for_consumer(@consumer), :format => "json"
      assert_response :not_acceptable
      assert_match /API-Version/, @response.body
    end

    should "not be able to list cards without a session parameter" do
      @request.env["API-Version"] = "2.2.0"
      get :index, :consumer_id => @consumer.to_param, :format => "json"
      assert_response :forbidden
      assert @response.body.blank?, "Should not have response body content"
    end

    should "not be able to list cards with a session belonging to another consumer" do
      other = Factory(:consumer)
      @request.env["API-Version"] = "2.2.0"
      get :index, :consumer_id => @consumer.to_param, :session => api_session_for_consumer(other), :format => "json"
      assert_response :not_found
      assert @response.body.blank?, "Should not have response body content"
    end
    
    should "be able to list existing credit cards with valid session parameter" do
      @request.env["API-Version"] = "2.2.0"
      get :index, :consumer_id => @consumer.to_param, :session => api_session_for_consumer(@consumer), :format => "json"
      assert_response :success
      
      json = JSON.parse(@response.body).sort_by { |credit_card| credit_card["token"] }
      assert_equal 2, json.size, "Should list two credit cards"
      
      credit_card = json[0]
      assert_equal "987xyz", credit_card["token"]
      assert_equal "Visa ending in 1234", credit_card["descriptor"]
      assert_equal "https://test.host/consumers/#{@consumer.id}/credit_cards/#{@credit_cards[1].id}.json", credit_card["methods"]["destroy"]

      credit_card = json[1]
      assert_equal "abc123", credit_card["token"]
      assert_equal "Visa ending in 9876", credit_card["descriptor"]
      assert_equal "https://test.host/consumers/#{@consumer.id}/credit_cards/#{@credit_cards[0].id}.json", credit_card["methods"]["destroy"]
    end
  end
  
  test "create with missing session parameter" do
    consumer = Factory(:consumer)
    assert_no_difference 'consumer.credit_cards.count' do
      @request.env["API-Version"] = "2.2.0"
      get :create, :consumer_id => consumer.to_param, :format => "json"
    end
    assert_response :forbidden
    assert_equal 0, @response.body.strip.size
  end
  
  test "create with a session belonging to another consumer" do
    consumer1 = Factory(:consumer)
    consumer2 = Factory(:consumer)
    assert_no_difference 'consumer1.credit_cards.count' do
      @request.env["API-Version"] = "2.2.0"
      get :create, :consumer_id => consumer1.to_param, :session => api_session_for_consumer(consumer2), :format => "json"
    end
    assert_response :not_found
    assert_equal 0, @response.body.strip.size
  end
  
  test "create with valid session parameter and consumer not in vault" do
    consumer = Factory(:consumer, :in_vault => false)
    assert_no_difference 'consumer.credit_cards.count' do
      @request.env["API-Version"] = "2.2.0"
      get :create, :consumer_id => consumer.to_param, :session => api_session_for_consumer(consumer), :format => "json"
    end
    assert_response :success
    json = JSON.parse(@response.body)
    assert json.keys.include?("is_new_customer"), "Should have an is_new_customer attribute"
    assert json["is_new_customer"], "Should be flagged as a new customer"
    assert json.keys.include?("payment_gateway")
    assert json.keys.include?("tr_data")
    assert_match %r{&customer%5Bid%5D=#{consumer.id_for_vault}&}, json["tr_data"]
    assert_match %r{#{CGI.escape(braintree_customer_redirect_consumer_credit_cards_path(consumer))}}, json["tr_data"]
  end
  
  test "create with valid session parameter and consumer already in vault" do
    consumer = Factory(:consumer, :in_vault => true)
    assert_no_difference 'consumer.credit_cards.count' do
      @request.env["API-Version"] = "2.2.0"
      get :create, :consumer_id => consumer.to_param, :session => api_session_for_consumer(consumer), :format => "json"
    end
    assert_response :success
    json = JSON.parse(@response.body)
    assert json.keys.include?("is_new_customer"), "Should have an is_new_customer attribute"
    assert !json["is_new_customer"], "Should not be flagged as a new customer"
    assert json.keys.include?("payment_gateway")
    assert json.keys.include?("tr_data")
    assert_match %r{&credit_card%5Bcustomer_id%5D=#{consumer.id_for_vault}&}, json["tr_data"]
    assert_match %r{#{CGI.escape(braintree_credit_card_redirect_consumer_credit_cards_path(consumer))}}, json["tr_data"]
  end
  
  test "braintree_customer_redirect with success result" do
    consumer = Factory(:consumer)
    card_data = { :token => "abc123", :bin => "123456", :last_4 => "9876", :card_type => "American Express" }
    Braintree::TransparentRedirect.expects(:confirm).returns(braintree_customer_created_result(consumer, card_data))

    assert_difference 'consumer.credit_cards.count' do
      @request.env["API-Version"] = "2.2.0"
      get :braintree_customer_redirect, :consumer_id => consumer.to_param, :format => "json"
    end
    assert_response :success
    card = consumer.credit_cards.last
    
    json = JSON.parse(@response.body)
    assert_equal "abc123", json["token"]
    assert_equal "American Express ending in 9876", json["descriptor"]
    assert_equal "https://test.host/consumers/#{consumer.id}/credit_cards/#{card.id}.json", json["methods"]["destroy"]

    assert consumer.reload.in_vault?, "Consumer record should be marked for vault"
    card_data.except(:bin).each do |key, val|
      assert_equal val, card.send(key), "card attribute #{key}"
    end
  end
  
  test "braintree_customer_redirect with success result but incorrect braintree customer ID" do
    consumer_1 = Factory(:consumer)
    card_data = { :token => "abc123", :bin => "123456", :last_4 => "9876", :card_type => "American Express" }
    Braintree::TransparentRedirect.expects(:confirm).returns(braintree_customer_created_result(consumer_1, card_data))

    consumer_2 = Factory(:consumer)

    assert_no_difference 'consumer_2.credit_cards.count' do
      @request.env["API-Version"] = "2.2.0"
      get :braintree_customer_redirect, :consumer_id => consumer_2.to_param, :format => "json"
    end
    assert_response :forbidden
    assert @response.body.blank?, "Should not return data"
    assert_equal 0, consumer_1.credit_cards.count
  end
      
  test "braintree_credit_card_redirect with success result" do
    consumer = Factory(:consumer)
    card_data = { :token => "abc123", :bin => "123456", :last_4 => "9876", :card_type => "American Express" }
    Braintree::TransparentRedirect.expects(:confirm).returns(braintree_credit_card_created_result(consumer, card_data))

    assert_difference 'consumer.credit_cards.count' do
      @request.env["API-Version"] = "2.2.0"
      get :braintree_credit_card_redirect, :consumer_id => consumer.to_param, :format => "json"
    end
    assert_response :success
    card = consumer.credit_cards.last
    
    json = JSON.parse(@response.body)
    assert_equal "abc123", json["token"]
    assert_equal "American Express ending in 9876", json["descriptor"]
    assert_equal "https://test.host/consumers/#{consumer.id}/credit_cards/#{card.id}.json", json["methods"]["destroy"]

    assert consumer.reload.in_vault?, "Consumer record should be marked for vault"

    card_data.except(:bin).each do |key, val|
      assert_equal val, card.send(key), "card attribute #{key}"
    end
  end
  
  test "braintree_credit_card_redirect with success result but incorrect braintree customer ID" do
    consumer_1 = Factory(:consumer)
    card_data = { :token => "abc123", :bin => "123456", :last_4 => "9876", :card_type => "American Express" }
    Braintree::TransparentRedirect.expects(:confirm).returns(braintree_credit_card_created_result(consumer_1, card_data))

    consumer_2 = Factory(:consumer)

    assert_no_difference 'consumer_2.credit_cards.count' do
      @request.env["API-Version"] = "2.2.0"
      get :braintree_credit_card_redirect, :consumer_id => consumer_2.to_param, :format => "json"
    end
    assert_response :forbidden
    assert @response.body.blank?, "Should not return data"
    assert_equal 0, consumer_1.credit_cards.count
  end
  
  test "braintree_credit_card_redirect with validation errors result" do
    consumer = Factory(:consumer)
    card_data = { :token => "abc123", :bin => "123456", :last_4 => "9876", :card_type => "American Express" }
    result = braintree_validation_errors_result([{ :code => 81715, :message => "Credit card number is invalid" }])
    Braintree::TransparentRedirect.expects(:confirm).returns(result)

    assert_no_difference 'consumer.credit_cards.count' do
      @request.env["API-Version"] = "2.2.0"
      get :braintree_credit_card_redirect, :consumer_id => consumer.to_param, :format => "json"
    end
    assert_response :conflict

    json = JSON.parse(@response.body)
    assert_match /card number is invalid/i, json["errors"].first
  end

  test "braintree_credit_card_redirect with processor declined result" do
    consumer = Factory(:consumer)
    card_data = { :token => "abc123", :bin => "123456", :last_4 => "9876", :card_type => "American Express" }
    Braintree::TransparentRedirect.expects(:confirm).returns(braintree_credit_card_processor_declined_result)

    assert_no_difference 'consumer.credit_cards.count' do
      @request.env["API-Version"] = "2.2.0"
      get :braintree_credit_card_redirect, :consumer_id => consumer.to_param, :format => "json"
    end
    assert_response :conflict

    json = JSON.parse(@response.body)
    assert_match /processor declined/i, json["errors"].first
  end

  test "braintree_credit_card_redirect with gateway rejected result" do
    consumer = Factory(:consumer)
    card_data = { :token => "abc123", :bin => "123456", :last_4 => "9876", :card_type => "American Express" }
    Braintree::TransparentRedirect.expects(:confirm).returns(braintree_credit_card_gateway_rejected_result)

    assert_no_difference 'consumer.credit_cards.count' do
      @request.env["API-Version"] = "2.2.0"
      get :braintree_credit_card_redirect, :consumer_id => consumer.to_param, :format => "json"
    end
    assert_response :conflict

    json = JSON.parse(@response.body)
    assert_match /processor declined/i, json["errors"].first
  end
  
  test "destroy with missing session parameter" do
    consumer = Factory(:consumer)
    card = consumer.credit_cards.create!(:token => "abc123", :bin => "123456", :last_4 => "9876", :card_type => "American Express")
    
    assert_no_difference 'consumer.credit_cards.count' do
      @request.env["API-Version"] = "2.2.0"
      delete :destroy, :consumer_id => consumer.to_param, :id => card.to_param, :format => "json"
    end
    assert_response :forbidden
    assert @response.body.blank?, "Should not have response data"
  end
  
  test "destroy with a session belonging to another consumer" do
    consumer1 = Factory(:consumer)
    card = consumer1.credit_cards.create!(:token => "abc123", :bin => "123456", :last_4 => "9876", :card_type => "American Express")
    consumer2 = Factory(:consumer)
    
    assert_no_difference 'consumer1.credit_cards.count' do
      @request.env["API-Version"] = "2.2.0"
      delete :destroy, :consumer_id => consumer1.to_param, :id => card.to_param, :session => api_session_for_consumer(consumer2), :format => "json"
    end
    assert_response :not_found
    assert @response.body.blank?, "Should not have response data"
  end

  test "destroy with valid card and session parameter" do
    consumer = Factory(:consumer)
    card = consumer.credit_cards.create!(:token => "abc123", :bin => "123456", :last_4 => "9876", :card_type => "American Express")
    Braintree::CreditCard.expects(:delete).with("abc123").returns(true)
    
    assert_difference 'consumer.credit_cards.count', -1 do
      @request.env["API-Version"] = "2.2.0"
      delete :destroy, :consumer_id => consumer.to_param, :id => card.to_param, :session => api_session_for_consumer(consumer), :format => "json"
    end
    assert_response :success
    assert @response.body.blank?, "Should not have response data"
  end
end
