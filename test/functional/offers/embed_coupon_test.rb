require File.dirname(__FILE__) + "/../../test_helper"

class OffersController::EmbedCouponTest < ActionController::TestCase
  tests OffersController

  def test_embed_coupon
    locm = publishers(:locm)
    advertiser = locm.advertisers.create!(:listing => "1234")
    offer = advertiser.offers.create!(:message => "buy more")
    get :embed_coupon, :id => offer.label, :format => "js"
    assert_response :success
    assert_layout nil
    assert_equal offer, assigns(:offer), "@offer"
  end

  def test_embed_coupon_with_label
    locm = publishers(:locm)
    advertiser = locm.advertisers.create!(:listing => "1234")
    offer = advertiser.offers.create!(:message => "buy more")
    offer.update_attribute :label, "123abc"
    get :embed_coupon, :id => "123abc", :format => "js"
    assert_response :success
    assert_layout nil
    assert_equal offer, assigns(:offer), "@offer"
  end

  def test_embed_coupon_not_found
    locm = publishers(:locm)
    advertiser = locm.advertisers.create!(:listing => "1234")
    offer = advertiser.offers.create!(:message => "buy more")
    offer.update_attribute :label, "123abc"
    get :embed_coupon, :id => "7777777", :format => "js"
    assert_response :not_found
  end
end
