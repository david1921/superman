require File.dirname(__FILE__) + "/../../test_helper"

class UserTest < ActiveSupport::TestCase
  test "should create user" do
    assert_difference 'User.count' do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end
  
  test "should create admin user" do
    # admin_privilege protected from mass-asignment
    user = User.new(
      :login => "super_admin", 
      :email => "scott@goatse.cx",
      :password => "secret",
      :password_confirmation => "secret")
    user.admin_privilege = User::FULL_ADMIN
    user.save!
  end
  
  test "fixture yaml privileges" do
    assert users(:aaron).has_admin_privilege?, "Aaron should have :admin privilege"
  end
  
  test "should require password" do
    assert_no_difference 'User.count' do
      u = create_user(:password => nil)
      assert u.errors.on(:password)
    end
  end
  
  test "should require password confirmation" do
    assert_no_difference 'User.count' do
      u = create_user(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end
  
  test "should require login for administrator" do
    assert_no_difference 'User.count' do
      u = create_user(:login => nil)
    end
  end
  
  test "login should be set to email for consumer" do
    user = publishers(:sdh_austin).consumers.create!(
      :email => "joe@blow.com",
      :name => "Joe Blow",
      :password => "secret",
      :password_confirmation => "secret",
      :agree_to_terms => "1"
    )
    assert_equal user.email, user.login, "Login should be set to email"
  end
  
  test "admin should not require publishers" do
    assert_difference 'User.count' do
      user = Factory :admin
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end
  
  test "should reset password" do
    users(:quentin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:quentin), User.authenticate('quentin', 'new password')
  end
  
  test "should not rehash password" do
    users(:quentin).update_attributes(:login => 'quentin2')
    assert_equal users(:quentin), User.authenticate('quentin2', 'monkey')
  end
  
  test "should authenticate user" do
    assert_equal users(:quentin), User.authenticate('quentin', 'monkey')
  end
  
  test "should set remember token" do
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
  end
  
  test "should unset remember token" do
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    users(:quentin).forget_me
    assert_nil users(:quentin).remember_token
  end
  
  test "should remember me for one week" do
    before = 1.week.from_now.utc
    users(:quentin).remember_me_for 1.week
    after = 1.week.from_now.utc
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert users(:quentin).remember_token_expires_at.between?(before, after)
  end
  
  test "should remember me until one week" do
    time = 1.week.from_now.utc
    users(:quentin).remember_me_until time
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert_equal users(:quentin).remember_token_expires_at, time
  end
  
  test "should remember me default two weeks" do
    before = 2.weeks.from_now.utc
    users(:quentin).remember_me
    after = 2.weeks.from_now.utc
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert users(:quentin).remember_token_expires_at.between?(before, after)
  end
  
  test "admin privilege" do
    assert_difference 'User.count' do
      user = create_user
      assert !user.has_admin_privilege?, "User should not have admin by default"
    
      assert user.update_attribute(:admin_privilege, User::FULL_ADMIN), "Should be able to assign admin privilege"
      assert user.reload.has_admin_privilege?, "User should have admin"
    end
  end
  
  test "observable publishers for user holding admin" do
    user = users(:aaron)
    assert user.has_admin_privilege?, "User fixture should have admin"
  
    assert Publisher.all.size > 0
    observable_publishers = Publisher.observable_by(user)
    Publisher.all.each { |publisher| assert observable_publishers.find(:all).include?(publisher) }
    Publisher.all.each { |publisher| assert_equal publisher, observable_publishers.find(publisher.id) }
    assert_not_nil observable_publishers.find(:first)
  end
  
  test "observable publishers for user belonging to advertising group" do
    user = users(:scott)
    assert !user.has_admin_privilege?, "User fixture should not have admin"
    publishing_group = user.company
    assert publishing_group.is_a?(PublishingGroup), "User fixture should belong to a publishing group"
    
    publishers = publishing_group.publishers
    assert publishers.size > 0, "Publishing Group fixture should have some publishers"
  
    other_publisher = publishers(:gvnews)
    assert !publishers.include?(other_publisher), "Publishing Group publishers should not include other publisher"
    
    observable_publishers = Publisher.observable_by(user)
    
    publishers.each { |publisher| assert observable_publishers.find(:all).include?(publisher) }
    publishers.each { |publisher| assert_equal publisher, observable_publishers.find(publisher.id) }
    assert publishers.include?(observable_publishers.find(:first))
    
    assert_raises ActiveRecord::RecordNotFound do
      observable_publishers.find(other_publisher.id)
    end
  end
  
  test "observable publishers for user belonging to publisher" do
    user = users(:quentin)
    assert !user.has_admin_privilege?, "User fixture should not have admin"
    publisher_1 = user.company
    assert publisher_1.is_a?(Publisher), "User fixture should belong to a publisher"
    publisher_2 = publishers(:gvnews)
    assert_not_equal publisher_2, publisher_1
    
    observable_publishers = Publisher.observable_by(user)
    
    assert_equal 1, observable_publishers.find(:all).size
    assert observable_publishers.find(:all).include?(publisher_1)
    assert_equal publisher_1, observable_publishers.find(publisher_1.id)
    assert_equal publisher_1, observable_publishers.find(:first)
    
    assert_raises ActiveRecord::RecordNotFound do
      observable_publishers.find(publisher_2.id)
    end
  end
  
  test "default session timeout" do
    assert_difference 'User.count' do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
      assert_equal 0, user.session_timeout, "Session timeout should default to zero for non-admin"
    end
  
    assert_difference 'User.count' do
      user = create_user(:login => 'user2', :privileges => [:admin])
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
      assert_equal 0, user.session_timeout, "Session timeout should default to zero for admin"
    end
  end
  
  test "valid session timeout" do
    assert_difference 'User.count' do
      user = create_user(:login => 'user1', :session_timeout => 300)
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
      assert_equal 300, user.session_timeout, "Valid session timeout for non-admin user"
    end
  
    assert_difference 'User.count' do
      user = create_user(:login => 'user2', :privileges => [:admin], :session_timeout => 300)
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
      assert_equal 300, user.session_timeout, "Valid session timeout for admin user"
    end
  end
  
  test "random password" do
    passwords = Array.new(100) { User.random_password }
    passwords.each do |password|
      assert_match(/^[a-z0-9]{16}$/, password, "Default password length and alphabet")
      assert_equal 1, passwords.select { |p| password == p }.size, "Random passwords should be unique"
    end
  
    passwords = Array.new(100) { User.random_password(5) }
    passwords.each do |password|
      assert_match(/^[a-z0-9]{5}$/, password, "Specified password length and alphabet")
      assert_equal 1, passwords.select { |p| password == p }.size, "Random passwords should be unique"
    end
  end
  
  test "randomize password" do
    user = create_user
    crypted_password = user.crypted_password
    user.randomize_password!
    assert_not_equal crypted_password, user.reload.crypted_password, "Password hash should have been updated"
  end
  
  test "authenticate locm for publisher" do
    publisher = publishers(:locm)
    publisher.update_attributes! :self_serve => true
    advertiser = publisher.advertisers.create!(:listing => "301")
    user = User.new(:login => "demo@local.com", :password => "secret", :password_confirmation => "secret")
    user.company = publisher
    user.save!
    #
    # Token decrypts to '3451 Local 7263 demo@local.com 9475 301 6824\000\000\000\000'
    #
    token = Base64.decode64('M61wwRms4gDwf/lzqQi8K7vHWG5kxyqF+6I6TlWuvUvrbn0mXcjeBU+aqZf6zOF0')
    assert_equal [user, advertiser], User.authenticate_locm(token), "Token should authenticate user"
  end
  
  test "authenticate locm for publishing group" do
    publishing_group = publishing_groups(:locm)
    publisher = publishing_group.publishers.first
    publishing_group.update_attributes! :self_serve => true
    advertiser = publisher.advertisers.create!(:listing => "301")
    user = User.new(:login => "demo@local.com", :password => "secret", :password_confirmation => "secret")
    user.company = publishing_group
    user.save!
    #
    # Token decrypts to '3451 Local 7263 demo@local.com 9475 301 6824\000\000\000\000'
    #
    token = Base64.decode64('M61wwRms4gDwf/lzqQi8K7vHWG5kxyqF+6I6TlWuvUvrbn0mXcjeBU+aqZf6zOF0')
    assert_equal [user, advertiser], User.authenticate_locm(token), "Token should authenticate user"
  end
  
  test "authenticate locm with garbled token" do
    publisher = publishers(:locm)
    publisher.update_attributes! :self_serve => true
    advertiser = publisher.advertisers.create!(:listing => "301")
    user = User.new(:login => "demo@local.com", :password => "secret", :password_confirmation => "secret")
    user.company = publisher
    user.save!
  
    token = Base64.decode64('x61wwRms4gDwf/lzqQi8K7vHWG5kxyqF+6I6TlWuvUvrbn0mXcjeBU+aqZf6zOF0')
    user = User.new(:login => "username", :password => "secret", :password_confirmation => "secret")
    assert_equal [nil, nil],  User.authenticate_locm(token), "Token should not authenticate user"
  end
  
  test "authenticate locm with nil token" do
    assert_equal [nil, nil], User.authenticate_locm(nil), "Nil token should not authenticate a user"
  end
  
  test "label" do
    user = publishers(:my_space).users.create!(
      :login => "login", 
      :email => "login@example.com",
      :password => "secret",
      :password_confirmation => "secret",
      :label => "123xyz")
    assert_equal user, User.find_by_label("123xyz"), "Should find user by label"
  end
  
  test "update label with nil name" do
    user = publishers(:my_space).users.create!(
      :name => nil,
      :login => "login@cnhi.com", 
      :password => "secret",
      :password_confirmation => "secret")
    user.reload
    assert_equal nil, user.name, "Name"
    user.update_attributes! :label => "95544"
  end
  
  test "email validation when not sending account setup instructions" do
    advertiser = advertisers(:changos)
    attrs = { :login => "user", :password => "secret", :password_confirmation => "secret" }
    
    user = User.new(attrs)
    user.admin_privilege = User::FULL_ADMIN
    assert user.valid?
    
    assert advertiser.publisher.users.new(attrs).valid?
    assert advertiser.users.new(attrs).valid?
  end
  
  test "email validation when sending account setup instructions" do
    advertiser = advertisers(:changos)
    attrs = { :login => "user", :password => "secret", :password_confirmation => "secret", :email_account_setup_instructions => "1" }
    
    user = User.new(attrs)
    user.admin_privilege = User::FULL_ADMIN
    assert user.invalid?
    assert_match %r{can\'t be blank}, user.errors.on(:email)
    user.email = "user@gmail.com"
    assert user.valid?
    
    user = advertiser.publisher.users.new(attrs)
    assert user.invalid?
    assert_match %r{can\'t be blank}, user.errors.on(:email)
    user.email = "user@gmail.com"
    assert user.valid?
    
    user = advertiser.users.new(attrs)
    assert user.invalid?
    assert_match %r{can\'t be blank}, user.errors.on(:email)
    user.email = "user@gmail.com"
    assert user.valid?
  end
  
  test "should send confirmation email" do
    UserMailer.deliveries.clear
    create_user_with_company(
      :email => "user@example.com", 
      :login => "user", 
      :password => "secret", 
      :password_confirmation => "secret", 
      :email_account_setup_instructions => "1",
      :company => advertisers(:changos)
    )
    assert_equal 1, UserMailer.deliveries.size, "Should send confirmation email"
  end

  test "demo user exists" do
    assert !User.demo_user_exists?, "demo_user_exists? with when no demo user"
    user = create_demo_user!
    assert User.demo_user_exists?, "demo_user_exists? with when demo user"
    assert_equal publishers(:my_space), user.company, "demo user company"
  end
  
  test "demo user can manage" do
    user = create_demo_user!
    assert !user.can_manage?(advertisers(:burger_king)), "demo users can never edit anything"
    assert !user.can_manage?(advertisers(:di_milles)), "demo users can never edit anything"
    assert !user.can_manage?(publishers(:my_space)), "demo users can never edit anything"
    assert !user.can_manage?(publishers(:li_press)), "demo users can never edit anything"
  end
  
  test "admin user can manage" do
    user = users(:aaron)
    assert user.can_manage?(advertisers(:burger_king)), "admin users can manage everything"
    assert user.can_manage?(advertisers(:di_milles)), "admin users can manage everything"
    assert user.can_manage?(publishers(:my_space)), "admin users can manage everything"
    assert user.can_manage?(publishers(:li_press)), "admin users can manage everything"
  end
  
  test "user can manage" do
    user = users(:quentin)
    assert user.can_manage?(advertisers(:burger_king)), "users can manage only their advertisers"
    assert !user.can_manage?(advertisers(:di_milles)), "users can manage only their advertisers"
    assert user.can_manage?(publishers(:my_space)), "users can manage only their publishers"
    assert !user.can_manage?(publishers(:li_press)), "users can manage only their publishers"
  end
  
  test "gender validity" do
    user = users(:quentin)
    ["M", "F", "", nil].each do |gender|
      user.gender = gender
      assert user.valid?, "#{gender} is a valid gender"
    end
    ["foo", "bar", "nonesense", "xxx"].each do |gender|
      user.gender = gender
      assert !user.valid?, "#{gender} is not a valid gender"
    end
  end
  
  test "gender assignment" do
    user = users(:quentin)
    ["m", "M", "male", "MALE", "Male"].each do |gender|
      user.gender = gender
      assert_equal "M", user.gender
    end
    ["f", "F", "female", "FEMALE", "Female"].each do |gender|
      user.gender = gender
      assert_equal "F", user.gender
    end
  end
  
  test "roles" do
    attrs = { :login => "joe@blow.org", :password => "secret", :password_confirmation => "secret" }
    
    user = User.new(attrs)
    user.admin_privilege = User::FULL_ADMIN
    user.save!
    assert user.administrator?
    assert !user.publishing_group?
    assert !user.publisher?
    assert !user.advertiser?
    assert !user.consumer?
  
    user.force_destroy
    user = User.new(attrs)
    user.company = publishing_groups(:vvm)
    user.save!
    assert user.administrator?
    assert user.publishing_group?
    assert !user.publisher?
    assert !user.advertiser?
    assert !user.consumer?
  
    user.force_destroy
    user = User.new(attrs)
    user.company = publishers(:sdh_austin)
    user.save!
    assert user.administrator?
    assert !user.publishing_group?
    assert user.publisher?
    assert !user.advertiser?
    assert !user.consumer?
  
    user.force_destroy
    user = User.new(attrs)
    user.company = advertisers(:changos)
    user.save!
    assert user.administrator?
    assert !user.publishing_group?
    assert !user.publisher?
    assert user.advertiser?
    assert !user.consumer?
  end
  
  test "affiliate?" do
    user = Factory(:user)
    affiliate = Factory(:affiliate, :login => "nonconflictinglogin")
    assert !user.affiliate?
    assert affiliate.affiliate?
  end
  
  test "logins that only differ in case are invalid" do
    company = Factory(:publisher)
    user = Factory(:user, :login => "goose@example.com", :company => company)
    assert user.valid?, "should be valid"
    assert !user.new_record?, "should be saved"
    
    dupe_user = Factory.build(:user, :login => "GOOSE@example.com", :company => company)
    assert !dupe_user.valid?, "Duplicate login should not be valid"
    assert dupe_user.errors.on(:login), "Should have error on login"
  end
  
  context "self_serve?" do
  
    should "not be self serve with no associated company" do
      user = Factory(:user)
      assert !user.self_serve?
    end
  
    should "not be self serve with company that is not self serve" do
      publisher = Factory(:publisher, :self_serve => false)
      assert !publisher.self_serve?
      user  = Factory(:user, :company => publisher)
      assert_equal publisher, user.reload.company, "publisher should be the user's company"
      assert !user.reload.self_serve?, "user should not be self server"
    end
  
    should "be self serve with company that is self serve" do
      publisher = Factory(:publisher, :self_serve => true)
      assert publisher.self_serve?
      user  = Factory(:user, :company => publisher)
      assert_equal publisher, user.reload.company, "publisher should be the user's company"
      assert user.reload.self_serve?, "user should be self serve"
    end
  
  end  
  
  test "current should return Thread.current[:user]" do
    user = Factory(:user)
    Thread.current[:user] = user
  
    assert_equal user, User.current
  end
  
  test "current= should set Thread.current[:user]" do
    user = Factory(:user)
    User.current = user
  
    assert_equal user, Thread.current[:user]
  end

  should "not be destroyable" do
    @user = Factory(:user_without_company)
    Factory(:off_platform_daily_deal_purchase, :api_user => @user)
    @user.destroy
    assert_equal @user, User.find_by_id(@user.id)
    assert_match /Cannot be deleted/, @user.errors[:base]
  end

  context "#force_destroy" do
    should "disable the destroy prevention" do
      user = Factory(:user)
      user_id = user.id
      user.force_destroy
      assert_raise ActiveRecord::RecordNotFound do
        User.find(user_id)
      end
    end
  end

  context "status_message" do
    setup do
      @user = Factory(:user)
    end

    context "given an unlocked user account" do
      setup do
        @user.unlock_access!
      end

      should "return appropriate message" do
        assert_equal "Active", @user.status_message
      end
    end

    context "given a locked user account" do
      setup do
        @user.lock_access!
      end

      should "return appropriate message" do
        assert_equal "Locked", @user.status_message
      end
    end
  end

  context "deliver_account_setup_instructions!" do
    setup do
      @user = Factory(:user, :email => "foo.bar@example.com")
      ActionMailer::Base.deliveries.clear
      @user.deliver_account_setup_instructions!
    end

    should "set perishable token" do
      assert_not_nil @user.reload.perishable_token
    end

    should "send email" do
      assert_equal 1, ActionMailer::Base.deliveries.size
    end
  end

  context "deliver_password_reset_instructions!" do
    setup do
      @user = Factory(:user, :email => "foo.bar@example.com")
      ActionMailer::Base.deliveries.clear
      @user.deliver_password_reset_instructions!
    end

    should "set perishable token" do
      assert_not_nil @user.reload.perishable_token
    end

    should "send email" do
      assert_equal 1, ActionMailer::Base.deliveries.size
    end
  end

  context "deliver_account_reactivation_instructions!!" do
    setup do
      @user = Factory(:user, :email => "foo.bar@example.com")
      ActionMailer::Base.deliveries.clear
      @user.deliver_account_reactivation_instructions!
    end

    should "set perishable token" do
      assert_not_nil @user.reload.perishable_token
    end

    should "send email" do
      assert_equal 1, ActionMailer::Base.deliveries.size
    end
  end

  context "can_manage_consumers?" do

    context "with admin user" do
      
      should "allow managing of consumers if even can_manage_consumers is set to false" do
        admin = Factory(:admin, :can_manage_consumers => false)
        assert admin.can_manage_consumers?
      end

      should "allow managing of consumers if can_manage_consumers is set to true" do
        admin = Factory(:admin, :can_manage_consumers => true)
        assert admin.can_manage_consumers?
      end

    end

    context "with non-admin user" do

      should "default to false for can_manage_consumers" do
        user = Factory(:user)
        assert !user.can_manage_consumers?
      end

      should "NOT allow managing of consumers if can_manage_consumers is set to false" do
        user = Factory(:user, :can_manage_consumers => false)
        assert !user.can_manage_consumers?
      end

      should "allow managing of consumers if the can_manage_consumers is set to true" do
        user = Factory(:user, :can_manage_consumers => true)
        assert user.can_manage_consumers?
      end
    end
  end

  context "User.authenticate and locked accounts" do

    setup do
      @admin = Factory :admin, :login => "admin@example.com", :password => "foobar", :password_confirmation => "foobar"
    end

    should "return :locked when a user account is locked, when an incorrect password is entered" do
      @admin.lock_access!
      assert @admin.access_locked?
      assert_equal :locked, User.authenticate("admin@example.com", "wrongpassword")
    end

    should "return :locked when a user account is locked, even if the password is correct" do
      @admin.lock_access!
      assert @admin.access_locked?
      assert_equal :locked, User.authenticate("admin@example.com", "foobar")
    end

    should "return :locked, and lock the account, when the user makes Users::Lockable::MAXIMUM_FAILED_ATTEMPTS failed login attempts" do
      @admin.failed_login_attempts = Users::Lockable::MAXIMUM_FAILED_ATTEMPTS - 1
      @admin.save!
      assert !@admin.access_locked?
      assert_equal :locked, User.authenticate("admin@example.com", "wrongpassword")

      @admin.reload
      assert_equal Users::Lockable::MAXIMUM_FAILED_ATTEMPTS, @admin.failed_login_attempts
      assert @admin.access_locked?
    end

    should "return a User and reset failed_login_attempts to 0 if the user is below the MAXIMUM_FAILED_ATTEMPTS threshold " +
           "and successfully authenticates" do
      @admin.failed_login_attempts = Users::Lockable::MAXIMUM_FAILED_ATTEMPTS - 1
      @admin.save!
      assert !@admin.access_locked?
      assert_instance_of User, User.authenticate("admin@example.com", "foobar")

      @admin.reload
      assert_equal 0, @admin.failed_login_attempts
      assert !@admin.access_locked?
    end
    
  end

  protected
  
  def create_user(options = {})
    attrs = {
      :login => 'quire',
      :email => 'quire@example.com',
      :password => 'quire69',
      :password_confirmation => 'quire69',
      :company => publishers(:my_space),
      :admin_privilege => nil
    }.merge(options)
    record = User.new(attrs.except(:company, :admin_privilege))
    record.company = attrs[:company]
    record.admin_privilege = attrs[:admin_privilege]
  
    record.save
    record
  end
end
