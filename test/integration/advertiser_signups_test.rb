require File.dirname(__FILE__) + "/../test_helper"

class AdvertiserSignupsTest < ActionController::IntegrationTest
  def test_happy_path
    publisher = publishers(:sdh_austin)
    publisher.update_attributes! :advertiser_self_serve => true
    
    get new_publisher_advertiser_signup_path(publisher)
    assert_response :success
    
    post publisher_advertiser_signups_path(publisher), :advertiser_signup => {
      :advertiser_name => "Mary's Club",
      :email => "mary@example.com",
      :password => "trustno1",
      :password_confirmation => "trustno1"
    }
    
    advertiser = assigns(:advertiser)
    assert_redirected_to edit_advertiser_path(advertiser)
    
    put advertiser_path(advertiser), 
        :publisher_id => publisher.to_param,
        :advertiser => {
          :name => "Mary's Club",
          :coupon_clipping_modes => [ "email" ],
          :website_url => "http://www.530marketplace.com",
          :email_address => "mary@example.com",
          :stores_attributes => {
            "0" => {
              :city => "Marysville",
              :zip => "95901",
              :address_line_1 => "1530 Ellis Lake Dr.",
              :phone_number => "(530) 741-2345",
              :address_line_2 => "OCEAN BEACH",
              :state => "OR"
            }
          }
        }

    assert_redirected_to new_advertiser_offer_path(advertiser)
    advertiser = assigns(:advertiser)
    assert_equal "http://www.530marketplace.com", advertiser.website_url, "website_url"
    assert_not_nil advertiser.store, "Should create store"
    assert_equal "Marysville", advertiser.store.city, "Store city"
    
    post advertiser_offers_path(advertiser),
      :offer => {
        :message => "My Offer",
        :txt_message => "txt"
      }
    
    assert_redirected_to edit_advertiser_path(advertiser)
    offer = assigns(:offer)
    assert_equal "My Offer", offer.message, "offer.message"
    
    logout

    get edit_advertiser_path(advertiser)
    assert_redirected_to new_session_path

    post session_path, :user => { :login => "mary@example.com", :password => "trustno1", :remember_me_tag => true }
    assert_redirected_to edit_advertiser_path(advertiser)    
  end
  
  def logout
    get logout_path
    assert_redirected_to login_path
    assert_nil session[:user_id]    
  end
end
