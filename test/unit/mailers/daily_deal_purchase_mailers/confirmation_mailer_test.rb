require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class DailyDealPurchaseMailers::ConfirmationMailerTest

module DailyDealPurchaseMailers
  class ConfirmationMailerTest < ActionMailer::TestCase
    def setup
      @booking = Factory(:successful_travelsavers_booking)
      @purchase = @booking.daily_deal_purchase
      @purchase.publisher.tap do |pub|
        pub.support_email_address = "support@dealpublisher.com"
        pub.save!
      end
      @email = DailyDealPurchaseMailer.create_confirmation(@purchase)
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

    should "be sent to the purchaser" do
      assert_equal [@purchase.consumer.email], @email.to
    end

    should "be from the publisher email address" do
      assert_equal [@purchase.publisher.support_email_address], @email.from
    end

    should "have Purchase Confirmed as the subject" do
      assert_equal "Purchase Confirmed", @email.subject
    end

    should "have a thank you" do
      assert_match /thank you/i, @parts[:text].body
      assert_match /thank you/i, html_body(@email).css("#thank_you").inner_html
    end

    should "have the purchase summary" do
      summary = <<"EOF"
Vacation summary: #{@booking.product_name}
#{@booking.subproduct_name}
Total: #{@booking.total_charges}
Booking Reference: #{@booking.confirmation_number}
EOF
      assert_match /#{Regexp.escape summary}/, plain_body(@email)

      assert_equal @booking.product_name, html_body(@email).css("#product_name").inner_html
      assert_equal @booking.subproduct_name, html_body(@email).css("#subproduct_name").inner_html
      assert_equal @booking.provider_name, html_body(@email).css('#provider_name').inner_html
      assert_equal @booking.formatted_product_date, html_body(@email).css('#product_date').inner_html
      assert_equal @booking.total_charges, html_body(@email).css("#total_charges").inner_html
      assert_equal @booking.confirmation_number, html_body(@email).css("#confirmation_number").inner_html
    end

    should "have the passenger info" do
      @booking.passengers.each_with_index do |passenger, i|
        passenger_text = <<"EOF"
#{passenger.name}
#{passenger.address1}
#{passenger.locality}, #{passenger.region} #{passenger.postal_code} #{passenger.country_code}
Date Of Birth: #{passenger.birth_date.strftime("%m/%d/%Y")}
EOF
        assert_match /#{Regexp.escape passenger_text}/, plain_body(@email)

        node = html_body(@email).css "#passenger_#{i}.passenger"
        assert_equal passenger.name, node.css(".passenger_name").inner_html
        assert_equal passenger.address1, node.css(".passenger_address1").inner_html
        assert_nil node.css(".passenger_address2").first
        assert_equal passenger.locality, node.css(".passenger_locality").inner_html
        assert_equal passenger.region, node.css(".passenger_region").inner_html
        assert_equal passenger.postal_code, node.css(".passenger_postal_code").inner_html
        assert_equal passenger.country_code, node.css(".passenger_country").inner_html
        assert_equal passenger.country_code, node.css(".passenger_country").inner_html
        assert_equal "Date Of Birth: #{passenger.birth_date.strftime("%m/%d/%Y")}", node.css(".passenger_birth_date").inner_html
      end
    end

    should "have the Next Steps" do
      assert plain_body(@email).include?(@booking.next_steps.text)
      expected_html = @booking.next_steps.html
      actual_html = html_body(@email).css("#next_steps").inner_html
      assert_similar_html expected_html, actual_html
    end

    context "A booking with no Next Steps provided in the response" do
      setup do
        @booking = Factory(:successful_travelsavers_booking_without_next_steps)
        @purchase = @booking.daily_deal_purchase
        @email = DailyDealPurchaseMailer.create_confirmation(@purchase)
        @parts = parts(@email)
      end

      should "not have Next Steps in the email body" do
        assert html_body(@email).css("#next_steps").inner_html.blank?
      end

    end

  end
end
