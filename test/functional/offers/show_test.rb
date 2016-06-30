require File.dirname(__FILE__) + "/../../test_helper"

class OffersController::ShowTest < ActionController::TestCase
  tests OffersController

  def test_show
    locm = publishers(:locm)
    advertiser = locm.advertisers.create!(:listing => "1234")
    offer = advertiser.offers.create!(:message => "buy more")
    get :show, :id => offer.to_param
    assert_response :success
    assert_layout "offers/show"
    assert_not_nil assigns(:offer), "assigns :offer"
    assert_equal locm, assigns(:publisher), "@publisher"
    assert_select "div.embedded_coupon"
    assert_select "div.narrow"
    assert_select "link[href=?]", /\/stylesheets\/narrow\/offers.css.*/
  end

  def test_show_deleted
    locm = publishers(:locm)
    offer = locm.advertisers.create!(:listing => "1234").offers.create!(:message => "buy more", :deleted_at => Time.now)
    get :show, :id => offer.to_param
    assert_response :success
    assert_layout "offers/show"
    assert_not_nil assigns(:offer), "assigns :offer"
    assert_equal locm, assigns(:publisher), "@publisher"
    assert_select "div.embedded_coupon"
    assert_select "div.narrow"
    assert_select "link[href=?]", /\/stylesheets\/narrow\/offers.css.*/
  end
end
