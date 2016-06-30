require File.dirname(__FILE__) + "/../test_helper"

class PurchasedGiftCertificatesControllerTest < ActionController::TestCase
  setup :setup_mailer_expectation, :create_purchased_gift_certificate
  
  def setup_mailer_expectation
    GiftCertificateMailer.expects(:deliver_gift_certificate).at_least(0).returns(nil)    
  end
  
  def test_validate_routing
    assert_generates "/purchased_gift_certificates/validate", :controller => "purchased_gift_certificates", :action => "validate"
  end
  
  def test_redeem_routing
    assert_generates "/purchased_gift_certificates/redeem", :controller => "purchased_gift_certificates", :action => "redeem"
  end
  
  def test_ivr_validate_routing
    assert_generates "/purchased_gift_certificates/ivr_validate", :controller => "purchased_gift_certificates", :action => "ivr_validate"
  end
  
  def test_ivr_redeem_routing
    assert_generates "/purchased_gift_certificates/ivr_redeem", :controller => "purchased_gift_certificates", :action => "ivr_redeem"
  end
  
  def test_validate_without_serial_number
    with_user_required(:jimmy) do
      get :validate
    end
    assert_response :success
    assert_match /serial number to be validated/i, flash[:notice]
    
    assert_select "form[action=#{validate_purchased_gift_certificates_path}][method=get]", 1 do
      assert_select "input[type=text][name=serial_number]", 1
      assert_select "input[type=submit]", 1
    end
  end
  
  def test_validate_with_invalid_serial_number
    with_user_required(:jimmy) do
      get :validate, :serial_number => "1234-5678"
    end
    assert_response :success
    assert_match /1234\-5678 is not valid/i, assigns(:errors)
    
    assert_select "p.warn", assigns(:errors)
    assert_select "form[action=#{validate_purchased_gift_certificates_path}][method=get]", 1 do
      assert_select "input[type=text][name=serial_number]", 1
      assert_select "input[type=submit]", 1
    end
  end
  
  def test_validate_with_valid_serial_number_not_redeemed
    assert !@purchased_gift_certificate.redeemed?, "Purchased deal certificate should not be redeemed yet"
    
    with_user_required(:jimmy) do
      get :validate, :serial_number => @purchased_gift_certificate.serial_number
    end
    assert_response :success
    assert_match /#{@purchased_gift_certificate.serial_number} is valid/i, assigns(:status)
    assert_equal @purchased_gift_certificate, assigns(:purchased_gift_certificate)    
      
    assert_select "p.notice", assigns(:status)
    assert_select "form[action=#{redeem_purchased_gift_certificates_path}][method=post]" do
      assert_select "input[type=hidden][name=serial_number][value='#{@purchased_gift_certificate.serial_number}']", 1
      assert_select "input[type=text][name=serial_number][disabled=disabled]", 1
      assert_select "input[type=text][name=merchant][disabled=disabled]", 1
      assert_select "input[type=text][name=value][disabled=disabled]", 1
      assert_select "input[type=button][value=Cancel]", 1
      assert_select "input[type=submit]", 1
    end
  end
  
  def test_validate_with_valid_serial_number_already_redeemed
    assert @purchased_gift_certificate.update_attributes! :redeemed => true
    
    with_user_required(:jimmy) do
      get :validate, :serial_number => @purchased_gift_certificate.serial_number
    end
    assert_response :success
    assert_match /#{@purchased_gift_certificate.serial_number} is INVALID. Reason: it was already redeemed./i, assigns(:errors)
    assert @purchased_gift_certificate.reload.redeemed?, "Purchased deal certificate should still be redeemed"
      
    assert_select "p.warn", assigns(:errors)
    assert_select "form[action=#{validate_purchased_gift_certificates_path}][method=get]" do
      assert_select "input[type=text][name=serial_number]", 1
      assert_select "input[type=submit]", 1
    end
  end
  
  def test_redeem_with_valid_serial_number
    assert !@purchased_gift_certificate.redeemed?, "Purchased deal certificate should not be redeemed yet"
    
    with_user_required(:jimmy) do
      put :redeem, :serial_number => @purchased_gift_certificate.serial_number
    end
    assert_response :success
    assert_template :validate
    assert_match /#{@purchased_gift_certificate.serial_number} marked as redeemed/i, flash[:notice]
    assert @purchased_gift_certificate.reload.redeemed?, "Purchased deal certificate should be redeemed"
    
    assert_select "form[action=#{validate_purchased_gift_certificates_path}][method=get]", 1 do
      assert_select "input[type=text][name=serial_number]", 1
      assert_select "input[type=submit]", 1
    end
  end
  
  def test_redeem_with_valid_invalid_serial_number
    with_user_required(:jimmy) do
      put :redeem, :serial_number => "1234-5678"
    end
    assert_response :success
    assert_template :validate
    assert_match /could not locate deal certificate/i, flash[:warn]
    assert_match /serial number to be validated/i, flash[:notice]
    assert !@purchased_gift_certificate.reload.redeemed?, "Purchased deal certificate should not be redeemed"
    
    assert_select "form[action=#{validate_purchased_gift_certificates_path}][method=get]", 1 do
      assert_select "input[type=text][name=serial_number]", 1
      assert_select "input[type=submit]", 1
    end
  end
  
  def test_ivr_validate_with_valid_serial_number_not_redeemed
    @purchased_gift_certificate.update_attribute :serial_number, "1234-5678"
    assert_equal "1234-5678", @purchased_gift_certificate.reload.serial_number
    assert !@purchased_gift_certificate.redeemed?, "Purchased deal certificate should not be redeemed yet"
    
    get :ivr_validate, {
      :serial_number => "12345678",
      :survo_1 => "11111",
      :survo_2 => "22222"
    }
    assert_response :success
    expected_response = {
      "action" => {
        "app" => "SurVo",
        "parameters" => {
          "id" => "22222",
          "user_parameters" => {
            "please" => "Certificate, 1, 2, 3, 4, 5, 6, 7, 8, is confirmed as valid! For Changos, with a value of, $40.00."
          },
          "p_t" => "serial_number|1234-5678"
        }
      }
    }
    assert_equal expected_response, Hash.from_xml(@response.body)
  end
  
  def test_ivr_validate_with_valid_serial_number_already_redeemed
    @purchased_gift_certificate.update_attribute :serial_number, "1234-5678"
    assert_equal "1234-5678", @purchased_gift_certificate.reload.serial_number
    @purchased_gift_certificate.redeem!
    
    get :ivr_validate, {
      :serial_number => "12345678",
      :survo_1 => "11111",
      :survo_2 => "22222"
    }
    assert_response :success
    expected_response = {
      "action" => {
        "app" => "SurVo",
        "parameters" => {
          "id" => "11111",
          "user_parameters" => {
            "please" => "Certificate, 1, 2, 3, 4, 5, 6, 7, 8, is already marked as redeemed! To verify another certificate, please"
          },
          "p_t" => "serial_number|1234-5678"
        }
      }
    }
    assert_equal expected_response, Hash.from_xml(@response.body)
  end
  
  def test_ivr_validate_with_invalid_serial_number
    get :ivr_validate, {
      :serial_number => "123456",
      :survo_1 => "11111",
      :survo_2 => "22222"
    }
    assert_response :success
    expected_response = {
      "action" => {
        "app" => "SurVo",
        "parameters" => {
          "id" => "11111",
          "user_parameters" => {
            "please" => "Certificate, 1, 2, 3, 4, 5, 6, is not valid! To verify another certificate, please"
          },
          "p_t" => "serial_number|123456"
        }
      }
    }
    assert_equal expected_response, Hash.from_xml(@response.body)
  end
  
  def test_ivr_redeem_with_option_1_and_valid_serial_number_not_redeemed
    @purchased_gift_certificate.update_attribute :serial_number, "1234-5678"
    assert_equal "1234-5678", @purchased_gift_certificate.reload.serial_number
    assert !@purchased_gift_certificate.redeemed?, "Purchased deal certificate should not be redeemed yet"
    
    get :ivr_redeem, {
      :p_t => "serial_number|1234-5678",
      :survo_1 => "11111",
      :option => "1"
    }
    assert_response :success
    expected_response = {
      "action" => {
        "app" => "SurVo",
        "parameters" => {
          "id" => "11111",
          "user_parameters" => {
            "please" => "Certificate, 1, 2, 3, 4, 5, 6, 7, 8, is now marked as redeemed! To verify another certificate, please"
          },
        }
      }
    }
    assert_equal expected_response, Hash.from_xml(@response.body)
  end
  
  def test_ivr_redeem_with_option_1_and_invvalid_serial_number
    get :ivr_redeem, {
      :p_t => "serial_number|1234-5678",
      :survo_1 => "11111",
      :option => "1"
    }
    assert_response :success
    expected_response = {
      "action" => {
        "app" => "SurVo",
        "parameters" => {
          "id" => "11111",
          "user_parameters" => {
            "please" => "Certificate, 1, 2, 3, 4, 5, 6, 7, 8, is not valid! To verify another certificate, please"
          },
        }
      }
    }
    assert_equal expected_response, Hash.from_xml(@response.body)
  end
  
  def test_ivr_redeem_with_option_2
    get :ivr_redeem, {
      :p_t => "serial_number|1234-5678",
      :survo_1 => "11111",
      :option => "2"
    }
    assert_response :success
    expected_response = {
      "action" => {
        "app" => "SurVo",
        "parameters" => {
          "id" => "11111",
          "user_parameters" => {
            "please" => "Please"
          },
        }
      }
    }
    assert_equal expected_response, Hash.from_xml(@response.body)
  end
  
  def test_index_to_pdf_as_owning_publisher
    @purchased_gift_certificate.update_attribute :serial_number, "1234-5678"
    publisher = publishers(:sdh_austin)
    assert_equal publisher, users(:mickey).company, "User should belong to publisher"

    with_user_required(:mickey) do
      get :index, :format => "pdf", :publisher_id => publisher.to_param, :id => [@purchased_gift_certificate.id]
    end
    assert_response :success
    assert_equal 'application/pdf', @response.headers['Content-Type']
    assert_equal 'attachment; filename="Deal Certificate 1234-5678.pdf"', @response.headers['Content-Disposition']
  end
  
  def test_index_to_pdf_as_different_publisher
    @purchased_gift_certificate.update_attribute :serial_number, "1234-5678"
    publisher = publishers(:sdh_austin)
    assert_equal publisher, users(:mickey).company, "User should belong to publisher"

    login_as :quentin
    assert_raise ActiveRecord::RecordNotFound do
      get :index, :format => "pdf", :publisher_id => publisher.to_param, :id => [@purchased_gift_certificate.id]
    end
  end
  
  def test_index_to_pdf_as_admin
    @purchased_gift_certificate.update_attribute :serial_number, "1234-5678"

    with_user_required(:aaron) do
      get :index, :format => "pdf", :id => [@purchased_gift_certificate.id]
    end
    assert_response :success
    assert_equal 'application/pdf', @response.headers['Content-Type']
    assert_equal 'attachment; filename="Deal Certificate 1234-5678.pdf"', @response.headers['Content-Disposition']
  end
  
  private
  
  def create_purchased_gift_certificate
    advertiser = advertisers(:changos)
    assert !advertiser.gift_certificates.any?, "Advertiser fixture should not have any deal certificates"
    
    gift_certificate = advertiser.gift_certificates.create!(:message => "buy", :price => 23.99, :value => 40.00, :number_allocated => 3)
    @purchased_gift_certificate = gift_certificate.purchased_gift_certificates.create!(
      :paypal_payment_date => "14:18:05 Jan 14, 2010 PST",
      :paypal_txn_id => "38D93468JC7166634",
      :paypal_receipt_id => "3625-4706-3930-0684",
      :paypal_invoice => "123456789",
      :paypal_payment_gross => "23.99",
      :paypal_payer_email => "higgins@london.com",
      :paypal_payer_status => "verified",
      :paypal_address_name => "Henry Higgins",
      :paypal_first_name => "Henry",
      :paypal_last_name => "Higgins",
      :paypal_address_street => "1 Penny Lane",
      :paypal_address_city =>"London",
      :paypal_address_state => "KY",
      :paypal_address_zip => "40742",
      :paypal_address_status => "confirmed",
      :payment_status => "completed",
      :payment_status_updated_at => Time.zone.now,
      :payment_status_updated_by_txn_id => "38D93468JC7166634"
    )
  end
end
