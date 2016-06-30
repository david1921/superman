require File.dirname(__FILE__) + "/../test_helper"

class PasswordResetsControllerTest < ActionController::TestCase
  def test_edit
    user = advertisers(:changos).users.create!(:login => "joe@doe.com", :password => "secret", :password_confirmation => "secret")

    put :edit, :id => user.perishable_token
    
    assert_response :success
    assert_template :edit
    assert_select "form[action=#{password_reset_path(user.perishable_token)}]", 1 do
      assert_select "input[type=hidden][name=_method][value=put]", 1
      assert_select "input[type=password][name='user[password]']", 1
      assert_select "input[type=password][name='user[password_confirmation]']", 1
      assert_select "input[type=submit]", 1
    end
  end

  def test_edit_with_bad_perishable_token
    put :edit, :id => "x" * 16
    
    assert_redirected_to root_path
    assert_nil assigns(:user), "Should not have a @user assignment"
    assert_match /could not locate your account/, flash[:notice]
  end
  
  def test_update
    user = advertisers(:changos).users.create!(:login => "joe@doe.com", :password => "secret", :password_confirmation => "secret")
    crypted_password = user.crypted_password
    
    put :update, :id => user.perishable_token, :user => { :password => "changed", :password_confirmation => "changed" }
    
    assert_redirected_to root_path
    assert_not_equal crypted_password, user.reload.crypted_password, "Password should have changed"
  end
  
  def test_update_with_bad_perishable_token
    put :update, :id => "x" * 16, :user => { :password => "changed", :password_confirmation => "changed" }
    
    assert_redirected_to root_path
    assert_nil assigns(:user), "Should not have a @user assignment"
    assert_match /could not locate your account/, flash[:notice]
  end
  
  def test_update_disallows_blank_password
    user = advertisers(:changos).users.create!(:login => "joe@doe.com", :password => "secret", :password_confirmation => "secret")
    crypted_password = user.crypted_password
    
    put :update, :id => user.perishable_token, :user => { :password => " ", :password_confirmation => " " }
    
    assert_response :success
    assert_template :edit
    assert_not_nil assigns(:user), "Should have a @user assignment"
    assert assigns(:user).errors.on(:password), "Should have a passowrd error"
    assert_equal crypted_password, user.reload.crypted_password, "Password should not have changed"
  end

  context "new" do
    setup do
      get :new
    end

    should "render new template" do
      assert_template :new
    end
  end

  context "create" do
    setup do
      @user = Factory(:user, :email => "foo.bar@example.com")
    end

    context "given no email address" do
      setup do
        post :create, :email => ""
      end

      should "show a warning flash message" do
        assert_equal "Please provide an email address.", flash[:warn]
      end

      should "render new template" do
        assert_template :new
      end
    end

    context "given an invalid email address" do
      setup do
        post :create, :email => "not.an.email.net"
      end

      should "show a warning flash message" do
        assert_equal "The provided email address was invalid.", flash[:warn]
      end

      should "render new template" do
        assert_template :new
      end
    end

    context "given an valid email address that doesn't exist" do
      setup do
        post :create, :email => "does.not.exist@example.com"
      end

      should "show a warning flash message" do
        assert_equal "Sorry, no user was found with the provided email address.", flash[:warn]
      end

      should "render new template" do
        assert_template :new
      end
    end

    context "given the email of an unlocked user" do
      setup do
        @user.unlock_access!
        ActionMailer::Base.deliveries.clear
        post :create, :email => "foo.bar@example.com"
      end

      should "render create template" do
        assert_template :create
      end

      should "send password reset instructions" do
        assert_equal 1, ActionMailer::Base.deliveries.size
      end

      should "set perishable token" do
        assert_not_nil @user.reload.perishable_token
      end
    end

    context "given the email of a locked user" do
      setup do
        @user.lock_access!
        post :create, :email => "foo.bar@example.com"
      end

      should "show a warning flash message" do
        assert_equal "Sorry, that account is locked.  Please contact an administrator.", flash[:warn]
      end

      should "render new template" do
        assert_template :new
      end
    end
  end
end

