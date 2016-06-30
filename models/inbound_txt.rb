# TXT message that someone sent to us, via a SMS gateway
class InboundTxt < ActiveRecord::Base
  belongs_to :txt_offer
  has_many :txts, :as => :source
  
  after_create :create_reply_txt

  # Translate from SMS gateway's POST to AR model
  #
  # accepted_time: when CellTrust says they received the message
  # received_at: when we received the message
  #
  # CellTrust doesn't actually spec the time zone, so we set it to Pacific time.
  # We need to the time zone in _before_ the string is parsed into a time, because
  # once Rails parses the time, it's treated as UTC.
  def self.create_from_gateway!(params)
    logger.info(%Q{TxtGateway create_from_gateway! InboundTxt '#{params["Message"]}' from #{params["OriginatorAddress"]}})
    InboundTxt.create!(
      :message            => params["Message"],
      :accepted_time      => DateTime.strptime("#{params['AcceptedTime']} Pacific Time (US & Canada)", "%d%b,%y %H:%M:%S %Z"),
      :received_at        => Time.now,
      :keyword            => params["Message"][/([^ ]+)/, 0],
      :subkeyword         => params["Message"][/[ ]*[^ ]+[ ]+([^ ]+)/, 1],
      :network_type       => params["NetworkType"],
      :server_address     => params["ServerAddress"],
      :originator_address => params["OriginatorAddress"],
      :carrier            => params["Carrier"]
    )
  end
  
  def message=(value)
    _value = value || ""
    _value.strip!
    write_attribute(:message, _value)
  end

  def keyword=(value)
    _value = value || ""
    _value.strip!
    write_attribute(:keyword, _value)
  end

  def subkeyword=(value)
    _value = value || ""
    _value.strip!
    write_attribute(:subkeyword, _value)
  end

  def create_reply_txt
    MobilePhone.handle_inbound_txt(self)
  end
end
