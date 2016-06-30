class DailyDealTxt
  def self.handle_inbound_txt(inbound_txt)
    if (body = response_body(inbound_txt))
      MobilePhone.send_txt_to_number inbound_txt.originator_address, body, outgoing_message_options.merge(:source => inbound_txt)
    end
  end
  
  private
  
  def self.response_body(inbound_txt)
    if (digits = inbound_txt.subkeyword.gsub(/-/, '')) =~ /\d{8}/
      validation_response_body(digits, true)
    elsif inbound_txt.subkeyword =~ /r/i && (digits = inbound_txt.message[/\s*\S+\s+\S+\s+(\S+)/, 1].gsub(/-/, '')) =~ /\d{8}/
      validation_response_body(digits, true)
    elsif inbound_txt.subkeyword =~ /v/i && (digits = inbound_txt.message[/\s*\S+\s+\S+\s+(\S+)/, 1].gsub(/-/, '')) =~ /\d{8}/
      validation_response_body(digits)
    else
      help_response_body
    end
  end

  def self.validation_response_body(digits, redeem=false)
    serial_number = digits.gsub(/(\d{4})(\d{4})/, '\1-\2')
    daily_deal_certificate = DailyDealCertificate.find_by_serial_number(serial_number)
    if daily_deal_certificate.nil?
      status = "NOT VALID"
    elsif daily_deal_certificate.redeemed?
      status = "ALREADY REDEEMED"
    else
      daily_deal_certificate.redeem! if redeem
      status  = "VALID for #{daily_deal_certificate.humanize_value}"
      status << " and now marked REDEEMED" if redeem
    end
    "Voucher #{serial_number} is #{status}"
  end
  
  def self.help_response_body
    "Send BBD R <8-digits> to redeem, BBD V <8-digits> to validate daily-deal voucher."
  end
  
  def self.outgoing_message_options
    { :send_intro_txt => false }
  end
end
