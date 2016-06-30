require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class TravelsaversBookingMailers::GenericNonUserFixableBookingErrorMailerTest

module TravelsaversBookingMailers
  class GenericNonUserFixableBookingErrorMailerTest < ActionMailer::TestCase
    def setup
      @booking = Factory(:travelsavers_booking_with_vendor_retrieval_errors)
      @booking.consumer.tap do |c|
        c.email = "consumer@test.com"
        c.save!
      end
      @booking.publisher.tap do |pub|
        pub.support_email_address = "support@dealpublisher.com"
        pub.daily_deal_brand_name = "Portland Perks"
        pub.production_host = "portlandperks.com"
        pub.production_daily_deal_host = "http://test.com"
        pub.save!
      end
      @email = TravelsaversBookingMailer.create_non_user_fixable_booking_error(@booking)
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

    should "have 'Your Portland Perks Booking Could Not Be Processed' as the subject" do
      assert_equal "Your Portland Perks Booking Could Not Be Processed", @email.subject
    end

    should "have the correct plain text body" do
      expected_body = <<"EOF"
We're sorry!

We were unable to process your booking from Portland Perks, http://http://test.com/daily_deals/#{@booking.daily_deal.id}.

An unhandled error occurred while accessing the booking information from the vendor : Unable to communicate with the cruise line.  Please try again later.

Your request has not been processed and you have not been billed.
EOF

      assert_equal expected_body, plain_body(@email), "Plain-text part was not correct"
    end

    should "have the correct html body" do
      expected_body = <<"EOF"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head></head>
<body>

<h2>We're sorry!</head>

We were unable to process your booking from <a href="http://http://test.com/daily_deals/#{@booking.daily_deal.id}">Portland Perks</a>.
<p>
#{@booking.book_transaction.unfixable_errors.map(&:message).join(', ')}
</p>
<p>
Your request has not been processed and you have not been billed.
</p>
</body>
</html>
EOF
      assert_similar_html expected_body, html_body(@email).to_html, "HTML part was not correct"
    end

    should "use 'Deal of the Day' if brand name is blank" do
      @booking.publisher.tap do |pub|
        pub.daily_deal_brand_name = nil
      end

      @email = TravelsaversBookingMailer.create_user_fixable_booking_error(@booking)
      assert_match /Your Deal of the Day purchase/, html_body(@email).to_html
      assert_match /Your Deal of the Day purchase/, plain_body(@email)
    end
  end
end
