require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::ExpiredTest < ActionController::TestCase
  
  tests DailyDealPurchasesController

  fast_context "GET to expired" do
    
    setup do
      Timecop.freeze(Time.parse("2010-11-05T08:35:57Z")) do
        @publisher = Factory :publisher
        @advertiser_1 = Factory :advertiser, :publisher => @publisher
        @advertiser_2 = Factory :advertiser, :publisher => @publisher
        @deal_1 = Factory :daily_deal, :advertiser => @advertiser_1
        @deal_2 = Factory :side_daily_deal, :advertiser => @advertiser_2, :expires_on => Time.now + 3.months
        @consumer_1 = Factory :consumer, :publisher => @publisher
        @consumer_2 = Factory :consumer, :publisher => @publisher
      
        @purchase_1 = Factory :captured_daily_deal_purchase, :daily_deal => @deal_1, :quantity => 2, :consumer => @consumer_1
        @purchase_2 = Factory :captured_daily_deal_purchase, :daily_deal => @deal_2, :quantity => 1, :consumer => @consumer_1
        @purchase_3 = Factory :captured_daily_deal_purchase, :daily_deal => @deal_2, :quantity => 3, :consumer => @consumer_1
      
        @cert_1, @cert_2 = @purchase_1.daily_deal_certificates
        @cert_3 = @purchase_2.daily_deal_certificates.first
        @cert_4, @cert_5, @cert_6 = @purchase_3.daily_deal_certificates
      
        @cert_1.redeem!
        @cert_2.redeem!
        @cert_6.mark_used_by_user!
      end
    end
    
    fast_context "with an admin user" do
      
      setup do
        @admin = Factory :admin
        login_as @admin
        get :expired, :publisher_id => @publisher.to_param, :consumer_id => @consumer_1.to_param
      end
    
      should "respond successfully" do
        assert_response :success
      end
    
      should "populate @expired_certificates with only expired certs that have not been used" do
        assert_equal [@cert_3, @cert_4, @cert_5], assigns(:expired_certificates)
      end
      
      should "display the expired vouchers that have not been used" do
        assert_select "td.serial_number", 3
        assert_select "td.serial_number", :text => "##{@cert_3.serial_number}"
        assert_select "td.serial_number", :text => "##{@cert_4.serial_number}"
        assert_select "td.serial_number", :text => "##{@cert_5.serial_number}"
      end
      
    end
    
    fast_context "with the consumer that owns the expired vouchers" do
      
      setup do
        login_as @consumer_1
        get :expired, :publisher_id => @publisher.to_param, :consumer_id => @consumer_1.to_param
      end
    
      should "respond successfully" do
        assert_response :success
      end
    
      should "populate @expired_certificates with only expired certs that have not been used" do
        assert_equal [@cert_3, @cert_4, @cert_5], assigns(:expired_certificates)
      end
      
      should "display the expired vouchers that have not been used" do
        assert_select "td.serial_number", 3
        assert_select "td.serial_number", :text => "##{@cert_3.serial_number}"
        assert_select "td.serial_number", :text => "##{@cert_4.serial_number}"
        assert_select "td.serial_number", :text => "##{@cert_5.serial_number}"
      end
      
      should "display the expiry date" do
        assert_select "td.expired_on", :text => "February 05, 2011", :count => 3
      end
      
      should "show a Mark as Used for all expired vouchers" do
        assert_select "a", :text => "Mark as Used", :count => 3
      end
      
    end
    
    fast_context "with a consumer that does not own the expired vouchers" do
      
      setup do
        login_as @consumer_2
        get :expired, :publisher_id => @publisher.to_param, :consumer_id => @consumer_1.to_param
      end

      should "redirect to the daily deal login page" do
        assert_redirected_to daily_deal_login_path(:publisher_id => @publisher.id)
      end
      
    end
    
  end

  test "show expired WCAX off-platform certificates" do
    publishing_group = Factory(:publishing_group, :label => "wcax")
    publisher = Factory(:publisher, :label => "wcax-vermont", :publishing_group => publishing_group)
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :publisher => publisher, :advertiser => advertiser)
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal)

    off_platform_daily_deal_certificate = Factory(
      :off_platform_daily_deal_certificate, 
      :redeemed => false,
      :expires_on => 3.days.ago,
      :download_url => "http://wcax.com/deals/777.asp", 
      :consumer => daily_deal_purchase.consumer
    )

    login_as daily_deal_purchase.consumer
    get :expired,
        :publisher_id => daily_deal_purchase.publisher.to_param,
        :consumer_id => daily_deal_purchase.consumer.to_param
    assert_response :success

    assert_select "a[href='http://wcax.com/deals/777.asp']", :text => "Print"
  end

end