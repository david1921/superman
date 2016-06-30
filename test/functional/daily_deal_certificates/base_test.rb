require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealCertificatesController::BaseTest < ActionController::TestCase
  tests DailyDealCertificatesController
  include DailyDealCertificatesTestHelper

  setup :setup_mailer_and_certs
  
  def setup_mailer_and_certs
    DailyDealMailer.stubs(:purchase_confirmation_with_certificates => nil)
    create_daily_deal_certificate
  end
  
  def test_validate_routing
    assert_generates "/daily_deal_certificates/validate", :controller => "daily_deal_certificates", :action => "validate"
  end
  
  def test_redeem_routing
    assert_generates "/daily_deal_certificates/redeem", :controller => "daily_deal_certificates", :action => "redeem"
  end
  
  def test_ivr_validate_routing
    assert_generates "/daily_deal_certificates/ivr_validate", :controller => "daily_deal_certificates", :action => "ivr_validate"
  end
  
  def test_ivr_redeem_routing
    assert_generates "/daily_deal_certificates/ivr_redeem", :controller => "daily_deal_certificates", :action => "ivr_redeem"
  end
  
  def test_validate_without_serial_number
    with_user_required(:jimmy) do
      get :validate
    end
    assert_response :success
    assert_match(/serial number to be validated/i, flash[:notice])
    
    assert_select "form[action=#{validate_daily_deal_certificates_path}][method=get]", 1 do
      assert_select "input[type=text][name=serial_number]", 1
      assert_select "input[type=submit]", 1
    end
  end
  
  def test_validate_with_invalid_serial_number
    with_user_required(:jimmy) do
      get :validate, :serial_number => "1234-5678"
    end
    assert_response :success
    assert_match(/1234\-5678 is not valid/i, assigns(:errors))
    
    assert_select "p.warn", assigns(:errors)
    assert_select "form[action=#{validate_daily_deal_certificates_path}][method=get]", 1 do
      assert_select "input[type=text][name=serial_number]", 1
      assert_select "input[type=submit]", 1
    end
  end
  
  def test_validate_with_valid_serial_number_not_redeemed
    assert !@daily_deal_certificate.redeemed?, "Purchased certificate should not be redeemed yet"
    
    with_user_required(:jimmy) do
      get :validate, :serial_number => @daily_deal_certificate.serial_number
    end
    assert_response :success
    assert_match(/#{@daily_deal_certificate.serial_number} is valid/i, assigns(:status))
    assert_equal @daily_deal_certificate, assigns(:daily_deal_certificate)    
      
    assert_select "p.notice", assigns(:status)
    assert_select "form[action=#{redeem_daily_deal_certificates_path}][method=post]" do
      assert_select "input[type=hidden][name=serial_number][value='#{@daily_deal_certificate.serial_number}']", 1
      assert_select "input[type=text][name=serial_number][disabled=disabled]", 1
      assert_select "input[type=text][name=merchant][disabled=disabled]", 1
      assert_select "input[type=text][name=value][disabled=disabled]", 1
      assert_select "input[type=button][value=Cancel]", 1
      assert_select "input[type=submit]", 1
    end
  end
  
  def test_validate_with_valid_serial_number_already_redeemed
    assert @daily_deal_certificate.update_attributes! :status => "redeemed"
    
    with_user_required(:jimmy) do
      get :validate, :serial_number => @daily_deal_certificate.serial_number
    end
    assert_response :success
    assert_match(/#{@daily_deal_certificate.serial_number} has already been redeemed/i, assigns(:errors))
    assert @daily_deal_certificate.reload.redeemed?, "Purchased certificate should still be redeemed"
      
    assert_select "p.warn", assigns(:errors)
    assert_select "form[action=#{validate_daily_deal_certificates_path}][method=get]" do
      assert_select "input[type=text][name=serial_number]", 1
      assert_select "input[type=submit]", 1
    end
  end
  
  context "#validate" do
    should "have certificates for refunded purchases without loyalty_refund_amount" do
      refunded_purchase = Factory(:refunded_daily_deal_purchase, :loyalty_refund_amount => nil)
      refunded_certificate = Factory(:daily_deal_certificate, :daily_deal_purchase => refunded_purchase)

      with_user_required :aaron do
        get :validate, :serial_number => refunded_certificate.serial_number
      end

      assert_response :success
      assert_equal "Serial number #{refunded_certificate.serial_number} is VALID", assigns(:status)
    end
  end

  def test_redeem_with_valid_serial_number
    assert !@daily_deal_certificate.redeemed?, "Purchased certificate should not be redeemed yet"
    
    with_user_required(:jimmy) do
      put :redeem, :serial_number => @daily_deal_certificate.serial_number
    end
    assert_response :success
    assert_template :validate
    assert_match(/#{@daily_deal_certificate.serial_number} marked as redeemed/i, flash[:notice])
    assert @daily_deal_certificate.reload.redeemed?, "Purchased certificate should be redeemed"
    
    assert_select "form[action=#{validate_daily_deal_certificates_path}][method=get]", 1 do
      assert_select "input[type=text][name=serial_number]", 1
      assert_select "input[type=submit]", 1
    end
  end
  
  def test_redeem_with_valid_serial_number_and_location
    advertiser = advertisers(:changos)
    store = advertiser.stores.create!(:phone_number => "503 911-1212")
    
    daily_deal = daily_deals(:changos)
    daily_deal.location_required = true
    daily_deal.save!
    
    daily_deal_purchase = daily_deal.daily_deal_purchases.build
    daily_deal_purchase.consumer = users(:john_public)
    daily_deal_purchase.quantity = 1
    daily_deal_purchase.payment_status = "captured"
    daily_deal_purchase.daily_deal_payment = BraintreePayment.new
    daily_deal_purchase.daily_deal_payment.payment_gateway_id = "14432"
    daily_deal_purchase.daily_deal_payment.payment_at = Time.zone.now
    daily_deal_purchase.daily_deal_payment.amount = daily_deal.price
    daily_deal_purchase.daily_deal_payment.credit_card_last_4 =  "4545"
    daily_deal_purchase.store = store
    daily_deal_purchase.save!

    @daily_deal_certificate = daily_deal_purchase.daily_deal_certificates.create!(:redeemer_name => "John Public")
    
    with_user_required(:jimmy) do
      put :redeem, :serial_number => @daily_deal_certificate.serial_number
    end
    assert_response :success
    assert_template :validate
    assert_match(/#{@daily_deal_certificate.serial_number} marked as redeemed/i, flash[:notice])
    assert_match(/\(503\) 911-1212/i, flash[:notice])
    assert @daily_deal_certificate.reload.redeemed?, "Purchased certificate should be redeemed"
    assert "Certificate #{@daily_deal_certificate.serial_number} marked as redeemed at #{store.summary}"
    
    assert_select "form[action=#{validate_daily_deal_certificates_path}][method=get]", 1 do
      assert_select "input[type=text][name=serial_number]", 1
      assert_select "input[type=submit]", 1
    end
  end
  
  def test_redeem_with_invalid_serial_number
    with_user_required(:jimmy) do
      put :redeem, :serial_number => "1234-5678"
    end
    assert_response :success
    assert_template :validate
    assert_match(/could not locate certificate/i, flash[:warn])
    assert_match(/serial number to be validated/i, flash[:notice])
    assert !@daily_deal_certificate.reload.redeemed?, "Purchased certificate should not be redeemed"
    
    assert_select "form[action=#{validate_daily_deal_certificates_path}][method=get]", 1 do
      assert_select "input[type=text][name=serial_number]", 1
      assert_select "input[type=submit]", 1
    end
  end
  
  # NOTE: This shouldn't happen but it does, see:
  #   https://www.getexceptional.com/exceptions/8086339
  #   https://www.pivotaltracker.com/story/show/16378251
  def test_redeem_with_valid_serial_number_with_daily_deal_purchase_with_no_store_but_daily_deal_requires_location
    daily_deal_purchase =  Factory(:captured_daily_deal_purchase)
    daily_deal_certificate = daily_deal_purchase.daily_deal_certificates.first
    Advertiser.any_instance.stubs(:stores).returns([1, 2, 3]) # so we return many stores
    assert daily_deal_certificate.daily_deal.update_attribute(:location_required, true)
    assert daily_deal_purchase.update_attribute(:store_id, nil)
    login_as Factory(:admin)
    put :redeem, :serial_number => daily_deal_certificate.serial_number
    assert_response :success
    assert_template :validate    
    assert_equal "Certificate #{daily_deal_certificate.serial_number} marked as redeemed", flash[:notice]
  end
  
  def test_ivr_validate_with_valid_serial_number_not_redeemed
    @daily_deal_certificate.update_attribute :serial_number, "1234-5678"
    assert_equal "1234-5678", @daily_deal_certificate.reload.serial_number
    assert !@daily_deal_certificate.redeemed?, "Purchased certificate should not be redeemed yet"
    
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
            "please" => "Certificate, 1, 2, 3, 4, 5, 6, 7, 8, is confirmed as valid! For Changos, with a value of, $50.00."
          },
          "p_t" => "serial_number|1234-5678"
        }
      }
    }
    assert_equal expected_response, Hash.from_xml(@response.body)
  end
  
  def test_ivr_validate_with_valid_serial_number_already_redeemed
    @daily_deal_certificate.update_attribute :serial_number, "1234-5678"
    assert_equal "1234-5678", @daily_deal_certificate.reload.serial_number
    @daily_deal_certificate.redeem!
    
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
    @daily_deal_certificate.update_attribute :serial_number, "1234-5678"
    assert_equal "1234-5678", @daily_deal_certificate.reload.serial_number
    assert !@daily_deal_certificate.redeemed?, "Purchased certificate should not be redeemed yet"
    
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
  
  def test_ivr_redeem_with_option_1_and_invalid_serial_number
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
  
  context "POST to mark_used" do
    
    setup do
      @daily_deal = Factory :daily_deal
      @consumer_1 = Factory :consumer, :publisher => @daily_deal.publisher
      @consumer_2 = Factory :consumer, :publisher => @daily_deal.publisher
      @purchase = Factory :captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1, :consumer => @consumer_1
      @certificate = @purchase.daily_deal_certificates.first
    end
    
    should "require authentication" do
      post :mark_used, :id => @certificate.to_param
      assert_redirected_to new_publisher_daily_deal_session_path(@certificate.publisher)
    end
    
    context "with a user that does not own the certificate" do
      
      should "return a 404 not found when a user tries to mark used a voucher that doesn't belong to them" do
        login_as(@consumer_2)
        post :mark_used, :id => @certificate.to_param
        assert_response :not_found
      end

    end
    
    context "with the user that owns the certificate" do
      
      setup do
        login_as(@consumer_1)
        assert !@certificate.marked_used_by_user?
        @request.env["HTTP_REFERER"] = publisher_consumer_daily_deal_purchases_url(@certificate.publisher, @consumer_1)
        post :mark_used, :id => @certificate.to_param
        @certificate.reload
      end
      
      should "mark the voucher as used by the user" do
        assert @certificate.marked_used_by_user?
      end

      should "set a flash notice" do
        assert_equal "Certificate #{@certificate.serial_number} has been marked as used.", flash[:notice]
      end

      should "redirect back to the consumer DDP index" do
        assert_redirected_to publisher_consumer_daily_deal_purchases_url(@certificate.publisher, @consumer_1)
      end
      
    end
    
    context "with an admin user" do

      setup do
        login_as(Factory :admin)
        assert !@certificate.marked_used_by_user?
        @request.env["HTTP_REFERER"] = publisher_consumer_daily_deal_purchases_url(@certificate.publisher, @consumer_1)
        post :mark_used, :id => @certificate.to_param
        @certificate.reload
      end
      
      should "mark the voucher as used by the user" do
        assert @certificate.marked_used_by_user?
      end

      should "set a flash notice" do
        assert_equal "Certificate #{@certificate.serial_number} has been marked as used.", flash[:notice]
      end

      should "redirect back to the consumer DDP index" do
        assert_redirected_to publisher_consumer_daily_deal_purchases_url(@certificate.publisher, @consumer_1)
      end
      
    end
        
  end

  context "POST to mark_unused" do
    
    setup do
      @daily_deal = Factory :daily_deal
      @consumer_1 = Factory :consumer, :publisher => @daily_deal.publisher
      @consumer_2 = Factory :consumer, :publisher => @daily_deal.publisher
      @purchase = Factory :captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1, :consumer => @consumer_1
      @certificate = @purchase.daily_deal_certificates.first
      @certificate.mark_used_by_user!
    end
    
    should "require authentication" do
      post :mark_unused, :id => @certificate.to_param
      assert_redirected_to new_publisher_daily_deal_session_path(@certificate.publisher)
    end
    
    context "with a user that does not own the certificate" do
      
      should "return a 404 not found when a user tries to mark unused a voucher that doesn't belong to them" do
        login_as(@consumer_2)
        post :mark_unused, :id => @certificate.to_param
        assert_response :not_found
      end

    end
    
    context "with the user that owns the certificate" do
      
      setup do
        login_as(@consumer_1)
        assert @certificate.marked_used_by_user?
        @request.env["HTTP_REFERER"] = redeemed_publisher_consumer_daily_deal_purchases_url(@certificate.publisher, @consumer_1)
        post :mark_unused, :id => @certificate.to_param
        @certificate.reload
      end
      
      should "mark the voucher as unused" do
        assert !@certificate.marked_used_by_user?
      end

      should "set a flash notice" do
        assert_equal "Certificate #{@certificate.serial_number} has been marked as unused.", flash[:notice]
      end

      should "redirect back to the consumer redeemed certs page" do
        assert_redirected_to redeemed_publisher_consumer_daily_deal_purchases_url(@certificate.publisher, @consumer_1)
      end
      
    end
    
    context "with an admin user" do

      setup do
        login_as(Factory :admin)
        assert @certificate.marked_used_by_user?
        @request.env["HTTP_REFERER"] = redeemed_publisher_consumer_daily_deal_purchases_url(@certificate.publisher, @consumer_1)
        post :mark_unused, :id => @certificate.to_param
        @certificate.reload
      end
      
      should "mark the voucher as unused by the user" do
        assert !@certificate.marked_used_by_user?
      end

      should "set a flash notice" do
        assert_equal "Certificate #{@certificate.serial_number} has been marked as unused.", flash[:notice]
      end

      should "redirect back to the consumer redeemed certs page" do
        assert_redirected_to redeemed_publisher_consumer_daily_deal_purchases_url(@certificate.publisher, @consumer_1)
      end
      
    end
    
  end

  context "a daily deal purchase with one certificate for a deal which has not expired" do
    setup do
      now = Time.zone.now
      @daily_deal = Factory(:daily_deal, :start_at => now - 1.days, :hide_at => now + 1.days, :expires_on => now + 2.days)
      @daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1)
      @publisher = @daily_deal_purchase.publisher
    end

    should "not display voucher navigation" do
      login_as @daily_deal_purchase.consumer
      get :redeemable, :daily_deal_purchase_id => @daily_deal_purchase.to_param
      assert_response :success
      assert_select "#voucher_navigation", :count => 0
    end
  end
  
  context "a daily deal purchase with several certificates for a deal which has not expired" do
    setup do
      now = Time.zone.now
      @daily_deal = Factory(:daily_deal, :start_at => now - 1.days, :hide_at => now + 1.days, :expires_on => now + 2.days)
      @daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 3)
      @publisher = @daily_deal_purchase.publisher
    end
    
    should "redirect to the login url in redeemable if there is no current user" do
      get :redeemable, :daily_deal_purchase_id => @daily_deal_purchase.to_param
      assert_redirected_to new_publisher_daily_deal_session_url(@publisher)
    end
    
    should "redirect to the login url in redeemable if the current user is a consumer belonging to a different publisher" do
      login_as Factory(:consumer)
      
      get :redeemable, :daily_deal_purchase_id => @daily_deal_purchase.to_param
      assert_redirected_to new_publisher_daily_deal_session_url(@publisher)
    end
    
    should "return all certificates in redeemable if no certificates were marked by user" do
      login_as @daily_deal_purchase.consumer
      get :redeemable, :daily_deal_purchase_id => @daily_deal_purchase.to_param
      assert_response :success
      assert_equal @daily_deal_purchase, assigns(:daily_deal_purchase)
      assert_equal_arrays @daily_deal_purchase.daily_deal_certificates, assigns(:daily_deal_certificates)
    end

    should "return only unmarked certificates in redeemable if some certificates were marked by user" do
      @daily_deal_purchase.daily_deal_certificates[0].mark_used_by_user!
      @daily_deal_purchase.daily_deal_certificates[1].mark_used_by_user!
      
      login_as @daily_deal_purchase.consumer
      get :redeemable, :daily_deal_purchase_id => @daily_deal_purchase.to_param
      assert_response :success
      assert_equal @daily_deal_purchase, assigns(:daily_deal_purchase)
      assert_equal_arrays @daily_deal_purchase.daily_deal_certificates[2..-1], assigns(:daily_deal_certificates)
    end

    should "return no certificates in redeemable if the daily deal has expired" do
      Timecop.freeze(@daily_deal.expires_on + 1.days) do
        login_as @daily_deal_purchase.consumer
        get :redeemable, :daily_deal_purchase_id => @daily_deal_purchase.to_param
        assert_response :success
        assert_equal @daily_deal_purchase, assigns(:daily_deal_purchase)
        assert assigns(:daily_deal_certificates).empty?, "Should not return any certificates after expiration"
      end
    end

    should "display voucher navigation" do
      login_as @daily_deal_purchase.consumer
      get :redeemable, :daily_deal_purchase_id => @daily_deal_purchase.to_param
      assert_response :success
      assert_select "#voucher_navigation"
    end

    should "display three vouchers" do
      login_as @daily_deal_purchase.consumer
      get :redeemable, :daily_deal_purchase_id => @daily_deal_purchase.to_param
      assert_response :success
      assert_select ".voucher_1"
      assert_select ".voucher_2"
      assert_select ".voucher_3"
    end
  end
  
end
