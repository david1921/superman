class GiftCertificateMailer < ApplicationMailer
  helper :application
  #
  # ActionMailer doesn't perform implicit template rendering (e.g. of latest.text.plain.erb) when attachments are present
  #
  def gift_certificate(purchased_gift_certificate)
    recipients purchased_gift_certificate.paypal_payer_email
    subject    "Your #{purchased_gift_certificate.advertiser.name} Deal Certificate"
    from       offer_sending_email_address(purchased_gift_certificate.publisher)
    sent_on    Time.now
    
    part(
      :content_type => "text/plain",
      :body => render_message("gift_certificate.text.plain", :purchased_gift_certificate => purchased_gift_certificate)
    )
    attachment(
      :content_type => 'application/pdf',
      :filename => "#{purchased_gift_certificate.advertiser.name} Deal Certificate #{purchased_gift_certificate.serial_number}.pdf",
      :body => purchased_gift_certificate.to_pdf
    )
  end

  def confirm_purchase(purchased_gift_certificate)
    recipients purchased_gift_certificate.paypal_payer_email
    subject    "Your #{purchased_gift_certificate.advertiser.name} Deal Certificate"
    from       offer_sending_email_address(purchased_gift_certificate.publisher)
    sent_on    Time.now
    
    part(
      :content_type => "text/plain",
      :body => render_message("confirm_purchase.text.plain", :purchased_gift_certificate => purchased_gift_certificate)
    )
  end
end
