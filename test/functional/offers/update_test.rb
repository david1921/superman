require File.dirname(__FILE__) + "/../../test_helper"

class OffersController::UpdateTest < ActionController::TestCase
  tests OffersController

  def test_update
    advertiser = advertisers(:changos)
    offer = advertiser.offers.create!(:message => "Free yogurt with your taco")
    check_response = lambda { |role|
      assert_redirected_to edit_advertiser_path(advertiser), role
      assert_equal "New Message", offer.reload.message, "Updated offer as #{role}"
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      offer.update_attributes! :message => "Old Message"
      post :update, :id => offer.to_param, :advertiser_id => advertiser.to_param, :offer => {
        :category_names => "Dairy: Yogurt, Kids",
        :terms => "Free yogurt must be of equal or lesser value. Good w/ coupon through 7/31/09",
        :message => "New Message"
      }
    end
  end

  def test_invalid_update
    advertiser = advertisers(:changos)
    offer = advertiser.offers.create!(:message => "Free yogurt with your taco")
    check_response = lambda { |role|
      assert_response :success, role
      assert_template :edit
      offer = assigns(:offer)
      assert offer.errors.present?, "Offer should have errors as #{role}"
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      post :update, :id => offer.to_param, :advertiser_id => advertiser.to_param, :offer => {
        :category_names => "Dairy: Yogurt, Kids",
        :terms => "Free yogurt must be of equal or lesser value. Good w/ coupon through 7/31/09",
        :message => ""
      }
    end
  end

  context "update" do
    setup do
      @offer = Factory(:offer)
      @advertiser = @offer.advertiser
    end

    should "render edit on stale object error" do
      Offer.any_instance.expects(:update_attributes).raises(ActiveRecord::StaleObjectError)

      login_as Factory(:admin)

      post :update, :id => @offer.to_param, :advertiser_id => @advertiser.id, :offer => {
        :terms => "Free yogurt must be of equal or lesser value. Good w/ coupon through 7/31/09",
        :message => "My message is from a messenger." }

      assert_response :success
      assert_template :edit
      assert_equal "There was a change to the offer before your save. Please edit again.", flash[:error]
      assert_equal @offer, assigns(:offer)
    end
  end
end
