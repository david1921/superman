require File.dirname(__FILE__) + "/../test_helper"

class LeadsControllerTest < ActionController::TestCase
  setup :set_remote_addr
  
  def set_remote_addr
    @request.remote_addr = "196.255.151.209"
  end

  def test_create_for_publisher_with_remote_addr
    Lead.destroy_all
  
    offer = offers(:my_space_burger_king_free_fries)
    post :create, :offer_id => offer.to_param, :lead => {
      :publisher_id => offer.publisher.to_param,
      :mobile_number => "9876543210",
      :txt_me => true
    }
    assert_response :success
    assert_equal 1, Lead.count, "Should create one lead"

    lead = Lead.find(:first)
    assert_equal "196.255.151.209", lead.remote_ip, "Should set remote_ip from REMOTE_ADDR header"
  end

  def test_create_call_for_publisher
    Lead.destroy_all
  
    offer = offers(:my_space_burger_king_free_fries)
    post :create, :offer_id => offer.to_param, :lead => {
      :publisher_id => offer.publisher.to_param,
      :mobile_number => "9876543210",
      :call_me => true
    }
    assert_response :success
    assert_equal 1, Lead.count, "Should create one lead"
    assert_not_nil assigns(:lead), "@lead"
  end

  def test_invalid_email_create_for_publisher
    Lead.destroy_all
  
    offer = offers(:my_space_burger_king_free_fries)
    post :create, :offer_id => offer.to_param, :lead => {
      :publisher_id => offer.publisher.to_param,
      :email => "",
      :email_me => true
    }
    assert_response :success
    assert_equal 0, Lead.count, "Should not create one lead"
    
    assert_not_nil assigns(:lead), "@lead"
    assert_not_nil assigns(:offer), "@offer"
    assert assigns(:lead).errors.present?, "Lead should be invalid"
    assert_template "offers/panels/_email.html.erb"
  end

  def test_invalid_txt_create_for_publisher
    Lead.destroy_all
  
    offer = offers(:my_space_burger_king_free_fries)
    post :create, :offer_id => offer.to_param, :lead => {
      :publisher_id => offer.publisher.to_param,
      :mobile_number => "",
      :txt_me => true
    }
    assert_response :success
    assert_equal 0, Lead.count, "Should not create one lead"
    
    assert_not_nil assigns(:lead), "@lead"
    assert_not_nil assigns(:offer), "@offer"
    assert assigns(:lead).errors.present?, "Lead should be invalid"
    assert_template "offers/panels/_txt.html.erb"
  end
end
