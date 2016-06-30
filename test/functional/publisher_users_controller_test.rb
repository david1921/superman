require File.dirname(__FILE__) + "/../test_helper"

class PublisherUsersControllerTest < ActionController::TestCase
  def test_index
    publisher = publishers(:gvnews)
    assert publisher.users.count > 0, "Publisher fixture should have some users"
    
    with_admin_user_required(:quentin, :aaron) do
      get :index, :publisher_id => publisher.to_param
    end
    assert_response :success
    assert_equal publisher, assigns(:parent), "@parent assignment"
    assert_equal publisher.users, assigns(:users), "@users assignment"
    
    assert_application_page_title "Publisher Users"

    assert_select "form[action=#{delete_publisher_users_path(publisher)}]", 1 do
      assert_select "table", 1 do
        publisher.users.each do |user|
          assert_select "tr[id=user_#{user.id}]", 1 do
            assert_select "td.check input[type=checkbox][name='id[]'][value=#{user.id}]"
            assert_select "td.name", user.name
            assert_select "td.email", user.email
            assert_select "td.last a[href=#{edit_publisher_user_url(publisher, user)}]", 1
          end
        end
      end
      assert_select "input[type=submit]"
    end
  end
  
  def test_new
    publisher = publishers(:gvnews)
    
    with_admin_user_required(:quentin, :aaron) do
      get :new, :publisher_id => publisher.to_param
    end
    assert_response :success
    assert_equal publisher, assigns(:parent), "@parent assignment"
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
      assert_select "input[type=submit]", 1
      assert_select "input[type=checkbox][name='user[allow_syndication_access]']", 1
      assert_select "input[type=checkbox][name='user[allow_offer_syndication_access]']", 1
      assert_select "input[type=checkbox][name='user[can_manage_consumers]']", 1
    end
  end

  def test_create
    publisher = publishers(:gvnews)
    
    assert_difference 'User.count' do
      with_admin_user_required(:quentin, :aaron) do
        post :create, :publisher_id => publisher.to_param, :user => {
          :login => "new",
          :name => "New User",
          :email => "new@example.com",
          :password => "secret",
          :password_confirmation => "secret",
          :allow_syndication_access => '0',
          :allow_offer_syndication_access => '0',
          :admin_privilege => User::FULL_ADMIN,
          :company_type => "Publisher",
          :company_id => publishers(:gvnews).to_param
        }
      end
    end
    assert_redirected_to publisher_users_path(publisher)
    
    user = User.find_by_email("new@example.com")
    assert_not_nil user, "User should have been created with specified email address"
    assert_equal "New User", user.name, "New user should have the specified name"
    assert_equal publisher, user.company, "New user should belong to the specified publisher"
    assert !user.has_admin_privilege?, "New user should not have admin"
    assert !user.allow_syndication_access?, "User should not have syndication access"
    assert !user.allow_offer_syndication_access?, "User should not have offer syndication access"
  end


  def test_edit
    publisher = publishers(:gvnews)
    user = publisher.users.first
    assert_not_nil user, "Publisher fixture should have some users"
    user.update_attributes!(:allow_syndication_access => true)
    
    with_admin_user_required(:quentin, :aaron) do
      get :edit, :publisher_id => publisher.to_param, :id => user.to_param
    end
    assert_response :success
    assert_equal publisher, assigns(:parent), "@parent assignment"
    assert_equal user, assigns(:user), "@user assignment"
    
    assert_select "form.edit_user#edit_user_#{user.id}[method=post]", 1 do
      assert_select "input[type=text][name='user[name]'][value='#{user.name}']", 1
      assert_select "input[type=text][name='user[email]'][value='#{user.email}']", 1
      assert_select "input[type=checkbox][name='user[email_account_setup_instructions]']", 0
      assert_select "input[type=password][name='user[password]']", 1
      assert_select "input[type=password][name='user[password_confirmation]']", 1
      assert_select "input[type=submit]"
      assert_select "input[type=checkbox][name='user[allow_syndication_access]'][checked]", 1
      assert_select "input[type=checkbox][name='user[allow_offer_syndication_access]']", 1
      assert_select "input[type=checkbox][name='user[can_manage_consumers]']", 1
    end
  end

  def test_update
    publisher = publishers(:gvnews)
    user = publisher.users.first
    assert_not_nil user, "Publisher fixture should have some users"
    
    assert_no_difference 'User.count' do
      with_admin_user_required(:quentin, :aaron) do
        put :update, :publisher_id => publisher.to_param, :id => user.to_param, :user => {
          :name => "New User",
          :email => "new@example.com",
          :password => "secret",
          :password_confirmation => "secret",
          :allow_syndication_access => '1',
          :allow_offer_syndication_access => '1',
          :admin_privilege => User::FULL_ADMIN,
          :company => publishers(:gvnews)
        }
      end
    end
    assert_redirected_to publisher_users_path(publisher)
    
    user = User.find_by_email("new@example.com")
    assert_not_nil user, "User should have been updated with specified email address"
    assert_equal "New User", user.name, "User should have the specified name"
    assert_equal publisher, user.company, "User should belong to the specified publisher"
    assert !user.has_admin_privilege?, "User should not have admin"
    assert user.allow_syndication_access?, "User should have syndication access"
    assert user.allow_offer_syndication_access?, "User should have offer syndication access"
  end

  def test_delete
    publisher = publishers(:gvnews)
    users = returning([]) do |array|
      2.times do |i|
        array << publisher.users.create!({
          :name => "User #{i}", :login => "user#{i}", :password => "secret", :password_confirmation => "secret"
        })
      end
    end
    
    assert_difference 'User.count', -2 do
      with_admin_user_required(:quentin, :aaron) do
        post :delete, :publisher_id => publisher.to_param, :id => users.map(&:to_param)
      end
    end
    assert_redirected_to publisher_users_path(publisher)
    
    2.times { |i| assert_nil User.find_by_email("user#{i}@example.com"), "User #{i} should have been deleted" }
  end

  context "edit" do
    setup do
      @user = Factory(:user)
      @publisher = @user.publisher

      login_as Factory(:admin)
    end

    context "given an unlocked user" do
      setup do
        @user.unlock_access!
      end

      should "provide link to lock access" do
        get :edit, :publisher_id => @publisher.to_param, :id => @user.to_param
        assert_select "a", "Lock Access"
      end
    end

    context "given a locked user" do
      setup do
        @user.lock_access!
        get :edit, :publisher_id => @publisher.to_param, :id => @user.to_param
      end

      should "provide link to unlock access" do
        assert_select "a", "Unlock Access"
      end
    end
  end
end
