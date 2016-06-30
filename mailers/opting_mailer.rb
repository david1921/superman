class OptingMailer < ApplicationMailer
  helper :application
  
  def email_opt_in_instructions(email_recipient)
    subject       "Email opt-in instructions"
    recipients    email_recipient.email_address
    from          offer_sending_email_address
    sent_on       Time.now
    body          :email_recipient => email_recipient
  end
end
