require File.dirname(__FILE__) + "/../../test_helper"

class GiftCertificateMailerTest < ActionMailer::TestCase
  def setup
    @gift_certificate = advertisers(:changos).gift_certificates.create!(:message => "buy", :price => 23.99, :value => 40.00, :number_allocated => 3)
    @purchased_gift_certificate = @gift_certificate.purchased_gift_certificates.create(
      :paypal_payment_date => "14:18:05 Jan 14, 2010 PST",
      :paypal_txn_id => "38D93468JC7166634",
      :paypal_receipt_id => "3625-4706-3930-0684",
      :paypal_invoice => "123456789",
      :paypal_payment_gross => "%.2f" % @gift_certificate.price,
      :paypal_payer_email => "higgins@london.com",
      :paypal_payer_status => "verified",
      :paypal_address_name => "Henry Higgins",
      :paypal_first_name => "Henry",
      :paypal_last_name => "Higgins",
      :paypal_address_street => "1 Penny Lane",
      :paypal_address_city =>"London",
      :paypal_address_state => "KY",
      :paypal_address_zip => "40742",
      :paypal_address_status => "confirmed",
      :payment_status => "completed",
      :payment_status_updated_at => Time.zone.now,
      :payment_status_updated_by_txn_id => "38D93468JC7166634"
    )
    ActionMailer::Base.deliveries.clear
  end
  
  def test_deliver_gift_certificate
    GiftCertificateMailer.deliver_gift_certificate @purchased_gift_certificate
    assert_equal 1, ActionMailer::Base.deliveries.size, "Emails delivered"
    email = ActionMailer::Base.deliveries.first

    assert_equal ["support@txt411.com"], email.from, "From: header"
    assert_equal "MySDH.com Coupons", email.friendly_from, "From: header (friendly)"
    assert_equal ["higgins@london.com"], email.to, "To: header"
    assert_equal "Your Changos Deal Certificate", email.subject, "Subject: header"

    assert_equal "multipart/mixed", email.content_type, "Content-Type: header"
    assert_equal 2, email.parts.size, "Email message should have 2 parts"

    part = email.parts.detect { |p| p.content_type == "text/plain" }
    assert_not_nil part, "Should have text/plain part"
    assert_match %r{#{"%.2f" % @purchased_gift_certificate.paypal_payment_gross}}, part.body, "Should contain PayPal payment gross"
    assert_match %r{#{@purchased_gift_certificate.paypal_address_name}}, part.body, "Should contain PayPal payer name"
  
    assert_equal 1, email.attachments.size, "Should have one attachment"
    attachment = email.attachments.first
    assert_equal "application/pdf", attachment.content_type
    assert_match %r{\AChangos Deal Certificate #{@purchased_gift_certificate.serial_number}.pdf\z}, attachment.original_filename
  end
  
  def test_deliver_confirm_purchase
    GiftCertificateMailer.deliver_confirm_purchase @purchased_gift_certificate
    assert_equal 1, ActionMailer::Base.deliveries.size, "Emails delivered"
    email = ActionMailer::Base.deliveries.first

    assert_equal ["support@txt411.com"], email.from, "From: header"
    assert_equal "MySDH.com Coupons", email.friendly_from, "From: header (friendly)"
    assert_equal ["higgins@london.com"], email.to, "To: header"
    assert_equal "Your Changos Deal Certificate", email.subject, "Subject: header"

    assert_equal "multipart/mixed", email.content_type, "Content-Type: header"
    assert_equal 1, email.parts.size, "Email message should have 1 part"

    part = email.parts.detect { |p| p.content_type == "text/plain" }
    assert_not_nil part, "Should have text/plain part"
    assert_match %r{#{"%.2f" % @purchased_gift_certificate.paypal_payment_gross}}, part.body, "Should contain PayPal payment gross"
    assert_match %r{#{@purchased_gift_certificate.recipient_name}}, part.body, "Should contain recipient name"
    assert_match %r{#{@purchased_gift_certificate.paypal_address_street}}, part.body, "Should contain PayPal street address"
  
    assert_equal 0, email.attachments.size, "Should have no attachments"
  end
end
