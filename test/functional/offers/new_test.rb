require File.dirname(__FILE__) + "/../../test_helper"

class OffersController::NewTest < ActionController::TestCase
  assert_no_angle_brackets :except => [ :test_new_when_publishing_group_has_categories ]

  tests OffersController

  def test_new
    advertiser = advertisers(:changos)
    check_response = lambda { |role|
      assert_response :success, role
      assert_template :edit, role
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      get :new, :advertiser_id => advertiser.to_param
    end
  end

  test "new when publishing group has categories" do
    advertiser = Factory(:advertiser)
    advertiser.publisher.update_attribute(:self_serve, true)
    user = Factory(:user, :company => advertiser.publisher)

    publishing_group = advertiser.publisher.publishing_group
    category = Factory(:category)
    publishing_group.categories << category

    login_as user

    get :new, :advertiser_id => advertiser.to_param
    assert_select "#category_ids_categories", true
    assert_select "input[name='offer[account_executive]']"
  end

  test "new when publishing group does not have categories" do
    advertiser = Factory(:advertiser)
    advertiser.publisher.update_attribute(:self_serve, true)
    user = Factory(:user, :company => advertiser.publisher)
    login_as user
    get :new, :advertiser_id => advertiser.to_param
    assert_select "#category_ids_categories", false
    assert_select "input[name='offer[account_executive]']"
  end

end
