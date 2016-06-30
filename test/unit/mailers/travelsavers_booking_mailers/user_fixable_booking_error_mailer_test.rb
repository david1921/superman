require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class TravelsaversBookingMailers::UserFixableBookingErrorMailerTest

module TravelsaversBookingMailers
  class UserFixableBookingErrorMailerTest < ActionMailer::TestCase
    def setup
      @booking = Factory(:travelsavers_booking_with_validation_errors)
      @booking.consumer.tap do |c|
        c.email = "consumer@test.com"
        c.save!
      end
      @booking.publisher.tap do |pub|
        pub.support_email_address = "support@dealpublisher.com"
        pub.daily_deal_brand_name = "Portland Perks"
        pub.production_host = "portlandperks.com"
      end
      @email = TravelsaversBookingMailer.create_user_fixable_booking_error(@booking)
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
Oops! There's been an error

Your Portland Perks purchase could not be processed, but your deal is still available to be purchased. Please visit https://portlandperks.com/daily_deal_purchases/#{@booking.daily_deal_purchase.uuid}/error to purchase your deal again. Don't worry, you have not been billed!
EOF
      assert_equal expected_body, plain_body(@email), "Plain-text part was not correct"
    end

    should "have the correct html body" do
      expected_body = <<"EOF"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head></head>
<body>
<h2>Oops! There's been an error</h2>

Your Portland Perks purchase could not be processed, but your deal is still available to be purchased. Please <a href="https://portlandperks.com/daily_deal_purchases/#{@booking.daily_deal_purchase.uuid}/error">return to the deal page</a> to purchase your deal again. Don't worry, you have not been billed!
</body>
</html>
EOF
      assert_similar_html expected_body, html_body(@email).to_html, "HTML part was not correct"
    end

    should "have an unbranded subject line and body if the publisher brand name is blank" do
      @booking.publisher.daily_deal_brand_name = nil

      @email = TravelsaversBookingMailer.create_user_fixable_booking_error(@booking)
      assert_equal "Your Deal of the Day Booking Could Not Be Processed", @email.subject
      assert_match /Your Deal of the Day purchase/, html_body(@email).to_html
      assert_match /Your Deal of the Day purchase/, plain_body(@email)
    end
  end
end
