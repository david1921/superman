require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class AdvertisersController::Edit::CouponLinkTest

module AdvertisersController::Edit
  class CouponLinkTest < ActionController::TestCase
    tests AdvertisersController

    should "not have delete coupon link for non-admin users" do
      user = Factory(:user)
      user.company.tap do |publisher|
        publisher.self_serve = true
        publisher.save!
      end
      advertiser = Factory(:advertiser, :publisher => user.company)
      coupon = Factory(:offer, :advertiser => advertiser)

      login_as(user)
      get :edit, :id => advertiser.to_param
      assert_response :ok
      assert_template 'edit'
      assert_select "#coupon_#{coupon.id}"
      assert_select "a[href=#{advertiser_offer_path(advertiser, coupon)}]", :text => "Delete", :count => 0
    end

    should "have delete coupon link for full admin user" do
      user = Factory(:admin)
      coupon = Factory(:offer)
      advertiser = Advertiser.find(coupon.advertiser_id)

      login_as(user)
      get :edit, :id => advertiser.to_param
      assert_response :ok
      assert_template 'edit'
      assert_select "#coupon_#{coupon.id}"
      assert_select "a[href=#{advertiser_offer_path(advertiser, coupon)}]", :text => "Delete", :count => 1
    end

    should "have delete coupon link for restricted admin user" do
      user = Factory(:restricted_admin)
      coupon = Factory(:offer)
      advertiser = Advertiser.find(coupon.advertiser_id)
      user.user_companies.create!(:company => advertiser.publisher)

      login_as(user)
      get :edit, :id => advertiser.to_param
      assert_response :ok
      assert_template 'edit'
      assert_select "#coupon_#{coupon.id}"
      assert_select "a[href=#{advertiser_offer_path(advertiser, coupon)}]", :text => "Delete", :count => 1
    end
  end
end
