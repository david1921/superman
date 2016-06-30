require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::RefundedTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  context "GET to :refunded" do
    
    should "show a travelsavers booking that has been refunded" do
      booking = Factory :successful_travelsavers_booking
      Timecop.freeze(Time.zone.parse("Fri May 11 04:42:30 UTC 2012")) { booking.daily_deal_purchase.void_or_full_refund!(Factory(:admin)) }
      assert booking.daily_deal_purchase.refunded?
      login_as booking.consumer
      Timecop.freeze(booking.service_start_date - 1.day) do
        get :refunded, :publisher_id => booking.publisher.id, :consumer_id => booking.consumer.id
        assert_response :success
        assert_equal [booking], assigns(:refunded_travelsavers_bookings)
        assert_equal [booking], assigns(:refunded_items)
        assert_select "table#consumer_#{booking.consumer.id}_refunded_daily_deal_certificates tr", :count => 2
        assert_select "td.description", /for only/
        assert_select "td.serial_number", "#36329883"
        assert_select "td.recipient", "MR Johnny Tester, MRS Gabriella Testoo"
        assert_select "td.status", "May 10, 2012"
      end
    end

    should "not show a travelsavers booking that is not refunded" do
      booking = Factory :successful_travelsavers_booking
      assert booking.daily_deal_purchase.captured?
      login_as booking.consumer
      Timecop.freeze(booking.service_start_date - 1.day) do
        get :refunded, :publisher_id => booking.publisher.id, :consumer_id => booking.consumer.id
        assert_response :success
        assert_select "table#consumer_#{booking.consumer.id}_refunded_daily_deal_certificates tr", false
      end
    end

    context "with a WCAX publisher" do
      
      setup do
        wcax = Factory :publishing_group, :label => "wcax"
        publisher = Factory :publisher, :label => "wcax-vermont", :publishing_group => wcax
        ts_deal = Factory :travelsavers_daily_deal, :available_for_syndication => true
        wcax_vermont_deal = syndicate(ts_deal, publisher)
        purchase = Factory :travelsavers_captured_daily_deal_purchase, :daily_deal => wcax_vermont_deal
        @booking = Factory :successful_travelsavers_booking, :daily_deal_purchase => purchase
      end

      should "show a travelsavers booking that has been refunded, example using WCAX" do
        Timecop.freeze(Time.zone.parse("Fri May 11 04:42:30 UTC 2012")) { @booking.daily_deal_purchase.void_or_full_refund!(Factory(:admin)) }
        assert @booking.daily_deal_purchase.refunded?
        login_as @booking.consumer
        Timecop.freeze(@booking.service_start_date - 1.day) do
          get :refunded, :publisher_id => @booking.publisher.id, :consumer_id => @booking.consumer.id
          assert_response :success
          assert_equal [@booking], assigns(:refunded_travelsavers_bookings)
          assert_equal [@booking], assigns(:refunded_items)
          assert_select "table#consumer_#{@booking.consumer.id}_refunded_daily_deal_certificates tr", :count => 2
          assert_select "td.description", /for only/
          assert_select "td.serial_number", "#36329883"
          assert_select "td.recipient", "MR Johnny Tester, MRS Gabriella Testoo"
          assert_select "td.status", "May 10, 2012"
        end
      end

      should "not show a travelsavers booking that is not refunded, example using WCAX" do
        assert @booking.daily_deal_purchase.captured?
        login_as @booking.consumer
        Timecop.freeze(@booking.service_start_date - 1.day) do
          get :refunded, :publisher_id => @booking.publisher.id, :consumer_id => @booking.consumer.id
          assert_response :success
          assert_select "table#consumer_#{@booking.consumer.id}_refunded_daily_deal_certificates tr", false
        end
      end

    end

  end

end
