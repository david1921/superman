require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Mobile::Version1Test
module Mobile
  class Version1Test < ActionController::IntegrationTest
    include BraintreeHelper
  
    test "consumer app requests initial publisher info to get active deals" do
      setup_publisher_advertiser_and_daily_deal    
      assert @publisher.daily_deals.current_or_previous.present?
    
      get "/publishers/#{@publisher.label}.json", {}, headers
      assert_response :success 
        
      # now call active daily deals request
      active_daily_deals = ActiveSupport::JSON.decode(@response.body)["connections"]["active_daily_deals"]
      get active_daily_deals, {}, headers
      assert_response :success
          
      json              = ActiveSupport::JSON.decode(@response.body)
      daily_deal_json   = json[@daily_deal.uuid]
    
      assert_not_nil daily_deal_json
    
      assert_equal "http://#{AppConfig.api_host}/daily_deals/#{@daily_deal.to_param}/daily_deal_purchases.json", daily_deal_json["methods"]["purchase"]
    
      connections = daily_deal_json["connections"]
      assert_equal "http://#{AppConfig.api_host}/publishers/#{@daily_deal.publisher.label}.json",      connections["publisher"]
      assert_equal "http://#{AppConfig.api_host}/advertisers/#{@daily_deal.advertiser.to_param}.json", connections["advertiser"]
      assert_equal "http://#{AppConfig.api_host}/daily_deals/#{@daily_deal.to_param}/status.json",     connections["status"]
                                         
    end 
  
    test "consumer apps requests active deals then wants more info on the advertiser" do
      setup_publisher_advertiser_and_daily_deal
      get active_publisher_daily_deals_url(:publisher_id => @publisher.label, :format => "json", :host => AppConfig.api_host), {}, headers
      assert_response :success
    
      advertiser_url = ActiveSupport::JSON.decode(@response.body)[@daily_deal.uuid]["connections"]["advertiser"]
      get advertiser_url, {}, headers
      assert_response :success
    
      advertiser_json = ActiveSupport::JSON.decode(@response.body)
      assert_equal @advertiser.name, advertiser_json["name"]
      assert_equal "http://#{AppConfig.api_host}/publishers/#{@daily_deal.publisher.label}.json", advertiser_json["connections"]["publisher"]    
    end
  
    test "consumer apps requests active deals then wants more info on the publisher" do
      setup_publisher_advertiser_and_daily_deal
      get active_publisher_daily_deals_url(:publisher_id => @publisher.label, :format => "json", :host => AppConfig.api_host), {}, headers
      assert_response :success
    
      publisher_url = ActiveSupport::JSON.decode(@response.body)[@daily_deal.uuid]["connections"]["publisher"]
      get publisher_url, {}, headers
      assert_response :success    
    end  
  
    test "consumer apps requests active deals then wants more info on the daily deal" do
      setup_publisher_advertiser_and_daily_deal
      get active_publisher_daily_deals_url(:publisher_id => @publisher.label, :format => "json", :host => AppConfig.api_host), {}, headers
      assert_response :success
    

      status_url = ActiveSupport::JSON.decode(@response.body)[@daily_deal.uuid]["connections"]["status"]
      get status_url, {}, headers
      assert_response :success
    
      daily_deal_json = ActiveSupport::JSON.decode(@response.body)
      assert_equal @daily_deal.number_sold, daily_deal_json["quantity_sold"]
      assert_equal @daily_deal.updated_at.utc.to_formatted_s(:iso8601), daily_deal_json["updated_at"]
    
    end
  
    # NOTE: tried using "pending" but it didn't work, but "puts" seems to work well ;)
    test "consumer apps requests publisher info then wants to login in customer" do
      setup_publisher_advertiser_and_daily_deal

      get "/publishers/#{@publisher.label}.json", {}, headers
      assert_response :success
    
      login_url = ActiveSupport::JSON.decode(@response.body)["methods"]["login"]
      post login_url, { :session => {:email => @consumer.email, :password => "password"} }, headers
      assert_response :success 
    
      login_json = ActiveSupport::JSON.decode(@response.body)
      assert_equal @consumer.name, login_json["name"]
      assert_equal @consumer.credit_available, login_json["credit_available"]
      assert login_json["session"].present?
        
    end
  
    test "consumer apps requests publisher info then wants to signup and activate new customer" do
      setup_publisher_advertiser_and_daily_deal

      get "/publishers/#{@publisher.label}.json", {}, headers
      assert_response :success
    
      signup_url = ActiveSupport::JSON.decode(@response.body)["methods"]["signup"]
      post signup_url, { :consumer => {:name => "Joe Cool", :email => "joe@cool.com", :password => "password", :agree_to_terms => "1"} }, headers
      assert_response :success
    
      signup_json = ActiveSupport::JSON.decode(@response.body)
      activate_url = signup_json["methods"]["activate_consumer"]
      post activate_url, {}, headers
      assert_response :success
    
      activate_json = ActiveSupport::JSON.decode(@response.body)
      consumer      = Consumer.find_by_email("joe@cool.com")
      assert_equal consumer.name, activate_json["name"]
      assert_equal consumer.credit_available, activate_json["credit_available"]
      assert activate_json["session"].present?        
    end 
  
    test "consumer apps requests publisher info then wants to reset a customers password" do
      setup_publisher_advertiser_and_daily_deal

      get "/publishers/#{@publisher.label}.json", {}, headers
      assert_response :success
    
      reset_password_url = ActiveSupport::JSON.decode(@response.body)["methods"]["reset_password"]
      post reset_password_url, {:email => @consumer.email}, headers
      assert_response :success
        
      update_password_url = ActiveSupport::JSON.decode(@response.body)["methods"]["update_password"]
      reset_code = @consumer.reload.perishable_token
      post update_password_url, {:consumer => {:reset_code => reset_code, :password => "mynewpassword"}, :_method => "put"}, headers
      assert_response :success   
    
      assert_not_nil Consumer.authenticate( @publisher, @consumer.email, "mynewpassword" ), "should update password"
    
      update_password_json = ActiveSupport::JSON.decode(@response.body)
      assert_equal @consumer.name, update_password_json["name"]
      assert_equal @consumer.credit_available, update_password_json["credit_available"]
      assert update_password_json["session"].present?
    end
  
    test "consumer apps request active daily deals with active session and wants to purchase deal" do
      setup_publisher_advertiser_and_daily_deal
      setup_braintree_credentials    
    
      get active_publisher_daily_deals_url(:publisher_id => @publisher.label, :format => "json", :host => AppConfig.api_host), {}, headers
      assert_response :success
    
      purchase_url = ActiveSupport::JSON.decode(@response.body)[@daily_deal.uuid]["methods"]["purchase"]
      
      log_in_consumer
      consumer_session = ActiveSupport::JSON.decode(@response.body)["session"]

      post purchase_url, {:consumer => {:session => consumer_session}, :daily_deal_purchase => {:quantity => "1", :gift => "0"} }, headers
      assert_response :success

      daily_deal_purchase     = assigns(:daily_deal_purchase)

      purchase_json           = ActiveSupport::JSON.decode(@response.body)
      braintree_redirect_url  = URI.decode(purchase_json['tr_data'].split("&").collect{ |params| params if params.start_with?("redirect_url")}.compact.first.split("=").last)
      test = braintree_transaction_submitted_result(daily_deal_purchase)
      Braintree::TransparentRedirect.expects(:confirm).returns(braintree_transaction_submitted_result(daily_deal_purchase))    
      get braintree_redirect_url, {}, headers
      assert_response :success  
        
      braintree_redirect_json = ActiveSupport::JSON.decode(@response.body)
      status_url = braintree_redirect_json["status"]
      get status_url, {"consumer" => {"session" => consumer_session}}, headers
      assert_response :success
       
      status_json   = ActiveSupport::JSON.decode(@response.body)
      vouchers_json = status_json["vouchers"] 
    
      daily_deal_purchase.reload
      assert_equal 1, vouchers_json.size
      assert_equal daily_deal_purchase.daily_deal_certificates.first.serial_number, vouchers_json.first["serial_number"]
      assert_equal daily_deal_purchase.daily_deal_certificates.first.redeemer_name, vouchers_json.first["name"]
      assert_equal daily_deal_purchase.captured?.to_s, status_json["captured"]

    end
        
    private
  
    def headers
      { 
        "API-Version" => '1.0.0'    
      }
    end
  
    def setup_publisher_advertiser_and_daily_deal
      @publisher   = Factory(:publisher, :name => "API Test", :label => "api-test", :launched => true)
      @advertiser  = Factory(:advertiser, :publisher => @publisher)
      @daily_deal  = Factory(:daily_deal, :advertiser => @advertiser)
      @consumer    = Factory(:consumer, :publisher => @publisher, :password => "password", :password_confirmation => "password")
    end
  
    def log_in_consumer
      get "/publishers/#{@publisher.label}.json", {}, headers
      assert_response :success
    
      login_url = ActiveSupport::JSON.decode(@response.body)["methods"]["login"]
      post login_url, { :session => {:email => @consumer.email, :password => "password"} }, headers
      assert_response :success
    end
  
    def setup_braintree_credentials
      Braintree::Configuration.merchant_id  = "111111"
      Braintree::Configuration.private_key  = "222222"
      Braintree::Configuration.public_key   = "333333"
    end
  end
end
