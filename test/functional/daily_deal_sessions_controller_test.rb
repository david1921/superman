require File.dirname(__FILE__) + "/../test_helper"

class DailyDealSessionsControllerTest < ActionController::TestCase

  include Application::PasswordReset

  def test_show_signin_form
    get :new, :publisher_id => publishers(:sdh_austin).to_param
    assert_response :success
    assert_template "daily_deal_sessions/new"
  end

  def test_show_signin_form_for_ny_daily_news
    publisher = Factory(:publisher,  :name => "NY Daily News", :label => "nydailynews" )
    get :new, :publisher_id => publisher.to_param
    assert_response :success
    assert_template "daily_deal_sessions/new"
  end

  def test_signin
    publisher = publishers(:sdh_austin)
    post :create, :publisher_id => publisher.to_param, :session => { :email => 'john@public.com', :password => 'monkey' }
    assert_not_nil session[:user_id], "session :user_id"
    assert_equal session[:user_id], users(:john_public).id, "session :user_id"
    assert_redirected_to public_deal_of_day_url(publisher.label)
    assert @controller.send(:logged_in?), "logged_in?"
    assert_equal users(:john_public), @controller.send(:current_user), "current_user"
    assert_equal publisher.label, cookies['publisher_label']
  end

  def test_locked_consumers_cant_login
    user = users(:john_public)
    user.locked_at = 1.day.ago
    user.save!

    publisher = publishers(:sdh_austin)
    post :create, :publisher_id => publisher.to_param, :session => { :email => 'john@public.com', :password => 'monkey' }
    assert_equal nil, session[:user_id], "session :user_id"
    assert !@controller.send(:logged_in?), "!logged_in?"
    assert_equal nil, @controller.send(:current_user), "current_user"
    assert_response :success
    assert_template 'daily_deal_sessions/new'
  end

  def test_invalid_signin
    publisher = publishers(:sdh_austin)
    post :create, :publisher_id => publisher.to_param, :session => { :email => 'john@public.com', :password => '' }
    assert_response :success
    assert_template 'daily_deal_sessions/new'
  end

  def test_invalid_signin_using_get
    publisher = publishers(:sdh_austin)
    get :create, :publisher_id => publisher.to_param
    assert_response :success
    assert_template "daily_deal_sessions/new"
  end

  def test_signin_ajax
    publisher = publishers(:sdh_austin)
    xhr :post, :create, :publisher_id => publisher.to_param, :session => { :email => 'john@public.com', :password => 'monkey' }
    assert_not_nil session[:user_id], "session :user_id"
    assert_equal session[:user_id], users(:john_public).id, "session :user_id"
    assert_response :success
    assert @controller.send(:logged_in?), "logged_in?"
    assert_equal users(:john_public), @controller.send(:current_user), "current_user"
  end

  def test_signin_api_version_1_0_0_without_api_header
    publisher = publishers(:sdh_austin)
    post :create, :publisher_id => publisher.to_param, :session => { :email => 'john@public.com', :password => 'monkey' }, :format => "json"
    assert_response :not_acceptable
  end

  def test_signin_api_version_1_0_0
    @request.env['API-Version'] = "1.0.0"
    publisher = publishers(:sdh_austin)
    consumer  = publisher.consumers.find_by_email( "john@public.com" )
    post :create, :publisher_id => publisher.to_param, :session => { :email => 'john@public.com', :password => 'monkey' }, :format => "json"
    assert_response :success
    json = JSON.parse( @response.body )
    assert_equal @controller.send(:verifier).generate({:user_id => consumer.id, :active_session_token => consumer.active_session_token}), json["session"]
    assert_equal consumer.name, json["name"]
    assert_equal consumer.credit_available, json["credit_available"]
  end

  def test_signin_api_version_2_0_0
    @request.env['API-Version'] = "2.0.0"
    consumer  = Factory :consumer
    post :create, :publisher_id => consumer.publisher.to_param, :session => { :email => consumer.email, :password => "monkey" }, :format => "json"
    assert_response :success
    json = JSON.parse( @response.body )
    assert_equal @controller.send(:verifier).generate({:user_id => consumer.id, :active_session_token => consumer.active_session_token}), json["session"]
    assert_equal consumer.name, json["name"]
    assert_equal consumer.credit_available, json["credit_available"]
    assert json["connections"].present?
    assert_equal "https://test.host/consumers/#{consumer.id}/daily_deal_purchases.json",
                 json["connections"]["purchases"]
  end

  def test_signin_api_version_2_1_0
    @request.env['API-Version'] = "2.1.0"
    consumer  = Factory :consumer
    post :create, :publisher_id => consumer.publisher.to_param, :session => { :email => consumer.email, :password => "monkey" }, :format => "json"
    assert_response :success
    json = JSON.parse( @response.body )
    assert_equal @controller.send(:verifier).generate({:user_id => consumer.id, :active_session_token => consumer.active_session_token}), json["session"]
    assert_equal consumer.name, json["name"]
    assert_equal consumer.credit_available, json["credit_available"]
    assert json["connections"].present?
    assert_equal "https://test.host/consumers/#{consumer.id}/daily_deal_purchases.json", json["connections"]["purchases"]
  end

  def test_signin_api_version_2_2_0
    @request.env['API-Version'] = "2.2.0"
    consumer  = Factory(:consumer)
    post :create, :publisher_id => consumer.publisher.to_param, :session => { :email => consumer.email, :password => "monkey" }, :format => "json"
    assert_response :success
    
    json = JSON.parse(@response.body)
    assert_equal @controller.send(:verifier).generate({:user_id => consumer.id, :active_session_token => consumer.active_session_token}), json["session"]
    assert_equal consumer.name, json["name"]
    assert_equal consumer.credit_available, json["credit_available"]
    assert_equal "https://test.host/consumers/#{consumer.id}/daily_deal_purchases.json", json["connections"]["purchases"]
    assert_equal "https://test.host/consumers/#{consumer.id}/credit_cards.json", json["connections"]["credit_cards"]
    assert_equal "https://test.host/consumers/#{consumer.id}/credit_cards.json", json["methods"]["save_credit_card"]
  end

  def test_signin_api_version_1_0_0_with_invalid_credentials
    @request.env['API-Version'] = '1.0.0'
    publisher = publishers(:sdh_austin)
    consumer  = publisher.consumers.find_by_email( "john@public.com" )
    post :create, :publisher_id => publisher.to_param, :session => { :email => "blah", :password => "blah" }, :format => "json"
    assert_response :conflict
    json = JSON.parse( @response.body )
    assert_equal ["Invalid username and/or password"], json["errors"]
  end

  def test_signin_api_version_1_0_0_with_invalid_version_number
    @request.env['API-Version'] = "9.9.9"
    publisher = publishers(:sdh_austin)
    post :create, :publisher_id => publisher.to_param, :session => {:email => "blah@blah.com", :password => "idontknow"}, :format => "json"
    assert_response :not_acceptable
  end

  def test_invalid_signin_api_version_1_0_0
    publisher = publishers(:sdh_austin)
    post :create, :publisher_id => publisher.to_param, :session => {:email => "blah@blah.com", :password => "idontknow"}, :format => "json"
    assert_response :not_acceptable
  end

  def test_facebook_connect_api_version_1_0_0
    @request.env['API-Version'] = "1.0.0"
    publisher = Factory(:publisher)
    consumer  = Factory(:facebook_consumer, :publisher => publisher)
    post :api_facebook, :publisher_id => publisher.to_param, :consumer => { :facebook_token => "123123123213" }, :format => "json"
    assert_response :not_acceptable
  end

  def test_facebook_connect_api_version_2_0_0_with_non_post_request
    @request.env['API-Version'] = "2.0.0"
    publisher = Factory(:publisher)
    consumer  = Factory(:facebook_consumer, :publisher => publisher)
    get :api_facebook, :publisher_id => publisher.to_param, :consumer => { :facebook_token => "123123123213" }, :format => "json"
    assert_response :not_acceptable
  end

  def test_facebook_connect_api_version_2_0_0_with_invalid_token
    @request.env['API-Version'] = "2.0.0"
    publisher = Factory(:publisher)
    consumer  = Factory(:facebook_consumer, :publisher => publisher)
    post :api_facebook, :publisher_id => publisher.to_param, :consumer => { :facebook_token => "blah"}, :format => "json"
    assert_response :not_acceptable
  end

  def test_facebook_connect_api_version_2_0_0_with_valid_token
    publisher     = Factory(:publisher)
    @request.env['API-Version'] = "2.0.0"
    access_token_response = {
      "id" => "1234567",
      "name" => "Jonna Smith",
      "first_name" => "Jonna",
      "last_name" => "Smith",
      "link" => "http => //www.facebook.com/jonna-smith",
      "username" => "jonnasmith",
      "birthday" => "10/22/1965",
      "gender" => "female",
      "email" => "jonnasmith@gmail.com",
      "timezone" => -7,
      "locale" => "en_US",
      "verified" => true,
      "updated_time" => "2011-07-27T18:16:27+0000"
    }

    access_token_json = access_token_response.to_json
    token             = "723322323"

    consumer = Factory(:consumer, :publisher => publisher, :email => access_token_response["email"], :facebook_id => access_token_response["id"])
    access_token = mock("access_token")
    access_token.expects(:get).with("/me").returns( access_token_json.to_s )
    access_token.expects(:token).returns(token)
    OAuth2::AccessToken.expects(:new).returns(access_token)
    post :api_facebook, :publisher_id => publisher.to_param, :consumer => { :facebook_token => "123123123123132" }, :format => "json"
    assert_response :success
  end

  def test_invalid_signin
    publisher = publishers(:sdh_austin)
    post :create, :publisher_id => publisher.to_param, :session => { :email => 'john@public.com', :password => 't-rex' }
    assert_nil session[:user_id], "session :user_id"
    assert_response :success
    assert_not_nil flash[:warn], "Should give feedback for failed signin"
  end

  def test_show_signin_form_with_login_message
    publisher = publishers(:entercom)
    get :new, :publisher_id => publisher.to_param
    assert_response :success
    assert_template "daily_deal_sessions/new"
    assert_select "div[class=login_message]"
    assert @response.body["please sign up"], "Should show account sign up message"
  end

  def test_show_signin_form_without_login_message
    publisher = publishers(:sdh_austin)
    get :new, :publisher_id => publisher.to_param
    assert_response :success
    assert_template "daily_deal_sessions/new"
    assert !@response.body["please sign up"], "Should NOT show account sign up message"
  end

  context "market-aware link logic" do
    setup do
      @publisher = Factory.create(:publisher, :launched => true)
      @market = Factory(:market, :publisher => @publisher)
    end

    should "include a market in the create an account link when there is a market in the request params" do
      get :new, :publisher_id => @publisher.id, :market_label => @market.label
      assert_response :success
      assert_select "div[id='analog_analytics']" do
        assert_select "a[href='/publishers/#{@publisher.id}/#{@market.label}/consumers/new']"
      end
    end

    should "not include a market in the create an account link when there is not a market in the request params" do
      get :new, :publisher_id => @publisher.id
      assert_response :success
      assert_select "div[id='analog_analytics']" do
        assert_select "a[href='/publishers/#{@publisher.id}/consumers/new']"
      end
    end

    should "include a market in the reset your password link when there is a market in the request params" do
      get :new, :publisher_id => @publisher.id, :market_label => @market.label
      assert_response :success
      assert_select "div[id='analog_analytics']" do
        assert_select "a[href='/publishers/#{@publisher.id}/#{@market.label}/consumer_password_resets/new']"
      end
    end

    should "not include a market in the reset your password link when there is not a market in the request params" do
      get :new, :publisher_id => @publisher.id
      assert_response :success
      assert_select "div[id='analog_analytics']" do
        assert_select "a[href='/publishers/#{@publisher.id}/consumer_password_resets/new']"
      end
    end

  end

  context "coolsavings auto login on get to create action" do

    setup do
      @publisher = Factory(:publisher, :consumer_authentication_strategy => "coolsavings")
    end

    should "allow login via get for existing consumer" do
      Consumers::AuthenticationStrategy::Coolsavings.any_instance.expects(:retrieve_member_attributes).returns({})
      consumer = Factory(:consumer, :publisher => @publisher, :email => "yo@yahoo.com")
      get :create, :publisher_id => @publisher.id, :session => { :email => "yo@yahoo.com", :password => "doesnotmatter" }
      assert_redirected_to public_deal_of_day_url(@publisher.label)
      assert_not_nil session[:user_id]
      assert_equal session[:user_id], consumer.id
      assert @controller.send(:logged_in?), "logged_in?"
      assert_equal consumer, @controller.send(:current_user), "current_user"
    end

  end

  context "coolsavings auto login on daily_deal action" do

    setup do
      @publisher = Factory(:publisher, :consumer_authentication_strategy => "coolsavings")
    end

    should "auto logs in and redirects to deal url" do
      Consumers::AuthenticationStrategy::Coolsavings.any_instance.expects(:retrieve_member_attributes).returns({})
      consumer = Factory(:consumer, :publisher => @publisher, :email => "yo@yahoo.com")
      daily_deal = Factory(:daily_deal, :publisher => @publisher)
      get :daily_deals, :id => daily_deal.id, :session => { :email => "yo@yahoo.com", :password => "doesnotmatter" }
      assert_not_nil session[:user_id]
      assert_equal session[:user_id], consumer.id
      assert @controller.send(:logged_in?), "logged_in?"
      assert_equal consumer, @controller.send(:current_user), "current_user"
      assert_redirected_to daily_deal_url(daily_deal)
    end

    should "persist referral_code param if given" do
      Consumers::AuthenticationStrategy::Coolsavings.any_instance.expects(:retrieve_member_attributes).returns({})
      consumer = Factory(:consumer, :publisher => @publisher, :email => "yo@yahoo.com")
      daily_deal = Factory(:daily_deal, :publisher => @publisher)
      get :daily_deals, :id => daily_deal.id, 
        :referral_code => "testcode",
        :session => { :email => "yo@yahoo.com", :password => "doesnotmatter" }
      assert_redirected_to daily_deal_url(daily_deal, :referral_code => "testcode")
    end

  end

  context "force password reset" do

    should "redirect to reset password as needed" do
      publisher = Factory(:publisher)
      consumer = Factory(:consumer, :publisher => publisher, :force_password_reset => true)
      post :create, :publisher_id => publisher.to_param, :session => { :email => consumer.email, :password => consumer.password }
      assert_redirected_to consumer_password_reset_path_or_url(publisher)
      assert_nil session[:user_id]
    end

  end

  context "redirect_back_on_failure" do

    context "when referrer is not set" do

      should "render the daily deal session new template" do
        publisher = Factory(:publisher)
        post :create, :publisher_id => publisher.to_param, :session => { :email => "", :password => "" }
        assert_response :success
        assert_template "daily_deal_sessions/new"
      end

    end

    context "when referrer is set" do

      should "redirect back to the referrer location" do
        referrer_url = "http://example.com/original/path"
        @controller.stubs(:request_referrer).returns(referrer_url)
        publisher = Factory(:publisher)
        post :create, :publisher_id => publisher.to_param, :session => { :email => "", :password => "" }, :redirect_back_on_failure => "true"
        assert_redirected_to referrer_url
      end

    end

  end

  context "allow publisher switch on login" do

    setup do
      @publishing_group = Factory(:publishing_group, :allow_publisher_switch_on_login => false, :unique_email_across_publishing_group => true)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group, :label => "somepub")
      @publisher2 = Factory(:publisher, :publishing_group => @publishing_group, :label => "somepub2")
      @consumer = Factory(:consumer, :publisher => @publisher2, :email => "foobar@yahoo.com", :password => "password", :password_confirmation => "password")
    end

    should "should not switch publishers if allow_publisher_switch_on_login is false" do
       post :create, :publisher_id => @publisher.to_param, :session => { :email => 'foobar@yahoo.com', :password => 'password' }
       assert_response :success
       assert_template 'daily_deal_sessions/new', "Login should have failed"
    end

    context "given allow_publisher_switch_on_login" do
      setup do
        @publishing_group.allow_publisher_switch_on_login = true
        @publishing_group.save!
      end

      should "switch publishers when all settings are aligned" do
        post :create, :publisher_id => @publisher.to_param, :session => { :email => 'foobar@yahoo.com', :password => 'password' }
        assert_redirected_to public_deal_of_day_url(@publisher2.label)
      end

      should "ignore session[:return_to] if switching publishers" do
        @controller.stubs(:safe_to_return).returns(true)
        session[:return_to] = public_deal_of_day_url(@publisher.label)

        post :create, :publisher_id => @publisher.to_param, :session => { :email => 'foobar@yahoo.com', :password => 'password' }
        assert_redirected_to public_deal_of_day_url(@publisher2.label)
      end

      should "fail login if creds are invalid" do
        post :create, :publisher_id => @publisher.to_param, :session => { :email => 'doesnotexist@yahoo.com', :password => 'password' }
        assert_nil session[:user_id], "session :user_id"
        assert_response :success
      end
    end

  end

  context "return_to" do

    should "set session return_to to if given in params" do
      publisher = Factory(:publisher)
      session[:return_to] = nil
      get :new, :publisher_id => publisher.to_param, :return_to => "http://example.com"
      assert_equal "http://example.com", session[:return_to]
    end

    should "set session return_to referrer if same host as host of request" do
      @controller.stubs(:request_referrer => "http://deals.blindrabbit.com/somewhere")
      @controller.stubs(:production_host => "deals.blindrabbit.com")
      publisher = Factory(:publisher)
      session[:return_to] = nil
      get :new, :publisher_id => publisher.to_param
      assert_equal "http://deals.blindrabbit.com/somewhere", session[:return_to]
    end

    should "not set return_to if referrer host is different than request" do
      @controller.stubs(:request_referrer => "http://deals.blindrabbit.com/somewhere")
      @controller.stubs(:production_host => "deals.blindrhino.com")
      publisher = Factory(:publisher)
      session[:return_to] = nil
      get :new, :publisher_id => publisher.to_param
      assert_nil session[:return_to]
    end

    should "not set return_to if production host is nil" do
      @controller.stubs(:request_referrer => "http://deals.blindrabbit.com/somewhere")
      @controller.stubs(:production_host => nil)
      publisher = Factory(:publisher)
      session[:return_to] = nil
      get :new, :publisher_id => publisher.to_param
    end

    should "not set return_to if production host is empty" do
      @controller.stubs(:request_referrer => "http://deals.blindrabbit.com/somewhere")
      @controller.stubs(:production_host => "")
      publisher = Factory(:publisher)
      session[:return_to] = nil
      get :new, :publisher_id => publisher.to_param
    end

    should "not set return_to if referrer is empty" do
      @controller.stubs(:request_referrer => "")
      @controller.stubs(:production_host => "deals.blindrhino.com")
      publisher = Factory(:publisher)
      session[:return_to] = nil
      get :new, :publisher_id => publisher.to_param
    end

  end

  context "wcax create session" do

    setup do
      @publisher = Factory(:publisher, :publishing_group => Factory(:publishing_group, :label => 'wcax'), :label => 'wcax-sevendays')
      @consumer  = Factory(:consumer, :publisher => @publisher)
    end

    should "redirect to reset password on successful signin if force_reset_password is set" do
      @consumer.update_attribute(:force_password_reset, true)
      assert @consumer.force_password_reset?
      post :create, :publisher_id => @publisher.to_param, :session => { :email => @consumer.email, :password => "monkey" }
      assert_redirected_to consumer_password_reset_path_or_url(@publisher)
    end

    should "render reset your password message on failed login" do
      post :create, :publisher_id => @publisher.to_param, :session => { :email => "blah@somewhere.com", :password => "noway" }
      assert_response :success
      assert_template "themes/wcax/daily_deal_sessions/new.html.erb"
      assert_select "div#login_form" do
        assert_select "div.reset-password-message", :text => "We've upgraded! To reset your password, please click here. Please let us know if you need assistance by using this form and we would be glad to help!"
      end
    end

    should "render themed create.js.rjs for js request for failed login" do
      post :create, :publisher_id => @publisher.to_param, :session => { :email => "blah@somewhere.com", :password => "noway" }, :format => "js"
      assert_response :success
      assert_template "themes/wcax/daily_deal_sessions/create.js.rjs"
    end

  end

  context "return to last seen deal" do
    setup do
      @publishing_group = Factory(:publishing_group, :enable_redirect_to_last_seen_deal_on_login => true)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @consumer = Factory(:consumer, :publisher => @publisher, :email => "foobar@yahoo.com", :password => "password", :password_confirmation => "password")
    end

    context "when there is no last_seen_deal_id cookie set" do
      should "redirect to the publisher's deal of the day page if the consumer's publisher is not the current publisher" do
        @publishing_group.update_attribute(:allow_publisher_switch_on_login, true)
        other_publisher = Factory(:publisher, :publishing_group => @publishing_group)
        daily_deal = Factory(:daily_deal, :publisher => other_publisher)
        @request.cookies["#{@publishing_group.label}_last_seen_deal_id"] = nil
        post :create, :publisher_id => other_publisher.to_param, :session => { :email => "foobar@yahoo.com", :password => "password" }
        assert_response :redirect
        assert_redirected_to public_deal_of_day_url(@publisher.label)
      end

      should "redirect to the publisher's deal of the day page if the consumer's publisher is the current publisher" do
        @request.cookies["#{@publishing_group.label}_last_seen_deal_id"] = nil
        post :create, :publisher_id => @publisher.to_param, :session => { :email => "foobar@yahoo.com", :password => "password" }
        assert_response :redirect
        assert_redirected_to public_deal_of_day_url(@publisher.label)
      end
    end

    should "redirect to the consumers last seen deal of the day page if last_seen_deal_id cookie is set" do
      daily_deal = Factory(:daily_deal, :publisher => @publisher)
      @request.cookies["#{@publishing_group.label}_last_seen_deal_id"] = daily_deal.id
      post :create, :publisher_id => @publisher.to_param, :session => { :email => "foobar@yahoo.com", :password => "password" }
      assert_response :redirect
      assert_redirected_to daily_deal_url(daily_deal)
    end
  end

  context "PublisherGroup#enable_force_valid_consumers" do

    setup do
      @publishing_group = Factory(:publishing_group, :enable_force_valid_consumers => true)
      @publisher  = Factory(:publisher, :publishing_group => @publishing_group)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher)
      @consumer   = Factory(:consumer, :publisher => @publisher, :email => "beef@pork.com", :password => "password", :password_confirmation => "password")
      @consumer.activate!
    end

    context "invalid consumers" do
      setup do
        @consumer.update_attribute :agree_to_terms, false
        assert !@consumer.valid?
      end

      should "redirect to the user edit page" do
        post :create, :publisher_id => @publisher.to_param, :session => { :email => @consumer.email, :password => "password" }
        assert_redirected_to "http://test.host/publishers/#{@publisher.to_param}/consumers/#{@consumer.to_param}/edit"
      end

      should "not redirect to the edit page because the publishing group doesn't enforce valid consumers" do
        @publishing_group.update_attributes! :enable_force_valid_consumers => false
        post :create, :publisher_id => @publisher.to_param, :session => { :email => @consumer.email, :password => "password" }
        assert_redirected_to "http://test.host/publishers/#{@publisher.label}/deal-of-the-day"
      end
    end

    context "valid consumers" do
      should "not redirect to the edit page because the user is valid" do
        post :create, :publisher_id => @publisher.to_param, :session => { :email => @consumer.email, :password => "password" }
        assert_redirected_to "http://test.host/publishers/#{@publisher.label}/deal-of-the-day"
      end
    end
  end

  context "POST to :create when a user enters the wrong password and crosses the Users::Lockable::MAXIMUM_FAILED_ATTEMPTS threshold" do

    setup do
      @consumer = Factory :consumer, :email => "forgetfulbob@example.com"
      @consumer.failed_login_attempts = Users::Lockable::MAXIMUM_FAILED_ATTEMPTS - 1
      @consumer.save!
    end

    should "lock the user's account, set a flash warning telling them what happened, and log the locking of the account" do
      ::Users::Lockable.expects(:log_account_locking_activity).with("User forgetfulbob@example.com locked due to too many failed login attempts (5)")
      post :create, :publisher_id => @consumer.publisher.to_param, :session => { :email => @consumer.email, :password => "wrongpassword" }
      @consumer.reload
      assert @consumer.access_locked?, "user account should be locked"
      assert_response :success
      assert_match %r{Sorry, your account has been temporarily locked due to too many failed login attempts. Please <a href=".*" style='text-decoration:underline'>contact us</a> to unlock your account.}, flash[:warn]
    end

    context "with a locked account" do

      setup do
        @consumer.lock_access!
      end

      should "set the locked account response with an incorrect password" do
        post :create, :publisher_id => @consumer.publisher.to_param, :session => { :email => @consumer.email, :password => "wrongpassword" }
        assert_response :success
        assert_match %r{Sorry, your account has been temporarily locked due to too many failed login attempts. Please <a href=".*" style='text-decoration:underline'>contact us</a> to unlock your account.}, flash[:warn]
      end

      should "set the locked account response with the correct password" do
        post :create, :publisher_id => @consumer.publisher.to_param, :session => { :email => @consumer.email, :password => "monkey" }
        assert_response :success
        assert_match %r{Sorry, your account has been temporarily locked due to too many failed login attempts. Please <a href=".*" style='text-decoration:underline'>contact us</a> to unlock your account.}, flash[:warn]
      end

    end

  end

end
