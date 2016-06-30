require File.dirname(__FILE__) + "/../test_helper"

class PublishingGroupUsersControllerTest < ActionController::TestCase
  def test_index
    publishing_group = publishing_groups(:student_discount_handbook)
    assert publishing_group.users.count > 0, "Publishing group fixture should have some users"

    with_admin_user_required(:quentin, :aaron) do
      get :index, :publishing_group_id => publishing_group.to_param
    end
    assert_response :success
    assert_equal publishing_group, assigns(:parent), "@parent assignment"
    assert_equal publishing_group.users, assigns(:users), "@users assignment"
    
    assert_application_page_title "Publishing Group Users"

    assert_select "form[action=#{delete_publishing_group_users_path(publishing_group)}]", 1 do
      assert_select "table", 1 do
        publishing_group.users.each do |user|
          assert_select "tr[id=user_#{user.id}]", 1 do
            assert_select "td.check input[type=checkbox][name='id[]'][value=#{user.id}]"
            assert_select "td.name", user.name
            assert_select "td.email", user.email
            assert_select "td.last a[href=#{edit_publishing_group_user_url(publishing_group, user)}]", 1
          end
        end
      end
      assert_select "input[type=submit]"
    end
  end
  
  def test_new
    publishing_group = publishing_groups(:student_discount_handbook)
    
    with_admin_user_required(:quentin, :aaron) do
      get :new, :publishing_group_id => publishing_group.to_param
    end
    assert_response :success
    assert_equal publishing_group, assigns(:parent), "@parent assignment"
    assert_not_nil assigns(:user), "@user assignment"
    assert assigns(:user).new_record?, "@user should be a new record"
    assert_template :edit, "New should be rendered with edit template"
    assert_select "form.new_user", 1 do
      assert_select "input[type=text][name='user[login]']", 1
      assert_select "input[type=text][name='user[name]']", 1
      assert_select "input[type=text][name='user[email]']", 1
      assert_select "input[type=checkbox][name='user[email_account_setup_instructions]']", 1
      assert_select "input[type=password][name='user[password]']", 1
      assert_select "input[type=password][name='user[password_confirmation]']", 1
      assert_select "input[type=text][name='user[label]']", 1
      assert_select "input[type=text][name='user[session_timeout]']", 1
      assert_select "input[type=checkbox][name='user[allow_syndication_access]']", 1
      assert_select "input[type=checkbox][name='user[allow_offer_syndication_access]']", 1
      assert_select "input[type=checkbox][name='user[can_manage_consumers]']", 1
      assert_select "input[type=submit]", 1
    end
  end

  def test_create
    publishing_group = publishing_groups(:student_discount_handbook)
    publishing_group_2 = PublishingGroup.create!(:name => "New Publishing Group")

    assert_difference 'User.count' do
      with_admin_user_required(:quentin, :aaron) do
        post :create, :publishing_group_id => publishing_group.to_param, :user => {
          :login => "new",
          :name => "New User",
          :email => "new@example.com",
          :password => "secret",
          :password_confirmation => "secret",
          :admin_privilege => User::FULL_ADMIN,
          :company_type => "Publishing_group",
          :company_id => publishing_group_2.to_param
        }
      end
    end
    assert_redirected_to publishing_group_users_path(publishing_group)
    
    user = User.find_by_email("new@example.com")
    assert_not_nil user, "User should have been created with specified email address"
    assert_equal "New User", user.name, "New user should have the specified name"
    assert_equal publishing_group, user.company, "New user should belong to the specified publishing group"
    assert !user.has_admin_privilege?, "New user should not have admin"
  end

  def test_create_with_can_manage_consumers_set_to_true
    publishing_group = Factory(:publishing_group)
    login_as Factory(:admin)
    assert_difference 'User.count' do
      post :create, :publishing_group_id => publishing_group.to_param, :user => {
          :login => "new",
          :name => "New User",
          :email => "new@example.com",
          :password => "secret",
          :password_confirmation => "secret",
          :can_manage_consumers => "1"
      }
    end
    assert_redirected_to publishing_group_users_path(publishing_group)

    user = User.find_by_email("new@example.com")
    assert user.can_manage_consumers?
  end

  def test_edit
    publishing_group = publishing_groups(:student_discount_handbook)
    user = publishing_group.users.first
    assert_not_nil user, "Publishing Group fixture should have some users"
    
    with_admin_user_required(:quentin, :aaron) do
      get :edit, :publishing_group_id => publishing_group.to_param, :id => user.to_param
    end
    assert_response :success
    assert_equal publishing_group, assigns(:parent), "@parent assignment"
    assert_equal user, assigns(:user), "@user assignment"
    
    assert_select "form.edit_user#edit_user_#{user.id}[method=post]", 1 do
      assert_select "input[type=text][name='user[name]'][value='#{user.name}']", 1
      assert_select "input[type=text][name='user[email]'][value='#{user.email}']", 1
      assert_select "input[type=checkbox][name='user[email_account_setup_instructions]']", 0
      assert_select "input[type=password][name='user[password]']", 1
      assert_select "input[type=password][name='user[password_confirmation]']", 1
      assert_select "input[type=text][name='user[label]']", 1
      assert_select "input[type=text][name='user[session_timeout]']", 1
      assert_select "input[type=checkbox][name='user[allow_syndication_access]']", 1
      assert_select "input[type=checkbox][name='user[allow_offer_syndication_access]']", 1
      assert_select "input[type=checkbox][name='user[can_manage_consumers]']", 1
      assert_select "input[type=submit]"
    end
  end

  def test_update
    publishing_group = publishing_groups(:student_discount_handbook)
    user = publishing_group.users.first
    assert_not_nil user, "Publishing Group fixture should have some users"
    publishing_group_2 = PublishingGroup.create!(:name => "New Publishing Group")

    assert_no_difference 'User.count' do
      with_admin_user_required(:quentin, :aaron) do
        put :update, :publishing_group_id => publishing_group.to_param, :id => user.to_param, :user => {
          :name => "New User",
          :email => "new@example.com",
          :password => "secret",
          :password_confirmation => "secret",
          :admin_privilege => User::FULL_ADMIN,
          :company => publishing_group_2.to_param
        }
      end
    end
    assert_redirected_to publishing_group_users_path(publishing_group)
    
    user = User.find_by_email("new@example.com")
    assert_not_nil user, "User should have been updated with specified email address"
    assert_equal "New User", user.name, "User should have the specified name"
    assert_equal publishing_group, user.company, "User should belong to the specified publishing group"
    assert !user.has_admin_privilege?, "User should not have admin"
  end

  def test_delete
    publishing_group = publishing_groups(:student_discount_handbook)
    users = returning([]) do |array|
      2.times do |i|
        array << publishing_group.users.create!({
          :name => "User #{i}", :login => "user#{i}", :password => "secret", :password_confirmation => "secret"
        })
      end
    end
    
    assert_difference 'User.count', -2 do
      with_admin_user_required(:quentin, :aaron) do
        post :delete, :publishing_group_id => publishing_group.to_param, :id => users.map(&:to_param)
      end
    end
    assert_redirected_to publishing_group_users_path(publishing_group)
    
    2.times { |i| assert_nil User.find_by_email("user#{i}@example.com"), "User #{i} should have been deleted" }
  end

  should "not delete api users with external purchases" do
    group = Factory(:publishing_group)
    user = Factory(:user, :company => group)
    api_users = [Factory(:user, :company => group), Factory(:user, :company => group)]
    api_users.each do |api_user|
      opp = Factory(:off_platform_daily_deal_purchase, :api_user => api_user)
      assert_contains OffPlatformDailyDealPurchase.find(:all, :conditions => ["api_user_id = ?", [api_user.id]]), opp
    end

    login_as :aaron

    post :delete, :publishing_group_id => group.to_param, :id => ([user] + api_users).map(&:to_param)

    assert_redirected_to publishing_group_users_path(group)
    api_users.each do |api_user|
      assert_equal api_user, User.find(api_user)
    end
    assert_raise ActiveRecord::RecordNotFound do
      User.find(user)
    end
    assert_match /could not be deleted: #{api_users.map(&:login).join(', ')}/, flash[:error]
  end
end
