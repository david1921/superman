class EmailRecipientsController < ApplicationController
  layout 'txt411/application'
  
  def opt_out
    @email_recipient = EmailRecipient.find_by_random_code(params[:random_code])
    return render(:action => :invalid_link) unless @email_recipient

    if @email_recipient.opt_out
      logger.info "Email recipient '#{@email_recipient.email_address}' opted out"
    end
  end
  
  def trigger_opt_in
    @email_recipient = EmailRecipient.find_by_random_code(params[:random_code])
    return render(:action => :invalid_link) unless @email_recipient

    @email_recipient.trigger_opt_in
  end
  
  def confirm_opt_in
    @email_recipient = EmailRecipient.find_by_random_code(params[:random_code])
    return render(:action => :invalid_link) unless @email_recipient
    
    if @email_recipient.opt_in
      logger.info "Email recipient '#{@email_recipient.email_address}' opted in"
    end
  end
end
