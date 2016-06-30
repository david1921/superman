require File.dirname(__FILE__) + "/../test_helper"

class SessionTimeoutTest < ActionController::IntegrationTest
  def test_non_admin_having_session_timeout
    publisher = publishers(:my_space)

    get reports_publisher_advertisers_path(publisher)
    assert_redirected_to new_session_path

    user = User.new(
      :login => "guest2",
      :email => "guest@analoganalytics.com",
      :name => "Guest",
      :password => "secret",
      :password_confirmation => "secret",
      :session_timeout => 300
    )
    user.company = publisher
    user.save!

    login_time = Time.now
    crypted_password = user.crypted_password
    Time.expects(:now).at_least_once.returns(login_time)
    #
    # Log in as non-admin user
    #
    post session_path, :user => { :login => user.login, :password => "secret", :remember_me_tag => true }
    assert_redirected_to reports_publisher_advertisers_path(publisher)
    assert_equal user.id, session[:user_id], "session :user_id"
    assert_equal login_time + 300, session[:time_out_at], "session :time_out_at"
    assert_not_equal crypted_password, user.reload.crypted_password, "user.crypted_password"
    #
    # Get reports page again at 299 seconds
    #
    Time.expects(:now).at_least_once.returns(login_time + 299)
    
    get reports_publisher_advertisers_path(publisher)
    assert_response :success
    assert_equal session[:user_id], user.id, "session :user_id"
    assert_equal login_time + 300, session[:time_out_at], "session :time_out_at"
    #
    # Get reports page again at 300 seconds (fails)
    #
    Time.expects(:now).at_least_once.returns(login_time + 300)
    
    get reports_publisher_advertisers_path(publisher)
    assert_redirected_to new_session_path

    assert_nil session[:user_id], "session :user_id"
    assert_equal login_time + 300, session[:time_out_at], "session :time_out_at"
    #
    # Try to log in again with original password (fails)
    #
    post session_path, :user => { :login => user.login, :password => "secret", :remember_me_tag => true }
    assert_response :success
    assert_nil session[:user_id], "session :user_id"
    assert_equal login_time + 300, session[:time_out_at], "session :time_out_at"
  end

  def test_admin_having_session_timeout
    #
    # Users page requires admin login
    #
    get admins_path
    assert_redirected_to new_session_path

    user = User.new(
      :login => "admin",
      :email => "admin@analoganalytics.com",
      :name => "Admin",
      :password => "secret",
      :password_confirmation => "secret",
      :session_timeout => 300
    )
    user.admin_privilege = User::FULL_ADMIN
    user.save!
    
    login_time = Time.now
    crypted_password = user.crypted_password
    Time.expects(:now).at_least_once.returns(login_time)
    #
    # Log in as admin
    #
    post session_path, :user => { :login => user.login, :password => "secret", :remember_me_tag => true }
    assert_redirected_to admins_path
    assert_equal user.id, session[:user_id], "session :user_id"
    assert_equal login_time + 300, session[:time_out_at], "session :time_out_at"
    assert_equal crypted_password, user.reload.crypted_password, "user.crypted_password"
    #
    # Get users page again at 299 seconds
    #
    Time.expects(:now).at_least_once.returns(login_time + 299)
    
    get admins_path
    assert_response :success
    assert_equal session[:user_id], user.id, "session :user_id"
    assert_equal login_time + 300, session[:time_out_at], "session :time_out_at"
    #
    # Get users page again at 300 seconds (succeeds)
    #
    Time.expects(:now).at_least_once.returns(login_time + 300)
    
    get admins_path
    assert_response :success
    assert_equal session[:user_id], user.id, "session :user_id"
    assert_equal login_time + 300, session[:time_out_at], "session :time_out_at"
    #
    # Get users page again at 600 seconds (succeeds)
    #
    Time.expects(:now).at_least_once.returns(login_time + 600)
    
    get admins_path
    assert_response :success
    assert_equal session[:user_id], user.id, "session :user_id"
    assert_equal login_time + 300, session[:time_out_at], "session :time_out_at"
    #
    # Log out
    #
    Time.expects(:now).at_least_once.returns(login_time + 630)

    get logout_path
    assert_redirected_to login_path
    assert_nil session[:user_id]    
    #
    # Log in again with original password
    #
    login_time = login_time + 700
    Time.expects(:now).at_least_once.returns(login_time)
    
    post session_path, :user => { :login => user.login, :password => "secret", :remember_me_tag => true }
    assert_redirected_to root_path
    assert_equal user.id, session[:user_id], "session :user_id"
    assert_equal login_time + 300, session[:time_out_at], "session :time_out_at"
    assert_equal crypted_password, user.reload.crypted_password, "user.crypted_password"  end
end
