class CallApiRequest < ApiRequest
  before_validation :normalize_phone_numbers
  before_validation :normalize_report_group
  
  validates_format_of :consumer_phone_number, :with => /^1\d{10}$/
  validates_format_of :merchant_phone_number, :with => /^1\d{10}$/
  
  after_create :setup_voice_call
  
  VOICE_RESPONSE_CODE = 4957
  
  def error
    case
    when errors.on(:consumer_phone_number) || errors.on(:merchant_phone_number)
      ApiRequest::InvalidPhoneNumberError.new
    end
  end
  
  private
  
  def normalize_phone_numbers
    self.consumer_phone_number = consumer_phone_number.phone_digits
    self.merchant_phone_number = merchant_phone_number.phone_digits
  end
  
  def setup_voice_call
    VoiceMessage.create!({
      :api_request => self,
      :voice_response_code => VOICE_RESPONSE_CODE,
      :mobile_number => consumer_phone_number,
      :center_phone_number => merchant_phone_number
    })
  end
end
