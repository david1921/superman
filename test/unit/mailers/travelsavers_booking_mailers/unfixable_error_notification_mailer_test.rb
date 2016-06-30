require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class TravelsaversBookingMailers::UnfixableErrorNotificationMailerTest

module TravelsaversBookingMailers

  class UnfixableErrorNotificationMailerTest < ActionMailer::TestCase

    context "#unfixable_error_internal_notification" do

      setup do
        @mailer = TravelsaversBookingMailer
      end

      context "when called with a booking that has no unfixable errors" do

        setup do
          @booking = Factory :successful_travelsavers_booking
        end

        should "raise an ArgumentError" do
          assert_raises(ArgumentError) { @mailer.create_unfixable_error_internal_notification(@booking) }
        end

      end

      context "when called with a booking that has at least one unfixable error" do

        setup do
          @booking = Factory :travelsavers_booking_with_vendor_retrieval_errors
          @email = @mailer.create_unfixable_error_internal_notification(@booking)
          @parts = parts(@email)
          @body = html_body(@email).to_html
        end

        should "send the error to the email addresses listed in TravelsaversConfig.internal_notification_recipients" do
          assert_equal %w(brad.bollenbach@analoganalytics.com
                          daniel.zajic@analoganalytics.com
                          jin.pak@analoganalytics.com
                          sean.debeikes@analoganalytics.com), TravelsaversConfig.internal_notification_recipients
          assert_equal TravelsaversConfig.internal_notification_recipients, @email.to
        end

        should "send from the error notification email address" do
          assert_equal ["app@analoganalytics.com"], @email.from
        end

        should "have an html part" do
          assert_not_nil @parts[:html]
          assert_match /html/, @parts[:html].content_type
        end

        should "have a subject line that says an unfixable error occurred, prefixed with the environment" do
          assert_equal "[test] TravelsaversBooking #{@booking.id}: Error - Action Required", @email.subject
        end

        should "provide the unfixable error messages" do
          assert_match /An unhandled error occurred while accessing the booking information from the vendor : Unable to communicate with the cruise line.  Please try again later./,
                       @body
        end

        should "provide instructions on what to do next" do
          assert_match /contact Brad B.*or Dan Z./i, @body
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
end
