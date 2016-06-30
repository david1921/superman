class AdvertiserSignupMailer < ApplicationMailer
  helper :application
  
  default_url_options[:host] = AppConfig.admin_host || "admin.analoganalytics.com"
    
  def notification(user)
    unless user.advertiser && user.email.present?
      raise NotSending, "notification for user #{user.id}: not an advertiser or email blank"
    end
    subject "Your new account at #{user.publisher.name}"
    recipients user.email
    from offer_sending_email_address(user.publisher)
    bcc user.publisher.approval_email_address
    sent_on Time.now
    body :user => user, :support_email_address => support_email_address(user)
  end
  
  private
  
  def support_email_address(user)
    @@support_email_address = AppConfig.support_email_address || "support@analoganalytics.com"
    (publisher_email = user.company.publisher.try(:email_only_from_support_email_address)).present? ? publisher_email : @@support_email_address
  end
end
