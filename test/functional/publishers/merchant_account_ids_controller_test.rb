require File.dirname(__FILE__) + "/../../test_helper"

class Publishers::MerchantAccountIdsControllerTest < ActionController::TestCase
  test "edit" do
    publisher = Factory(:publisher, :merchant_account_id => "DSA321")
    
    login_as Factory(:admin)

    get :edit, :publisher_id => publisher.to_param

    assert_response :success
    assert_template :edit
    assert_select "input[type=text][name='publisher[merchant_account_id]']", 1
    assert_select "input[type=submit][name='save']", 1
  end

  test "edit should require login" do
    get :edit, :publisher_id => Factory(:publisher).to_param
    assert_redirected_to new_session_path
  end

  test "edit should require admin login" do
    login_as Factory(:user)
    get :edit, :publisher_id => Factory(:publisher).to_param
    assert_redirected_to root_path
  end

  test "update with valid attributes" do
    publisher = Factory(:publisher, :merchant_account_id => "DSA321")
    user = Factory(:admin)
    
    login_as user

    put :update, :publisher_id => publisher.to_param, :publisher => {
      :merchant_account_id => "12345G"
    }

    publisher = assigns(:publisher)
    assert publisher.errors.empty?
    assert_redirected_to edit_publisher_url(publisher)
    assert_equal "Merchant account ID was updated.", flash[:notice]
  end

  test "update with invalid attributes" do
    publisher = Factory(:publisher)

    login_as Factory(:admin)

    # all integers is invalid
    put :update, :publisher_id => publisher.to_param, :publisher => {
      :merchant_account_id => "1234" 
    }

    publisher = assigns(:publisher)
    assert publisher.errors.on(:merchant_account_id)
    assert_template :edit
  end
end
