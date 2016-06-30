class EmailApiRequest < ApiRequest
  before_validation :normalize_report_group
  
  validates_presence_of :email_subject
  validates_email :destination_email_address
  validates_length_of :text_plain_content, :within => 1..8192
  
  after_create :send_email
  
  def error
    case
    when errors.on(:email_subject)
      ApiRequest::MissingEmailSubjectError.new
    when errors.on(:destination_email_address)
      ApiRequest::InvalidEmailAddressError.new
    when errors.on(:text_plain_content) =~ /too long/i || errors.on(:text_plain_content) =~ /too short/i
      ApiRequest::InvalidContentLengthError.new
    end
  end
  
  private
  
  def send_email
    ApiRequestMailer.deliver_api_generated_message(self)
  end
end
