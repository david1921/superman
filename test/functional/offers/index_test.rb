require File.dirname(__FILE__) + "/../../test_helper"

class OffersController::IndexTest < ActionController::TestCase
  tests OffersController

  def test_index
    advertiser = advertisers(:changos)
    with_user_required(:aaron) do
      get :index, :advertiser_id => advertiser.to_param
    end
    assert_equal advertiser, assigns(:advertiser), "@advertiser"
  end

  def test_index_without_advertiser
    with_user_required(:aaron) do
      get :index
    end
    advertiser = assigns(:advertiser)
    assert_not_nil advertiser, "@advertiser"
    assert users(:aaron).can_manage?(advertiser), "Should assign manageable Advertiser"
  end

  def test_anonymous_index
    advertiser = advertisers(:changos)
    get :index
    assert_redirected_to new_session_path
  end

  def test_demo_index
    create_demo_user!
    get :index
    assert_response :success
    assert_equal advertisers(:burger_king), assigns(:advertiser), "@advertiser"
  end

end
