require File.dirname(__FILE__) + "/../../test_helper"

class OffersController::EmailAndTxtTest < ActionController::TestCase
  tests OffersController

  def test_email
    offer = offers(:my_space_burger_king_free_fries)
    publisher = publishers(:sdh_austin)
    xhr :post, :email, :id => offer.to_param, :publisher_id => publisher.to_param
    assert_response :success
    assert_nil session[:user_id], "Should not automatically login user"
    assert_equal offer, assigns(:offer), "assigns @offer"
    assert_template 'offers/email.rjs'
    lead = assigns(:lead)
    assert_not_nil lead, "@lead assignment"
    assert_equal publisher, lead.publisher
  end

  def test_email_with_advertiser_id
    offer       = offers(:my_space_burger_king_free_fries)
    advertiser  = offer.advertiser
    xhr :post, :email, :id => offer.to_param, :advertiser_id => advertiser.to_param
    assert_response :success
    assert_nil session[:user_id], "Should not automatically login user"
    assert_equal offer, assigns(:offer), "assigns @offer"
    assert_template 'advertisers/offers/email.rjs'
    lead = assigns(:lead)
    assert_not_nil lead, "@lead assignment"
    assert_equal advertiser.publisher, lead.publisher
  end

  def test_xd_email
    offer = offers(:my_space_burger_king_free_fries)
    publisher = publishers(:sdh_austin)
    get :xd_email, :id => offer.to_param, :publisher_id => publisher.to_param
    assert_response :success
    assert_nil session[:user_id], "Should not automatically login user"
    assert_equal offer, assigns(:offer), "assigns @offer"
    assert_template 'offers/panels/_email.html.erb'
    assert_layout   'offers/xd_lead_panel'
    lead = assigns(:lead)
    assert_not_nil lead, "@lead assignment"
    assert_equal publisher, lead.publisher
  end

  def test_xd_email_with_advertiser_id
    offer       = offers(:my_space_burger_king_free_fries)
    advertiser  = offer.advertiser
    get :xd_email, :id => offer.to_param, :advertiser_id => advertiser.to_param
    assert_response :success
    assert_nil session[:user_id], "Should not automatically login user"
    assert_equal offer, assigns(:offer), "assigns @offer"
    assert_template 'advertisers/offers/_xd_email.html.erb'
    assert_layout   'advertisers/xd_lead_panel'
    lead = assigns(:lead)
    assert_not_nil lead, "@lead assignment"
    assert_equal advertiser.publisher, lead.publisher
  end

  def test_txt
    offer = offers(:my_space_burger_king_free_fries)
    publisher = publishers(:sdh_austin)
    xhr :post, :txt, :id => offer.to_param, :publisher_id => publisher.to_param
    assert_response :success
    assert_nil session[:user_id], "Should not automatically login user"
    assert_equal offer, assigns(:offer), "assigns @offer"
    assert_template 'offers/txt.rjs'
    lead = assigns(:lead)
    assert_not_nil lead, "@lead assignment"
    assert_equal publisher, lead.publisher
  end

  def test_txt_with_advertiser_id
    offer       = offers(:my_space_burger_king_free_fries)
    advertiser  = offer.advertiser
    xhr :post, :txt, :id => offer.to_param, :advertiser_id => advertiser.to_param
    assert_response :success
    assert_nil session[:user_id], "Should not automatically login user"
    assert_equal offer, assigns(:offer), "assigns @offer"
    assert_template 'advertisers/offers/txt.rjs'
    lead = assigns(:lead)
    assert_not_nil lead, "@lead assignment"
    assert_equal advertiser.publisher, lead.publisher
  end

  def test_xd_txt
    offer = offers(:my_space_burger_king_free_fries)
    publisher = publishers(:sdh_austin)
    get :xd_txt, :id => offer.to_param, :publisher_id => publisher.to_param
    assert_response :success
    assert_nil session[:user_id], "Should not automatically login user"
    assert_equal offer, assigns(:offer), "assigns @offer"
    assert_template 'offers/panels/_txt.html.erb'
    assert_layout   'offers/xd_lead_panel'
    lead = assigns(:lead)
    assert_not_nil lead, "@lead assignment"
    assert_equal publisher, lead.publisher
  end

  def test_xd_txt_with_advertiser_id
    offer       = offers(:my_space_burger_king_free_fries)
    advertiser  = offer.advertiser
    get :xd_txt, :id => offer.to_param, :advertiser_id => advertiser.to_param
    assert_response :success
    assert_nil session[:user_id], "Should not automatically login user"
    assert_equal offer, assigns(:offer), "assigns @offer"
    assert_template 'advertisers/offers/_xd_txt.html.erb'
    assert_layout   'advertisers/xd_lead_panel'
    lead = assigns(:lead)
    assert_not_nil lead, "@lead assignment"
    assert_equal advertiser.publisher, lead.publisher
  end
end
