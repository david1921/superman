require File.dirname(__FILE__) + "/../test_helper"

class AdvertiserUsersControllerTest < ActionController::TestCase
  setup :setup_advertiser_and_publisher
  
  def setup_advertiser_and_publisher
    @advertiser = advertisers(:changos)
    @publisher = @advertiser.publisher
  end
  
  def test_index
    check_result = lambda do |description|
      assert_response :success
      assert_equal @advertiser, assigns(:parent), "@parent assignment as #{description}"
      assert_equal @advertiser.users, assigns(:users), "@users assignment as #{description}"
    end
    with_login_managing_publisher_required(@publisher, check_result) do
      get :index, 'advertiser_id' => @advertiser.to_param
    end
  end
  
  def test_new
    check_result = lambda do |description|
      assert_response :success
      assert_equal @advertiser, assigns(:parent), "@parent assignment as #{description}"
      assert_not_nil assigns(:user), "@user assignment #{description}"
      assert assigns(:user).new_record?, "@user should be a new record as #{description}"
      assert_template :edit, "New should be rendered with edit template as #{description}"
      assert_select "form.new_user", 1 do
        assert_select "input[type=text][name='user[login]']", 1
        assert_select "input[type=text][name='user[name]']", 1
        assert_select "input[type=text][name='user[email]']", 1
        assert_select "input[type=checkbox][name='user[email_account_setup_instructions]']", 1
        assert_select "input[type=password][name='user[password]']", 1
        assert_select "input[type=password][name='user[password_confirmation]']", 1
        assert_select "input[type=submit]", 1
      end
    end
    with_login_managing_publisher_required(@publisher, check_result) do
      get :new, 'advertiser_id' => @advertiser.to_param
    end
  end
  
  def test_create
    check_result = lambda do |description|
      assert_redirected_to advertiser_users_path(@advertiser)
      user = User.find_by_email("new@example.com")
      assert_not_nil user, "User created by #{description} should exist with the specified email address"
      assert_equal "New User", user.name, "User created by #{description} should have the specified name"
      assert_equal @advertiser, user.company, "User created by #{description} should belong to the specified advertiser"
      assert !user.has_admin_privilege?, "User created by #{description} should not have admin"
    end
    
    with_login_managing_publisher_required(@publisher, check_result) do
      User.find_all_by_email("new@example.com").map &:force_destroy
      post :create, :advertiser_id => @advertiser.to_param, :user => {
        :login => "new",
        :name => "New User",
        :email => "new@example.com",
        :password => "secret",
        :password_confirmation => "secret",
        :admin_privilege => User::FULL_ADMIN,
        :company_type => "Publisher",
        :company_id => publishers(:gvnews).to_param
      }
    end
  end
  

  def test_create_as_publisher_user_sends_notification_email
    @publisher.update_attributes! :self_serve => true
    user = @publisher.users.first
    assert_not_nil user, "Publisher fixture should have a user"
    ActionMailer::Base.deliveries.clear
  
    with_user_required(user) do
      post :create, :advertiser_id => @advertiser.to_param, :user => {
        :login => "new@example.com",
        :email => "new@example.com",
        :name => "New User",
        :email_account_setup_instructions => "1"
      }
    end
    assert_redirected_to advertiser_users_path(@advertiser)
    user = User.find_by_email("new@example.com")
    assert_not_nil user, "Should create a new user"
    assert_equal "New User", user.name
    assert_equal @advertiser, user.company
    assert_equal "new@example.com", user.login
    
  end
  
  def test_edit
    assert_not_nil user = @advertiser.users.first, "Advertiser should have a user"
      
    check_result = lambda do |description|
      assert_response :success
      assert_equal @advertiser, assigns(:parent), "@parent assignment as #{description}"
      assert_equal user, assigns(:user), "@user assignment #{description}"
      assert_select "form.edit_user", 1 do
        assert_select "input[type=text][name='user[login]']", 1
        assert_select "input[type=text][name='user[name]']", 1
        assert_select "input[type=text][name='user[email]']", 1
        assert_select "input[type=checkbox][name='user[email_account_setup_instructions]']", 0
        assert_select "input[type=password][name='user[password]']", 1
        assert_select "input[type=password][name='user[password_confirmation]']", 1
        assert_select "input[type=submit]", 1
      end
    end
    
    with_login_managing_publisher_required(@publisher, check_result) do
      get :edit, :advertiser_id => @advertiser.to_param, :id => user.to_param
    end
  end
  
  def test_update
    assert_not_nil user = @advertiser.users.first, "Advertiser should have a user"
      
    check_result = lambda do |description|
      assert_redirected_to advertiser_users_path(@advertiser)
      assert flash[:notice].any?, "Should have flash as #{description}"
      user = User.find_by_email("new@example.com")
      assert_not_nil user, "User updated as #{description} should have been updated with specified email address"
      assert_equal "New User", user.name, "User updated as #{description} should have the specified name"
      assert_equal @advertiser, user.company, "User updated as #{description} should belong to the specified publisher"
      assert !user.has_admin_privilege?, "User updated as #{description} should not have admin"
    end
    
    with_login_managing_publisher_required(@publisher, check_result) do
      user.update_attributes! :name => "Old User", :email => "old@example.com"
      put :update, :advertiser_id => @advertiser.to_param, :id => user.to_param, :user => {
        :name => "New User",
        :email => "new@example.com",
        :password => "secret",
        :password_confirmation => "secret",
        :admin_privilege => User::FULL_ADMIN,
        :company_type => "Publisher",
        :company_id => publishers(:gvnews).to_param
      }
    end
  end
  
  def test_delete
    original_users = @advertiser.users.sort
    
    check_result = lambda do |description|
      assert_redirected_to advertiser_users_path(@advertiser)
      assert flash[:notice].any?, "Should have flash as #{description}"
      assert_equal Set.new(original_users), Set.new(@advertiser.users(true)), "Users should have been deleted as #{description}"
    end

    with_login_managing_publisher_required(@publisher, check_result) do
      2.times do
        @advertiser.users.create!({
          :login => "user#{rand(10**9)}",
          :password => "secret",
          :password_confirmation => "secret",
          :name => 'Test User'
        })
      end
      users_to_delete = @advertiser.users(true).reject { |user| original_users.include?(user) }
      assert !users_to_delete.empty?, "Should have some users to delete"
      post :delete, 'advertiser_id' => @advertiser.to_param, 'id' => users_to_delete.map(&:id)
    end
  end
end
