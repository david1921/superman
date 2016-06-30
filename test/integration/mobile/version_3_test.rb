require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Mobile::Version3Test
module Mobile
  class Version3Test < ActionController::IntegrationTest
    
    def setup
      @consumer  = Factory(:consumer, :password => "password", :password_confirmation => "password", :activated_at => 2.minutes.ago)      
      @publisher = @consumer.publisher
      @headers   = {"API-Version" => "3.0.0"}
    end
    
    test "mobile app requests publisher details, and logs consumer in with valid credentials" do
      get "/publishers/#{@publisher.label}.json", {}, @headers      
      assert_nil session.to_hash[:user_id]
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      login_url = json["methods"]["login"]
      post login_url, {"session" => {"email" => @consumer.email, "password" => "password"}}, @headers
      assert_response :success
      assert_equal @consumer.id, session.to_hash[:user_id]
      json = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil json["session"]
    end
    
    test "mobile app request publisher details, and locked consumer tries to login with valid credentials" do
      get "/publishers/#{@publisher.label}.json", {}, @headers      
      assert_nil session.to_hash[:user_id]
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      login_url = json["methods"]["login"]
      
      @consumer.lock_access!
      
      post login_url, {"session" => {"email" => @consumer.email, "password" => "password"}}, @headers
      assert_response :conflict
      
      response = ActiveSupport::JSON.decode(@response.body)
      assert_equal [I18n.translate(:user_account_locked)], response["errors"]                  
    end
    
    test "mobile app request publisher details, 5 failed login attempts should lock consumer account" do
      get "/publishers/#{@publisher.label}.json", {}, @headers      
      assert_nil session.to_hash[:user_id]
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      login_url = json["methods"]["login"]
      
      assert !@consumer.reload.access_locked?
      
      4.times do |n|
        post login_url, {"session" => {"email" => @consumer.email, "password" => "blah"}}, @headers
        assert !@consumer.reload.access_locked?, "account should not be locked on #{n.ordinalize} failed attempt"
      end
      
      post login_url, {"session" => {"email" => @consumer.email, "password" => "blah"}}, @headers
      assert @consumer.reload.access_locked?, "account should locked after fifth failed attempt"      
                  
    end
    
    test "mobile app requests publisher details, and directs consumer to the login page where they enter invalid credentials" do
      get "/publishers/#{@publisher.label}.json", {}, @headers
      json = ActiveSupport::JSON.decode(@response.body)
      login_url = json["methods"]["login"]
      post login_url, {"session" => {"email" => @consumer.email, "password" => ""}}, @headers
      assert_response :conflict
    end
  
    
    test "mobile app requests a session logout without a session parameter" do
      post "/publishers/#{@publisher.id}/daily_deal/logout.json", {}, @headers
      assert_response :forbidden
    end
    
    test "mobile app logs consumer in, then logs themselve out again" do
      post "/publishers/#{@publisher.id}/daily_deal_sessions.json", {"session" => {"email" => @consumer.email, "password" => "password"}}, @headers
      assert_response :success
      assert_equal @consumer.id, session.to_hash[:user_id]      
      json = ActiveSupport::JSON.decode(@response.body)
      consumer_session = json["session"]
      assert_not_nil consumer_session, "we should have a consumer session passed back to us in the response"
            
      post "/publishers/#{@publisher.id}/daily_deal/logout.json", {"consumer" => {"session" => consumer_session}}, @headers
      assert_response :success
      assert_nil session.to_hash[:user_id], "should not longer have a user id in the session"
      json = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil json
      assert_equal @publisher.label, json["label"]
    end
    
    test "mobile api, consumer loads publisher details and views active daily deal without being logged in" do
      daily_deal = Factory(:daily_deal, :publisher => @publisher)
      get "/publishers/#{@publisher.label}.json", {}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      active_daily_deals_url = json["connections"]["active_daily_deals"]
      
      get active_daily_deals_url, {}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body).first
      details_url = json["connections"]["details"]

      get details_url, {}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      purchase_url = json["methods"]["purchase"]
      assert_not_nil purchase_url
    end
    
    test "mobile api, consumer wants to signup via facebook connect" do
      facebook_token = "myfacebooktoken"
      
      get "/publishers/#{@publisher.label}.json", {}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      facebook_connect_url = json["methods"]["facebook_connect"]

      access_token = mock("access_token")
      access_token.expects(:get).at_least_once.with("/me").returns({
        "token" => facebook_token,
        "id" => "myfacebookid",
        "email" => @consumer.email
      }.to_json)
      DailyDealSessionsController.any_instance.expects(:access_token_from_publisher_and_facebook_token).with(@publisher, facebook_token).returns(access_token)      
      Consumer.expects(:find_or_create_by_fb).returns(@consumer)
      post facebook_connect_url, {"consumer" => {"facebook_token" => facebook_token}}, @headers
      json = ActiveSupport::JSON.decode(@response.body)
      assert_response :success
      assert_equal @consumer.name, json["name"]      
      assert_equal @consumer.id, session.to_hash[:user_id]
    end
    
    test "mobile api, consumer signsup via email address and password" do
      get "/publishers/#{@publisher.label}.json", {}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      signup_url = json["methods"]["signup"]
      
      post signup_url, 
          {"consumer" => {
            "name" => "Jack John", 
            "email" => "jack@somewhere.com", 
            "password" => "password", 
            "agree_to_terms" => "1", 
            "zip_code" => "97206"}}, @headers
            
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      assert_equal "Jack John", json["name"]
    end
    
    test "mobile api, authenticated consumer should be able to view their deals" do
      daily_deal = Factory(:daily_deal, :publisher => @publisher)
      daily_deal_purchase = Factory(:authorized_daily_deal_purchase, :daily_deal => daily_deal, :consumer => @consumer)
      post "/publishers/#{@publisher.id}/daily_deal_sessions.json", {"session" => {"email" => @consumer.email, "password" => "password"}}, @headers
      assert_response :success
      assert_equal @consumer.id, session.to_hash[:user_id]      
      json = ActiveSupport::JSON.decode(@response.body)
      consumer_session = json["session"]
      assert_not_nil consumer_session
      
      my_deals_url = json["connections"]["purchases"]
      get my_deals_url, {"consumer" => {"session" => consumer_session}}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      assert_equal 1, json.size, "should have on daily deal"
    end
    
    test "mobile api, authenticated consumer who some how becomes locked tries to view their deals should be forbidden" do
      daily_deal = Factory(:daily_deal, :publisher => @publisher)
      daily_deal_purchase = Factory(:authorized_daily_deal_purchase, :daily_deal => daily_deal, :consumer => @consumer)
      post "/publishers/#{@publisher.id}/daily_deal_sessions.json", {"session" => {"email" => @consumer.email, "password" => "password"}}, @headers
      assert_response :success
      assert_equal @consumer.id, session.to_hash[:user_id]      
      json = ActiveSupport::JSON.decode(@response.body)
      consumer_session = json["session"]
      assert_not_nil consumer_session
      
      @consumer.lock_access!
      
      my_deals_url = json["connections"]["purchases"]
      get my_deals_url, {"consumer" => {"session" => consumer_session}}, @headers
      assert_response :forbidden
    end
    
    test "mobile api, a consumer who has forgotten their password should be able to reset and login with that new password" do
      get "/publishers/#{@publisher.label}.json", {}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      reset_password_url  = json["methods"]["reset_password"]
      login_url           = json["methods"]["login"]
      post reset_password_url, {"email" => @consumer.email}, @headers
      assert_response :success
      
      json = ActiveSupport::JSON.decode(@response.body)
      update_password_url = json["methods"]["update_password"]
      put update_password_url, {"consumer" => {"password" => "mynewpassword", "reset_code" => @consumer.reload.perishable_token}}, @headers
      assert_response :success
      
      assert_nil session.to_hash[:user_id], "should not log consumer in"

      post login_url, {"session" => {"email" => @consumer.email, "password" => "mynewpassword"}}, @headers
      assert_response :success
      assert_equal @consumer.id, session.to_hash[:user_id]
    end
    
    test "mobile api, a consumer wants to signup for push notifications" do
      get "/publishers/#{@publisher.label}.json", {}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      register_push_notification_url = json["methods"]["register_push_notification_device"]
      post register_push_notification_url, {"device" => {"token" => "12312312312312312"}}, @headers
      assert_response :success
      assert_not_nil @publisher.push_notification_devices.find_by_token("12312312312312312"), "should add the device to the push notifications" 
    end
    
    test "mobile api, a consumer wants to remove push notifications" do
      post "https://test.host/publishers/#{@publisher.id}/push_notification_devices.json", {"device" => {"token" => "123123111111"}}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)      
      destroy_push_notification_url = json["methods"]["destroy"]
      delete destroy_push_notification_url, {}, @headers
      assert_response :success            
      assert_nil @publisher.push_notification_devices.find_by_token("123123111111"), "should not have the push notification device anymore"  
    end
    
    test "mobile api, a consumer wants to save a credit card" do
      assert @consumer.credit_cards.empty?
      post "/publishers/#{@publisher.id}/daily_deal_sessions.json", {"session" => {"email" => @consumer.email, "password" => "password"}}, @headers
      assert_response :success
      assert_equal @consumer.id, session.to_hash[:user_id]      
      json = ActiveSupport::JSON.decode(@response.body)
      save_credit_card_url  = json["methods"]["save_credit_card"]
      session               = json["session"]
      post save_credit_card_url, {"consumer" => {"session" => session}}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil json["payment_gateway"]
      assert_not_nil json["tr_data"]

      # NOTE: we pretend we make a request to the payment gateway.
      card_data = { :token => "abc123", :bin => "123456", :last_4 => "9876", :card_type => "American Express" }
      Braintree::TransparentRedirect.expects(:confirm).returns(braintree_credit_card_created_result(@consumer, card_data))
      
      get "/consumers/#{@consumer.id}/credit_cards/braintree_credit_card_redirect.json", {}, @headers
      assert_response :success
      assert_equal 1, @consumer.reload.credit_cards.size
    end
    
    test "mobile api, a consumer wants to delete a credit card they just saved" do
      card_data = { :token => "abc123", :bin => "123456", :last_4 => "9876", :card_type => "American Express" }
      Braintree::TransparentRedirect.expects(:confirm).returns(braintree_credit_card_created_result(@consumer, card_data))      
      get "/consumers/#{@consumer.id}/credit_cards/braintree_credit_card_redirect.json", {}, @headers
      assert_response :success
      assert_equal 1, @consumer.reload.credit_cards.size
      json = ActiveSupport::JSON.decode(@response.body)
      
      # make sure we are logged in, before trying to delete card
      post "/publishers/#{@publisher.id}/daily_deal_sessions.json", {"session" => {"email" => @consumer.email, "password" => "password"}}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      consumer_session = json["session"]
      assert_not_nil consumer_session
      
      credit_cards_url = json["connections"]["credit_cards"]
      get credit_cards_url, {"consumer" => {"session" => consumer_session}}, @headers
      json = ActiveSupport::JSON.decode(@response.body)
      
      
      Braintree::CreditCard.expects(:delete)
      destroy_credit_card_url = json.first["methods"]["destroy"]
      delete destroy_credit_card_url, {"consumer" => {"session" => consumer_session}}, @headers
      assert_response :success
      assert @consumer.reload.credit_cards.empty?
    end
    
    test "mobile api, consumer should be able to view their saved credit cards" do
      credit_card = Factory(:credit_card, :consumer => @consumer)
      assert_equal 1, @consumer.reload.credit_cards.size
      post "/publishers/#{@publisher.id}/daily_deal_sessions.json", {"session" => {"email" => @consumer.email, "password" => "password"}}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      consumer_session = json["session"]
      assert_not_nil consumer_session
      credit_cards_url = json["connections"]["credit_cards"]
      get credit_cards_url, {"consumer" => {"session" => consumer_session}}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      assert_equal "Visa ending in #{credit_card.last_4}", json.first["descriptor"]
    end
    
    test "mobile api, request active daily deals with active session and wants to purchase deal" do
      setup_braintree_credentials    
      
      daily_deal = Factory(:daily_deal, :publisher => @publisher)
      
      post "/publishers/#{@publisher.id}/daily_deal_sessions.json", {"session" => {"email" => @consumer.email, "password" => "password"}}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      consumer_session = json["session"]
      assert_not_nil consumer_session

      get "/daily_deals/#{daily_deal.id}/details.json", {}, @headers
      json = ActiveSupport::JSON.decode(@response.body)
      purchase_url = json["methods"]["purchase"]
      
      post purchase_url, {:consumer => {:session => consumer_session}, :daily_deal_purchase => {:quantity => "1", :gift => "0"} }, @headers
      assert_response :success
      daily_deal_purchase     = assigns(:daily_deal_purchase)
      json                    = ActiveSupport::JSON.decode(@response.body)
      braintree_redirect_url  = URI.decode(json['tr_data'].split("&").collect{ |params| params if params.start_with?("redirect_url")}.compact.first.split("=").last)
      test = braintree_transaction_submitted_result(daily_deal_purchase)
      Braintree::TransparentRedirect.expects(:confirm).returns(braintree_transaction_submitted_result(daily_deal_purchase))    
      get braintree_redirect_url, {}, @headers
      assert_response :success            
      json = ActiveSupport::JSON.decode(@response.body)
      purchases_url = json["consumer"]["connections"]["purchases"]
      get purchases_url, {"consumer" => {"session" => consumer_session}}, @headers
      assert_response :success

      json = ActiveSupport::JSON.decode(@response.body)
      assert_equal 1, json.size
      assert_equal "captured", json.first["status"]
      
      details_url = json.first["connections"]["details"]
      get details_url, {"consumer" => {"session" => consumer_session}}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      assert_equal 1, json["vouchers"].size
      assert_not_nil json["vouchers"].first["bar_code"]
    end
    
    test "mobile api, request active daily deals with active session and wants to purchase deal with a variation" do
      setup_braintree_credentials    
      
      @publisher.update_attribute(:enable_daily_deal_variations, true)
      daily_deal = Factory(:daily_deal, :publisher => @publisher)
      daily_deal_variation = Factory(:daily_deal_variation, :daily_deal => daily_deal)
      
      assert daily_deal.reload.has_variations?
      
      post "/publishers/#{@publisher.id}/daily_deal_sessions.json", {"session" => {"email" => @consumer.email, "password" => "password"}}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      consumer_session = json["session"]
      assert_not_nil consumer_session

      get "/daily_deals/#{daily_deal.id}/details.json", {}, @headers
      json = ActiveSupport::JSON.decode(@response.body)
      purchase_url = json["methods"]["purchase"]
      
      post purchase_url, {:consumer => {:session => consumer_session}, :daily_deal_purchase => {:quantity => "1", :gift => "0", :daily_deal_variation_id => daily_deal_variation.id} }, @headers
      assert_response :success
      daily_deal_purchase     = assigns(:daily_deal_purchase)
      json                    = ActiveSupport::JSON.decode(@response.body)
      braintree_redirect_url  = URI.decode(json['tr_data'].split("&").collect{ |params| params if params.start_with?("redirect_url")}.compact.first.split("=").last)
      test = braintree_transaction_submitted_result(daily_deal_purchase)
      Braintree::TransparentRedirect.expects(:confirm).returns(braintree_transaction_submitted_result(daily_deal_purchase))    
      get braintree_redirect_url, {}, @headers
      assert_response :success            
      json = ActiveSupport::JSON.decode(@response.body)
      purchases_url = json["consumer"]["connections"]["purchases"]
      get purchases_url, {"consumer" => {"session" => consumer_session}}, @headers
      assert_response :success

      json = ActiveSupport::JSON.decode(@response.body)
      assert_equal 1, json.size
      assert_equal "captured", json.first["status"]
      
      details_url = json.first["connections"]["details"]
      get details_url, {"consumer" => {"session" => consumer_session}}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      assert_equal 1, json["vouchers"].size
      
      assert_not_nil daily_deal_purchase.reload.daily_deal_variation
    end
    
    test "mobile api, request active daily deals with active session and wants to purchase deal with a discount" do
      setup_braintree_credentials    
      
      discount   = Factory(:discount, :publisher => @publisher)
      daily_deal = Factory(:daily_deal, :publisher => @publisher)
      
      assert_equal 1, @publisher.reload.discounts.usable.size, "should have one discount"
      
      post "/publishers/#{@publisher.id}/daily_deal_sessions.json", {"session" => {"email" => @consumer.email, "password" => "password"}}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      consumer_session = json["session"]
      assert_not_nil consumer_session

      get "/daily_deals/#{daily_deal.id}/details.json", {}, @headers
      json = ActiveSupport::JSON.decode(@response.body)
      purchase_url = json["methods"]["purchase"]
      discount_url = json["methods"]["discount"]
      
      post discount_url, {:consumer => {:discount => discount.code}}, @headers
      json = ActiveSupport::JSON.decode(@response.body)
      
      discount_uuid = json["discount_uuid"]
      assert_not_nil discount_uuid

      post purchase_url, {:consumer => {:session => consumer_session}, :daily_deal_purchase => {:discount_uuid => discount_uuid, :quantity => "1", :gift => "0"} }, @headers
      assert_response :success
      daily_deal_purchase     = assigns(:daily_deal_purchase)
      json                    = ActiveSupport::JSON.decode(@response.body)
      braintree_redirect_url  = URI.decode(json['tr_data'].split("&").collect{ |params| params if params.start_with?("redirect_url")}.compact.first.split("=").last)
      test = braintree_transaction_submitted_result(daily_deal_purchase)
      Braintree::TransparentRedirect.expects(:confirm).returns(braintree_transaction_submitted_result(daily_deal_purchase))    
      get braintree_redirect_url, {}, @headers
      assert_response :success            
      json = ActiveSupport::JSON.decode(@response.body)
      purchases_url = json["consumer"]["connections"]["purchases"]
      get purchases_url, {"consumer" => {"session" => consumer_session}}, @headers
      assert_response :success

      json = ActiveSupport::JSON.decode(@response.body)
      assert_equal 1, json.size
      assert_equal "captured", json.first["status"]
      
      details_url = json.first["connections"]["details"]
      get details_url, {"consumer" => {"session" => consumer_session}}, @headers
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      assert_equal 1, json["vouchers"].size
      
      assert_not_nil daily_deal_purchase.reload.discount
    end    

    private
    
    def setup_braintree_credentials
      Braintree::Configuration.merchant_id  = "111111"
      Braintree::Configuration.private_key  = "222222"
      Braintree::Configuration.public_key   = "333333"
    end
    
    
  end
end
