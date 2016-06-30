require File.dirname(__FILE__) + "/../../test_helper"

class TravelsaversBookingMailerTest < ActionMailer::TestCase

  def setup
    @mailer = TravelsaversBookingMailer
  end

  context ".user_fixable_credit_card_errors" do

    should "raise an ArgumentError when called with a booking that has no user fixable credit card error" do
      booking = Factory :successful_travelsavers_booking
      e = assert_raises(ArgumentError) { @mailer.create_user_fixable_credit_card_errors(booking) }
      assert_equal "can't deliver user fixable credit card errors notification for " +
                   "TravelsaversBooking #{booking.id}: this booking has no user fixable " +
                   "credit card errors", e.message
    end

    fast_context "when called with a booking that has user fixable credit card errors" do

      setup do
        @booking = Factory :travelsavers_booking_with_fixable_booking_errors
        @booking.consumer.update_attributes! :email => "bob@example.com"
        @booking.publisher.update_attributes! :support_email_address => "support@dealpublisher.com",
                                             :daily_deal_brand_name => "Portland Perks",
                                             :production_host => "portlandperks.com"
        @email = @mailer.create_user_fixable_credit_card_errors(@booking)
        @parts = parts(@email)
        @html_body = html_body(@email).to_html
        @plain_text_body = plain_body(@email)
      end

      should "set the consumer email as the recipient" do
        assert_equal ["bob@example.com"], @email.to
      end

      should "set the from email as the publisher's email address" do
        assert_equal ["support@dealpublisher.com"], @email.from
      end

      should "set the subject line to 'Your [Daily Deal Brand Name] Booking Has Been Received!'" do
        assert_equal "Regarding Your Recent Portland Perks Booking", @email.subject
      end

      should "have a text part" do
        assert @plain_text_body.present?
      end

      should "have an html part" do
        assert @html_body.present?
      end

      should "set the html body to the copy provided by AMs" do
        assert_equal %Q{\
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head></head>
<body>
<h2>We're sorry!</h2>

<p>It looks like there's a problem with the credit card you used for this purchase.</p>

<p>Please <a href="http://portlandperks.com/daily_deals/#{@booking.daily_deal.id}">return to the deal page</a> to purchase your deal again using a valid method of payment.</p>
</body>
</html>
}, @html_body
      end

      should "set the plain text body to the copy provided by AMs" do
        assert_equal %Q{\
We're sorry!

It looks like there's a problem with the credit card you used for this purchase.

Please return to the deal page:

  http://portlandperks.com/daily_deals/#{@booking.daily_deal.id}

to purchase your deal again using a valid method of payment.
}, @plain_text_body
      end

    end

  end

  context ".booking_unresolved_after_24_hours_internal_notification" do

    setup do
      @booking = Factory :pending_travelsavers_booking, :book_transaction_id => "old_unresolved_booking"
      Timecop.freeze(@booking.created_at + 24.hours + 1.second) do
        @email = TravelsaversBookingMailer.create_booking_unresolved_after_24_hours_internal_notification(@booking)
        @parts = parts(@email)
        @body = html_body(@email).to_html
      end
    end

    should "raise an ArgumentError when called with a resolved booking" do
      booking = Factory :successful_travelsavers_booking
      e = assert_raises(ArgumentError) { TravelsaversBookingMailer.create_booking_unresolved_after_24_hours_internal_notification(booking) }
      assert_equal "can't call booking_unresolved_after_24_hours_internal_notification with a resolved booking", e.message
    end

    should "raise an ArgumentError when called with a booking that has been unresolved for less than 24 hours" do
      booking = Factory :pending_travelsavers_booking
      e = assert_raises(ArgumentError) { TravelsaversBookingMailer.create_booking_unresolved_after_24_hours_internal_notification(booking) }
      assert_equal "can't call booking_unresolved_after_24_hours_internal_notification with a booking that has been unresolved for less than 24 hours", e.message
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

    should "have a subject line describing this alert, prefixed with environment" do
      assert_equal "[test] TravelsaversBooking #{@booking.id}: Unresolved - Action Required", @email.subject
    end

    should "describe the nature of the issue, and include relevant debugging details" do
      assert_match /TravelsaversBooking #{@booking.id} has been in an unresolved state for over 24 hours/, @body
      assert_match /This means that either the booking, the payment, or both have not yet gone through successfully/, @body
      assert_match /We should contact Travelsavers to find out if there is an issue with this booking/, @body
      assert_match /Deal: .+/, @body
      assert_match /Book Transaction ID: old_unresolved_booking/, @body
      assert_match /Created at: .+/, @body
      assert_match /Booking Status: Pending/, @body
      assert_match /Payment Status: Pending/, @body
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
