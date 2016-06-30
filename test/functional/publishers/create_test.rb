require File.dirname(__FILE__) + "/../../test_helper"

class PublishersController::CreateTest < ActionController::TestCase
  tests PublishersController

  def setup
    @valid_publisher_attributes = {
      :federal_tax_id => "12-12121212",
      :address_line_1 => "1600 Pennsylvania Avenue NW",
      :city =>           "Washington",
      :state =>          "DC",
      :zip =>            "20500"
    }
  end

  def test_create
    with_admin_user_required(:quentin, :aaron) do
      post(:create, :publisher => @valid_publisher_attributes.merge({
          :name => "new",
          :label => "new",
          :subcategories => true,
          :account_sign_up_message => "please sign up",
          :daily_deal_referral_message => "Refer a friend",
          :enable_unlimited_referral_time => '1'
      }))
    end
    publisher = assigns(:publisher)
    assert publisher.errors.empty?, "@publisher should not have errors, but has: #{publisher.errors.full_messages}" if publisher
    assert_redirected_to edit_publisher_path(assigns(:publisher))
    assert flash[:notice].any?, "Should have flash"
    assert_nil publisher.publishing_group, "Should not have a publishing group"
    assert_equal "simple", publisher.theme, "theme after create"
    assert_equal "please sign up", publisher.account_sign_up_message
    assert_equal "Refer a friend", publisher.daily_deal_referral_message
    assert publisher.enable_unlimited_referral_time
  end

  def test_create_with_standard_theme
    with_admin_user_required(:quentin, :aaron) do
      post(:create, :publisher => @valid_publisher_attributes.merge({ :name => "new", :label => "new", :subcategories => true, :theme => "standard" }))
    end
    publisher = assigns(:publisher)
    assert publisher.errors.empty?, "@publisher should not have errors, but has: #{publisher.errors.full_messages}" if publisher
    assert_redirected_to edit_publisher_path(assigns(:publisher))
    assert flash[:notice].any?, "Should have flash"
    assert_nil publisher.publishing_group, "Should not have a publishing group"
    assert_equal "standard", publisher.theme, "theme after create"
  end

  def test_create_with_enhanced_theme
    with_admin_user_required(:quentin, :aaron) do
      post(:create, :publisher => @valid_publisher_attributes.merge({ :name => "new", :label => "new", :subcategories => true, :theme => "enhanced" }))
    end
    publisher = assigns(:publisher)
    assert publisher.errors.empty?, "@publisher should not have errors, but has: #{publisher.errors.full_messages}" if publisher
    assert_equal "enhanced", publisher.theme, "theme after create"
  end

  def test_create_with_existing_publishing_group
    with_admin_user_required(:quentin, :aaron) do
      post :create, :publisher => @valid_publisher_attributes.merge({
        :name => "Test Publisher",
        :publishing_group_id => publishing_groups(:student_discount_handbook).to_param,
        :publishing_group_name => "",
        :label => "testpublisher",
        :subcategories => true,
        :brand_name => "TestPublisher.com",
        :brand_headline => "Another Great Coupon from TestPublisher.com",
        :brand_txt_header => "tpub.com"
      })
    end
    publisher = assigns(:publisher)
    assert(publisher.errors.empty?, "@publisher should not have errors, but has: #{publisher.errors.full_messages}") if publisher
    assert_redirected_to edit_publisher_path(assigns(:publisher))
    assert(flash[:notice].any?, "Should have flash")
    assert_equal publishing_groups(:student_discount_handbook), publisher.publishing_group, "Should belong to publishing group"
    assert_equal "TestPublisher.com", publisher.brand_name
    assert_equal "Another Great Coupon from TestPublisher.com", publisher.brand_headline
    assert_equal "tpub.com", publisher.brand_txt_header
  end

  def test_create_with_new_publishing_group
    with_admin_user_required(:quentin, :aaron) do
      post :create, :publisher => @valid_publisher_attributes.merge({
        :name => "Test Publisher",
        :publishing_group_id => "",
        :publishing_group_name => "New Publishing Group",
        :label => "testpublisher",
        :subcategories => true
      })
    end
    publisher = assigns(:publisher)
    assert publisher.errors.empty?, "@publisher should not have errors, but has: #{publisher.errors.full_messages}" if publisher
    assert_redirected_to edit_publisher_path(assigns(:publisher))
    assert flash[:notice].any?, "Should have flash"

    publishing_group = PublishingGroup.find_by_name("New Publishing Group")
    assert_not_nil publishing_group, "Should have created new publishing group"
    assert_equal publishing_group, publisher.publishing_group, "Should belong to new publishing group"
  end

  def test_create_with_existing_and_new_publishing_group
    with_admin_user_required(:quentin, :aaron) do
      post :create, :publisher => @valid_publisher_attributes.merge({
        :name => "Test Publisher",
        :publishing_group_id => publishing_groups(:student_discount_handbook).to_param,
        :publishing_group_name => "New Publishing Group",
        :label => "testpublisher",
        :subcategories => true
      })
    end
    publisher = assigns(:publisher)
    assert publisher.errors.on(:publishing_group)
    assert_response :success

    publishing_group = PublishingGroup.find_by_name("New Publishing Group")
    assert_nil publishing_group, "Should not have created new publishing group"
  end

  def test_create_with_uk_address
    uk = Country::UK
    with_admin_user_required(:quentin, :aaron) do
      post(:create, :publisher => @valid_publisher_attributes.merge({
                     :name => "Thomsonlocal.com Directories",
                     :label => "thomsonlocal",
                     :address_line_1 => "Thomson House",
                     :address_line_2 => "296 Farnborough Road",
                     :city => "Farnborough",
                     :region => "Hants",
                     :zip => "GU14 7NU",
                     :phone_number => "01252 555 555",
                     :country => uk
                     }))
    end
    publisher = assigns(:publisher)
    assert publisher.errors.empty?, "@publisher should not have errors, but has: #{publisher.errors.full_messages}" if publisher
    assert_redirected_to edit_publisher_path(assigns(:publisher))
    assert flash[:notice].any?, "Should have flash"
    assert_nil publisher.publishing_group, "Should not have a publishing group"
    assert_equal uk, publisher.country
    assert_equal "Hants", publisher.region
    assert_equal nil, publisher.state
  end

end
