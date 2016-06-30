require File.dirname(__FILE__) + "/../../test_helper"

class AdvertiserSignupMailerTest < ActionMailer::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end

  def test_deliver_account_setup_message
    user = users(:jorge)
    user.reset_perishable_token!
    user.publisher.update_attributes!(
      :support_email_address => "support@sdhaustin.com",
      :approval_email_address => "approval@sdhaustin.com"
    )
    
    AdvertiserSignupMailer.deliver_notification(user)

    assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email"
    email = ActionMailer::Base.deliveries.first

    assert_equal ["support@sdhaustin.com"], email.from, "From: header"
    assert_equal "Green Valley News Coupons", email.friendly_from, "From: header (friendly)"
    assert_equal ["jorgeb@dimilles.com"], email.to, "To: header"
    assert_equal ["approval@sdhaustin.com"], email.bcc, "Should BCC approval email"
    assert_equal "Your new account at Green Valley News", email.subject, "Subject: header"
    assert_equal "multipart/alternative", email.content_type, "Content-Type: header"

    assert_equal 1, email.parts.size, "Should have 1 part"
    
    part = email.parts.first
    assert_equal "text/plain", part.content_type, "Content-Type: of first part"
    assert_equal "quoted-printable", part.transfer_encoding, "Content-Transfer-Encoding: of first part"
    assert_no_match(%r{/password_resets/}, part.body)
    assert_match(/support@sdhaustin\.com/, part.body)
  end
  
  def test_deliver_account_setup_message_with_publisher_support_email_address_with_display_name
    user = users(:jorge)
    user.reset_perishable_token!
    user.publisher.update_attributes!(
      :support_email_address => "Student Discount <support@sdhaustin.com>",
      :approval_email_address => "approval@sdhaustin.com"
    )
    
    AdvertiserSignupMailer.deliver_notification(user)

    assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email"
    email = ActionMailer::Base.deliveries.first

    assert_equal ["support@sdhaustin.com"], email.from, "From: header"
    assert_equal "Student Discount", email.friendly_from, "From: header (friendly)"
    assert_equal ["jorgeb@dimilles.com"], email.to, "To: header"
    assert_equal ["approval@sdhaustin.com"], email.bcc, "Should BCC approval email"
    assert_equal "Your new account at Green Valley News", email.subject, "Subject: header"
    assert_equal "multipart/alternative", email.content_type, "Content-Type: header"

    assert_equal 1, email.parts.size, "Should have 1 part"
    
    part = email.parts.first
    assert_equal "text/plain", part.content_type, "Content-Type: of first part"
    assert_equal "quoted-printable", part.transfer_encoding, "Content-Transfer-Encoding: of first part"
    assert_no_match(%r{/password_resets/}, part.body)
    assert_match(/support@sdhaustin\.com/, part.body)
  end

end
