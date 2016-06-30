require File.dirname(__FILE__) + "/../test_helper"

class SessionTest < ActionController::IntegrationTest
  def test_admin_login_after_default
    demo_user = create_demo_user!
    
    get publisher_advertisers_path(publishers(:my_space))
    assert_response :success
    assert_equal session[:user_id], demo_user.id, "session :user_id"
    
    get logout_path
    assert_redirected_to login_path
    assert_nil session[:user_id]
    
    post session_path, :user => { :login => "quentin", :password => "monkey" }
    assert_redirected_to root_path
    assert_equal session[:user_id], users(:quentin).id, "session :user_id"

    get publisher_advertisers_path(publishers(:my_space))
    assert_response :success
    assert_equal session[:user_id], users(:quentin).id, "session :user_id"
  end
  
  def test_set_user_current    
    assert_equal nil, User.current
    
    get login_path
    assert_equal nil, User.current
    assert_nil session[:user_id]

    post session_path, :user => { :login => "quentin", :password => "monkey" }
    assert_redirected_to root_path
    assert_equal session[:user_id], users(:quentin).id, "session :user_id"
    assert_equal users(:quentin), User.current
  end
end
