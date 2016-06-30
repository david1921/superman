require File.dirname(__FILE__) + "/../../test_helper"

# hydra class TravelsaversBookings::CoreTest

module TravelsaversBookings
  
  class CoreTest < ActiveSupport::TestCase

    def setup
      FakeWeb.allow_net_connect = false
    end

    context "self.create_or_reset_with_transaction_id!" do
      setup do
        @transaction_id = "DEF-54321"
      end

      context "existing booking" do
        setup do
          @booking = Factory(:travelsavers_booking_with_validation_errors, :book_transaction_id => "ABC-12345")
        end

        should "reset booking xml, update the ts_transaction_id, and transition to :booking_nil_payment_nil" do
          assert_no_difference "TravelsaversBooking.count" do
            result = TravelsaversBooking.create_or_reset_with_new_transaction_id!(@transaction_id, @booking.daily_deal_purchase.uuid)
            assert_equal @booking, result
          end
          @booking.reload
          assert_nil @booking.book_transaction_xml
          assert_nil @booking.booking_status
          assert_nil @booking.payment_status
          assert_equal @transaction_id, @booking.book_transaction_id
        end
      end

      context "new booking" do
        should "create a new booking for the purchase with the transaction id" do
          @purchase = Factory(:travelsavers_daily_deal_purchase)
          assert_difference "TravelsaversBooking.count" do
            @booking = TravelsaversBooking.create_or_reset_with_new_transaction_id!(@transaction_id, @purchase.uuid)
          end
          assert_equal @purchase, @booking.daily_deal_purchase
          assert_equal @transaction_id, @booking.book_transaction_id
          assert_nil @booking.booking_status
          assert_nil @booking.payment_status
        end
      end
    end

    context "#flag_for_manual_review!" do
      
       should "set needs_manual_review to true" do
         booking = Factory :successful_travelsavers_booking_with_failed_payment
         assert !booking.needs_manual_review?
         booking.flag_for_manual_review!
         assert booking.needs_manual_review?
       end

    end

    context "sync_with_travelsavers!" do

      setup do
        @booking = Factory :pending_travelsavers_booking
        url = "https://psclient:TSvH78%23L$@bookingservices.travelsavers.com:443/productservice.svc/REST/BookingTransaction?TransactionID=#{@booking.book_transaction_id}"
        stub_ts_success_with_vendor_booking_retrieval_errors_response(url)
        ActionMailer::Base.deliveries.clear
      end

      
      should "send an internal notification email when one or more unfixable errors occur" do
        assert ActionMailer::Base.deliveries.blank?
        assert !@booking.needs_manual_review?
        @booking.sync_with_travelsavers!
        @booking.reload
        assert @booking.needs_manual_review?
        error_emails = ActionMailer::Base.deliveries.select { | e | e.subject =~ /error/i }
        assert_equal 1, error_emails.size
        email = error_emails.first
        assert_equal "[test] TravelsaversBooking #{@booking.id}: Error - Action Required", email.subject
      end

      should "raise an exception when called on a booking that needs manual review" do
        @booking.flag_for_manual_review!
        assert @booking.needs_manual_review?
        e = assert_raises(RuntimeError) { @booking.sync_with_travelsavers! }
        assert_equal "Can't call sync_with_travelsavers! on TravelsaversBooking #{@booking.id} because this booking has been flagged for manual review",
                     e.message
      end

    end

    context "has_user_fixable_cc_errors?" do
      
      should "return true when the booking has user fixable CC errors" do
        booking = Factory :travelsavers_booking_with_fixable_booking_errors
        assert booking.has_user_fixable_cc_errors?
      end

      should "return false whenthe booking does not have user fixable CC errors" do
        booking = Factory :successful_travelsavers_booking
        assert !booking.has_user_fixable_cc_errors?
      end

    end

  end
  
end
