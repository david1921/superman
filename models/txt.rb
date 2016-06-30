# Outbound TXT message we send to an external gateway like CellTrust
# TODO Store and remeber the CellTrust MessageId, maybe as gateway_message_id
#
# Note: CellTrust will only send messages from "blessed" IP addresses. Add them in My Gateway: Account Module
class Txt < ActiveRecord::Base
  acts_as_message

  belongs_to :source, :polymorphic => true

  MAX_LENGTH = 160
  validates_length_of :message, :maximum => MAX_LENGTH, :allow_blank => true
  
  after_update :call_back_lead

  # We could use a Rails' Observer, but this logic feels central to Txt and Lead
  def call_back_lead
    if "sent" == status && "Lead" == source_type
      source.after_sent(self)
    end
  end

  def update_from_gateway(response)
    begin
      txt_notify_response = Hash.from_xml(response)["TxTNotifyResponse"]

      if txt_notify_response["Error"] && !txt_notify_response["Error"].empty?
        logger.info "Txt send error: response for Txt id #{id}: #{response}"
        self.status = "error"
        self.gateway_response_code = txt_notify_response["Error"]["ErrorCode"].to_i
        self.gateway_response_message = txt_notify_response["Error"]["ErrorMessage"]
      else
        self.gateway_response_id = txt_notify_response["MsgResponseList"]["MsgResponse"]["MessageId"].to_i
        self.gateway_response_message = txt_notify_response["MsgResponseList"]["MsgResponse"]["Status"]
        self.status = "sent"
      end
    rescue Exception => e
      self.status = "error"
      self.gateway_response_message = e.message
    end
  end

  def to_gateway_format
    {
      "Message" => message,
      "PhoneDestination" => mobile_number,
      "CustomerNickname" => "TOMCTA",
      "Shortcode" => "898411",
      "XMLResponse" => "true"
    }
  end
end
