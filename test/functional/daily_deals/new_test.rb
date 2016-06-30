require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::NewTest < ActionController::TestCase
  tests DailyDealsController

  def setup
  	login_as Factory(:admin)
  end

  test "should use PublishingGroup voucher_has_qr_code_default default" do
    publishing_group = Factory(:publishing_group, :voucher_has_qr_code_default => true)
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    advertiser = Factory(:advertiser, :publisher => publisher)

    get :new, :advertiser_id => advertiser.id

    daily_deal = assigns(:daily_deal)
    assert_equal true, daily_deal.voucher_has_qr_code
    assert_equal true, daily_deal.voucher_has_qr_code?
  end

  test "should default to blank if no PublishingGroup " do
    advertiser = Factory(:advertiser)

    get :new, :advertiser_id => advertiser.id

    daily_deal = assigns(:daily_deal)
    assert_equal "", daily_deal.terms
  end

  test "should default to blank if  PublishingGroup terms_default default" do
    publishing_group = Factory(:publishing_group)
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    advertiser = Factory(:advertiser, :publisher => publisher)

    get :new, :advertiser_id => advertiser.id

    daily_deal = assigns(:daily_deal)
    assert_equal "", daily_deal.terms
  end

  test "should use PublishingGroup terms_default default" do
    publishing_group = Factory(:publishing_group, :terms_default => "One per customer")
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    advertiser = Factory(:advertiser, :publisher => publisher)

  	get :new, :advertiser_id => advertiser.id

  	daily_deal = assigns(:daily_deal)
    assert_equal "<p>One per customer</p>", daily_deal.terms
  end
end
