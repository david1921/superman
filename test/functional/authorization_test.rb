require File.dirname(__FILE__) + "/../test_helper"

class AuthorizationTest < ActionController::TestCase
  tests AdvertisersController
  
  def test_helper_methods
    get :index
    assert !@controller.send(:admin?), "admin?"
    assert !@controller.send(:publishing_group?), "publishing_group?"
    assert !@controller.send(:publisher?), "publisher?"
    assert !@controller.send(:advertiser?), "advertiser?"
  end
end
