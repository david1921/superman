require File.dirname(__FILE__) + "/../../test_helper"

class PublishingGroups::MerchantAccountIdsControllerTest < ActionController::TestCase
  test "edit" do
    pg = Factory(:publishing_group, :merchant_account_id => "DSA321")
    
    login_as Factory(:admin)

    get :edit, :publishing_group_id => pg.to_param

    assert_response :success
    assert_template :edit
    assert_select "input[type=text][name='publishing_group[merchant_account_id]']", 1
    assert_select "input[type=submit][name='save']", 1
  end

  test "edit should require login" do
    get :edit, :publishing_group_id => Factory(:publishing_group).to_param
    assert_redirected_to new_session_path
  end

  test "edit should require admin login" do
    login_as Factory(:user)
    get :edit, :publishing_group_id => Factory(:publishing_group).to_param
    assert_redirected_to root_path
  end
  
  test "update with valid attributes" do
    pg = Factory(:publishing_group, :merchant_account_id => "DSA321")

    login_as Factory(:admin)

    put :update, :publishing_group_id => pg.to_param, :publishing_group => {
      :merchant_account_id => "12345G"
    }

    pg = assigns(:publishing_group)
    assert pg.errors.empty?
    assert_redirected_to edit_publishing_group_url(pg)
    assert_equal "Merchant account ID was updated.", flash[:notice]
  end

  test "update with invalid attributes" do
    pg = Factory(:publishing_group)

    login_as Factory(:admin)

    # all integers is invalid
    put :update, :publishing_group_id => pg.to_param, :publishing_group => {
      :merchant_account_id => "12345"
    }

    pg = assigns(:publishing_group)
    assert pg.errors.on(:merchant_account_id)
    assert_template :edit
  end
end
