require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::RedeemedTest < ActionController::TestCase
  
  tests DailyDealPurchasesController

  fast_context "GET to redeemed" do
    
    setup do
      Timecop.freeze(Time.parse("2011-11-05T08:35:57Z")) do
        @publisher = Factory :publisher
        @advertiser_1 = Factory :advertiser, :publisher => @publisher
        @advertiser_2 = Factory :advertiser, :publisher => @publisher
        @deal_1 = Factory :daily_deal, :advertiser => @advertiser_1
        @deal_2 = Factory :side_daily_deal, :advertiser => @advertiser_2
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
        get :redeemed, :publisher_id => @publisher.to_param, :consumer_id => @consumer_1.to_param
      end
    
      should "respond successfully" do
        assert_response :success
      end
    
      should "populate @redeemed_certificates with only certs that have been redeemed " +
             "or marked used by the user" do
        assert_equal [@cert_1, @cert_2, @cert_6], assigns(:redeemed_certificates)
      end
      
      should "display the vouchers" do
        assert_select "td.serial_number", :text => "##{@cert_1.serial_number}"
        assert_select "td.serial_number", :text => "##{@cert_2.serial_number}"
        assert_select "td.serial_number", :text => "##{@cert_6.serial_number}"
      end
      
    end
    
    fast_context "with the consumer that owns the redeemed vouchers" do
      
      setup do
        login_as @consumer_1
        get :redeemed, :publisher_id => @publisher.to_param, :consumer_id => @consumer_1.to_param
      end
    
      should "respond successfully" do
        assert_response :success
      end
    
      should "populate @redeemed_certificates with only certs that have been redeemed " +
             "or marked used by the user" do
        assert_equal [@cert_1, @cert_2, @cert_6], assigns(:redeemed_certificates)
      end
      
      should "display the vouchers" do
        assert_select "td.serial_number", :text => "##{@cert_1.serial_number}"
        assert_select "td.serial_number", :text => "##{@cert_2.serial_number}"
        assert_select "td.serial_number", :text => "##{@cert_6.serial_number}"
      end
      
      should "display the redemption date, or N/A for vouchers that were marked as used" do
        assert_select "td.redeemed_on", :text => "November 05, 2011", :count => 2
        assert_select "td.redeemed_on", :text => "N/A", :count => 1
      end
      
      should "show a Mark as Unused for the marked-used voucher only" do
        assert_select "a", :text => "Mark as Unused", :count => 1
      end
      
    end
    
    fast_context "with a consumer that does not own the redeemed vouchers" do
      
      setup do
        login_as @consumer_2
        get :redeemed, :publisher_id => @publisher.to_param, :consumer_id => @consumer_1.to_param
      end

      should "redirect to the daily deal login page" do
        assert_redirected_to daily_deal_login_path(:publisher_id => @publisher.id)
      end
      
    end
    
  end

  context "A consumer that bought Travelsavers deals" do
    
    setup do
      @booking = Factory :successful_travelsavers_booking
      @purchase = @booking.daily_deal_purchase
      @publisher = @purchase.publisher
      @consumer = @purchase.consumer
      assert @booking.service_start_date.present?
      login_as @purchase.consumer
    end

    context "GET to :redeemed" do
      
      should "not show the Travelsavers deal when its service start date is in the future" do
        Timecop.freeze(@booking.service_start_date - 1.day) do
          get :redeemed, :publisher_id => @publisher.to_param, :consumer_id => @consumer.to_param
        end
        assert_response :success
        assert_select "table#consumer_#{@consumer.id}_redeemed_daily_deal_certificates tr", false
      end

      should "show the Travelsavers deal when its service start date has passed" do
        Timecop.freeze(@booking.service_start_date + 1.day) do
          get :redeemed, :publisher_id => @publisher.to_param, :consumer_id => @consumer.to_param
        end
        assert_response :success
        assert_select "table#consumer_#{@consumer.id}_redeemed_daily_deal_certificates tr", :count => 2
        assert_select "td.description", /for only/
        assert_select "td.serial_number", "#36329883"
        assert_select "td.recipient", "MR Johnny Tester, MRS Gabriella Testoo"
        assert_select "td.redeemed_on", "April 21, 2012"
      end

    end

  end

  context "A consumer that bought Travelsavers deals from WCAX" do
    
    setup do
      @wcax = Factory :publishing_group, :label => "wcax"
      @publisher = Factory :publisher, :label => "wcax-vermont", :publishing_group => @wcax
      ts_deal = Factory :travelsavers_daily_deal, :available_for_syndication => true
      wcax_vermont_deal = syndicate(ts_deal, @publisher)
      @purchase = Factory :travelsavers_captured_daily_deal_purchase, :daily_deal => wcax_vermont_deal
      @booking = Factory :successful_travelsavers_booking, :daily_deal_purchase => @purchase
      @consumer = @purchase.consumer
      assert @booking.service_start_date.present?
      login_as @purchase.consumer
    end

    context "GET to :redeemed" do
      
      should "not show the Travelsavers deal when its service start date is in the future" do
        Timecop.freeze(@booking.service_start_date - 1.day) do
          get :redeemed, :publisher_id => @publisher.to_param, :consumer_id => @consumer.to_param
        end
        assert_response :success
        assert_select "table#consumer_#{@consumer.id}_redeemed_daily_deal_certificates tr", false
      end

      should "show the Travelsavers deal when its service start date has passed" do
        Timecop.freeze(@booking.service_start_date + 1.day) do
          get :redeemed, :publisher_id => @publisher.to_param, :consumer_id => @consumer.to_param
        end
        assert_response :success
        assert_select "table#consumer_#{@consumer.id}_redeemed_daily_deal_certificates tr", :count => 2
        assert_select "td.description", /for only/
        assert_select "td.serial_number", "#36329883"
        assert_select "td.recipient", "MR Johnny Tester, MRS Gabriella Testoo"
        assert_select "td.redeemed_on", "April 21, 2012"
      end

    end

  end

  test "show redeemed WCAX off-platform certificates" do
    publishing_group = Factory(:publishing_group, :label => "wcax")
    publisher = Factory(:publisher, :label => "wcax-vermont", :publishing_group => publishing_group)
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :publisher => publisher, :advertiser => advertiser)
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal)

    off_platform_daily_deal_certificate = Factory(
      :off_platform_daily_deal_certificate, 
      :redeemed => true,
      :redeemed_at => Time.zone.local(2011, 12, 13, 13, 0, 0),
      :download_url => "http://wcax.com/deals/777.asp", 
      :consumer => daily_deal_purchase.consumer
    )

    login_as daily_deal_purchase.consumer
    get :redeemed,
        :publisher_id => daily_deal_purchase.publisher.to_param,
        :consumer_id => daily_deal_purchase.consumer.to_param
    assert_response :success

    assert_select "td.status", :text => "Redeemed at December 13, 2011 13:00"
  end
  
end
