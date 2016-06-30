require File.dirname(__FILE__) + "/../../test_helper"

class OffersController::CreateTest < ActionController::TestCase
  tests OffersController

  def test_create
    advertiser = advertisers(:changos)
    check_response = lambda { |role|
      assert_redirected_to edit_advertiser_path(advertiser), role
      offer = assigns(:offer)
      assert offer.errors.empty?, "As #{role}: #{offer.errors.full_messages}"
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      put :create, :advertiser_id => advertiser.to_param, :offer => {
        :value_proposition => "Value", :category_names => "Fish: Tropical", :value_proposition => "Detail", :message => "Message"
      }
    end
  end

  def test_invalid_create
    advertiser = advertisers(:changos)
    check_response = lambda { |role|
      assert_response :success, role
      assert_template :edit, role
      offer = assigns(:offer)
      assert offer.errors.any?, "Offer should have errors as #{role}"
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      put :create, :advertiser_id => advertiser.to_param, :offer => {
        :value_proposition => "", :category_names => "", :value_proposition => "", :message => ""
      }
    end
  end

  def test_invalid_create_with_image
    advertiser = advertisers(:changos)
    check_response = lambda { |role|
      assert_response :success, role
      assert_template :edit, role
      offer = assigns(:offer)
      assert offer.errors.any?, "Offer should have errors as #{role}"
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      put :create, :advertiser_id => advertiser.to_param, :offer => {
        :value_proposition => "", :category_names => "", :value_proposition => "", :message => "",
        :offer_image => ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png'),
        :photo => ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
      }
    end
  end

end
