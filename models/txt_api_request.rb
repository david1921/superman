class TxtApiRequest < ApiRequest
  before_validation :normalize_mobile_number
  before_validation :normalize_report_group
  
  validates_format_of :mobile_number, :with => /^1\d{10}$/
  validates_length_of :message, :within => 1..110
  
  after_create :send_txt
  
  def error
    case
    when errors.on(:mobile_number)
      ApiRequest::InvalidPhoneNumberError.new
    when errors.on(:message) =~ /too long/i || errors.on(:message) =~ /too short/i
      ApiRequest::InvalidContentLengthError.new
    end
  end
  
  private
  
  def normalize_mobile_number
    self.mobile_number = mobile_number.phone_digits
  end
  
  def send_txt
    MobilePhone.send_txt_to_number(mobile_number, message, :source => self)
  end
end
