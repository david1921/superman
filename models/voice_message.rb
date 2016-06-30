# Outbound voice call we send to an external gateway like Ifbyphone.com
# TODO Rename to VoiceCall
class VoiceMessage < ActiveRecord::Base
  acts_as_message

  belongs_to :lead
  belongs_to :api_request
  has_one :call_detail_record, :dependent => :destroy
  
  validates_presence_of :lead, :if => Proc.new { |voice_message| voice_message.api_request.blank? }
  validates_presence_of :voice_response_code
  validates_format_of :center_phone_number, :with => /\A\d{11}\Z/, :allow_blank => true
  
  before_validation :set_voice_response_code
  before_validation :set_center_phone_number
  
  after_save :associate_call_detail_record
  
  def set_voice_response_code
    if self.voice_response_code.blank? && lead
      self.voice_response_code = lead.advertiser.voice_response_code
    end
  end
  
  def set_center_phone_number
    if self.center_phone_number.blank? && lead
      self.center_phone_number = lead.advertiser.call_phone_number
    end
  end
  
  def associate_call_detail_record
    if !call_detail_record && call_detail_record_sid.present?
      self.call_detail_record = CallDetailRecord.find_by_sid(call_detail_record_sid)
      if call_detail_record
        save
      end
    end
  end

  def to_gateway_format
    returning({
      "app" => "CTS",
      "key" => "e319fcab70ecdd48749bc97eb2d3abc6390ca675",
      "acct" => "6313",
      "first_callerid" => center_phone_number.present? ? center_phone_number[1..-1] : "8005209405",
      "survo_id" => self.voice_response_code,
      "phone_to_call" => self.mobile_number[1..-1],
      "p_t" => self.to_param
    }) do |params|
      params.merge! "user_parameters" => "center_phone_number|#{center_phone_number[1..-1]}" if center_phone_number.present?
    end
  end

  def update_from_gateway(body)
    if body.match(/connected/i)
      self.status = "sent"
    else
      self.status = "retry"
      self.gateway_response_message = body
    end
  end
end
