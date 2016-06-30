require File.dirname(__FILE__) + "/../test_helper"

class HttpsEverywhereTest < ActionController::IntegrationTest

  def setup
    # ApplicationController.any_instance doesn't work here; #any_instance doesn't
    # work with inheritance.
    [PublishersController,
     DailyDealsController,
     DailyDealPurchasesController,
     DailyDealSessionsController,
     ConsumersController,
     ConsumerPasswordResetsController,
     ShoppingMallsController,
     AuthorizeController,
     SubscribersController].each do |controller_class|
      controller_class.any_instance.stubs(:ssl_rails_environment?).returns(true)
    end
  end
  
  context "requests to a publisher via a host that does not require HTTPS" do

    setup do
      @non_https_host = "nothttps.com"
      @daily_deal = Factory :daily_deal
      @publisher = @daily_deal.publisher
      @publisher.update_attribute :enable_daily_deal_referral, true
      @consumer = Factory :consumer, :publisher => @publisher
      @purchase = Factory :daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer
      assert !HttpsOnlyHost.exists?(:host => @non_https_host)
    end
    
    should "render the deal-of-the-day page successfully under HTTP" do
      get public_deal_of_day_path(:label => @publisher.label), nil, :host => @non_https_host
      assert_response :success
    end
    
    should "redirect the deal-of-the-day page from HTTPS to HTTP" do
      https!
      get public_deal_of_day_path(:label => @publisher.label), nil, :host => @non_https_host
      assert_redirected_to public_deal_of_day_url(:label => @publisher.label, :host => @non_https_host, :protocol => "http")
    end
    
  end
  
  context "requests to a publisher via a host that requires HTTPS" do
    
    setup do
      @prod_host = "blue365deals.com"
      @daily_deal = Factory :daily_deal
      @publisher = @daily_deal.publisher
      @publisher.update_attribute :enable_daily_deal_referral, true
      @consumer = Factory :consumer, :publisher => @publisher
      @purchase = Factory :daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer
      
      Factory :https_only_host, :host => @prod_host
    end
    
    should "redirect the deal-of-the-day page from HTTP to HTTPS" do
      get public_deal_of_day_url(:label => @publisher.label), nil, :host => @prod_host
      assert_redirected_to public_deal_of_day_url(:label => @publisher.label, :host => @prod_host, :protocol => "https")
    end
    
    should "render the deal-of-the-day page successfully under HTTPS" do
      https!
      get public_deal_of_day_path(:label => @publisher.label), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect the deal show page from HTTP to HTTPS" do
      get daily_deal_path(:id => @daily_deal.to_param), nil, :host => @prod_host
      assert_redirected_to daily_deal_url(:id => @daily_deal.to_param, :protocol => "https")
    end
    
    should "render the deal show page successfully under HTTPS" do
      https!
      get daily_deal_path(:id => @daily_deal.to_param), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect the shopping mall page from HTTP to HTTPS" do
      get publisher_shopping_mall_path(:publisher_id => @publisher.label), nil, :host => @prod_host
      assert_redirected_to publisher_shopping_mall_url(:publisher_id => @publisher.label, :protocol => "https", :host => @prod_host)      
    end
    
    should "render the shopping mall page successfully under HTTPS" do
      https!
      get publisher_shopping_mall_path(:publisher_id => @publisher.label), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect the how-it-works page from HTTP to HTTPS" do
      get how_it_works_publisher_daily_deals_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_redirected_to how_it_works_publisher_daily_deals_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "render the how-it-works page successfully under HTTPS" do
      https!
      get how_it_works_publisher_daily_deals_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect the feature-your-business page from HTTP to HTTPS" do
      get feature_your_business_publisher_daily_deals_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_redirected_to feature_your_business_publisher_daily_deals_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "render the feature-your-business page successfully under HTTPS" do
      https!
      get feature_your_business_publisher_daily_deals_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_response :success
    end

    should "redirect the FAQ page from HTTP to HTTPS" do
      get faqs_publisher_daily_deals_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_redirected_to faqs_publisher_daily_deals_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "render the FAQ page successfully under HTTPS" do
      https!
      get faqs_publisher_daily_deals_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_response :success
    end
  
    should "redirect the contact page from HTTP to HTTPS" do
      get contact_publisher_daily_deals_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_redirected_to contact_publisher_daily_deals_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "render the contact page successfully under HTTPS" do
      https!
      get contact_publisher_daily_deals_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect the login page from HTTP to HTTPS" do
      get daily_deal_login_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_redirected_to daily_deal_login_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "render the login page successfully under HTTPS" do
      https!
      get daily_deal_login_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect the RAF page from HTTP to HTTPS" do
      post publisher_daily_deal_sessions_url(@publisher, :host => @prod_host, :protocol => "https"),
          :session => { :email => @consumer.email, :password => "monkey" }
      assert session[:user_id].present?

      get refer_a_friend_publisher_consumers_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "http")
      assert_redirected_to refer_a_friend_publisher_consumers_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "render the RAF page successfully under HTTPS" do
      post publisher_daily_deal_sessions_url(@publisher, :host => @prod_host, :protocol => "https"),
          :session => { :email => @consumer.email, :password => "monkey" }
      assert session[:user_id].present?
      
      https!
      get refer_a_friend_publisher_consumers_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect the consumer signup page from HTTP to HTTPS" do
      get new_publisher_consumer_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_redirected_to new_publisher_consumer_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "render the consumer signup page successfully under HTTPS" do
      https!
      get new_publisher_consumer_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect a POST to consumer creation to HTTPS, and not create the user" do
      assert_no_difference "User.count" do
        post publisher_consumers_url(:publisher_id => @publisher.to_param, :host => @prod_host),
             :consumer => {
               :first_name => "Foo", :last_name => "Bar", 
               :email => "foobar@example.com", :password => "foobar",
               :password_confirmation => "foobar", :agree_to_terms => "1"
             }
      end
      assert_redirected_to publisher_consumers_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "successfully create the user when POSTed to the consumer create URL with HTTPS" do
      assert_difference "User.count", 1 do
        post publisher_consumers_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https"),
             :consumer => {
               :first_name => "Foo", :last_name => "Bar", 
               :email => "foobar@example.com", :password => "foobar",
               :password_confirmation => "foobar", :agree_to_terms => "1"
             }
      end
      assert_response :success
    end
    
    should "redirect the terms page from HTTP to HTTPS" do
      get terms_publisher_daily_deals_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_redirected_to terms_publisher_daily_deals_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "render the terms page successfully under HTTPS" do
      https!
      get terms_publisher_daily_deals_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_response :success
    end    

    should "redirect the privacy policy page from HTTP to HTTPS" do
      get privacy_policy_publisher_daily_deals_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_redirected_to privacy_policy_publisher_daily_deals_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "render the privacy policy page successfully under HTTPS" do
      https!
      get privacy_policy_publisher_daily_deals_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect the forgot password page from HTTP to HTTPS" do
      get new_publisher_consumer_password_reset_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_redirected_to new_publisher_consumer_password_reset_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "render the forgot password page successfully under HTTPS" do
      https!
      get new_publisher_consumer_password_reset_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect a POST to consumer password reset create from HTTP to HTTPS" do
      old_perishable_token = @consumer.perishable_token
      post publisher_consumer_password_resets_url(:publisher_id => @publisher.to_param, :host => @prod_host),
           :email => @consumer.email
      assert_redirected_to publisher_consumer_password_resets_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https")
      assert_equal old_perishable_token, @consumer.perishable_token
    end
    
    should "successfully create a consumer password reset when POSTing over HTTPS" do
      old_perishable_token = @consumer.perishable_token
      post publisher_consumer_password_resets_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https"),
           :email => @consumer.email
      assert_response :success
      assert old_perishable_token != @consumer.reload.perishable_token
    end
    
    should "redirect a POST to subscriber create from HTTP to HTTPS" do
      assert_no_difference "Subscriber.count" do
        post publisher_subscribers_url(:publisher_id => @publisher.to_param, :host => @prod_host),
             :subscriber => { :email => "foobar@example.com" }
      end
      assert_redirected_to publisher_subscribers_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "successfully create a subscriber when POSTing over HTTPS" do
      assert_difference "Subscriber.count", 1 do
        post publisher_subscribers_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https"),
             :subscriber => { :email => "foobar@example.com" }
      end
      assert_response :redirect
    end    
    
    should "redirect the consumer presignup from HTTP to HTTPS" do
      get presignup_publisher_consumers_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_redirected_to presignup_publisher_consumers_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "successfully render the consumer presignup under HTTPS" do
      https!
      get presignup_publisher_consumers_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect the consumer thank you page from HTTP to HTTPS" do
      get thank_you_publisher_consumer_path(:publisher_id => @publisher.to_param, :id => @consumer.to_param), nil, :host => @prod_host
      assert_redirected_to thank_you_publisher_consumer_url(:publisher_id => @publisher.to_param, :id => @consumer.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "successfully render the consumer thank you page under HTTPS" do
      post publisher_daily_deal_sessions_url(@publisher, :host => @prod_host), 
          :session => { :email => @consumer.email, :password => "monkey" }

      https!
      get thank_you_publisher_consumer_path(:publisher_id => @publisher.to_param, :id => @consumer.to_param), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect the subscribed page from HTTP to HTTPS" do
      get subscribed_publisher_daily_deals_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_redirected_to subscribed_publisher_daily_deals_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "successfully render the subscribed page under HTTPS" do
      https!
      get subscribed_publisher_daily_deals_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect the facebook share link from HTTP to HTTPS" do
      get facebook_daily_deal_path(:id => @daily_deal.to_param), nil, :host => @prod_host
      assert_redirected_to facebook_daily_deal_url(:id => @daily_deal.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "successfully redirect the facebook share link to facebook, when accessed via HTTPS" do
      https!
      get facebook_daily_deal_path(:id => @daily_deal.to_param), nil, :host => @prod_host
      assert_match(/facebook\.com/, @response.headers["Location"].to_s)
    end

    should "redirect the twitter share link from HTTP to HTTPS" do
      get twitter_daily_deal_path(:id => @daily_deal.to_param), nil, :host => @prod_host
      assert_redirected_to twitter_daily_deal_url(:id => @daily_deal.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "successfully redirect the twitter share link to twitter, when accessed via HTTPS" do
      https!
      get twitter_daily_deal_path(:id => @daily_deal.to_param), nil, :host => @prod_host
      assert_match(/twitter\.com/, @response.headers["Location"].to_s)
    end
    
    should "redirect the fb authorize link from HTTP to HTTPS" do
      get auth_init_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_redirected_to auth_init_url(:publisher_id => @publisher.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "successfully redirect the fb authorize link to facebook, when accessed via HTTPS" do
      https!
      get auth_init_path(:publisher_id => @publisher.to_param), nil, :host => @prod_host
      assert_match(/facebook\.com/, @response.headers["Location"].to_s, "Expected facebook.com in #{headers["Location"].to_s}")
    end

    should "redirect the deal email scrape page from HTTP to HTTPS" do
      get publisher_deal_of_day_email_path(:label => @publisher.label), nil, :host => @prod_host
      assert_redirected_to "https://#{@prod_host}/publishers/#{@publisher.label}/deal-of-the-day-email"
    end
    
    should "successfully render the deal email scrape page under HTTPS" do
      https!
      get publisher_deal_of_day_email_path(:label => @publisher.label), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect the new purchase page from HTTP to HTTPS" do
      get new_daily_deal_daily_deal_purchases_path(:daily_deal_id => @daily_deal.to_param), nil, :host => @prod_host
      assert_redirected_to new_daily_deal_daily_deal_purchases_url(:daily_deal_id => @daily_deal.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "successfully render the new purchase page under HTTPS" do
      https!
      get new_daily_deal_daily_deal_purchases_path(:daily_deal_id => @daily_deal.to_param), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect the purchase confirmation page from HTTP to HTTPS" do
      get confirm_daily_deal_purchase_path(:id => @purchase.to_param), nil, :host => @prod_host
      assert_redirected_to confirm_daily_deal_purchase_url(:id => @purchase.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "successfully render the purchase confirmation page under HTTPS" do
      https!
      post publisher_daily_deal_sessions_url(@publisher, :host => @prod_host), 
          :session => { :email => @consumer.email, :password => "monkey" }
      get confirm_daily_deal_purchase_path(:id => @purchase.to_param), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect the purchase thank you page from HTTP to HTTPS" do
      post publisher_daily_deal_sessions_url(@publisher, :host => @prod_host), 
          :session => { :email => @consumer.email, :password => "monkey" }
      get thank_you_daily_deal_purchase_path(:id => @purchase.to_param), nil, :host => @prod_host
      assert_redirected_to thank_you_daily_deal_purchase_url(:id => @purchase.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "successfully render the purchase thank you page under HTTPS" do
      https!
      post publisher_daily_deal_sessions_url(@publisher, :host => @prod_host), 
          :session => { :email => @consumer.email, :password => "monkey" }

      https!
      get thank_you_daily_deal_purchase_path(:id => @purchase.to_param), nil, :host => @prod_host
      assert_response :success
    end
    
    should "redirect the consumer purchases listing from HTTP to HTTPS" do
      post publisher_daily_deal_sessions_url(@publisher, :host => @prod_host, :protocol => "https"),
          :session => { :email => @consumer.email, :password => "monkey" }
      assert session[:user_id].present?
            
      get publisher_consumer_daily_deal_purchases_url(:publisher_id => @publisher.to_param, :consumer_id => @consumer.to_param, :host => @prod_host, :protocol => "http")
      assert_redirected_to publisher_consumer_daily_deal_purchases_url(:publisher_id => @publisher.to_param, :consumer_id => @consumer.to_param, :host => @prod_host, :protocol => "https")
    end
    
    should "successfully render the consumer purchases listing under HTTPS" do
      post publisher_daily_deal_sessions_url(@publisher, :host => @prod_host, :protocol => "https"),
          :session => { :email => @consumer.email, :password => "monkey" }
      assert session[:user_id].present?
      
      https!
      get publisher_consumer_daily_deal_purchases_path(:publisher_id => @publisher.to_param, :consumer_id => @consumer.to_param), nil, :host => @prod_host
      assert_response :success
    end

    context "logging in" do

      should "return a secure cookie when authenticating through a host that requires https" do
        post publisher_daily_deal_sessions_url(@publisher, :host => @prod_host, :protocol => "https"),
            :session => { :email => @consumer.email, :password => "monkey" }
        assert_match(/_super_banner_session.* secure;/, headers["Set-Cookie"].to_s, "Did not find secure cookie header in #{headers["Set-Cookie"]}")
      end
      
      should "return a non-secure cookie when authenticating through a non-https host" do
        post publisher_daily_deal_sessions_url(@publisher, :host => "insecure.org", :protocol => "https"),
            :session => { :email => @consumer.email, :password => "monkey" }
        
        assert_no_match(/_super_banner_session.* secure;/, headers["Set-Cookie"].to_s, "Did not find secure cookie header in #{headers["Set-Cookie"]}")
      end
    end
  end
    
end
