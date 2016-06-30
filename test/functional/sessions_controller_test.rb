require File.dirname(__FILE__) + "/../test_helper"

class SessionsControllerTest < ActionController::TestCase
  def test_should_login_and_redirect
    post :create, :user => { :login => 'quentin', :password => 'monkey' }
    assert_not_nil session[:user_id], "session :user_id"
    assert_equal session[:user_id], users(:quentin).id, "session :user_id"
    assert_response :redirect
    assert @controller.send(:logged_in?), "logged_in?"
    assert_equal users(:quentin), @controller.send(:current_user), "current_user"
  end

  def test_should_fail_login_and_not_redirect
    post :create, :user => { :email => 'quentin@example.com', :password => 'bad password' }
    assert_nil session[:user_id]
    assert_response :success
  end

  def test_should_fail_login_when_locked
    user = users(:quentin)
    user.locked_at = 1.day.ago
    user.save!
    
    post :create, :user => { :email => 'quentin@example.com', :password => 'monkey' }
    assert_nil session[:user_id]
    assert_response :success
  end

  def test_cookies_disabled
    @controller.expects(:verified_request?).returns(false)
    post :create, :user => { :email => 'quentin@example.com', :password => 'bad password' }
    assert_nil session[:user_id]
    assert_response :success
    assert flash[:warn]["cookies"], "Should have flash warning about cookies"
  end

  def test_should_logout
    login_as :quentin
    get :destroy
    assert_nil session[:user_id]
    assert_redirected_to login_path
  end
  
  def test_logout_without_current_user
    get :destroy
    assert_redirected_to login_path
  end

  def test_should_remember_me
    @request.cookies["auth_token"] = nil
    post :create, :user => { :login => 'quentin', :password => 'monkey', :remember_me_flag => "1" }
    assert_not_nil @response.cookies["auth_token"]
  end

  def test_should_not_remember_me
    @request.cookies["auth_token"] = nil
    post :create, :user => { :email => 'quentin@example.com', :password => 'monkey', :remember_me_flag => "0" }
    assert @response.cookies["auth_token"].blank?
  end
  
  def test_should_delete_token_on_logout
    login_as :quentin
    get :destroy
    assert @response.cookies["auth_token"].blank?
  end

  def test_should_login_with_cookie
    users(:quentin).remember_me
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :new
    assert @controller.send(:logged_in?)
  end

  def test_should_not_login_with_cookie_with_locked_admin_account
    admin = Factory :admin
    @request.cookies["auth_token"] = auth_token(admin.remember_token)
    admin.lock_access!
    get :new
    assert !@controller.send(:logged_in?)
  end

  def test_should_fail_expired_cookie_login
    users(:quentin).remember_me
    users(:quentin).update_attribute :remember_token_expires_at, 5.minutes.ago
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :new
    assert !@controller.send(:logged_in?)
  end

  def test_should_fail_cookie_login
    users(:quentin).remember_me
    @request.cookies["auth_token"] = auth_token('invalid_auth_token')
    get :new
    assert !@controller.send(:logged_in?)
  end
  
  def test_create_for_non_admin_with_session_timeout
    user = users(:guest)
    session_timeout = user.session_timeout
    assert session_timeout > 0, "Fixture should have session timeout"
    crypted_password = user.crypted_password
    login_time = Time.now
    Time.expects(:now).at_least_once.returns(login_time)
    
    post :create, :user => { :login => user.login, :password => 'monkey' }

    user.reload
    assert_equal user.id, session[:user_id], "session :user_id"
    assert_response :redirect
    assert @controller.send(:logged_in?), "logged_in?"
    assert_equal user, @controller.send(:current_user), "current_user"
    assert_equal login_time + session_timeout, session[:time_out_at], "session :time_out_at"
    assert_not_equal crypted_password, user.crypted_password, "Password should change"
  end

  def test_create_for_admin_with_session_timeout
    user = users(:aaron)
    assert user.has_admin_privilege?, "Fixture should have admin"
    user.update_attributes! :session_timeout => 30
    crypted_password = user.crypted_password
    login_time = Time.now
    Time.expects(:now).at_least_once.returns(login_time)
    
    post :create, :user => { :login => user.login, :password => 'monkey' }

    user.reload
    assert_equal user.id, session[:user_id], "session :user_id"
    assert_response :redirect
    assert @controller.send(:logged_in?), "logged_in?"
    assert_equal user, @controller.send(:current_user), "current_user"
    assert_equal login_time + 30, session[:time_out_at], "session :time_out_at"
    assert_equal crypted_password, user.crypted_password, "Password should not change"
  end
  
  def test_new_without_locm_param
    user = User.new(:login => "demo@locm.com", :password => "secret", :password_confirmation => "secret")
    user.company = publishers(:locm)
    user.save!

    get :new
    
    assert_nil session[:user_id], "Session user ID should not be set"
    assert !@controller.send(:logged_in?), "Should not be logged in"
    assert_response :success
    assert_template :new, "Should render login page"
    assert_nil flash[:warn], "Should not warn of failed login"
  end

  def test_new_with_invalid_locm_param
    user = User.new(:login => "username", :password => "secret", :password_confirmation => "secret")
    user.company = publishers(:locm)
    user.save!

    get :new, :param => 'xN6qwqvvk+vPrC83oEh3GJXaWTLuiUVapjA24922UPw='
    
    assert_nil session[:user_id], "Session user ID should not be set"
    assert !@controller.send(:logged_in?), "Should not be logged in"
    assert_response :success
    assert_template "sessions/locm_login_failure", "Should render login-failure page"
    assert flash[:warn].any?, "Should warn about failed login"
  end

  def test_new_with_valid_locm_param_for_publisher_with_self_serve_and_own_advertiser
    publisher = publishers(:locm)
    publisher.update_attributes! :self_serve => true
    advertiser = publisher.advertisers.create!(:listing => "301")
    
    user = User.new(:login => "demo@local.com", :password => "secret", :password_confirmation => "secret")
    user.company = publisher
    user.save!
    #
    # Param decrypts to '3451 Local 7263 demo@local.com 9475 301 6824\000\000\000\000'
    #
    get :new, :param => 'M61wwRms4gDwf/lzqQi8K7vHWG5kxyqF+6I6TlWuvUvrbn0mXcjeBU+aqZf6zOF0'
    
    assert_equal user.id, session[:user_id], "Session user ID should be set"
    assert @controller.send(:logged_in?), "Should be logged in"
    assert_equal user, @controller.send(:current_user), "Current user should be set"
    assert_redirected_to edit_advertiser_path(advertiser), "Should redirected to edit advertiser"
    assert flash[:notice].any?, "Should note successful login"
  end
  
  def test_new_with_valid_locm_param_for_publisher_without_self_serve_and_own_advertiser
    publisher = publishers(:locm)
    advertiser = publisher.advertisers.create!(:listing => "301")
    
    user = User.new(:login => "demo@local.com", :password => "secret", :password_confirmation => "secret")
    user.company = publisher
    user.save!
    #
    # Param decrypts to '3451 Local 7263 demo@local.com 9475 301 6824\000\000\000\000'
    #
    get :new, :param => 'M61wwRms4gDwf/lzqQi8K7vHWG5kxyqF+6I6TlWuvUvrbn0mXcjeBU+aqZf6zOF0'
    
    assert_equal user.id, session[:user_id], "Session user ID should be set"
    assert @controller.send(:logged_in?), "Should be logged in"
    assert_equal user, @controller.send(:current_user), "Current user should be set"
    assert_response :success
    assert_template "sessions/locm_login_failure"
    assert flash[:notice].any?, "Should note failed login"
  end
  
  def test_new_with_valid_locm_param_for_publisher_with_self_serve_and_unknown_advertiser
    publisher = publishers(:locm)
    publisher.update_attributes! :self_serve => true
    advertiser = publisher.advertisers.create!(:listing => "302")
    
    user = User.new(:login => "demo@local.com", :password => "secret", :password_confirmation => "secret")
    user.company = publisher
    user.save!
    #
    # Param decrypts to '3451 Local 7263 demo@local.com 9475 301 6824\000\000\000\000'
    #
    get :new, :param => 'M61wwRms4gDwf/lzqQi8K7vHWG5kxyqF+6I6TlWuvUvrbn0mXcjeBU+aqZf6zOF0'
    
    assert_equal user.id, session[:user_id], "Session user ID should be set"
    assert @controller.send(:logged_in?), "Should be logged in"
    assert_equal user, @controller.send(:current_user), "Current user should be set"
    assert_response :success
    assert_template "sessions/locm_login_failure"
    assert flash[:notice].any?, "Should note successful login"
  end
  
  def test_should_login_and_redirect_with_demo_user
    create_demo_user!
    post :create, :user => { :login => 'quentin', :password => 'monkey' }
    assert_not_nil session[:user_id], "session :user_id"
    assert_equal session[:user_id], users(:quentin).id, "session :user_id"
    assert_response :redirect
    assert @controller.send(:logged_in?), "logged_in?"
    assert_equal users(:quentin), @controller.send(:current_user), "current_user"
  end

  def test_should_fail_login_and_not_redirect_with_demo_user
    create_demo_user!
    post :create, :user => { :login => 'quentin@example.com', :password => 'bad password' }
    assert_nil session[:user_id]
    assert_response :success
  end

  def test_should_logout_with_demo_user
    create_demo_user!
    login_as :quentin
    get :destroy
    assert_nil session[:user_id]
    assert_redirected_to login_path
  end

  context "when on reports.aa.com" do
    setup do
      stub_host_as_reports_server
    end

    should_redirect_to_admin_server_for :new
    should_redirect_to_admin_server_for :destroy
  end

  test "should create for Affiliate" do
    affiliate = Factory(:affiliate)
    
    post :create, :user => { :login => affiliate.login, :password => 'monkey' }

    assert_equal affiliate.id, session[:user_id], "session :user_id"
    assert_response :redirect
    assert @controller.send(:logged_in?), "logged_in?"
    assert_equal affiliate, @controller.send(:current_user), "current_user"
  end
  
  test "create should fail for JSON when API version header is missing" do
    post :create, :format => "json", :user => { :login => 'quentin', :password => 'monkey' }
    assert_response :not_acceptable
    assert_match /api-version/i, @response.body
  end
  
  test "create should fail for JSON when invoked with bad credentials" do
    @request.env['API-Version'] = "2.0.0"    
    post :create, :format => "json", :user => { :login => 'quentin', :password => 'xxxxxx' }
    assert_response :not_found
    assert_nil @controller.send(:current_user)
    assert @response.body.blank?, "Should not have response body content"
  end
  
  test "create should succeed for JSON and return a user session when invoked with good credentials" do
    @request.env['API-Version'] = "2.0.0"    
    post :create, :format => "json", :user => { :login => 'quentin', :password => 'monkey' }
    assert_response :success
    assert_nil @controller.send(:current_user)
    json = JSON.parse(@response.body)
    assert_match /\w+/, json["session"]
    assert_match /https/, json["connections"]["find_daily_deal_certificate"]
  end

  test "create should not fail when cookies are not present for a JSON request" do
    @request.env['API-Version'] = "2.0.0"    
    @controller.expects(:verified_request?).returns(false)
    post :create, :format => "json", :user => { :login => 'quentin', :password => 'monkey' }
    assert_response :success
    assert_nil @controller.send(:current_user)
    json = JSON.parse(@response.body)
    assert_match /\w+/, json["session"]
  end

  context "logging" do
    setup do
      @user = Factory(:user,
                      :login => "john_doe",
                      :password => "secret",
                      :password_confirmation => "secret")
      @now = Time.zone.now
    end

    context "login" do
      setup do
        Timecop.freeze(@now) do
          post :create, :user => {:login => "john_doe", :password => "secret"}
        end
      end

      should "log login" do
        assert_equal 1, @user.user_logs.size
        log = @user.user_logs.first
        assert_equal "login", log.action
        assert_equal @now.to_i, log.created_at.to_i
      end
    end

    context "logout" do
      setup do
        login_as @user
        Timecop.freeze(@now) do
          get :destroy
        end
      end

      should "log logout" do
        assert_equal 1, @user.user_logs.size
        log = @user.user_logs.first
        assert_equal "logout", log.action
        assert_equal @now.to_i, log.created_at.to_i
      end
    end
  end
  
  protected
    def auth_token(token)
      CGI::Cookie.new('name' => 'auth_token', 'value' => token)
    end
    
    def cookie_for(user)
      auth_token users(user).remember_token
    end
end
