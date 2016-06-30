class ApiRequestMailer < ApplicationMailer
  helper :application
  
  def api_generated_message(email_api_request)
    subject       email_api_request.email_subject || "NO SUBJECT"
    recipients    email_api_request.destination_email_address
    from          offer_sending_email_address(email_api_request.publisher)
    content_type  "multipart/alternative"

    part :content_type => "text/plain" do |p|
      p.body = render_message(
                "message_as_plain", 
                :email_api_request => email_api_request, 
                :opt_out_random_code => EmailRecipient.random_code_for(email_api_request.destination_email_address))
      p.transfer_encoding = "base64"
    end

    part :content_type => "text/html" do |p|
      p.body = render_message(
                "message_as_html", 
                :email_api_request => email_api_request, 
                :opt_out_random_code => EmailRecipient.random_code_for(email_api_request.destination_email_address))
      p.transfer_encoding = "base64"
    end
  end
end
