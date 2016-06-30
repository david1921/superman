require File.dirname(__FILE__) + "/../../test_helper"

class PublishersController::UpdateTest < ActionController::TestCase
  tests PublishersController

  def test_update
    with_admin_user_required(:quentin, :aaron) do
      put(:update, :id => publishers(:my_space).to_param, :publisher => {
        :name => "updated",
        :publishing_group_id => publishing_groups(:student_discount_handbook).to_param,
        :label => "updated",
        :link_to_email => false,
        :link_to_map => false,
        :link_to_website => false,
        :account_sign_up_message => "please sign up for an account",
        :daily_deal_referral_message => "Refer a friend",
        :market_name => "pub west"
      })
    end
    publisher = assigns(:publisher)
    assert(publisher.errors.empty?, "@publisher should not have errors, but has: #{publisher.errors.full_messages}") if publisher
    assert_redirected_to edit_publisher_path(assigns(:publisher))
    assert(flash[:notice].any?, "Should have flash")
    assert_equal publishing_groups(:student_discount_handbook), publisher.publishing_group
    assert_equal false, publisher.link_to_email?, "link_to_email? should be updated"
    assert_equal false, publisher.link_to_map?, "link_to_map? should be updated"
    assert_equal false, publisher.link_to_website?, "link_to_website? should be updated"
    assert_equal "please sign up for an account", publisher.account_sign_up_message
    assert_equal "Refer a friend", publisher.daily_deal_referral_message
    assert_equal "pub west", publisher.market_name
  end

  def test_update_with_blank_parent_theme
    with_admin_user_required(:quentin, :aaron) do
      put(:update, :id => publishers(:my_space).to_param, :publisher => {
        :name => "updated",
        :publishing_group_id => publishing_groups(:student_discount_handbook).to_param,
        :label => "updated",
        :link_to_email => false,
        :link_to_map => false,
        :link_to_website => false,
        :account_sign_up_message => "please sign up for an account",
        :daily_deal_referral_message => "Refer a friend",
        :market_name => "pub west",
        :parent_theme => ""
      })
    end
    publisher = assigns(:publisher)
    assert publisher.errors.empty?
    assert publisher.parent_theme.blank?
    assert_redirected_to edit_publisher_path(assigns(:publisher))
  end

  def test_update_with_new_publishing_group
    with_admin_user_required(:quentin, :aaron) do
      put(:update, :id => publishers(:my_space).to_param, :publisher => {
        :name => "updated",
        :publishing_group_id => "",
        :publishing_group_name => "New Publishing Group",
        :label => "updated",
        :link_to_email => false,
        :link_to_map => false,
        :link_to_website => false
      })
    end
    publisher = assigns(:publisher)
    assert(publisher.errors.empty?, "@publisher should not have errors, but has: #{publisher.errors.full_messages}") if publisher
    assert_redirected_to edit_publisher_path(assigns(:publisher))
    assert(flash[:notice].any?, "Should have flash")
    assert_equal false, publisher.link_to_email?, "link_to_email? should be updated"
    assert_equal false, publisher.link_to_map?, "link_to_map? should be updated"
    assert_equal false, publisher.link_to_website?, "link_to_website? should be updated"

    publishing_group = PublishingGroup.find_by_name("New Publishing Group")
    assert_not_nil publishing_group, "Should have created new publishing group"
    assert_equal publishing_group, publisher.publishing_group, "Should belong to new publishing group"
  end

  def test_update_removing_publishing_group
    publishers(:my_space).update_attributes! :publishing_group => publishing_groups(:student_discount_handbook)

    with_admin_user_required(:quentin, :aaron) do
      put(:update, :id => publishers(:my_space).to_param, :publisher => {
        :name => "updated",
        :publishing_group_id => "",
        :publishing_group_name => "",
        :label => "updated",
        :link_to_email => false,
        :link_to_map => false,
        :link_to_website => false
      })
    end
    publisher = assigns(:publisher)
    assert(publisher.errors.empty?, "@publisher should not have errors, but has: #{publisher.errors.full_messages}") if publisher
    assert_redirected_to edit_publisher_path(assigns(:publisher))
    assert(flash[:notice].any?, "Should have flash")
    assert_equal false, publisher.link_to_email?, "link_to_email? should be updated"
    assert_equal false, publisher.link_to_map?, "link_to_map? should be updated"
    assert_equal false, publisher.link_to_website?, "link_to_website? should be updated"
    assert_nil publisher.publishing_group, "Should remove associating to publishing group"
  end

  def test_invalid_update
    with_admin_user_required(:quentin, :aaron) do
      put(:update, :id => publishers(:my_space).to_param, :publisher => {
        :name => "",
        :publishing_group_id => "",
        :publishing_group_name => "",
        :label => "",
        :link_to_email => false,
        :link_to_map => false,
        :link_to_website => false
      })
    end
    publisher = assigns(:publisher)
    assert_not_nil publisher, "Should assign @publisher"
    assert publisher.errors.present?, "@publisher should have errors"
    assert_response :success
  end

  def test_update_with_uk_address
    uk = Country::UK
    publisher = Factory(:publisher_with_uk_address)
    with_admin_user_required(:quentin, :aaron) do
      put(:update, :id => publisher.to_param, :publisher => {
        :address_line_1 => "296 Farnborough Road",
        :address_line_2 => nil,
        :zip => "GU24 7NU",
        :phone_number => "01252 666 555",
      })
    end
    publisher = assigns(:publisher)
    assert publisher.errors.empty?, "@publisher should not have errors, but has: #{publisher.errors.full_messages}" if publisher
    assert_redirected_to edit_publisher_path(assigns(:publisher))
    assert flash[:notice].any?, "Should have flash"
    assert_nil publisher.publishing_group, "Should not have a publishing group"
    assert_equal uk, publisher.country
    assert_equal "Hants", publisher.region
    assert_equal nil, publisher.state
    assert_equal "GU24 7NU", publisher.zip
    assert_equal "4401252666555", publisher.phone_number
  end

end
