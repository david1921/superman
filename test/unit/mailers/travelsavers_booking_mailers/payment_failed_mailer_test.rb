require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class TravelsaversBookingMailers::PaymentFailedMailerTest

module TravelsaversBookingMailers
  class PaymentFailedMailerTest < ActionMailer::TestCase
    def setup
      @booking = Factory(:successful_travelsavers_booking_with_failed_payment)
      @booking.consumer.tap do |c|
        c.email = "consumer@test.com"
        c.save!
      end
      @booking.publisher.tap do |pub|
        pub.support_email_address = "support@dealpublisher.com"
        pub.daily_deal_brand_name = "Portland Perks"
      end
      @email = TravelsaversBookingMailer.create_payment_failed(@booking)
      @parts = parts(@email)
    end

    should "have a plain text part" do
      assert_not_nil @parts[:text]
      assert_match /plain/, @parts[:text].content_type
    end

    should "have a html part" do
      assert_not_nil @parts[:html]
      assert_match /html/, @parts[:html].content_type
    end

    should "be sent to the booking's consumer" do
      assert_equal ["consumer@test.com"], @email.to
    end

    should "be from the publisher email address" do
      assert_equal ["support@dealpublisher.com"], @email.from
    end

    should "have the correct subject" do
      assert_equal "Your Portland Perks Booking Could Not Be Processed", @email.subject
    end

    should "have the correct plain text body" do
      expected_body = <<"EOF"
We're sorry!

It looks like there's a problem with the credit card you used for this purchase.

Your booking will be held for one business day. Please contact us within this time at (516) 730-3099 to verify your credit card information or to try again with another card.
EOF
      assert_equal expected_body, plain_body(@email), "Plain-text part was not correct"
    end

    should "have the correct html body" do
      expected_body = <<"EOF"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head></head>
<body>
<p>We're sorry!</p>
<p>It looks like there's a problem with the credit card you used for this purchase.</p>
<p>Your booking will be held for one business day. Please contact us within this time at <span style="color: blue;">(516) 730-3099</span> to verify your credit card information or to try again with another card.</p>
</body>
</html>
EOF
      assert_similar_html expected_body, html_body(@email).to_html, "HTML part was not correct"
    end

    should "have an unbranded subject if the publisher brand name is blank" do
      @booking.publisher.daily_deal_brand_name = nil

      @email = TravelsaversBookingMailer.create_payment_failed(@booking)
      assert_equal "Your Deal of the Day Booking Could Not Be Processed", @email.subject
    end
  end
end
