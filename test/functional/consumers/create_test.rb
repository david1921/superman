require File.dirname(__FILE__) + "/../../test_helper"

class ConsumersController::CreateTest < ActionController::TestCase
  include ConsumersHelper
  include Application::PasswordReset
  tests ConsumersController

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

  def test_create
    assert_difference 'Consumer.count' do
      post :create, :publisher_id => @publisher.to_param, :consumer => @valid_consumer_attrs
    end
    assert_response :success
    assert_select "form[action='#{activate_publisher_consumers_path(@publisher)}']", 1 do
      assert_select "input[name=activation_code]", 1
      assert_select "input[type=submit]", 1
    end

    consumer = assigns(:consumer)
    assert_not_nil consumer, "Assignment of @consumer"
    assert_equal "Joe Blow", consumer.name
    assert_equal "joe@blow.com", consumer.email
    assert !consumer.active?, "New consumer should not be activated"
    assert_nil session[:user_id], "New consumer should not be logged in"
    assert_equal @publisher.label, cookies['publisher_label']

    assert @controller.analytics_tag.signup?

    assert_equal 1, ActionMailer::Base.deliveries.count, "Should send activation email"
    email = ActionMailer::Base.deliveries.first
    assert_equal ["joe@blow.com"], email.to, "To: header"
    activation_path = "/publishers/#{@publisher.to_param}/consumers/activate?activation_code=#{consumer.activation_code}"
    assert_match %r{http://[^/]+#{Regexp.escape(activation_path)}}, email.body
  end

  def test_create_with_invalid_attributes
    post :create, :publisher_id => @publisher.to_param, :consumer => {}
    assert_response :success
    assert_equal nil, cookies['publisher_label']
    assert_template "consumers/new"
  end

  def test_create_with_invalid_attributes_for_ny_daily_news
    @publisher.update_attributes! :label => "nydailynews", :launched => true
    post :create, :publisher_id => @publisher.to_param, :consumer => {}
    assert_response :success
    assert_template "themes/nydailynews/consumers/new"
  end

  def test_create_with_require_billing_address_for_entertainment
    publishing_group = Factory(:publishing_group, :label => 'entertainment')
    publisher = Factory(
      :publisher,
      :label => 'entertainmentdallas',
      :publishing_group => publishing_group,
      :launched => true,
      :require_billing_address => true
    )
    post :create, :publisher_id => publisher.to_param, :consumer => @valid_consumer_attrs

    consumer = assigns(:consumer)

    %w{ address_line_1 billing_city zip_code state country_code }.each do |attrib|
      assert consumer.errors.on(attrib.to_sym).present?, "Should have errors on #{attrib}"
    end
  end

  def test_create_incorrect_can_zip_code
    publishing_group = Factory(:publishing_group, :label => 'entertainment')
    publisher = Factory(:publisher, :launched => true, :require_billing_address => true)

    post :create, :publisher_id => publisher.to_param,
         :consumer => {
           :country_code => 'CA',
           :zip_code => '11125'
         }
    consumer = assigns(:consumer)
    assert consumer.errors.on(:zip_code), 'Should fail validation of CA zip_code regexp'
  end


  def test_create_presignup_failed
    @publisher.update_attributes! :label => "nydailynews", :launched => false
    assert_no_difference 'Consumer.count' do
      post :create, :publisher_id => @publisher.to_param, :consumer => @valid_consumer_attrs.merge(:agree_to_terms => "0")
    end
    assert_response :success
    assert_template :presignup
    assert_theme_layout "nydailynews/layouts/daily_deals"
  end

  def test_create_with_purchase_credit
    assert_difference 'Consumer.count' do
      post :create, :publisher_id => @publisher.to_param, :consumer => @valid_consumer_attrs.merge(:purchase_credit => "5.0")
    end
    assert_response :success
    assert_select "form[action='#{activate_publisher_consumers_path(@publisher)}']", 1 do
      assert_select "input[name=activation_code]", 1
      assert_select "input[type=submit]", 1
    end

    consumer = assigns(:consumer)
    assert_not_nil consumer, "Assignment of @consumer"
    assert_equal "Joe Blow", consumer.name
    assert_equal "joe@blow.com", consumer.email
    assert !consumer.active?, "New consumer should not be activated"
    assert_nil session[:user_id], "New consumer should not be logged in"

    assert @controller.analytics_tag.signup?

    assert_equal 1, ActionMailer::Base.deliveries.count, "Should send activation email"
    email = ActionMailer::Base.deliveries.first
    assert_equal ["joe@blow.com"], email.to, "To: header"
    activation_path = "/publishers/#{@publisher.to_param}/consumers/activate?activation_code=#{consumer.activation_code}"
    assert_match %r{http://[^/]+#{Regexp.escape(activation_path)}}, email.body
    assert_equal "applied", cookies["deal_credit"], "Should set deal_credit cookie to 'applied'"
  end

  test "create with existing passive consumer" do
    discount = Factory(:discount)
    publisher = discount.publisher
    consumer = publisher.consumers.build(:email => "barack@whitehouse.gov")
    consumer.signup_discount = discount
    consumer.save false

    assert_no_difference 'Consumer.count' do
      post :create, :publisher_id => publisher.to_param, :consumer => {
        :name => "Barack Obama",
        :email => consumer.email,
        :password => "michelle",
        :password_confirmation => "michelle",
        :agree_to_terms => "1"
      }
    end
    assert_response :success
    assert_select "form[action='#{activate_publisher_consumers_path(publisher)}']", 1 do
      assert_select "input[name=activation_code]", 1
      assert_select "input[type=submit]", 1
    end

    assert_equal consumer.reload, assigns(:consumer)
    assert_equal "Barack Obama", consumer.name
    assert_equal "barack@whitehouse.gov", consumer.email
    assert !consumer.active?, "Consumer should not be activated"
    assert_equal discount, consumer.signup_discount
    assert_nil session[:user_id], "New consumer should not be logged in"

    assert_equal 1, ActionMailer::Base.deliveries.count, "Should send activation email"
    email = ActionMailer::Base.deliveries.first
    assert_equal ["barack@whitehouse.gov"], email.to, "To: header"
    activation_path = "/publishers/#{publisher.to_param}/consumers/activate?activation_code=#{consumer.activation_code}"
    assert_match %r{http://[^/]+#{Regexp.escape(activation_path)}}, email.body
    assert_equal "applied", cookies["deal_credit"], "Should set deal_credit cookie to 'applied'"
  end

  def test_create_without_terms_accepted
    assert_no_difference 'Consumer.count' do
      post :create, :publisher_id => @publisher.to_param, :consumer => @valid_consumer_attrs.merge(:agree_to_terms => "0")
    end
    assert_response :success
    assert_template :new
  end

  def test_create_with_existing_email
    assert_no_difference 'Consumer.count' do
      post :create, :publisher_id => @publisher.to_param, :consumer => @valid_consumer_attrs.merge(:email => users(:john_public).email)
    end
    assert_response :success
    assert_template :new
  end

  def test_create_with_referral_code_cookie
    @request.cookies["referral_code"] = "abcd1234"
    assert_difference 'Consumer.count' do
      post :create, :publisher_id => @publisher.to_param, :consumer => @valid_consumer_attrs
    end
    assert_response :success

    consumer = assigns(:consumer)
    assert_not_nil consumer, "Assignment of @consumer"
    assert_equal "abcd1234", consumer.referral_code
  end

  def test_create_with_device_and_user_agent
    @request.env["HTTP_USER_AGENT"] = "Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)"
    assert_difference 'Consumer.count' do
      post :create, :publisher_id => @publisher.to_param, :consumer => @valid_consumer_attrs.merge(:device => "mobile")
    end
    assert_response :success

    consumer = assigns(:consumer)
    assert_not_nil consumer, "Assignment of @consumer"
    assert_equal "mobile", consumer.device
    assert_equal "Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)", consumer.user_agent
  end

  def test_create_with_api_1_0_0_with_missing_api_header
    post :create, :publisher_id => @publisher.to_param, :consumer => {:name => "John Smith", :email => "john@smith.com", :password => "mypassword", :agree_to_terms => "1"}, :format => "json"
    assert_response :not_acceptable
  end

  def test_create_with_api_1_0_0_with_invalid_api_header
    @request.env['API-Version'] = "9.9.9"
    post :create, :publisher_id => @publisher.to_param, :consumer => {:name => "John Smith", :email => "john@smith.com", :password => "mypassword", :agree_to_terms => "1"}, :format => "json"
    assert_response :not_acceptable
  end

  def test_create_with_api_1_0_0
    @request.env['API-Version'] = "1.0.0"
    post :create, :publisher_id => @publisher.to_param, :consumer => {:name => "John Smith", :email => "john@smith.com", :password => "mypassword", :agree_to_terms => "1"}, :format => "json"
    assert_response :success
    json      = JSON.parse( @response.body )
    consumer  = assigns(:consumer)
    assert_equal activate_consumer_url( consumer, :format => "json", :protocol => "https", :host => AppConfig.api_host ), json["methods"]["activate_consumer"]
  end

  def test_create_with_api_1_0_0_with_invalid_attributes
    @request.env['API-Version'] = '1.0.0'
    post :create, :publisher_id => @publisher.to_param, :consumer => {:name => "John Smith", :email => "", :password => "mypassword", :agree_to_terms => "1"}, :format => "json"
    assert_response :conflict
    json = JSON.parse( @response.body )
    assert_equal ["Email can't be blank"], json["errors"]
  end

  def test_create_with_api_2_0_0
    @request.env['API-Version'] = "2.0.0"
    assert_difference "Consumer.count", 1 do
      post :create, :publisher_id => @publisher.to_param, :consumer => {:name => "John Smith", :email => "john@smith.com", :password => "mypassword", :agree_to_terms => "1", :zip_code => "90210" }, :format => "json"
    end
    assert_response :success
    json      = JSON.parse( @response.body )
    consumer  = assigns(:consumer)
    assert_equal "90210", consumer.zip_code
    assert_equal activate_consumer_url( consumer, :format => "json", :protocol => "https", :host => AppConfig.api_host ), json["methods"]["activate_consumer"]
  end

  def test_create_with_api_3_0_0
    @request.env['API-Version'] = "3.0.0"
    consumer_params = { :name => "John Smith", :email => "john@smith.com", :password => "mypassword", :agree_to_terms => "1", :zip_code => "90210" }
    assert_difference "Consumer.count", 1 do
      post :create, :publisher_id => @publisher.to_param, :consumer => consumer_params, :format => "json"
    end
    assert_response :success
    assert_equal 1, ActionMailer::Base.deliveries.size
    
    assert_equal Consumer.last, (consumer = assigns(:consumer))
    assert consumer.active?, "Consumer should have been activated"
    
    json = JSON.parse(@response.body)
    assert_equal @controller.send(:verifier).generate({:user_id => consumer.id, :active_session_token => consumer.active_session_token}), json["session"]
    assert_equal consumer.name, json["name"]
    assert_equal consumer.credit_available, json["credit_available"]
    assert_equal "https://test.host/consumers/#{consumer.id}/daily_deal_purchases.json", json["connections"]["purchases"]
    assert_equal "https://test.host/consumers/#{consumer.id}/credit_cards.json", json["connections"]["credit_cards"]
    assert_equal "https://test.host/consumers/#{consumer.id}/credit_cards.json", json["methods"]["save_credit_card"]
  end

  context "notifying third parties of account creation" do
    should "enqueue a job if the publisher requires third-party notification" do
      publisher = Factory(:publisher, :notify_third_parties_of_consumer_creation => true)
      NotifyPublisherOfConsumerCreation.expects(:perform)
      post :create, :publisher_id => publisher.to_param, :consumer => @valid_consumer_attrs
    end

    should "not enqueue a job if the publisher does not require third-party notification" do
      publisher = Factory(:publisher, :notify_third_parties_of_consumer_creation => false)
      NotifyPublisherOfConsumerCreation.expects(:perform).never
      post :create, :publisher_id => publisher.to_param, :consumer => @valid_consumer_attrs
    end
  end

  context "create and force_password_reset" do
    should "redirect to password reset when passed a consumer with force reset flag set" do
      consumer = Factory(:consumer, :force_password_reset => true)
      post :create, :publisher_id => consumer.publisher.to_param, :consumer => consumer.attributes
      assert_redirected_to consumer_password_reset_path_or_url consumer.publisher
    end
  end

  context "given session[:return_to] is set to a return URL" do
    should "redirect to return URL" do
      @request.session[:return_to] = "http://example.com"
      publisher = Factory(:publisher, :label => 'test-pub')
      consumer = publisher.consumers.build(:email => "barack@whitehouse.gov")
      consumer.activated_at = Time.now
      consumer.password = "foo bar"
      consumer.save false

      assert_no_difference 'Consumer.count' do
        post :create, :publisher_id => publisher.to_param, :consumer => {
          :name => "Foo Bar",
          :email => consumer.email,
          :password => "foo bar",
          :password_confirmation => "foo bar",
          :agree_to_terms => "1"
        }
        assert_redirected_to "http://example.com"
        assert_equal cookies['publisher_label'], 'test-pub'
      end
    end
  end

  context "when publishing group requires publisher membership codes" do
    setup do
      @publishing_group = Factory.create(:publishing_group, :require_publisher_membership_codes => true)
      @publisher = Factory.create(:publisher, :publishing_group => @publishing_group)
      @publisher_membership_code = Factory.create(:publisher_membership_code, :publisher => @publisher)
    end
    
    should "create the new user and render the consumer create view when a valid membership code is entered" do
      membership_code_valid_attrs = @valid_consumer_attrs.merge( :publisher_membership_code_as_text => @publisher_membership_code.code )
      assert_difference 'Consumer.count' do post:create, :publisher_id => @publisher.to_param, :consumer => membership_code_valid_attrs end
      assert_response :success
      assert_template "consumers/create.html.erb"
    end
    
    should "keep the user on the signup page when the user does not enter a membership code" do
      post :create, :publisher_id => @publisher.to_param, :consumer => @valid_consumer_attrs
      assert_response :success
      assert_template "consumers/new.html.erb"
    end

    should "render the membership code error page when the user enters an invalid membership code" do
      membership_code_valid_attrs = @valid_consumer_attrs.merge( :publisher_membership_code_as_text => "not the code you're looking for")
      post :create, :publisher_id => @publisher.to_param, :consumer => membership_code_valid_attrs
      assert_template "consumers/membership_code_error.html.erb"
    end
  end

  context "when signing up for a publisher that is not launched" do

    setup do
      @publishing_group = Factory(:publishing_group, :require_publisher_membership_codes => true)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group, :launched => false)
      @code = Factory(:publisher_membership_code, :publisher => @publisher, :code => "1234")
      @consumer = Factory.build(:consumer, :publisher => @publisher)
    end

    should "assign the publisher member to the new publisher not the publisher" do
      post :create, :publisher_id => @publisher.to_param,
           :consumer => @consumer.attributes.merge(:publisher_membership_code_as_text => @code.code,
                                                   :password => "passwd",
                                                   :password_confirmation => "passwd")
      assert_equal assigns(:publisher), @publisher
      assert_redirected_to "http://test.host/publishers/#{@publisher.to_param}/daily_deal_subscribers/presignup?email=#{CGI::escape(@consumer.email)}&name=John+Public"
    end

  end

  context "create when publisher membership code results in changing the publisher of the newly created customer" do

    setup do
      @publishing_group = Factory(:publishing_group, :require_publisher_membership_codes => true)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @code = Factory(:publisher_membership_code, :publisher => @publisher, :code => "1234")
      @consumer = Factory.build(:consumer, :publisher => @publisher, :publisher_membership_code => @code)
      @publisher2 = Factory(:publisher, :publishing_group => @publishing_group)
      @code2 = Factory(:publisher_membership_code, :publisher => @publisher2, :code => "3456")
    end

    should "assign the publisher member to the new publisher not the publisher" do
      assert_difference 'Consumer.count' do
        post :create, :publisher_id => @publisher.to_param,
                      :consumer => @consumer.attributes.merge(:publisher_membership_code_as_text => @code2.code,
                                                              :password => "passwd",
                                                              :password_confirmation => "passwd")
      end
      assert_equal assigns(:publisher), @publisher2
    end

  end

end
