class UserMailer < ApplicationMailer
  helper :application
  
  default_url_options[:host] = AppConfig.admin_host || "admin.analoganalytics.com"
    
  def account_setup_instructions(user)
    account_instructions_email(user, "Account Setup")
  end

  def account_reactivation_instructions(user)
    account_instructions_email(user, "Account Reactivation")
  end

  def password_reset_instructions(user)
    account_instructions_email(user, "Password Reset")
  end

  private

  def account_instructions_email(user, subject_stub)
    ensure_instructions_are_sendable(user)

    subject "#{user.organization_name} #{subject_stub}"
    recipients user.email
    from support_sending_email_address(user.publisher_or_company)
    bcc user.publisher.approval_email_address if user.publisher.present?
    sent_on Time.now
    body :user => user, :company_name => user.organization_name, :support_email_address => support_email_address(user.publisher)
  end

  def ensure_instructions_are_sendable(user)
    if !user.email.present?
      raise NotSending, "account setup instructions for user #{user.id}: email blank"
    end
  end

end
