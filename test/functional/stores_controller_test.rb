require File.dirname(__FILE__) + "/../test_helper"

class StoresControllerTest < ActionController::TestCase
  def test_destroy
    store = stores(:changos)
    xhr :delete, :destroy, :id => store
    assert_response :success
    assert !Store.exists?(store.id), "Should destroy store"
  end
end
