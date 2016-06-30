require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::IndexTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  test "consumer index with pending purchase" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)

    login_as daily_deal_purchase.consumer
    get :index,
        :publisher_id => daily_deal_purchase.publisher.to_param,
        :consumer_id => daily_deal_purchase.consumer.to_param
    assert_response :success
    assert_layout "daily_deals"

    href = publisher_consumer_daily_deal_purchase_url(
              daily_deal_purchase.daily_deal.publisher.to_param,
              daily_deal_purchase.consumer.to_param,
              daily_deal_purchase.to_param,
              :format => :pdf)
    assert_select "a[href='#{href}']", :text => "Download to print", :count => 0
  end

  test "consumer index with pending purchase - with a locked consumer account" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    login_as daily_deal_purchase.consumer
    daily_deal_purchase.consumer.lock_access!
    get :index,
        :publisher_id => daily_deal_purchase.publisher.to_param,
        :consumer_id => daily_deal_purchase.consumer.to_param
    assert_redirected_to daily_deal_login_url(:publisher_id => daily_deal_purchase.consumer.publisher.to_param)
  end

  test "consumer index with pending purchase - with a locked consumer account, using basic auth" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    set_http_basic_authentication(:name => daily_deal_purchase.consumer.login, :pass => "monkey")
    daily_deal_purchase.consumer.lock_access!
    get :index,
        :publisher_id => daily_deal_purchase.publisher.to_param,
        :consumer_id => daily_deal_purchase.consumer.to_param
    assert_redirected_to daily_deal_login_url(:publisher_id => daily_deal_purchase.consumer.publisher.to_param)
  end
  
  test "consumer index with expired purchase" do
    daily_deal = Factory :daily_deal, :start_at => 3.months.ago, :hide_at => 2.months.ago, :expires_on => 1.month.ago
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal)
    login_as daily_deal_purchase.consumer
    get :index,
        :publisher_id => daily_deal_purchase.publisher.to_param,
        :consumer_id => daily_deal_purchase.consumer.to_param
    assert_response :success
    assert_layout "daily_deals"
    assert_select "td.serial_number", false
  end

  test "index with voided purchase" do
    daily_deal_purchase = Factory(:voided_daily_deal_purchase)

    login_as daily_deal_purchase.consumer
    get :index,
        :publisher_id => daily_deal_purchase.publisher.to_param,
        :consumer_id => daily_deal_purchase.consumer.to_param
    assert_response :success
    assert_layout "daily_deals"

    href = publisher_consumer_daily_deal_purchase_url(
              daily_deal_purchase.daily_deal.publisher.to_param,
              daily_deal_purchase.consumer.to_param,
              daily_deal_purchase.to_param,
              :format => :pdf)
    assert_select "a[href='#{href}']", :text => "Download to Print", :count => 0
  end

  test "consumer index purchase" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase)

    login_as daily_deal_purchase.consumer
    get :index,
        :publisher_id => daily_deal_purchase.publisher.to_param,
        :consumer_id => daily_deal_purchase.consumer.to_param
    assert_response :success
    assert_layout "daily_deals"

    href = publisher_consumer_daily_deal_purchase_url(
              daily_deal_purchase.daily_deal.publisher.to_param,
              daily_deal_purchase.consumer.to_param,
              daily_deal_purchase.to_param,
              :format => :pdf)

    assert_select "a[href='#{href}']", :text => "Download to print", :count => 1
  end

  context "consumer index with Travelsavers bookings" do

    setup do
      @deal = Factory :travelsavers_daily_deal, :available_for_syndication => true, :value_proposition => "a test travelsavers deal"
      @consumer = Factory :consumer, :publisher => @deal.publisher
    end
    
    should "show a booking when the booking and payment have succeeded" do
      Timecop.freeze(Time.parse("2012-04-22 11:15:28 PDT"))
      purchase = Factory :travelsavers_captured_daily_deal_purchase, :daily_deal => @deal, :consumer => @consumer
      booking = Factory :successful_travelsavers_booking, :daily_deal_purchase => purchase
      Timecop.return

      login_as booking.daily_deal_purchase.consumer
      Timecop.freeze(booking.service_start_date - 1.day) do
        get :index,
            :publisher_id => booking.publisher.to_param,
            :consumer_id => booking.consumer.to_param
        assert_response :success
        assert_select "table#consumer_#{booking.consumer.id}_daily_deal_purchases tr", :count => 2
        assert_select "td.description", "a test travelsavers deal"
        assert_select "td.serial_number", "#36329883"
        assert_select "td.recipient", "MR Johnny Tester, MRS Gabriella Testoo"
        assert_select "td.purchased_on", "April 22, 2012 11:15"
        assert_select "td.expires", "April 21, 2012"
        assert_select "td.status a[href='#{resend_email_daily_deal_purchase_path(booking.daily_deal_purchase)}']", "Resend email"
      end
    end

    should "show a booking when the booking and payment have succeeded, when the purchased deal is a distributed deal" do
      other_publisher = Factory :publisher
      other_consumer = Factory :consumer, :publisher => other_publisher
      distributed_ts_deal = syndicate(@deal, other_publisher)
      Timecop.freeze(Time.parse("2012-04-22 11:15:28 PDT"))
      purchase = Factory :travelsavers_captured_daily_deal_purchase, :daily_deal => distributed_ts_deal, :consumer => other_consumer
      booking = Factory :successful_travelsavers_booking, :daily_deal_purchase => purchase
      Timecop.return

      login_as booking.daily_deal_purchase.consumer
      Timecop.freeze(booking.service_start_date - 1.day) do
        get :index,
            :publisher_id => booking.publisher.to_param,
            :consumer_id => booking.consumer.to_param
        assert_response :success
        assert_select "table#consumer_#{booking.consumer.id}_daily_deal_purchases tr", :count => 2
        assert_select "td.description", "a test travelsavers deal"
        assert_select "td.serial_number", "#36329883"
        assert_select "td.recipient", "MR Johnny Tester, MRS Gabriella Testoo"
        assert_select "td.purchased_on", "April 22, 2012 11:15"
        assert_select "td.expires", "April 21, 2012"
        assert_select "td.status a[href='#{resend_email_daily_deal_purchase_path(booking.daily_deal_purchase)}']", "Resend email"
      end
    end

    should "show a booking when the booking succeeded and the payment status is unknown" do
      Timecop.freeze(Time.parse("2011-03-15 09:10:11 PDT"))
      booking = Factory :travelsavers_booking_with_vendor_retrieval_errors
      Timecop.return
      assert booking.daily_deal_purchase.authorized?

      login_as booking.daily_deal_purchase.consumer
      get :index,
          :publisher_id => booking.publisher.to_param,
          :consumer_id => booking.consumer.to_param
      assert_response :success
      assert_select "table#consumer_#{booking.consumer.id}_daily_deal_purchases tr", :count => 2
      assert_select "td.description", /for only/
      assert_select "td.serial_number", ""
      assert_select "td.recipient", ""
      assert_select "td.purchased_on", "Payment status: Unknown"
      assert_select "td.expires", ""
      assert_select "td.status a[href='#{resend_email_daily_deal_purchase_path(booking.daily_deal_purchase)}']", false
      assert_select "td.status", "Needs To Complete Payment"
    end

    should "not show a booking when the booking is pending" do
      Timecop.freeze(Time.parse("2011-03-15 09:10:11 PDT"))
      booking = Factory :pending_travelsavers_booking
      Timecop.return

      login_as booking.daily_deal_purchase.consumer
      get :index,
          :publisher_id => booking.publisher.to_param,
          :consumer_id => booking.consumer.to_param
      assert_response :success
      assert_select "table#consumer_#{booking.consumer.id}_daily_deal_purchases tr", false
      assert_match /no vouchers to redeem/, @response.body
    end

    should "not show a failed booking" do
      Timecop.freeze(Time.parse("2011-03-15 09:10:11 PDT"))
      booking = Factory :travelsavers_booking_with_validation_errors
      Timecop.return

      login_as booking.daily_deal_purchase.consumer
      get :index,
          :publisher_id => booking.publisher.to_param,
          :consumer_id => booking.consumer.to_param
      assert_response :success
      assert_select "table#consumer_#{booking.consumer.id}_daily_deal_purchases tr", false
      assert_match /no vouchers to redeem/, @response.body
    end

    should "not show a successful booking when the current time is past the service_start_date" do
      Timecop.freeze(Time.parse("2011-04-30 11:15:28 PDT"))
      booking = Factory :successful_travelsavers_booking
      Timecop.return

      login_as booking.daily_deal_purchase.consumer
      Timecop.freeze(booking.service_start_date + 1.day) do
        get :index,
            :publisher_id => booking.publisher.to_param,
            :consumer_id => booking.consumer.to_param
        assert_response :success
        assert_select "table#consumer_#{booking.consumer.id}_daily_deal_purchases tr", false
      end
    end

    should "not show a refunded booking" do
      Timecop.freeze(Time.parse("2011-04-30 11:15:28 PDT"))
      booking = Factory :successful_travelsavers_booking
      Timecop.return
      booking.daily_deal_purchase.void_or_full_refund!(Factory(:admin))
      assert booking.daily_deal_purchase.refunded?

      login_as booking.daily_deal_purchase.consumer
      Timecop.freeze(booking.service_start_date - 1.day) do
        get :index,
            :publisher_id => booking.publisher.to_param,
            :consumer_id => booking.consumer.to_param
      end
      assert_response :success
      assert_select "table#consumer_#{booking.consumer.id}_daily_deal_purchases tr", false
    end

  end

  context "consumer index with Travelsavers bookings, for WCAX publisher" do

    setup do
      @wcax = Factory :publishing_group, :label => "wcax"
      @wcax_vermont = Factory :publisher, :label => "wcax-vermont", :publishing_group => @wcax
      source_deal = Factory :travelsavers_daily_deal, :available_for_syndication => true, :value_proposition => "a test travelsavers deal"
      @deal = syndicate(source_deal, @wcax_vermont)
      @consumer = Factory :consumer, :publisher => @deal.publisher
    end
    
    should "show a booking when the booking and payment have succeeded" do
      Timecop.freeze(Time.parse("2012-04-22 11:15:28 PDT"))
      purchase = Factory :travelsavers_captured_daily_deal_purchase, :daily_deal => @deal, :consumer => @consumer
      booking = Factory :successful_travelsavers_booking, :daily_deal_purchase => purchase
      Timecop.return

      login_as booking.daily_deal_purchase.consumer
      Timecop.freeze(booking.service_start_date - 1.day) do
        get :index,
            :publisher_id => booking.publisher.to_param,
            :consumer_id => booking.consumer.to_param
        assert_response :success
        assert_select "table#consumer_#{booking.consumer.id}_daily_deal_purchases tr", :count => 2
        assert_select "td.description", "a test travelsavers deal"
        assert_select "td.serial_number", "#36329883"
        assert_select "td.recipient", "MR Johnny Tester, MRS Gabriella Testoo"
        assert_select "td.purchased_on", "April 22, 2012 11:15"
        assert_select "td.expires", "April 21, 2012"
        assert_select "td.status a[href='#{resend_email_daily_deal_purchase_path(booking.daily_deal_purchase)}']", "Resend email"
      end
    end

    should "show a booking when the booking succeeded and the payment status is unknown" do
      Timecop.freeze(Time.parse("2011-03-15 09:10:11 PDT"))
      purchase = Factory :travelsavers_authorized_daily_deal_purchase, :daily_deal => @deal, :consumer => @consumer
      booking = Factory :travelsavers_booking_with_vendor_retrieval_errors, :daily_deal_purchase => purchase
      Timecop.return
      assert booking.daily_deal_purchase.authorized?

      login_as booking.daily_deal_purchase.consumer
      get :index,
          :publisher_id => booking.publisher.to_param,
          :consumer_id => booking.consumer.to_param
      assert_response :success
      assert_select "table#consumer_#{booking.consumer.id}_daily_deal_purchases tr", :count => 2
      assert_select "td.description", /test travelsavers deal/
      assert_select "td.serial_number", ""
      assert_select "td.recipient", ""
      assert_select "td.purchased_on", "Payment status: Unknown"
      assert_select "td.expires", ""
      assert_select "td.status a[href='#{resend_email_daily_deal_purchase_path(booking.daily_deal_purchase)}']", false
      assert_select "td.status", "Needs To Complete Payment"
    end

    should "not show a booking when the booking is pending" do
      Timecop.freeze(Time.parse("2011-03-15 09:10:11 PDT"))
      purchase = Factory :travelsavers_pending_daily_deal_purchase, :daily_deal => @deal, :consumer => @consumer
      booking = Factory :pending_travelsavers_booking, :daily_deal_purchase => purchase
      Timecop.return

      login_as booking.daily_deal_purchase.consumer
      get :index,
          :publisher_id => booking.publisher.to_param,
          :consumer_id => booking.consumer.to_param
      assert_response :success
      assert_select "table#consumer_#{booking.consumer.id}_daily_deal_purchases tr", false
      assert_match /You have not purchased any deals yet/, @response.body
    end

    should "not show a failed booking" do
      Timecop.freeze(Time.parse("2011-03-15 09:10:11 PDT"))

      purchase = Factory :travelsavers_pending_daily_deal_purchase, :daily_deal => @deal, :consumer => @consumer
      booking = Factory :travelsavers_booking_with_validation_errors, :daily_deal_purchase => purchase
      Timecop.return

      login_as booking.daily_deal_purchase.consumer
      get :index,
          :publisher_id => booking.publisher.to_param,
          :consumer_id => booking.consumer.to_param
      assert_response :success
      assert_select "table#consumer_#{booking.consumer.id}_daily_deal_purchases tr", false
      assert_match /You have not purchased any deals yet/, @response.body
    end

    should "not show a successful booking when the current time is past the service_start_date" do
      Timecop.freeze(Time.parse("2011-04-30 11:15:28 PDT"))
      purchase = Factory :travelsavers_captured_daily_deal_purchase, :daily_deal => @deal, :consumer => @consumer
      booking = Factory :successful_travelsavers_booking, :daily_deal_purchase => purchase
      Timecop.return

      login_as booking.daily_deal_purchase.consumer
      Timecop.freeze(booking.service_start_date + 1.day) do
        get :index,
            :publisher_id => booking.publisher.to_param,
            :consumer_id => booking.consumer.to_param
        assert_response :success
        assert_select "table#consumer_#{booking.consumer.id}_daily_deal_purchases tr", false
      end
    end

    should "not show a refunded booking" do
      Timecop.freeze(Time.parse("2011-04-30 11:15:28 PDT"))
      purchase = Factory :travelsavers_captured_daily_deal_purchase, :daily_deal => @deal, :consumer => @consumer
      booking = Factory :successful_travelsavers_booking, :daily_deal_purchase => purchase
      Timecop.return
      booking.daily_deal_purchase.void_or_full_refund!(Factory(:admin))
      assert booking.daily_deal_purchase.refunded?

      login_as booking.daily_deal_purchase.consumer
      Timecop.freeze(booking.service_start_date - 1.day) do
        get :index,
            :publisher_id => booking.publisher.to_param,
            :consumer_id => booking.consumer.to_param
      end
      assert_response :success
      assert_select "table#consumer_#{booking.consumer.id}_daily_deal_purchases tr", false
    end

  end

  test "show WCAX off-platform certificates on consumer index page without expires_on" do
    publishing_group = Factory(:publishing_group, :label => "wcax")
    publisher = Factory(:publisher, :label => "wcax-vermont", :publishing_group => publishing_group)
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :publisher => publisher, :advertiser => advertiser)
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal)
    off_platform_daily_deal_certificate = Factory(
      :off_platform_daily_deal_certificate, 
      :expires_on => nil,
      :redeemed => false,
      :download_url => "http://wcax.com/deals/777.asp", 
      :consumer => daily_deal_purchase.consumer
    )

    login_as daily_deal_purchase.consumer
    get :index,
        :publisher_id => daily_deal_purchase.publisher.to_param,
        :consumer_id => daily_deal_purchase.consumer.to_param
    assert_response :success
    
    href = publisher_consumer_daily_deal_purchase_url(
              daily_deal_purchase.daily_deal.publisher.to_param,
              daily_deal_purchase.consumer.to_param,
              daily_deal_purchase.to_param,
              :format => :pdf)
    assert_select "a[href='#{href}']", :text => "Download to print"
    assert_select "a[href='http://wcax.com/deals/777.asp']", :text => "Print"
    assert_select "td.status a:first-child", "Download to print"
    assert_select "td.status a:last-child", "Mark as Used"
  end

  test "index with partial refund" do
    daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
    purchase = partially_refunded_purchase(daily_deal, 2, 30)

    login_as purchase.consumer
    get :index, :publisher_id => purchase.publisher.to_param, :consumer_id => purchase.consumer.to_param
    assert_response :success
    assert_template :index
    assert_layout "daily_deals"

    href = publisher_consumer_daily_deal_purchase_url(daily_deal.publisher.to_param, purchase.consumer.to_param, purchase.to_param, :format => :pdf)
    assert_select "a[href='#{href}']", :text => "Download to print", :count => 1
  end

  context "index for TWC publisher" do
    
    setup do
      publishing_group    = Factory(:publishing_group, :label => 'rr' )
      daily_deal_purchase = Factory(:captured_daily_deal_purchase)
      daily_deal_purchase.publisher.update_attributes!(:publishing_group => publishing_group, :label => 'rr' )

      login_as daily_deal_purchase.consumer
      get :index, :publisher_id => daily_deal_purchase.publisher.to_param, :consumer_id => daily_deal_purchase.consumer.to_param      
    end
    
    should "response successfully" do
      assert_response :success
    end

    should "render the themed templates" do
      assert_theme_layout "rr/layouts/daily_deals"
      assert_template "themes/rr/daily_deal_purchases/index"
    end

    should "assign the purchases to @daily_deal_purchases" do
      assert_not_nil assigns(:daily_deal_purchases)
    end
    
    should "show the navigation menu" do
      # assert_match %r{<nav>}, @response.body
      assert_match '<div class="nav">', @response.body
    end
    
    should "show a link to print the voucher" do
      assert_match %r{<a[^>]*>Download\ to\ print</a>}, @response.body
    end
    
    should "show a link to mark the voucher as used" do
      assert_match %r{<a[^>]*>Mark as Used</a>}, @response.body
    end
    
  end

  should "render 404 without publisher_id" do
    get :index
    assert_response 404
  end

  should "render 404 with publisher_id but no consumer_id" do
    publisher = Factory(:publisher)
    get :index, :publisher_id => publisher.id
    assert_response 404
  end
  
  context "redeemed vouchers" do
    
    setup do
      @purchase = Factory :captured_daily_deal_purchase, :quantity => 3
      @first_certificate, @second_certificate, @third_certificate = @purchase.daily_deal_certificates
      @consumer = @purchase.consumer
      @first_certificate.redeem!
      
      login_as @consumer
      get :index, :publisher_id => @purchase.publisher.to_param, :consumer_id => @consumer.to_param
    end
    
    should "not show up in the My Deals listing" do
      assert_select "td.serial_number", :text => "##{@second_certificate.serial_number}"
      assert_select "td.serial_number", :text => "##{@third_certificate.serial_number}"
      assert_select "td.serial_number", :text => "##{@first_certificate.serial_number}", :count => 0
    end
    
  end
  
  context "vouchers marked as used" do
    
    setup do
      @purchase = Factory :captured_daily_deal_purchase, :quantity => 3
      @first_certificate, @second_certificate, @third_certificate = @purchase.daily_deal_certificates
      @consumer = @purchase.consumer
      @first_certificate.mark_used_by_user!
      
      login_as @consumer
      get :index, :publisher_id => @purchase.publisher.to_param, :consumer_id => @consumer.to_param
    end
    
    should "not show up in the My Deals listing" do
      assert_select "td.serial_number", :text => "##{@second_certificate.serial_number}"
      assert_select "td.serial_number", :text => "##{@third_certificate.serial_number}"
      assert_select "td.serial_number", :text => "##{@first_certificate.serial_number}", :count => 0
    end
    
  end

  context "non-voucher purchases" do
    setup do
      @publishing_group = Factory(:publishing_group, :allow_non_voucher_deals => true)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @daily_deal = Factory(:non_voucher_daily_deal, :publisher => @publisher)
      @daily_deal_purchase = Factory(:captured_non_voucher_daily_deal_purchase, :daily_deal => @daily_deal)
      @consumer = @daily_deal_purchase.consumer

      login_as @consumer
    end

    should "show in listing" do
      get :index, :publisher_id => @publisher.to_param, :consumer_id => @consumer.to_param
      assert_select "td.serial_number", "##{@daily_deal_purchase.daily_deal_certificates.first.serial_number}"
    end

    should "show link to redemption page instead of voucher" do
      get :index, :publisher_id => @publisher.to_param, :consumer_id => @consumer.to_param
      assert_select "td.status a[href='#{non_voucher_redemption_daily_deal_purchase_url(@daily_deal_purchase)}']", "View"
    end

    context "bcbsa" do
      setup do
        @publishing_group.update_attributes(:label => "bcbsa")
      end

      should "show link to redemption page instead of voucher" do
        get :index, :publisher_id => @publisher.to_param, :consumer_id => @consumer.to_param
        assert_select "a[href='#{non_voucher_redemption_daily_deal_purchase_url(@daily_deal_purchase)}']", "Click to view Voucher"
      end
    end

  end

end
