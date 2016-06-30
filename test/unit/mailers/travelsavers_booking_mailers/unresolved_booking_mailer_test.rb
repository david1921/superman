require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class TravelsaversBookingMailers::UnresolvedBookingMailerTest

module TravelsaversBookingMailers
  class UnresolvedBookingMailerTest < ActionMailer::TestCase
    def setup
      @booking = Factory(:pending_travelsavers_booking)
      @booking.consumer.tap do |c|
        c.email = "consumer@test.com"
      end
      @booking.publisher.tap do |pub|
        pub.support_email_address = "support@dealpublisher.com"
        pub.daily_deal_brand_name = "Portland Perks"
      end
      @email = TravelsaversBookingMailer.create_unresolved_booking(@booking)
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
      assert_equal "Your Portland Perks Booking Has Been Received!", @email.subject
    end

    should "have the correct plain text body" do
      expected_body = (<<"EOF"
We have received your request and are currently processing your information.

You will receive another confirmation email shortly with more information.

Enjoy your trip!
EOF
      ).chomp
      assert_equal expected_body, plain_body(@email), "Plain-text part was not correct"
    end

    should "have the correct html body" do
      expected_body = <<"EOF"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head></head>
<body>
<p>We have received your request and are currently processing your information.</p>
<p>You will receive another confirmation email shortly with more information.</p>
<p>Enjoy your trip!</p>
</body>
</html>
EOF
      assert_similar_html expected_body, html_body(@email).to_html, "HTML part was not correct"
    end

    should "have an unbranded subject if the publisher brand name is blank" do
      @booking.publisher.daily_deal_brand_name = nil

      @email = TravelsaversBookingMailer.create_unresolved_booking(@booking)
      assert_equal "Your Deal of the Day Booking Has Been Received!", @email.subject
    end
  end
end
