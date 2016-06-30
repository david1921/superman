require File.dirname(__FILE__) + "/../test_helper"

class AdvertiserSignupsControllerTest < ActionController::TestCase
  test "should get new" do
    get :new, :publisher_id => publishers(:sdreader)
    assert_response :success
  end

  test "should explain about non-participating publishers" do
    get :new, :publisher_id => publishers(:gvnews)
    assert_select "#next_button", 0
    assert_response :success
  end

  test "should create signup" do
    ActionMailer::Base.deliveries.clear
    publisher = publishers(:sdreader)
    publisher.subscription_rate_schedules.create!(:name => "Standard", :uuid => "123333555-4200-4f02-ae70-fe4f48964159")
    
    post :create, 
         :publisher_id => publisher.to_param,
         :advertiser_signup => {
           :advertiser_name => "Sassy's",
           :email => "sassy@example.com",
           :password => "secret",
           :password_confirmation => "secret"
         }
    
    advertiser = assigns(:advertiser)
    assert_not_nil advertiser, @advertiser
    assert advertiser.errors.empty?, advertiser.errors.full_messages
    assert_not_nil assigns(:advertiser_signup), @advertiser_signup
    assert assigns(:advertiser_signup).errors.empty?, assigns(:advertiser_signup).errors.full_messages
    assert_not_nil assigns(:advertiser_user), @advertiser_user
    assert assigns(:advertiser_user).errors.empty?, assigns(:advertiser_user).errors.full_messages
    
    assert_redirected_to edit_advertiser_path(advertiser)
    user = User.find_by_login("sassy@example.com")
    assert_not_nil user, "should create user with email address as login"
    advertiser = Advertiser.find_by_name("Sassy's")
    assert_equal advertiser, user.company, "Should set company to new Advertiser"
    advertiser_signup = AdvertiserSignup.find_by_email("sassy@example.com")
    assert_not_nil advertiser_signup, "Should create AdvertiserSignup"
    assert_equal advertiser, advertiser_signup.advertiser, "AdvertiserSignup advertiser"
    assert_equal user, advertiser_signup.user, "AdvertiserSignup user"
    assert advertiser.paid?, "Should create paid Advertiser"
    assert !advertiser.active?, "Advertiser should not be active"
    assert_equal(
      publisher.subscription_rate_schedules.first, 
      advertiser.subscription_rate_schedule, 
      "Advertiser subscription_rate_schedule should be Publisher's default"
    )
    assert_equal 1, AdvertiserSignupMailer.deliveries.size, "Should deliver notification email"
   end

  test "invalid signup should not raise error" do
    publisher = publishers(:sdreader)
    publisher.subscription_rate_schedules.create!(:name => "Standard", :uuid => "123333555-4200-4f02-ae70-fe4f48964159")
    
    post :create, 
         :publisher_id => publisher.to_param,
         :advertiser_signup => {
           :advertiser_name => "",
           :email => "",
           :password => "",
           :password_confirmation => ""
         }

    advertiser = assigns(:advertiser)
    assert_not_nil advertiser, @advertiser
    assert advertiser.errors.empty?, advertiser.errors.full_messages
    assert advertiser.new_record?, "advertiser should still be new record"

    assert_not_nil assigns(:advertiser_signup), @advertiser_signup
    assert assigns(:advertiser_signup).errors.empty?, assigns(:advertiser_signup).errors.full_messages
    assert assigns(:advertiser_signup).new_record?, "advertiser_signup should still be new record"

    assert_not_nil assigns(:advertiser_user), @advertiser_user
    assert !assigns(:advertiser_user).errors.empty?, assigns(:advertiser_user).errors.full_messages
    assert assigns(:advertiser_user).new_record?, "advertiser_user should still be new record"

    assert_response :success
  end

  test "invalid user should not save any records" do
    ActionMailer::Base.deliveries.clear
    publisher = publishers(:sdreader)
    publisher.subscription_rate_schedules.create!(:name => "Standard", :uuid => "123333555-4200-4f02-ae70-fe4f48964159")
    
    post :create, 
         :publisher_id => publisher.to_param,
         :advertiser_signup => {
           :advertiser_name => "Doggy Daycare",
           :email => "dogs@example.com",
           :password => "secre",
           :password_confirmation => "secret"
         }

    advertiser = assigns(:advertiser)
    assert_not_nil advertiser, @advertiser
    assert advertiser.errors.empty?, advertiser.errors.full_messages
    assert advertiser.new_record?, "advertiser should still be new record"

    assert_not_nil assigns(:advertiser_signup), @advertiser_signup
    assert assigns(:advertiser_signup).errors.empty?, assigns(:advertiser_signup).errors.full_messages
    assert assigns(:advertiser_signup).new_record?, "advertiser_signup should still be new record"

    assert_not_nil assigns(:advertiser_user), @advertiser_user
    assert !assigns(:advertiser_user).errors.empty?, assigns(:advertiser_user).errors.full_messages
    assert assigns(:advertiser_user).new_record?, "advertiser_user should still be new record"

    assert_response :success
    assert_equal 0, AdvertiserSignupMailer.deliveries.size, "Should not deliver notification email"
  end
end
