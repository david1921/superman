require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class TravelsaversBookingMailers::InvalidTransitionInternalNotificationTest

module TravelsaversBookingMailers
  class InvalidTransitionInternalNotificationTest < ActionMailer::TestCase

    context "#invalid_transition_internal_notification" do

      setup do
        @mailer = TravelsaversBookingMailer
        @booking = Factory :successful_travelsavers_booking_with_pending_payment
        begin
          @booking.transition_to(:booking_pending_payment_pending)
        rescue ::StateMachine::InvalidTransition => e
          @exception = e
        end

        @email = @mailer.create_invalid_transition_internal_notification(@booking, @exception)
        @parts = parts(@email)
        @body = html_body(@email).to_html
      end

      should "have an html part" do
        assert_not_nil @parts[:html]
        assert_match /html/, @parts[:html].content_type
      end

      should "send the error to the email addresses listed in TravelsaversConfig.internal_notification_recipients" do
        TravelsaversConfig.internal_notification_recipients = %w(
          brad.bollenbach@analoganalytics.com
          daniel.zajic@analoganalytics.com
          jin.pak@analoganalytics.com
          sean.debeikes@analoganalytics.com)
        assert_equal TravelsaversConfig.internal_notification_recipients, @email.to
      end

      should "send from the error notification email address" do
        assert_equal ["app@analoganalytics.com"], @email.from
      end

      should "have a subject line that says an invalid transition occurred" do
        assert_equal "[test] TravelsaversBooking #{@booking.id}: Invalid Transition - Action Required", @email.subject
      end

      should "provide the invalid transition message" do
        assert_match /TravelsaversBooking #{@booking.id} transition error: Cannot transition state via :booking_pending_and_payment_pending from :booking_success_payment_pending/, @body, "email.body expected to have: #{@exception.message}"
      end

      should "provide instructions on what to do next" do
        assert_match /contact Brad B.*or Dan Z./i, @body
        assert_match /Have an account manager contact Travelsavers about the booking to determine the cause of the transition/, @body
        assert_match /Have an AA engineer manually execute transitions on the booking/, @body
      end

      should "provide contact info of account managers and developers" do
        assert_match /Jin Pak \(.+\)/, @body
        assert_match /Sean Debeikes \(.+\)/, @body
        assert_match /Jeff Brisnehan \(.+\)/, @body
        assert_match /Ed Jukkola \(.+\)/, @body
      end
    end
  end
end
