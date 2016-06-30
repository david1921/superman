require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::CreateTest < ActionController::TestCase
  tests DailyDealsController

  def setup
    login_as Factory(:admin)
  end

  test "should use voucher_has_qr_code default" do
    advertiser = Factory(:advertiser)
    post :create,
       :advertiser_id => advertiser.id,
       :daily_deal => Factory.attributes_for(:daily_deal, :voucher_has_qr_code => false)

    daily_deal = assigns(:daily_deal)
    assert_equal false, daily_deal.voucher_has_qr_code
    assert_equal false, daily_deal.voucher_has_qr_code?
  end

  test "should honor checked voucher_has_qr_code" do
    advertiser = Factory(:advertiser)
    post :create,
       :advertiser_id => advertiser.id,
       :daily_deal => Factory.attributes_for(:daily_deal, :voucher_has_qr_code => true)

    daily_deal = assigns(:daily_deal)
    assert_equal true, daily_deal.voucher_has_qr_code
    assert_equal true, daily_deal.voucher_has_qr_code?
  end

  test "should honor false publishing group voucher_has_qr_code default" do
    publishing_group = Factory(:publishing_group, :voucher_has_qr_code_default => false)
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    advertiser = Factory(:advertiser, :publisher => publisher)
    post :create,
       :advertiser_id => advertiser.id,
       :daily_deal => Factory.attributes_for(:daily_deal)

    daily_deal = assigns(:daily_deal)
    assert_equal false, daily_deal.voucher_has_qr_code
    assert_equal false, daily_deal.voucher_has_qr_code?
  end

  test "should honor true publishing group voucher_has_qr_code default" do
    publishing_group = Factory(:publishing_group, :voucher_has_qr_code_default => true)
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    advertiser = Factory(:advertiser, :publisher => publisher)
    post :create,
       :advertiser_id => advertiser.id,
       :daily_deal => Factory.attributes_for(:daily_deal)

    daily_deal = assigns(:daily_deal)
    assert_equal true, daily_deal.voucher_has_qr_code
    assert_equal true, daily_deal.voucher_has_qr_code?
  end

  test "should override publishing group voucher_has_qr_code default" do
    publishing_group = Factory(:publishing_group, :voucher_has_qr_code_default => true)
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    advertiser = Factory(:advertiser, :publisher => publisher)
    post :create,
       :advertiser_id => advertiser.id,
       :daily_deal => Factory.attributes_for(:daily_deal, :voucher_has_qr_code => false)

    daily_deal = assigns(:daily_deal)
    assert_equal false, daily_deal.voucher_has_qr_code
    assert_equal false, daily_deal.voucher_has_qr_code?
  end

  test "should override publishing group voucher_has_qr_code default with true" do
    publishing_group = Factory(:publishing_group, :voucher_has_qr_code_default => false)
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    advertiser = Factory(:advertiser, :publisher => publisher)
    post :create,
       :advertiser_id => advertiser.id,
       :daily_deal => Factory.attributes_for(:daily_deal, :voucher_has_qr_code => true)

    daily_deal = assigns(:daily_deal)
    assert_equal true, daily_deal.voucher_has_qr_code
    assert_equal true, daily_deal.voucher_has_qr_code?
  end

  test "should use max_quantity default" do
    advertiser = Factory(:advertiser)
    post :create,
       :advertiser_id => advertiser.id,
       :daily_deal => Factory.attributes_for(:daily_deal, :max_quantity => 7)

    daily_deal = assigns(:daily_deal)
    assert_equal 7, daily_deal.max_quantity
  end

  test "should honor publishing group max_quantity default" do
    publishing_group = Factory(:publishing_group, :max_quantity_default => 23)
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    advertiser = Factory(:advertiser, :publisher => publisher)
    post :create,
       :advertiser_id => advertiser.id,
       :daily_deal => Factory.attributes_for(:daily_deal)

    daily_deal = assigns(:daily_deal)
    assert_equal 23, daily_deal.max_quantity
  end

  test "should override publishing group max_quantity default" do
    publishing_group = Factory(:publishing_group, :max_quantity_default => 19)
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    advertiser = Factory(:advertiser, :publisher => publisher)
    post :create,
       :advertiser_id => advertiser.id,
       :daily_deal => Factory.attributes_for(:daily_deal, :max_quantity => 11)

    daily_deal = assigns(:daily_deal)
    assert_equal 11, daily_deal.max_quantity
  end

  test "should use terms default" do
    advertiser = Factory(:advertiser)
    post :create,
       :advertiser_id => advertiser.id,
       :daily_deal => Factory.attributes_for(:daily_deal, :terms => "no whiners")

    daily_deal = assigns(:daily_deal)
    assert_equal "<p>no whiners</p>", daily_deal.terms
  end

  test "should override publishing group terms default" do
    publishing_group = Factory(:publishing_group, :terms_default => "Must bring photo ID")
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    advertiser = Factory(:advertiser, :publisher => publisher)
    post :create,
       :advertiser_id => advertiser.id,
       :daily_deal => Factory.attributes_for(:daily_deal, :terms => "$2 parking fee")

    daily_deal = assigns(:daily_deal)
    assert_equal "<p>$2 parking fee</p>", daily_deal.terms
  end
end
