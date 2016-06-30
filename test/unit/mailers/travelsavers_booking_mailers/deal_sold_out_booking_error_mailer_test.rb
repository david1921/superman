require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class TravelsaversBookingMailers::DealSoldOutBookingErrorMailerTest

module TravelsaversBookingMailers
  class DealSoldOutBookingErrorMailerTest < ActionMailer::TestCase
    def setup
      @booking = Factory(:travelsavers_booking_with_sold_out_error)
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
      @email = TravelsaversBookingMailer.create_deal_sold_out_booking_error(@booking)
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

The Portland Perks deal, http://http://test.com/daily_deals/#{@booking.daily_deal.id}, you recently tried to purchase has sold out! Your request has not been processed and you have not been billed.

Portland Perks specially negotiates our deals and they are only available in limited quantities. Sign up for Portland Perks emails, http://http://test.com/publishers/#{@booking.publisher.id}/subscribers/new, and be sure to check out the Portland Perks deal page,  http://http://test.com/publishers/#{@booking.publisher.label}/deal-of-the-day, to be the first to view upcoming offers you'll love!
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
<p>
The <a href=\"http://http://test.com/daily_deals/#{@booking.daily_deal.id}\">Portland Perks deal</a> you recently tried to purchase has sold out! Your request has not been processed and you have not been billed.
</p>
<p>
Portland Perks specially negotiates our deals and they are only available in limited quantities. <a href=\"http://http://test.com/publishers/#{@booking.publisher.id}/subscribers/new\">Sign up for Portland Perks emails</a> and be sure to <a href=\"http://http://test.com/publishers/#{@booking.publisher.label}/deal-of-the-day\"> check out the Portland Perks deal page</a> to be the first to view upcoming offers you'll love!
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
