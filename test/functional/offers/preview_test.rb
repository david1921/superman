require File.dirname(__FILE__) + "/../../test_helper"

class OffersController::PreviewTest < ActionController::TestCase
  tests OffersController

  def test_preview_without_valid_account
    publisher   = publishers(:my_space)
    advertiser  = publisher.advertisers.create!( :name => "My Advertiser" )
    offer       = advertiser.offers.create!(:message => "buy more")

    get :preview, :id => offer.to_param

    assert_redirected_to new_session_path
  end

  def test_preview_with_enhanced_theme
    advertiser = advertisers(:di_milles)
    publisher  = advertiser.publisher
    offer      = advertiser.offers.create!(:message => "buy more")

    publisher.reload
    publisher.update_attribute(:theme, 'enhanced')

    with_user_required(:aaron) do
      get :preview, :id => offer.to_param
    end

    assert_response :success
    assert_template 'offers/preview'
    assert_layout   'offers/public_index'
    assert assigns(:publisher)
    assert assigns(:offers)
    assert_equal 0, offer.impressions
  end

  def test_preview_with_simple_layout
    advertiser = advertisers(:di_milles)
    publisher  = advertiser.publisher
    offer      = advertiser.offers.create!(:message => "buy more")

    publisher.reload
    publisher.update_attribute(:theme, 'simple')

    with_user_required(:aaron) do
      get :preview, :id => offer.to_param
    end

    assert_response :success
    assert_template 'offers/preview'
    assert_layout   'offers/public_index'
    assert assigns(:publisher)
    assert assigns(:offers)
    assert_equal 0, offer.impressions
  end

  def test_preview_with_narrow_layout
    advertiser = advertisers(:di_milles)
    publisher  = advertiser.publisher
    offer      = advertiser.offers.create!(:message => "buy more")

    publisher.reload
    publisher.update_attribute(:theme, 'narrow')

    with_user_required(:aaron) do
      get :preview, :id => offer.to_param
    end

    assert_response :success
    assert_template 'offers/preview'
    assert_layout   'offers/public_index'
    assert assigns(:publisher)
    assert assigns(:offers)
    assert_equal 0, offer.impressions
  end

  def test_preview_with_sdcitybeat_layout
    advertiser = Factory(:advertiser)
    publisher  = advertiser.publisher
    offer      = advertiser.offers.create!(:message => "buy more")

    publisher.reload
    publisher.update_attribute(:theme, 'sdcitybeat')

    with_user_required(:aaron) do
      get :preview, :id => offer.to_param
    end

    assert_response :success
    assert_template 'offers/sdcitybeat/preview'
    assert_layout   'offers/public_index'
    assert assigns(:publisher)
    assert assigns(:offers)
    assert_equal 0, offer.impressions
  end

  def test_preview_with_sdcitybeat_layout_and_universityofarizonatucson_label
    advertiser = advertisers(:di_milles)
    publisher  = advertiser.publisher
    offer      = advertiser.offers.create!(:message => "buy more")

    publisher.reload
    publisher.update_attributes(:theme => 'sdcitybeat', :label => 'universityofarizonatucson')

    with_user_required(:aaron) do
      get :preview, :id => offer.to_param
    end

    assert_response :success
    assert_template 'offers/universityofarizonatucson/preview'
    assert_layout   'offers/public_index'
    assert assigns(:publisher)
    assert assigns(:offers)
    assert_equal 0, offer.impressions
  end
end
