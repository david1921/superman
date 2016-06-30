class CouponMailer < ApplicationMailer

  helper :application
  
  def coupon(lead)
    publisher  lead.publisher
    subject    "#{publisher.brand_name_or_name} Coupons: Your #{lead.offer.advertiser.name} coupon"
    recipients lead.email
    from       offer_sending_email_address(publisher)
    sent_on    Time.now
    body       :lead => lead, :publisher => publisher, :opt_out_random_code => EmailRecipient.random_code_for(lead.email)
  end
end
