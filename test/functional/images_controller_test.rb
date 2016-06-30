require File.dirname(__FILE__) + "/../test_helper"

class ImagesControllerTest < ActionController::TestCase
  def test_index_for_anonymous
    get :index, :publisher_id => publishers(:houston_press)
    assert_redirected_to new_session_path
  end
  
  def test_index_for_admin
    login_as :aaron
    get :index, :publisher_id => publishers(:houston_press)
    assert_response :success
  end
  
  def test_index_for_publisher
    login_as :robert
    get :index, :publisher_id => publishers(:houston_press)
    assert_response :success
  end
  
  def test_index_for_advertiser
    login_as :zorba
    get :index, :publisher_id => publishers(:houston_press)
    assert_redirected_to new_session_path
  end
end
