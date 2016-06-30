require File.dirname(__FILE__) + "/../../test_helper"

class Accounting::RevenueSharingAgreementsControllerTest < ActionController::TestCase
  
  fast_context "user without admin or accountant privileges" do
    setup do
      @user = Factory(:user)
      login_as(@user)
      get :index
    end
    
    should "redirect to the login page" do
      assert_redirected_to new_session_path
    end
    
    should "set a flash notice" do
      assert_equal 'Unauthorized access', flash[:notice]
    end
  end
  
  fast_context "user with admin privilege only" do
    setup do
      @user = Factory(:admin)
      login_as(@user)
      get :index
    end
    
    should "redirect to the login page" do
      assert_redirected_to new_session_path
    end
    
    should "set a flash notice" do
      assert_equal 'Unauthorized access', flash[:notice]
    end
  end
  
  fast_context "user with admin and accountant access" do
    setup do
      @user = Factory(:accountant)
      login_as(@user)
      get :index
    end
    
    should "redirect to the index page" do
      assert_response :success
      assert_template :index
      assert_layout :application
    end
    
    should "NOT set a flash notice" do
      assert_nil flash[:notice]
    end
    
  end
  
  fast_context "index" do
    setup do
      @publishing_group = Factory(:publishing_group)
      @user = Factory(:accountant)
      login_as(@user)
      get :index
    end
    
    should "list publishers" do
      assert_response :success
      assert_template :index
      assert @response.body.include?(@publishing_group.name), "Should have publishing group name on page"
    end
  end
  
end