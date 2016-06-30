require File.dirname(__FILE__) + "/../test_helper"

class AdminsControllerTest < ActionController::TestCase
  
  def test_index
    admins = User.all.select(&:has_full_admin_privileges?)
    assert admins.size > 0, "Some User fixtures should have admin"
    
    with_admin_user_required(:quentin, :aaron) do
      get :index
    end
    assert_response :success
    assert_equal admins, assigns(:users), "@users assignment"
    
    assert_application_page_title "Admins"

    assert_select "form[action=#{delete_admins_path}]", 1 do
      assert_select "table", 1 do
        admins.each do |admin|
          assert_select "tr[id=user_#{admin.id}]", 1 do
            assert_select "td.check input[type=checkbox][name='id[]'][value=#{admin.id}]"
            assert_select "td.name", admin.name
            assert_select "td.email", admin.login
            assert_select "td.last a[href=#{edit_admin_path(admin)}]", 1
          end
        end
      end
      assert_select "input[type=submit]"
    end
  end
  
  def test_new
    with_admin_user_required(:quentin, :aaron) do
      get :new
    end
    assert_response :success
    assert_not_nil assigns(:user), "@user assignment"
    assert assigns(:user).new_record?, "@user should be a new record"
    assert_template :edit, "New should be rendered with edit template"
    assert_select "form.new_user", 1 do
      assert_select "input[type=text][name='user[login]']", 1
      assert_select "input[type=text][name='user[name]']", 1
      assert_select "input[type=text][name='user[email]']", 1
      assert_select "input[type=checkbox][name='user[email_account_setup_instructions]']", 0
      assert_select "input[type=password][name='user[password]']", 1
      assert_select "input[type=password][name='user[password_confirmation]']", 1
      assert_select "input[type=submit]", 1
    end
  end

  def test_create
    assert_difference 'User.count' do
      with_admin_user_required(:quentin, :aaron) do
        post :create, :user => {
          :login => "new",
          :name => "New User",
          :email => "new@example.com",
          :password => "secret",
          :password_confirmation => "secret",
          :admin_privilege => User::FULL_ADMIN
        }
      end
    end
    assert_redirected_to admins_path
    
    user = User.find_by_email("new@example.com")
    assert_not_nil user, "User should have been created with specified email address"
    assert_equal "New User", user.name, "New user should have the specified name"
    assert_nil user.company, "New user should not belong to any company"
    assert user.has_full_admin_privileges?, "New user should have admin"
  end

  def test_create_does_not_assign_a_company
    assert_difference 'User.count' do
      with_admin_user_required(:quentin, :aaron) do
        post :create, :user => {
          :login => "new",
          :name => "New User",
          :email => "new@example.com",
          :password => "secret",
          :password_confirmation => "secret",
          :company_type => "Publisher",
          :company_id => publishers(:gvnews).to_param
        }
      end
    end
    assert_redirected_to admins_path

    user = User.find_by_email("new@example.com")
    assert_not_nil user, "User should have been created with specified email address"
    assert_nil user.company, "New user should not belong to any company"
  end
  
  def test_edit
    user = User.all.select(&:has_full_admin_privileges?).first
    assert_not_nil user, "Some User fixtures should have admin"
    
    with_admin_user_required(:quentin, :aaron) do
      get :edit, :id => user.to_param
    end
    assert_response :success
    assert_equal user, assigns(:user), "@user assignment"
    
    assert_select "form.edit_user#edit_user_#{user.id}[method=post]", 1 do
      assert_select "input[type=text][name='user[name]'][value='#{user.name}']", 1
      assert_select "input[type=text][name='user[email]'][value='#{user.email}']", 1
      assert_select "input[type=checkbox][name='user[email_account_setup_instructions]']", 0
      assert_select "input[type=password][name='user[password]']", 1
      assert_select "input[type=password][name='user[password_confirmation]']", 1
      assert_select "input[type=submit]"
    end
  end

  def test_update
    user = User.all.select(&:has_full_admin_privileges?).first
    assert_not_nil user, "Some User fixtures should have admin"
    
    assert_no_difference 'User.count' do
      with_admin_user_required(:quentin, :aaron) do
        put :update, :id => user.to_param, :user => {
          :name => "New User",
          :email => "new@example.com",
          :password => "secret",
          :password_confirmation => "secret"
        }
      end
    end
    assert_redirected_to admins_path
    
    user = User.find_by_email("new@example.com")
    assert_not_nil user, "User should have been updated with specified email address"
    assert_equal "New User", user.name, "User should have the specified name"
    assert_nil user.company, "New user should not belong to any company"
    assert user.has_full_admin_privileges?, "User should still have admin"
  end

  def test_update_does_not_remove_admin
    user = User.all.select(&:has_full_admin_privileges?).first
    assert_not_nil user, "Some User fixtures should have admin"
    
    assert_no_difference 'User.count' do
      with_admin_user_required(:quentin, :aaron) do
        put :update, :id => user.to_param, :user => {
          :name => "New User",
          :email => "new@example.com",
          :password => "secret",
          :password_confirmation => "secret",
          :admin_privilege => ""
        }
      end
    end
    assert_redirected_to admins_path
    
    user = User.find_by_email("new@example.com")
    assert_not_nil user, "User should have been updated with specified email address"
    assert_nil user.company, "New user should not belong to any company"
    assert user.has_full_admin_privileges?, "User should still have admin"
  end

  def test_update_does_not_set_company
    user = User.all.select(&:has_full_admin_privileges?).first
    assert_not_nil user, "Some User fixtures should have admin"
    
    assert_no_difference 'User.count' do
      with_admin_user_required(:quentin, :aaron) do
        put :update, :id => user.to_param, :user => {
          :name => "New User",
          :email => "new@example.com",
          :password => "secret",
          :password_confirmation => "secret",
          :company_type => "Publisher",
          :company_id => publishers(:gvnews).to_param
        }
      end
    end
    assert_redirected_to admins_path
    
    user = User.find_by_email("new@example.com")
    assert_not_nil user, "User should have been updated with specified email address"
    assert_nil user.company, "New user should not belong to any company"
    assert user.has_full_admin_privileges?, "User should still have admin"
  end

  def test_delete
    users = returning([]) do |array|
      2.times do |i|
        admin = User.new({
          :login => "admin#{i}",
          :name => "Admin #{i}",
          :email => "admin#{i}@example.com",
          :password => "secret",
          :password_confirmation => "secret",
        })
        admin.admin_privilege = User::FULL_ADMIN
        admin.save!
        array << admin
      end
    end

    assert_difference 'User.count', -2 do
      with_admin_user_required(:quentin, :aaron) do
        post :delete, :id => users.map(&:to_param)
      end
    end
    assert_redirected_to admins_path
    
    2.times { |i| assert_nil User.find_by_email("admin#{i}@example.com"), "Admin #{i} should have been deleted" }
  end

  def test_show_non_admin
    user = users(:guest)
    with_admin_user_required(:quentin, :aaron) do
      get :show, :id => user.to_param
    end
    assert_response :success
    assert_equal user, assigns(:user)
    assert_select "form[action=#{randomize_password_admin_path(user)}][method=post]", true do
      assert_select "p.email", "guest@example.com"
      assert_select "p.password", 0
      assert_select "input[type=submit]"
    end
  end
  
  def test_show_admin
    user = users(:aaron)
    assert user.has_full_admin_privileges?, "Fixture should have admin"
    with_admin_user_required(:quentin, :aaron) do
      get :show, :id => user.to_param
    end
    assert_response :success
    assert_equal user, assigns(:user)
    assert_match /not allowed/i, flash[:warn]
    assert_select "input[type=submit]", false
  end
  
  def test_randomize_password_non_admin
    user = users(:guest)
    with_admin_user_required(:quentin, :aaron) do
      put :randomize_password, :id => user.to_param
    end
    assert_response :success
    assert_equal user, assigns(:user)
    assert_template :show
    assert_select "form[action=#{randomize_password_admin_path(user)}][method=post]", true do
      assert_select "p.email", "guest@example.com"
      assert_select "p.password", /^[a-z0-9]{6}$/
      assert_select "input[type=submit]"
    end
  end
  
  def test_randomize_password_admin
    user = users(:aaron)
    assert user.has_full_admin_privileges?, "Fixture should have admin"
    
    with_admin_user_required(:quentin, :aaron) do
      put :randomize_password, :id => user.to_param
    end
    assert_response :success
    assert_equal user, assigns(:user)
    assert_template :show
    assert_match /not allowed/i, flash[:warn]
    assert_select "input[type=submit]", false
  end
end
