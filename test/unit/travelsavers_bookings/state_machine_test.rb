require File.dirname(__FILE__) + "/../../test_helper"

# hydra class TravelsaversBookings::StateMachineTest

module TravelsaversBookings
  
  class StateMachineTest < ActiveSupport::TestCase
    
    def self.should_call_method_on_transition_to_state(method, transition_target_state)
      should "call #{method} on transition to state #{transition_target_state}" do
        @booking.expects(method)
        @booking.transition_to(transition_target_state)
        assert_equal transition_target_state.to_s, @booking.state
      end
    end
    
    context "The TravelsaversBooking state machine" do

      should "not allow directly setting the booking status" do
        booking = Factory :pending_travelsavers_booking
        e = assert_raises(RuntimeError) { booking.booking_status = TravelsaversBookings::Statuses::BookingStatus::SUCCESS }
        assert_equal "can't assign booking_status directly on an existing record. use transition_to instead.", e.message
      end
      
      should "not allow directly setting the payment status" do
        booking = Factory :pending_travelsavers_booking
        e = assert_raises(RuntimeError) { booking.payment_status = TravelsaversBookings::Statuses::PaymentStatus::SUCCESS }
        assert_equal "can't assign payment_status directly on an existing record. use transition_to instead.", e.message
      end

      context "transition rules" do

        context "transitioning to an unknown state" do

          should "raise a StateMachine with a description of the invalid state" do
            booking = Factory :pending_travelsavers_booking
            e = assert_raises(::StateMachine::Error) { booking.transition_to(:some_made_up_state) }
            assert_equal "transition failure: no such state :some_made_up_state (TravelsaversBooking ID: #{booking.id})", e.message
          end

        end

        context "with booking_status nil, payment_status nil" do

          setup do
            @booking = Factory :travelsavers_booking
            assert_equal "booking_nil_payment_nil", @booking.state
          end

          should "not allow a transition to a state that doesn't exist" do
            should_not_allow_transition_to(@booking, :does_not_exist)
          end

          should "allow transitions to the following states" do
            should_allow_transition_to(
              @booking,
              :booking_success_payment_success,
              :booking_success_payment_fail,
              :booking_fail_payment_fail,
              :booking_success_payment_pending,
              :booking_pending_payment_pending,
              :booking_canceled_payment_unknown,
              :booking_unknown_payment_unknown,
              :booking_nil_payment_nil,
              :booking_success_payment_unknown
            )
          end

        end

        context "with booking_status success, payment_status success" do

          setup do
            @booking = Factory :travelsavers_booking,
                               :booking_status => TravelsaversBookings::Statuses::BookingStatus::SUCCESS,
                               :payment_status => TravelsaversBookings::Statuses::PaymentStatus::SUCCESS
            assert_equal "booking_success_payment_success", @booking.state
          end

          should "allow transitions to the following states" do
            should_allow_transition_to(
              @booking,
              :booking_success_payment_success,
              :booking_canceled_payment_unknown)
          end

          should "not allow transitions to the following states" do
            should_not_allow_transition_to(
              @booking,
              :booking_success_payment_fail,
              :booking_fail_payment_fail,
              :booking_success_payment_pending,
              :booking_pending_payment_pending,
              :booking_unknown_payment_unknown,
              :booking_nil_payment_nil,
              :booking_success_payment_unknown)
          end

        end

        context "with booking_status success, payment_status fail" do

          setup do
            @booking = Factory :successful_travelsavers_booking_with_failed_payment
            assert_equal "booking_success_payment_fail", @booking.state
          end

          should "allow transitions to the following states" do
            should_allow_transition_to(
              @booking,
              :booking_success_payment_success,
              :booking_canceled_payment_unknown,
              :booking_success_payment_fail
            )
          end

          should "not allow transitions to the following states" do
            should_not_allow_transition_to(
              @booking,
              :booking_fail_payment_fail,
              :booking_success_payment_pending,
              :booking_pending_payment_pending,
              :booking_unknown_payment_unknown,
              :booking_nil_payment_nil,
              :booking_success_payment_unknown)
          end

        end
        
        context "with booking_status success, payment_status unknown" do
          
          setup do
            @booking = Factory :travelsavers_booking_with_vendor_retrieval_errors
            assert_equal "booking_success_payment_unknown", @booking.state
          end
          
          should "allow transitions to the following states" do
            should_allow_transition_to(
              @booking,
              :booking_success_payment_unknown,
              :booking_success_payment_success,
              :booking_success_payment_fail,
              :booking_success_payment_pending,
              :booking_canceled_payment_unknown)
          end
          
          should "not allow transitions to the following states" do
            should_not_allow_transition_to(
              @booking,
              :booking_fail_payment_fail,
              :booking_pending_payment_pending,
              :booking_unknown_payment_unknown,
              :booking_nil_payment_nil)
          end
          
        end

        context "with booking_status fail, payment_status fail" do

          setup do
            @booking = Factory :travelsavers_booking,
                               :booking_status => TravelsaversBookings::Statuses::BookingStatus::FAIL,
                               :payment_status => TravelsaversBookings::Statuses::PaymentStatus::FAIL
            assert_equal "booking_fail_payment_fail", @booking.state
          end
          
          should "allow transitions to each of these states" do
            should_allow_transition_to(
              @booking,
              :booking_fail_payment_fail,
              :booking_nil_payment_nil)
          end

          should "not allow transitions to any of these states" do
            should_not_allow_transition_to(
              @booking,
              :booking_success_payment_success,
              :booking_success_payment_fail,
              :booking_success_payment_pending,
              :booking_pending_payment_pending,
              :booking_canceled_payment_unknown,
              :booking_unknown_payment_unknown,
              :booking_success_payment_unknown)
          end

        end

        context "with booking_status success, payment_status pending" do

          setup do
            @booking = Factory :travelsavers_booking,
                               :booking_status => TravelsaversBookings::Statuses::BookingStatus::SUCCESS,
                               :payment_status => TravelsaversBookings::Statuses::PaymentStatus::PENDING
            assert_equal "booking_success_payment_pending", @booking.state
          end

          should "allow transitions to each of these states" do
            should_allow_transition_to(
              @booking,
              :booking_success_payment_success,
              :booking_success_payment_fail,
              :booking_canceled_payment_unknown,
              :booking_success_payment_pending)
          end

          should "not allow transitions to any of these states" do
            should_not_allow_transition_to(
              @booking,
              :booking_fail_payment_fail,
              :booking_pending_payment_pending,
              :booking_unknown_payment_unknown,
              :booking_nil_payment_nil,
              :booking_success_payment_unknown)
          end

        end

        context "with booking_status pending, payment_status pending" do

          setup do
            @booking = Factory :travelsavers_booking,
                               :booking_status => TravelsaversBookings::Statuses::BookingStatus::PENDING,
                               :payment_status => TravelsaversBookings::Statuses::PaymentStatus::PENDING
            assert_equal "booking_pending_payment_pending", @booking.state
          end

          should "allow transitions to each of these states" do
            should_allow_transition_to(
              @booking,
              :booking_pending_payment_pending,
              :booking_success_payment_success,
              :booking_success_payment_fail,
              :booking_success_payment_pending,
              :booking_fail_payment_fail,
              :booking_unknown_payment_unknown,
              :booking_success_payment_unknown)
          end

          should "not allow transitions to any of these states" do
            should_not_allow_transition_to(
              @booking,
              :booking_canceled_payment_unknown,
              :booking_nil_payment_nil)
          end

        end

        context "with booking_status canceled, payment_status unknown" do

          setup do
            @booking = Factory :travelsavers_booking,
                               :booking_status => TravelsaversBookings::Statuses::BookingStatus::CANCELED,
                               :payment_status => TravelsaversBookings::Statuses::PaymentStatus::UNKNOWN
            assert_equal "booking_canceled_payment_unknown", @booking.state
          end
          
          should "allow transition to its own state" do
            should_allow_transition_to(@booking, :booking_canceled_payment_unknown)
          end

          should "not allow transitions to any of these states" do
            should_not_allow_transition_to(
              @booking,
              :booking_success_payment_success,
              :booking_success_payment_fail,
              :booking_fail_payment_fail,
              :booking_success_payment_pending,
              :booking_pending_payment_pending,
              :booking_unknown_payment_unknown,
              :booking_nil_payment_nil,
              :booking_success_payment_unknown)
          end

        end

        context "with booking_status unknown, payment_status unknown" do

          setup do
            @booking = Factory :travelsavers_booking,
                               :booking_status => TravelsaversBookings::Statuses::BookingStatus::UNKNOWN,
                               :payment_status => TravelsaversBookings::Statuses::PaymentStatus::UNKNOWN
            assert_equal "booking_unknown_payment_unknown", @booking.state
          end

          should "allow transitions to any of these states" do
            should_allow_transition_to(
              @booking,
              :booking_success_payment_success,
              :booking_success_payment_fail,
              :booking_fail_payment_fail,
              :booking_success_payment_pending,
              :booking_pending_payment_pending,
              :booking_canceled_payment_unknown,
              :booking_unknown_payment_unknown,
              :booking_success_payment_unknown)
          end

          should "not allow transitions to any of these states" do
            should_not_allow_transition_to(
              @booking,
              :booking_nil_payment_nil)
          end

        end

        context "invalid transition" do
          should "raise an exception when already flagged for review" do
            booking = Factory :travelsavers_booking,
                              :booking_status => TravelsaversBookings::Statuses::BookingStatus::SUCCESS,
                              :payment_status => TravelsaversBookings::Statuses::PaymentStatus::PENDING,
                              :needs_manual_review => true
            assert_equal "booking_success_payment_pending", booking.state
            assert booking.needs_manual_review
            assert_no_difference "ActionMailer::Base.deliveries.size" do
              assert_raises ::StateMachine::InvalidTransition do
                booking.transition_to(:booking_pending_payment_pending)
              end
            end
            booking.reload
            assert booking.needs_manual_review?
            assert_equal "booking_success_payment_pending", booking.state
          end

          should "deliver internal notification and flag for review when not already flagged for review" do
            booking = Factory :travelsavers_booking,
                              :booking_status => TravelsaversBookings::Statuses::BookingStatus::SUCCESS,
                              :payment_status => TravelsaversBookings::Statuses::PaymentStatus::PENDING,
                              :needs_manual_review => false
            assert_equal "booking_success_payment_pending", booking.state
            assert !booking.needs_manual_review?
            assert_difference "ActionMailer::Base.deliveries.size" do
              assert_raises ::StateMachine::InvalidTransition do
                booking.transition_to(:booking_pending_payment_pending)
              end
            end
            booking.reload
            assert booking.needs_manual_review?
            assert_equal "booking_success_payment_pending", booking.state
            email = ActionMailer::Base.deliveries.last
            assert_equal "[test] TravelsaversBooking #{booking.id}: Invalid Transition - Action Required", email.subject
          end
        end

      end

      context "methods called on transitions" do
        
        context "initial state booking_status success, payment_status success" do
          
          setup do
            @booking = Factory :travelsavers_booking,
                               :booking_status => TravelsaversBookings::Statuses::BookingStatus::SUCCESS,
                               :payment_status => TravelsaversBookings::Statuses::PaymentStatus::SUCCESS
          end
          
          should_call_method_on_transition_to_state(:cancel_booking, :booking_canceled_payment_unknown)

        end
        
        context "initial state booking_status success, payment_status fail" do
          
          setup do
            @booking = Factory :travelsavers_booking,
                               :booking_status => TravelsaversBookings::Statuses::BookingStatus::SUCCESS,
                               :payment_status => TravelsaversBookings::Statuses::PaymentStatus::FAIL
          end
          
          should_call_method_on_transition_to_state(
            :capture_successful_payment_that_failed_initially_on_successful_booking, :booking_success_payment_success)
          should_call_method_on_transition_to_state(
            :cancel_successful_booking_with_failed_payment, :booking_canceled_payment_unknown)          

        end
        
        context "initial state booking_status success, payment_status pending" do
          
          setup do
            @booking = Factory :travelsavers_booking,
                               :booking_status => TravelsaversBookings::Statuses::BookingStatus::SUCCESS,
                               :payment_status => TravelsaversBookings::Statuses::PaymentStatus::PENDING
          end
          
          should_call_method_on_transition_to_state(
            :capture_payment_for_successful_booking, :booking_success_payment_success)
          should_call_method_on_transition_to_state(
            :capture_successful_booking_and_failed_payment, :booking_success_payment_fail)
          should_call_method_on_transition_to_state(
            :cancel_successful_booking_with_pending_payment, :booking_canceled_payment_unknown)
        end
        
        context "initial state booking_status pending, payment_status pending" do
          
          setup do
            @booking = Factory :travelsavers_booking,
                               :booking_status => TravelsaversBookings::Statuses::BookingStatus::PENDING,
                               :payment_status => TravelsaversBookings::Statuses::PaymentStatus::PENDING
          end
          
          should_call_method_on_transition_to_state(
            :capture_successful_booking_and_successful_payment, :booking_success_payment_success)
          should_call_method_on_transition_to_state(
            :capture_successful_booking_and_failed_payment, :booking_success_payment_fail)
          should_call_method_on_transition_to_state(
            :capture_successful_booking_with_payment_still_pending, :booking_success_payment_pending)
          should_call_method_on_transition_to_state(
            :capture_successful_booking_and_unknown_payment, :booking_success_payment_unknown)
          should_call_method_on_transition_to_state(
            :capture_failed_booking_and_failed_payment, :booking_fail_payment_fail)
          
        end
        
        context "initial state booking_status unknown, payment_status unknown" do
          
          setup do
            @booking = Factory :travelsavers_booking,
                               :booking_status => TravelsaversBookings::Statuses::BookingStatus::UNKNOWN,
                               :payment_status => TravelsaversBookings::Statuses::PaymentStatus::UNKNOWN
          end
          
          should_call_method_on_transition_to_state(
            :capture_successful_booking_and_successful_payment, :booking_success_payment_success)
          should_call_method_on_transition_to_state(
            :capture_successful_booking_and_failed_payment, :booking_success_payment_fail)
          should_call_method_on_transition_to_state(
            :capture_failed_booking_and_failed_payment, :booking_fail_payment_fail)
          should_call_method_on_transition_to_state(
            :capture_successful_booking_and_pending_payment, :booking_success_payment_pending)
          should_call_method_on_transition_to_state(
            :capture_booking_pending_and_payment_pending, :booking_pending_payment_pending)
          should_call_method_on_transition_to_state(
            :capture_successful_booking_and_unknown_payment, :booking_success_payment_unknown)
          should_call_method_on_transition_to_state(
            :cancel_booking_with_unknown_booking_and_payment_status, :booking_canceled_payment_unknown)
          
        end

        context "initial state booking_status nil, payment_status nil" do
          
          setup do
            @booking = Factory :travelsavers_booking, :booking_status => nil, :payment_status => nil
          end
          
          should_call_method_on_transition_to_state(
            :capture_successful_booking_and_successful_payment, :booking_success_payment_success)
          should_call_method_on_transition_to_state(
            :capture_successful_booking_and_failed_payment, :booking_success_payment_fail)
          should_call_method_on_transition_to_state(
            :capture_failed_booking_and_failed_payment, :booking_fail_payment_fail)
          should_call_method_on_transition_to_state(
            :capture_successful_booking_and_pending_payment, :booking_success_payment_pending)
          should_call_method_on_transition_to_state(
            :capture_booking_pending_and_payment_pending, :booking_pending_payment_pending)
          should_call_method_on_transition_to_state(
            :capture_successful_booking_and_unknown_payment, :booking_success_payment_unknown)
          should_call_method_on_transition_to_state(
            :cancel_booking_with_nil_booking_and_payment_status, :booking_canceled_payment_unknown)
          
        end
        
      end

      context "behavior of transition methods" do

        context "#capture_successful_booking_and_successful_payment" do

          should "capture the purchase" do
            booking = Factory(:pending_travelsavers_booking)
            assert !booking.daily_deal_purchase.captured?
            booking.send(:capture_successful_booking_and_successful_payment)
            assert booking.daily_deal_purchase.captured?
          end

        end
        
        context "#capture_successful_payment_that_failed_initially_on_successful_booking" do

          should "capture the purchase" do
            booking = Factory(:successful_travelsavers_booking_with_failed_payment)
            assert !booking.daily_deal_purchase.captured?
            booking.send(:capture_successful_payment_that_failed_initially_on_successful_booking)
            assert booking.daily_deal_purchase.captured?            
          end

        end
        
        context "#capture_successful_booking_and_failed_payment" do
          setup do
            @booking = Factory(:travelsavers_booking)
            assert !@booking.daily_deal_purchase.authorized?
            ActionMailer::Base.deliveries.clear
          end

          should "set the purchase row to authorized if it wasn't already authorized" do
            @booking.send(:capture_successful_booking_and_failed_payment)
            assert @booking.daily_deal_purchase.authorized?
          end

          should "notify consumer about payment failure if past polling limit" do
            assert !ActionMailer::Base.deliveries.any? { |e| e.subject == "Your Deal of the Day Booking Could Not Be Processed" }
            Timecop.freeze(@booking.updated_at + TravelsaversBooking::BROWSER_POLLING_TIME_LIMIT) do
              @booking.send(:capture_successful_booking_and_failed_payment)
            end
            payment_failure_emails = ActionMailer::Base.deliveries.select { |e| e.subject == "Your Deal of the Day Booking Could Not Be Processed" }
            assert_equal 1, payment_failure_emails.size
            email = payment_failure_emails.first
            assert_equal [@booking.daily_deal_purchase.consumer.email], email.to
            assert_equal "Your Deal of the Day Booking Could Not Be Processed", email.subject
          end

          should "send the payment failure notification if within polling time limit" do
            assert ActionMailer::Base.deliveries.blank?
            Timecop.freeze(@booking.updated_at + TravelsaversBooking::BROWSER_POLLING_TIME_LIMIT - 1.second) do
              @booking.send(:capture_successful_booking_and_failed_payment)
            end
            assert_equal 2, ActionMailer::Base.deliveries.size
            assert_same_elements ["Purchase Confirmed", "Your Deal of the Day Booking Could Not Be Processed"],
                                 ActionMailer::Base.deliveries.map(&:subject)
          end

        end
        
        context "#capture_successful_booking_with_payment_still_pending" do

          should "call set_payment_status_and_executed_at! with 'authorized'" do
            booking = Factory(:travelsavers_booking)
            assert booking.daily_deal_purchase.pending?
            booking.expects(:set_payment_status_and_executed_at!).with('authorized')
            booking.send(:capture_successful_booking_with_payment_still_pending)
          end

        end
        
        context "#capture_failed_booking_and_failed_payment" do
          
          should "leave the purchase row as pending if it was already pending" do
            booking = Factory(:travelsavers_booking)
            assert booking.daily_deal_purchase.pending?
            booking.send(:capture_failed_booking_and_failed_payment)
            assert booking.daily_deal_purchase.pending?                                                
          end
          
          should "void the purchase if it was authorized" do
            booking = Factory(:successful_travelsavers_booking_with_failed_payment)
            assert booking.daily_deal_purchase.authorized?
            booking.send(:capture_failed_booking_and_failed_payment)
            assert booking.daily_deal_purchase.voided?                                                            
          end

          context "user-fixable error" do

            should "deliver a user-fixable booking failed email when the booking has validation errors" do
              booking = Factory(:travelsavers_booking_with_validation_errors)
              booking.publisher.production_host = "not-empty.com"
              assert_difference "ActionMailer::Base.deliveries.size", 1 do
                Timecop.travel(TravelsaversBooking::BROWSER_POLLING_TIME_LIMIT.seconds.from_now) do
                  booking.send(:capture_failed_booking_and_failed_payment)
                end
              end
              email = ActionMailer::Base.deliveries.last
              assert_equal [booking.consumer.email], email.to
              assert_equal "Your Deal of the Day Booking Could Not Be Processed", email.subject
              assert_match "your deal is still available to be purchased", email.body
            end

            should  "deliver an email telling the user an error occurred with their credit card when " +
                    "the booking fails with user fixable credit card errors" do
              booking = Factory :travelsavers_booking_with_fixable_booking_errors
              assert booking.has_user_fixable_cc_errors?
              assert_difference "ActionMailer::Base.deliveries.size", 1 do
                Timecop.travel(TravelsaversBooking::BROWSER_POLLING_TIME_LIMIT.seconds.from_now) do
                  booking.send(:capture_failed_booking_and_failed_payment)
                end
              end
              email = ActionMailer::Base.deliveries.last
              assert_equal [booking.consumer.email], email.to
              assert_match /problem with the credit card/, email.body
              assert_match /return to the deal page/, email.body
            end

          end

          context 'non-fixable user error' do
            should "deliver a sold out error email" do
              booking = Factory(:travelsavers_booking_with_sold_out_error)
              booking.publisher.update_attributes! :production_daily_deal_host => 'test.com'
              assert_difference "ActionMailer::Base.deliveries.size" do
                Timecop.travel(TravelsaversBooking::BROWSER_POLLING_TIME_LIMIT.seconds.from_now) do
                  booking.send(:capture_failed_booking_and_failed_payment)
                end
              end
              email = ActionMailer::Base.deliveries.last
              assert_equal [booking.consumer.email], email.to
              assert_equal "Your Deal of the Day Booking Could Not Be Processed", email.subject
              assert_match "you recently tried to purchase has sold out", email.body
            end

            should "deliver a generic error email" do
              booking = Factory(:travelsavers_booking_with_vendor_retrieval_errors)
              booking.publisher.update_attributes! :production_daily_deal_host => 'test.com'
              assert_difference "ActionMailer::Base.deliveries.size" do
                Timecop.travel(TravelsaversBooking::BROWSER_POLLING_TIME_LIMIT.seconds.from_now) do
                  booking.send(:capture_failed_booking_and_failed_payment)
                end
              end
              email = ActionMailer::Base.deliveries.last
              assert_equal [booking.consumer.email], email.to
              assert_equal "Your Deal of the Day Booking Could Not Be Processed", email.subject
              assert_match "We were unable to process your booking from Deal of the Day", email.body
            end


          end

        end
        
        context "#cancel_successful_booking_with_failed_payment" do
          
          should "NOOP because Travelsavers purchases are manually refunded in the backend" do
            booking = Factory :successful_travelsavers_booking_with_failed_payment
            booking.expects(:noop).with("Cancelled bookings are manually refunded.")
            booking.send(:cancel_successful_booking_with_failed_payment)
          end
          
        end
        
        context "#cancel_successful_booking_with_pending_payment" do
          
          should "NOOP because Travelsavers purchases are manually refunded in the backend" do
            booking = Factory :successful_travelsavers_booking_with_pending_payment
            booking.expects(:noop).with("Cancelled bookings are manually refunded.")
            booking.send(:cancel_successful_booking_with_pending_payment)
          end
          
        end

        context "#capture_payment_for_successful_booking" do
          
          should "mark the purchase as captured" do
            booking = Factory(:travelsavers_booking_with_vendor_retrieval_errors)
            assert !booking.daily_deal_purchase.captured?
            booking.send(:capture_payment_for_successful_booking)
            assert booking.daily_deal_purchase.captured?            
          end
          
        end
        
        context "#capture_successful_booking_and_pending_payment" do
          
          should "set the purchase to authorized if it was in a pending state" do
            booking = Factory :travelsavers_booking
            assert_nil booking.booking_status
            assert_nil booking.payment_status
            assert booking.daily_deal_purchase.pending?
            booking.send(:capture_successful_booking_and_pending_payment)
            assert booking.daily_deal_purchase.authorized?
          end
          
          should "set purchase.executed_at if not already set" do
            booking = Factory(:travelsavers_booking)
            assert_nil booking.daily_deal_purchase.executed_at
            Timecop.freeze do
              booking.send(:capture_successful_booking_and_pending_payment)
              assert_equal Time.now, booking.daily_deal_purchase.executed_at
            end

            assert_no_difference "booking.daily_deal_purchase.reload.executed_at" do
              booking.send(:capture_successful_booking_and_pending_payment)
            end
          end
       end
        
        context "#capture_booking_pending_and_payment_pending" do
          
          should "leave the purchase as pending" do
            booking = Factory :travelsavers_booking
            assert_nil booking.booking_status
            assert_nil booking.payment_status
            assert booking.daily_deal_purchase.pending?
            booking.send(:capture_booking_pending_and_payment_pending)
            assert booking.daily_deal_purchase.pending?
          end
          
        end
        
        context "#cancel_booking_with_unknown_booking_and_payment_status" do
          
          should "NOOP because Travelsavers purchases are manually refunded in the backend" do
            booking = Factory :travelsavers_booking_with_unknown_errors
            booking.expects(:noop).with("Cancelled bookings are manually refunded.")
            booking.send(:cancel_booking_with_unknown_booking_and_payment_status)
          end
          
        end
        
        context "#cancel_booking_with_nil_booking_and_payment_status" do
          
          should "NOOP because Travelsavers purchases are manually refunded in the backend" do
            booking = Factory :travelsavers_booking
            assert_nil booking.booking_status
            assert_nil booking.payment_status
            booking.expects(:noop).with("Cancelled bookings are manually refunded.")
            booking.send(:cancel_booking_with_nil_booking_and_payment_status)
          end
          
        end
        
        context "#capture_successful_booking_and_unknown_payment" do
          
          should "set the purchase as authorized if it is not already" do
            booking = Factory :travelsavers_booking
            assert !booking.daily_deal_purchase.authorized?
            booking.send(:capture_successful_booking_and_unknown_payment)
            assert booking.daily_deal_purchase.authorized?
          end

        end
        
      end
      
    end
    
    class DoNotSaveBookingChanges < Exception
    end

    def should_allow_transition_to(booking, *states)
      initial_state = booking.state
      valid_transition_states = get_valid_transition_states(booking, states)
      failed_transition_states = states - valid_transition_states
      assert failed_transition_states.blank?,
             "transition from #{initial_state} to #{failed_transition_states.to_sentence} should be allowed"
    end
    
    def should_not_allow_transition_to(booking, *states)
      initial_state = booking.state
      valid_transition_states = get_valid_transition_states(booking, states)
      assert valid_transition_states.blank?,
             "transition from #{initial_state} to #{valid_transition_states.to_sentence} should not be allowed"
    end
    
    def get_valid_transition_states(booking, target_states)
      valid_transition_states = target_states.select do |s|
        booking.reload
        
        begin
          TravelsaversBooking.transaction do
            booking.transition_to(s)
            raise DoNotSaveBookingChanges
          end
        rescue DoNotSaveBookingChanges
          true
        rescue ::StateMachine::InvalidTransition, ::StateMachine::Error
          false
        else
          raise "expected to rollback transaction"
        end
      end
      
      valid_transition_states || []
    end
    
  end
  
end
