require File.dirname(__FILE__) + "/../../test_helper"

class ConsumersControllerTest < ActionController::TestCase
  include ConsumersHelper
  
  assert_no_angle_brackets :except => [
    :test_create,
    :test_create_with_purchase_credit,
    :test_create_with_existing_passive_consumer,
    :test_create_with_referral_code_cookie
  ]

  def setup
    @publisher = publishers(:sdh_austin)
    @valid_consumer_attrs = {
      :name => "Joe Blow",
      :email => "joe@blow.com",
      :password => "secret",
      :password_confirmation => "secret",
      :agree_to_terms => "1"
    }
    ActionMailer::Base.deliveries.clear
  end
  
  def test_thank_you
    consumer = @publisher.consumers.create!(@valid_consumer_attrs)
    get :thank_you, :id => consumer.to_param, :publisher_id => @publisher.to_param
    assert_response :success
    assert_match %r{Thank you for signing up to receive the #{Regexp.escape(@publisher.label)}}, @response.body
  end
  
  def test_thank_you_with_special_deal
    consumer = @publisher.consumers.create!(@valid_consumer_attrs)
    @publisher.show_special_deal = true
    @publisher.save!
    discount = Factory(:discount, :publisher => @publisher, :code => "SIGNUP_CREDIT", :amount => 5.00)
    get :thank_you, :id => consumer.to_param, :publisher_id => @publisher.to_param
    assert_response :success
    assert_match %r{Thank you for signing up to receive the #{Regexp.escape(@publisher.label)}}, @response.body
    assert_equal true, @response.body.include?("You will automatically receive $5.00 off your first Deal of the Day purchase.") 
  end
  
  test "deal_credit via post with usable signup discount" do
    signup_discount = Factory(:discount, :code => "SIGNUP_CREDIT", :amount => 10.00)
    publisher = signup_discount.publisher
    daily_deal = Factory(:daily_deal, :publisher => publisher)
  
    post :deal_credit, :publisher_id => publisher.to_param
    assert_response :success
    assert_template :new
    assert_select "p", :text => /sign up now and get \$10.00 off/i, :count => 1
    assert_select "form[action=#{publisher_consumers_path(publisher)}][method=post]", 1 do
      assert_select "input[type=hidden][name='consumer[discount_code]'][value=SIGNUP_CREDIT]", 1
    end
  end
  
  test "deal_credit via get with usable signup discount" do
    signup_discount = Factory(:discount, :code => "SIGNUP_CREDIT", :amount => 10.00)
    publisher = signup_discount.publisher
    daily_deal = Factory(:daily_deal, :publisher => publisher)
  
    get :deal_credit, :publisher_id => publisher.to_param
    assert_response :success
    assert_template :new
    assert_select "p", :text => /sign up now and get \$10.00 off/i, :count => 1
    assert_select "form[action=#{publisher_consumers_path(publisher)}][method=post]", 1 do
      assert_select "input[type=hidden][name='consumer[discount_code]'][value=SIGNUP_CREDIT]", 1
    end
  end
  
  test "deal_credit via get without usable signup discount" do
    signup_discount = Factory(:discount, :code => "SIGNUP10", :amount => 10.00, :last_usable_at => Time.zone.now.yesterday)
    publisher = signup_discount.publisher
    daily_deal = Factory(:daily_deal, :publisher => publisher)
  
    get :deal_credit, :publisher_id => publisher.to_param
    assert_response :success
    assert_template :new
    assert_select "p", :text => /sign up now and get \$10.00 off/i, :count => 0
    assert_select "form[action=#{publisher_consumers_path(publisher)}][method=post]", 1 do
      assert_select "input[type=hidden][name='consumer[discount_code]'][value=SIGNUP_CREDIT]", 0
    end
  end
  
  def test_deal_credit_cannot_be_used_while_logged_in
    consumer = users(:john_public)
    consumer.save!
  
    login_as :john_public
  
    daily_deal = daily_deals(:changos)
    post :deal_credit, :daily_deal_id => daily_deal.to_param, :publisher_id => @publisher.to_param
    assert_redirected_to public_deal_of_day_path(@publisher.label)
    assert_not_nil flash[:warn], "should set flash warning"
  end    
  
  def test_consumer_add_credit
    login_as :aaron
    publisher = Factory(:publisher)
    discount = Factory(:discount, :publisher => publisher)
    consumer = Factory(:consumer, :publisher => publisher)
  
    post :add_credit, :id => consumer.to_param
    assert_not_nil flash[:notice]  
    assert_redirected_to consumers_path
  
    assert_equal discount, assigns(:consumer).signup_discount
  end
  
  def test_presignup_assigns_referral_code
    publisher = Factory(:publisher, :launched => false)
    get :presignup, :referral_code => "123456789", :publisher_id => publisher.id
    assert_response :success
    assert_equal "123456789", assigns(:referral_code), "@referral_code"
  end
  
  test "refer a friend page requires login" do
    publisher = Factory(:publisher, :enable_daily_deal_referral => true)
    
    get :refer_a_friend, :publisher_id => publisher.to_param
    assert_redirected_to new_publisher_daily_deal_session_path(publisher)
  end
  
  test "refer a friend page after login when publisher does not have daily deal referral enabled" do
    publisher = Factory(:publisher, :enable_daily_deal_referral => false)
    consumer = Factory(:consumer, :publisher => publisher)
    
    login_as consumer
    assert_raises ActiveRecord::RecordNotFound do
      get :refer_a_friend, :publisher_id => publisher.to_param
    end
  end
  
  test "refer a friend page after login when publisher has daily deal referral enabled" do
    publisher = Factory(:publisher, :enable_daily_deal_referral => true)
    consumer = Factory(:consumer, :publisher => publisher)
    
    login_as consumer
    get :refer_a_friend, :publisher_id => publisher.to_param
    assert_response :success
    assert_equal consumer, assigns(:consumer)
  end

  test "refer a friend page when publishing group is using SSO" do
    publishing_group = Factory(:publishing_group, :allow_single_sign_on => true, :unique_email_across_publishing_group => true)
    publisher1 = Factory(:publisher, :publishing_group => publishing_group, :enable_daily_deal_referral => true)
    publisher2 = Factory(:publisher, :publishing_group => publishing_group, :enable_daily_deal_referral => true)
    consumer = Factory(:consumer, :publisher => publisher1)
    
    login_as consumer
    get :refer_a_friend, :publisher_id => publisher2.to_param
    assert_response :success
    assert_select ".consumer_referral_link[value='#{consumer.referral_url(publisher2)}']", true
  end
  
  test "refer a friend page for TWC" do
    publishing_group = Factory(:publishing_group, :label => 'rr' )
    publisher        = Factory(:publisher, :publishing_group => publishing_group, :enable_daily_deal_referral => true)
    consumer         = Factory(:consumer, :publisher => publisher)
    
    login_as consumer
    get :refer_a_friend, :publisher_id => publisher.to_param
    
    assert_theme_layout("rr/layouts/daily_deals")
    assert_template("themes/rr/consumers/refer_a_friend")
    
  end
  
  context "when publisher has a presignup theme" do
    setup do
      @publisher = Factory(:publisher, :label => "hearst-seattlepi")
    end
    
    should "render the themed layout and html template as the default format" do
      get :presignup, :publisher_id => @publisher.to_param
      assert_response :success
      
      assert_theme_layout "hearst-seattlepi/layouts/presignup"
      assert_template "themes/hearst-seattlepi/consumers/presignup.html.liquid"
      assert_equal "text/html", @response.content_type
    end

    should "raise an error when a format with no corresponding themed layout is requested" do
      exception = nil
      begin
        get :presignup, :publisher_id => @publisher.to_param, :format => "ics"
      rescue Exception => exception
      end

      assert RuntimeError === exception, "Should raise a RuntimeError"
      assert_match /could not find theme layout/i, exception.message
    end
  end

  def test_twitter
    publisher = Factory(:publisher, :enable_daily_deal_referral => true)
    login_as (consumer = Factory(:consumer, :publisher => publisher))
    Consumer.stubs(:find => consumer)
    consumer.expects(:record_click).with('twitter').times(1)
    get :twitter, :id => consumer.id, :publisher_id => publisher.id

    assert_redirected_to "http://twitter.com/?status=#{CGI.escape(consumer.twitter_status).gsub('+', '%20')}"
  end

  def test_twitter_with_sso_pub
    publishing_group = Factory(:publishing_group,
                               :unique_email_across_publishing_group => true,
                               :allow_single_sign_on => true)
    publisher1 = Factory(:publisher, :enable_daily_deal_referral => true, :publishing_group => publishing_group)
    publisher2 = Factory(:publisher, :enable_daily_deal_referral => true, :publishing_group => publishing_group)

    consumer = Factory(:consumer, :publisher => publisher1)
    login_as consumer

    get :twitter, :id => consumer.id, :publisher_id => publisher2.id

    assert_redirected_to "http://twitter.com/?status=#{CGI.escape(consumer.twitter_status(publisher2)).gsub('+', '%20')}"
  end
 
  def test_facebook
    publisher = Factory(:publisher, :enable_daily_deal_referral => true)
    login_as (consumer = Factory(:consumer, :publisher => publisher))
    Consumer.stubs(:find => consumer)
    get :facebook, :id => consumer.id, :publisher_id => publisher.id
    url_facebook = "http://www.facebook.com/share.php"
    url = consumer.referral_url_for_bit_ly
    assert_response(:redirect)
    assert @response.redirected_to.include?( url_facebook), "missing facebook host: #{@response.redirected_to}"
    assert @response.redirected_to.include?( "t=#{CGI.escape(consumer.facebook_title)}"), "share title should be #{consumer.facebook_title}"
    assert @response.redirected_to.include?( "u=#{CGI.escape(url)}"), "share url should be #{CGI.escape(url)}"
    h = CGI::parse(URI.parse(@response.redirected_to).query)
    u = h["u"]
    u = u[0] if u.is_a?(Array)
    # redirect url should include timestamp
    assert_match(/[&?]v\=[0-9]+/, u, "timestamp not included")
  end

  def test_facebook_with_sso_pub
    publishing_group = Factory(:publishing_group,
                               :unique_email_across_publishing_group => true,
                               :allow_single_sign_on => true)
    publisher1 = Factory(:publisher, :enable_daily_deal_referral => true, :publishing_group => publishing_group)
    publisher2 = Factory(:publisher, :enable_daily_deal_referral => true, :publishing_group => publishing_group)

    consumer = Factory(:consumer, :publisher => publisher1)
    login_as consumer

    get :facebook, :id => consumer.id, :publisher_id => publisher2.id

    url = consumer.referral_url_for_bit_ly(publisher2)
    assert @response.redirected_to.include?("u=#{CGI.escape(url)}")
  end
  
  context "a consumer's purchases, exported as json" do
    
    setup do
      @publisher = Factory :publisher
      @advertiser = Factory :advertiser, :publisher => @publisher
      @daily_deal = Factory :daily_deal, :advertiser => @advertiser,
                            :value_proposition => "An amazingly good deal",
                            :price => 25
      @consumer = Factory :consumer, :publisher => @publisher
      @session = @controller.send(:verifier).generate(:user_id => @consumer.id)
      
      @executed_purchase_1 = Factory :captured_daily_deal_purchase, :daily_deal => @daily_deal,
                                     :uuid => "the-first-uuid", :consumer => @consumer
      @executed_purchase_2 = Factory :captured_daily_deal_purchase, :daily_deal => @daily_deal,
                                     :uuid => "the-second-uuid", :consumer => @consumer,
                                     :quantity => 3
      @pending_purchase_1 = Factory :pending_daily_deal_purchase, :daily_deal => @daily_deal,
                                    :consumer => @consumer
                                    
      @request.env["API-Version"] = "2.0.0"
    end
    
    should "return a 406 Not Acceptable if the API-Version header is not present" do
      @request.env["API-Version"] = ""
      get :daily_deal_purchases, :id => @consumer, :format => "json"
      assert_response :not_acceptable
    end
    
    should "return a 403 Forbidden if missing the consumer[session] parameter" do
      get :daily_deal_purchases, :id => @consumer, :format => "json"
      assert_response 403
    end
    
    should "return a 406 Not Acceptable if the API-Version header is less than 2.0.0" do
      @request.env["API-Version"] = "1.0.0"
      get :daily_deal_purchases, :id => @consumer, :consumer => { :session => @session }, :format => "json"
      assert_response :not_acceptable
    end
    
    should "return a 403 Forbidden if the consumer[session] parameter is provided but does not authorize the correct consumer" do
      get :daily_deal_purchases, :id => @consumer, :consumer => { :session => "totallymadeup" }, :format => "json"
      assert_response 403
    end
           
    should "return a 200 Ok if consumer[session] matches the specified consumer" do
      get :daily_deal_purchases, :id => @consumer, :consumer => { :session => @session }, :format => "json"
      assert_response :success      
    end
    
    should "return each *executed* purchase in JSON format, for the authorized consumer for API 2.0.0" do
      get :daily_deal_purchases, :id => @consumer, :consumer => { :session => @session }, :format => "json"
      assert_response :success
      
      purchases = JSON.parse(@response.body)
      
      assert_equal 2, purchases.size
      assert purchases.include?("the-first-uuid")
      assert purchases.include?("the-second-uuid")
      
      first_purchase = {
        "status" => "captured",
        "description" => "An amazingly good deal",
        "quantity" => 1,
        "total_price" => 25,
        "credit_used" => 0.00,
        "executed_at" => @executed_purchase_1.executed_at.to_s(:iso8601),
        "expires_on" => nil,
        "terms" => "<p>these are my terms</p>",
        "photo" => "http://test.host/images/missing/daily_deals/photos/widget.png",
        "connections" => {
          "vouchers" => "https://test.host/daily_deal_purchases/the-first-uuid/daily_deal_certificates.json"
        }
      }
      second_purchase = {
        "status" => "captured",
        "description" => "An amazingly good deal",
        "quantity" => 3,
        "total_price" => 75,
        "credit_used" => 0.00,
        "executed_at" => @executed_purchase_2.executed_at.to_s(:iso8601),
        "expires_on" => nil,
        "terms" => "<p>these are my terms</p>",
        "photo" => "http://test.host/images/missing/daily_deals/photos/widget.png",
        "connections" => {
          "vouchers" => "https://test.host/daily_deal_purchases/the-second-uuid/daily_deal_certificates.json"
        }        
      }
      assert_equal first_purchase, purchases[@executed_purchase_1.uuid]
      assert_equal second_purchase, purchases[@executed_purchase_2.uuid]
    end
    
    should "return each executed purchase in JSON format, for the authorized consumer for API 3.0.0" do
      @request.env["API-Version"] = "3.0.0"
      get :daily_deal_purchases, :id => @consumer, :consumer => { :session => @session }, :format => "json"
      assert_response :success
      
      expected_json = [{
        "status" => "captured",
        "description" => "An amazingly good deal",
        "quantity" => 1,
        "executed_at" => @executed_purchase_1.executed_at.utc.to_s(:iso8601),
        "expires_on" => nil,
        "photo" => "http://test.host/images/missing/daily_deals/photos/widget.png",
        "connections" => {
          "details" => "https://test.host/daily_deal_purchases/the-first-uuid/status.json"
        }
      }, {
        "status" => "captured",
        "description" => "An amazingly good deal",
        "quantity" => 3,
        "executed_at" => @executed_purchase_2.executed_at.utc.to_s(:iso8601),
        "expires_on" => nil,
        "photo" => "http://test.host/images/missing/daily_deals/photos/widget.png",
        "connections" => {
          "details" => "https://test.host/daily_deal_purchases/the-second-uuid/status.json"
        }        
      }]
      assert_equal_arrays expected_json, JSON.parse(@response.body)
    end
  end

end
