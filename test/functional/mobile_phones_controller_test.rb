require File.dirname(__FILE__) + "/../test_helper"

class MobilePhonesControllerTest < ActionController::TestCase
  def test_new
    get(:new)
    assert_response(:success)
    assert_template("new")
    assert(assigns(:mobile_phone), "@mobile_phone")
    assert_layout("txt411/application")
  end
  
  def test_create
    assert !MobilePhone.number_opted_out?("11821269181")
    
    post :create, :mobile_phone => { :number => "(182) 126-9181" }
    assert_response :redirect
    assert_not_nil (mobile_phone = MobilePhone.find_by_number("11821269181"))
    assert_redirected_to opt_out_path(mobile_phone)

    assert MobilePhone.number_opted_out?("11821269181"), "Number should be opted out after create"
  end
  
  def test_invalid_create
    assert_no_difference 'MobilePhone.count' do
      post :create, :mobile_phone => { :number => "(182) XX-2126918181181" }
      assert_response :success
      assert_not_nil assigns(:mobile_phone), "@mobile_phone"
    end
  end
  
  def test_show
    get(:show, :id => mobile_phones(:scott).to_param)
    assert(assigns(:mobile_phone), "@mobile_phone")
    assert_response(:success)
    assert_layout("txt411/application")
  end
end
