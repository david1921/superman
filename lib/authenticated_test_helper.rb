module AuthenticatedTestHelper
  def login_as(user)
    user = users(user) unless !user || user.is_a?(User)
    @request.session[:user_id] = user.id || nil
    @request.session[:active_session_token] = user.active_session_token
    User.current = user
  end

  def with_user_required(user, options={})
    @controller = nil
    setup_controller_request_and_response
    yield
    if options[:format] == :xml
      assert_response :unauthorized, "Should attempt HTTP authentication"
    else
      assert_redirected_to new_session_path, "Login should be required"
    end

    @controller = nil
    setup_controller_request_and_response
    login_as user
    yield
  end

  def with_admin_user_required(user_lacking_admin, user_having_admin, options={})
    @controller = nil
    setup_controller_request_and_response
    yield
    if options[:format] == :xml
      assert_response :unauthorized, "Should attempt HTTP authentication"
    else
      assert_redirected_to new_session_path, "Login should be required"
    end

    @controller = nil
    setup_controller_request_and_response
    assert !users(user_lacking_admin).has_admin_privilege?, "User fixture :#{user_lacking_admin} should not have admin"
    login_as user_lacking_admin
    yield
    if options[:format] == :xml
      assert_response :forbidden, "Should not allow non-admin access"
      assert @response.body.blank?
    else
      assert_redirected_to root_path, "Non-admin user should be redirected to root"
      assert_equal "Unauthorized access", flash[:notice]
    end

    @controller = nil
    setup_controller_request_and_response
    assert users(user_having_admin).has_admin_privilege?, "User fixture :#{user_having_admin} should have admin"
    login_as user_having_admin
    yield
  end

  def authorize_as(user)
    @request.env["HTTP_AUTHORIZATION"] = user ? ActionController::HttpAuthentication::Basic.encode_credentials(users(user).email, 'monkey') : nil
  end

  def with_consumer_login_required(consumer)
    @controller = nil
    setup_controller_request_and_response
    yield
    assert_redirected_to new_publisher_daily_deal_session_path(consumer.publisher), "Login should be required"

    @controller = nil
    setup_controller_request_and_response
    login_as consumer
    yield
  end

  def set_http_basic_authentication(options)
    @request.env['HTTP_AUTHORIZATION'] = 'Basic ' + Base64::encode64("#{options[:name]}:#{options[:pass]}")
  end
end
