require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Travelsavers::UpdateUnresolvedTravelsaversBookingStatusesTest

module Travelsavers
  
  class UpdateUnresolvedTravelsaversBookingStatusesTest < ActiveSupport::TestCase
    
    context "UpdateUnresolvedTravelsaversBookingStatuses.perform" do
      
      setup do
        FakeWeb.allow_net_connect = false

        @unresolved_booking_1_url = "https://psclient:TSvH78%23L$@bookingservices.travelsavers.com:443/productservice.svc/REST/BookingTransaction?TransactionID=unresolved_booking_1"
        @unresolved_booking_2_url = "https://psclient:TSvH78%23L$@bookingservices.travelsavers.com:443/productservice.svc/REST/BookingTransaction?TransactionID=unresolved_booking_2"
        
        @unresolved_booking_1 = Factory :successful_travelsavers_booking_with_failed_payment,
                                :book_transaction_id => "unresolved_booking_1"
        @unresolved_booking_2 = Factory :travelsavers_booking_with_unknown_errors,
                                :book_transaction_id => "unresolved_booking_2"
        @unresolved_booking_needing_manual_review = Factory :successful_travelsavers_booking_with_failed_payment,
                                                            :book_transaction_id => "unresolved_booking_needing_manual_review",
                                                            :needs_manual_review => true
        @resolved_booking_1 = Factory :successful_travelsavers_booking,
                              :book_transaction_id => "resolved_booking_1"
      end

      should "call sync_with_travelsavers on each unresolved booking that is not flagged for manual review" do
        Travelsavers::UpdateUnresolvedTravelsaversBookingStatuses.expects(:sync_with_travelsavers).with(equals(@unresolved_booking_1)).once
        Travelsavers::UpdateUnresolvedTravelsaversBookingStatuses.expects(:sync_with_travelsavers).with(equals(@unresolved_booking_2)).once
        Travelsavers::UpdateUnresolvedTravelsaversBookingStatuses.expects(:sync_with_travelsavers).with(equals(@unresolved_booking_needing_manual_review)).never
        Travelsavers::UpdateUnresolvedTravelsaversBookingStatuses.expects(:sync_with_travelsavers).with(equals(@resolved_booking_1)).never

        Travelsavers::UpdateUnresolvedTravelsaversBookingStatuses.perform
      end
      
      should "call the state transition method with the booking and payment statuses present in the TS XML" do
        stub_ts_success_response(@unresolved_booking_1_url)
        stub_ts_vendor_booking_errors_response(@unresolved_booking_2_url)
        
        Travelsavers::UpdateUnresolvedTravelsaversBookingStatuses.perform
        
        @unresolved_booking_1.reload
        @unresolved_booking_2.reload
        @resolved_booking_1.reload
        
        assert_equal "success", @unresolved_booking_1.booking_status
        assert_equal "success", @unresolved_booking_1.payment_status
        
        assert_equal "fail", @unresolved_booking_2.booking_status
        assert_equal "fail", @unresolved_booking_2.payment_status
        
        assert_equal "success", @resolved_booking_1.booking_status
        assert_equal "success", @resolved_booking_1.payment_status
      end
      
      should "catch exceptions raised when fetching statuses and send them to Exceptional, but continue processing" do
        stub_ts_server_500_error_response(@unresolved_booking_1_url)
        stub_ts_success_response(@unresolved_booking_2_url)
        
        Exceptional.expects(:handle).once
        Travelsavers::UpdateUnresolvedTravelsaversBookingStatuses.perform
        
        @unresolved_booking_1.reload
        @unresolved_booking_2.reload
        
        assert_equal "success", @unresolved_booking_1.booking_status
        assert_equal "fail", @unresolved_booking_1.payment_status
        
        assert_equal "success", @unresolved_booking_2.booking_status
        assert_equal "success", @unresolved_booking_2.booking_status
      end
      
      should "catch exceptions raised on transitions and send them to Exceptional, but continue processing" do
        stub_ts_pending_response(@unresolved_booking_1_url)
        stub_ts_success_response(@unresolved_booking_2_url)
        
        Exceptional.expects(:handle).once
        Travelsavers::UpdateUnresolvedTravelsaversBookingStatuses.perform
        
        @unresolved_booking_1.reload
        @unresolved_booking_2.reload
        
        assert_equal "success", @unresolved_booking_1.booking_status
        assert_equal "fail", @unresolved_booking_1.payment_status
        
        assert_equal "success", @unresolved_booking_2.booking_status
        assert_equal "success", @unresolved_booking_2.booking_status        
      end

      fast_context "when a booking has been unresolved for more than 24 hours" do

        setup do
          Timecop.freeze do
            @older_unresolved_booking = Factory :pending_travelsavers_booking, :book_transaction_id => "older_unresolved_booking", :created_at => (24.hours.ago - 1.second)
            older_unresolved_booking_url = "https://psclient:TSvH78%23L$@bookingservices.travelsavers.com:443/productservice.svc/REST/BookingTransaction?TransactionID=older_unresolved_booking"
            stub_ts_success_response(@unresolved_booking_1_url)
            stub_ts_vendor_booking_errors_response(@unresolved_booking_2_url)
            stub_ts_pending_response(older_unresolved_booking_url)

            assert !@older_unresolved_booking.needs_manual_review?
            assert !@unresolved_booking_1.needs_manual_review?
            assert !@unresolved_booking_2.needs_manual_review?
            ActionMailer::Base.deliveries.clear
            Travelsavers::UpdateUnresolvedTravelsaversBookingStatuses.perform
            [@older_unresolved_booking, @unresolved_booking_1, @unresolved_booking_2].each(&:reload)
          end
        end

        should "flag the booking for manual review" do
          assert @older_unresolved_booking.needs_manual_review?
          assert !@unresolved_booking_1.needs_manual_review?
          assert @unresolved_booking_2.needs_manual_review?
        end

        should "send an internal email notification that a booking as been unresolved for more than 24 hours" do
          unresolved_notifications = ActionMailer::Base.deliveries.select { | e | e.subject =~ /Unresolved - Action Required/ }
          assert_equal 1, unresolved_notifications.size
          email = unresolved_notifications.first
          assert_equal "[test] TravelsaversBooking #{@older_unresolved_booking.id}: Unresolved - Action Required", email.subject
        end

      end

    end

  end
  
end
