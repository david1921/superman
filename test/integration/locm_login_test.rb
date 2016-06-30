require File.dirname(__FILE__) + "/../test_helper"

class LocmLoginTest < ActionController::IntegrationTest
  def setup
    @publisher = publishers(:locm)
    @publisher.update_attributes! :self_serve => true
    @advertiser = @publisher.advertisers.create!(:listing => "301")
    
    @user = create_user_with_company(:login => "demo@local.com", :password => "secret", :password_confirmation => "secret", :company => @publisher)
  end
  
  def test_login_to_home_page_with_good_locm_param
    get_via_redirect "/", { :param => 'M61wwRms4gDwf/lzqQi8K7vHWG5kxyqF+6I6TlWuvUvrbn0mXcjeBU+aqZf6zOF0' }
    assert_response :success
    assert_template "advertisers/edit"
    assert_equal @user.id, session[:user_id], "User should be logged in"
  end

  def test_login_to_home_page_with_good_locm_param_for_unknown_user
    @user.force_destroy
    
    get_via_redirect "/", { :param => 'M61wwRms4gDwf/lzqQi8K7vHWG5kxyqF+6I6TlWuvUvrbn0mXcjeBU+aqZf6zOF0' }
    assert_response :success
    assert_template "sessions/locm_login_failure"
    assert_nil session[:user_id], "User should not be logged in"
  end

  def test_login_to_home_page_with_bad_locm_param
    get_via_redirect "/", { :param => 'x61wwRms4gDwf/lzqQi8K7vHWG5kxyqF+6I6TlWuvUvrbn0mXcjeBU+aqZf6zOF0' }
    assert_response :success
    assert_template "sessions/locm_login_failure"
    assert_nil session[:user_id], "User should not be logged in"
  end

  def test_login_to_home_page_without_locm_param
    get_via_redirect "/"
    assert_response :success
    assert_template "sessions/new"
    assert_nil session[:user_id], "User should not be logged in"
  end

  def test_multiple_visits_to_home_page_with_good_locm_params
    get_via_redirect "/", { :param => 'M61wwRms4gDwf/lzqQi8K7vHWG5kxyqF+6I6TlWuvUvrbn0mXcjeBU+aqZf6zOF0' }
    assert_response :success
    assert_template "advertisers/edit"
    assert_equal @user.id, session[:user_id], "User should be logged in"
    
    get_via_redirect "publishers/#{@publisher.to_param}/advertisers"
    assert_response :success
    assert_template "advertisers/index"

    get_via_redirect "/", { :param => '+Z3WeIcn7+pCqLqaLHv5RbvHWG5kxyqFzD0U4VTxcplQDxK+pabMxPttJ6uaFjOx' }
    assert_response :success
    assert_template "advertisers/edit"
    assert_equal @user.id, session[:user_id], "User should be logged in"
  end
end
