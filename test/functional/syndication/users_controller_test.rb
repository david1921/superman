require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::UsersControllerTest

class Syndication::UsersControllerTest < ActionController::TestCase     
  
  context "login" do
    
    context "with no authenticated account" do
      setup do
        get :edit
      end
      should redirect_to( "syndication login path" ) { syndication_login_path }
    end
    
    context "with user that is not self serve" do
      setup do
        @user = Factory(:user, :allow_syndication_access => true)
        login_as @user
        get :edit, :id => @user.id
      end
      should "not be self serve" do
        assert !@user.self_serve?
      end
      should redirect_to( "syndication login path" ) { syndication_login_path }
    end
    
    context "with user that is self serve" do
      setup do
        @publisher = Factory(:publisher, :self_serve => true)
        @user = Factory(:user, :company => @publisher, :allow_syndication_access => true)
        login_as @user
        get :edit, :id => @user.id
      end
      should "be a self serve user" do
        assert @user.self_serve?
      end
      should respond_with(:success)
      should render_template(:edit)
      should render_with_layout(:syndication)
    end
    
  end
  
  context "edit" do
    setup do
      @publisher = Factory(:publisher, :self_serve => true)
      @user = Factory(:user, :company => @publisher, :allow_syndication_access => true)
      login_as @user
      get :edit, :id => @user.id
    end
    
    should assign_to(:user)
    should respond_with(:success)
    should render_template(:edit)
    should render_with_layout(:syndication)
    should_not set_the_flash
    
    should "render correct context" do
      assert_select "#site_nav" do
        assert_select "li:nth-child(1)" do
          assert_select "a[href='#{list_syndication_deals_path}']", :text => I18n.t('browse_deals')
        end
        assert_select "li.current:nth-child(2)" do
          assert_select "a[href='#{edit_syndication_user_path(@user.id)}']", :text => I18n.t('my_account')
        end
        assert_select "li:nth-child(3)" do
          assert_select "a[href='#{syndication_logout_path}']", :text => I18n.t('logout')
        end
      end
    end
    should "render login in disabled text field" do
      assert_select "input[id='user_login'][disabled='disabled'][value='#{@user.login}']"
    end
    should "display instruction message" do
      assert_select "p", :text => "To change your password, enter your new password below and click \"Change\"."
    end

  end
  
  context "update" do
    setup do
      @publisher = Factory(:publisher, :self_serve => true)
      @user = Factory(:user, :company => @publisher, :allow_syndication_access => true)
      login_as @user
    end
    
    should "not allow blank password" do
      original_crypted_password = @user.crypted_password
      post :update, :id => @user.to_param, :user => { :password => '',
                                                      :password_confirmation => '' }
      assert_select "div[id='errorExplanation']", :count => 1
      assert_equal original_crypted_password, @user.reload.crypted_password, "Password should not have been updated"
      assert_equal "Could not update login information.", flash[:error]
    end
    
    should "change password" do
      original_crypted_password = @user.crypted_password
      post :update, :id => @user.to_param, :user => { :password => 'new_password',
                                                      :password_confirmation => 'new_password' }
      assert_select "div[id='errorExplanation']", :count => 0
      assert_not_equal original_crypted_password, @user.reload.crypted_password, "Password should have been updated"
      assert_equal "Updated login information.", flash[:notice]
    end
    
    should "change address" do
      uk_country = Country.find_by_code("uk")
      post :update, :id => @user.to_param, :publisher => { :address_line_1 => "296 Farnborough Road",
                                                           :address_line_2 => "Suite 1",
                                                           :city => "Farnborough",
                                                           :region => "Hants",
                                                           :zip => "GU14 7NU",
                                                           :country_id => uk_country.id }
      assert_select "div[id='errorExplanation']", :count => 0
      assert_equal "296 Farnborough Road", @publisher.reload.address_line_1
      assert_equal "Suite 1", @publisher.address_line_2
      assert_equal "Farnborough", @publisher.city
      assert_equal "Hants", @publisher.region
      assert_equal "GU14 7NU", @publisher.zip
      assert_equal "UK", @publisher.country.code
      assert_equal "Updated contact information.", flash[:notice]
    end
  end
end
