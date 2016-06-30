require File.dirname(__FILE__) + "/../../test_helper"

class ApiRequestMailerTest < ActionMailer::TestCase
  tests ApiRequestMailer
  
  def setup
    ActionMailer::Base.deliveries.clear
  end
  
  def test_api_generated_message
    email_api_request = publishers(:li_press).email_api_requests.build(
      :email_subject => "Your Long Island Press coupon",
      :destination_email_address => "jdoe@hotmail.com",
      :text_plain_content => "Here is the coupon you requested at longislandpress.com",
      :text_html_content => "<table><tr><td>Here is the coupon you requested</td></tr></table>".html_safe
                                                                       
    )
    assert email_api_request.valid?
    ApiRequestMailer.deliver_api_generated_message(email_api_request)

    assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email"
    email = ActionMailer::Base.deliveries.first

    assert_equal ["support@txt411.com"], email.from, "From: header"
    assert_equal "Long Island Press Coupons", email.friendly_from, "From: header (friendly)"
    assert_equal ["jdoe@hotmail.com"], email.to, "To: header"
    assert_equal "Your Long Island Press coupon", email.subject, "Subject: header"
    assert_equal "multipart/alternative", email.content_type, "Content-Type: header"

    assert_equal 2, email.parts.size, "Should have 2 parts"
    
    part = email.parts.first
    assert_equal "text/plain", part.content_type, "Content-Type: of first part"
    assert_equal "base64", part.transfer_encoding, "Content-Transfer-Encoding: of first part"
    assert_match /\AHere is the coupon you requested at longislandpress.com/, part.body
    
    part = email.parts.second
    assert_equal "text/html", part.content_type, "Content-Type: of second part"
    assert_equal "base64", part.transfer_encoding, "Content-Transfer-Encoding: of second part"
    assert_match %r{<table><tr><td>Here is the coupon you requested</td></tr></table>}, part.body
  end
end
