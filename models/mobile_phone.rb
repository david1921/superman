# Current code assume that MobilePhone are only created to opt out, and no one ever opts in
class MobilePhone < ActiveRecord::Base
  attr_reader :number_as_entered

  before_validation :remember_and_normalize_number

  validates_uniqueness_of :number
  validates_format_of :number, :with => /^1\d{10}$/

  def self.from_params(attrs)
    returning find_or_initialize_by_number(attrs[:number].phone_digits) do |mobile_phone|
      mobile_phone.update_attributes(attrs.except(:number))
    end
  end
  
  def self.number_opted_out?(number)
    mobile_phone = find_by_number(number.phone_digits)
    mobile_phone && mobile_phone.opt_out
  end
  
  def self.send_txt_to_number(number, body, options={})
    mobile_phone = find_or_create_by_number(:number => number.phone_digits, :opt_out => false)
    mobile_phone.valid? && mobile_phone.send_txt(message(body, options), options)
  end

  def self.handle_inbound_txt(inbound_txt)
    originating_number = inbound_txt.originator_address

    case inbound_txt.keyword
    when /^stop$/i, /^quit$/i:
      from_params :number => originating_number, :opt_out => true
      reply = stop_message
    when /^start$/i:
      from_params :number => originating_number, :opt_out => false
      reply = start_message
    when /^help$/i:
      from_params :number => originating_number
      reply = help_message
    when /^bbd$/i:
      DailyDealTxt.handle_inbound_txt(inbound_txt)  
    end
    if defined?(reply) && reply.present?
      Txt.create!(:mobile_number => originating_number, :message => reply, :source => inbound_txt)
    else
      TxtOffer.handle_inbound_txt(inbound_txt)
    end
  end

  def self.max_body_length(options={})
    message_head = normalized_message_head(options)
    message_foot = normalized_message_foot(options)
    Txt::MAX_LENGTH - message_head.mb_chars.size - message_foot.mb_chars.size
  end

  def self.message(body, options)
    message_head = normalized_message_head(options)
    message_body = normalized_message_body(body)
    message_foot = normalized_message_foot(options)
    
    if message_body.mb_chars.size > (max_message_body_size = Txt::MAX_LENGTH - message_head.mb_chars.size - message_foot.mb_chars.size)
      message_body = message_body.mb_chars[0...max_message_body_size-2] + ".."
    end
    
    message_head + message_body + message_foot
  end
  
  def self.stop_message(options={})
    normalized_message_head(options) + "You won't receive messages from TXT411 any more. For help txt HELP to 898411, email support@txt411.com or call 877-898-4114"
  end
  
  def self.start_message(options={})
    normalized_message_head(options) + "Messaging service reactivated. For help send HELP to 898411, email support@txt411.com or call 877-898-4114"
  end
  
  def self.help_message(options={})
    normalized_message_head(options) + "Coupons to your mobile. For help email support@txt411.com or call 877-898-4114. To stop text STOP to 898411. Std msg chrgs apply. T&Cs at txt411.com"
  end
  
  def send_txt(message, options={})
    if options[:send_intro_txt] && !intro_txt_sent
      intro_message = self.class.help_message(options)
      create_txt(intro_message, options) && update_attributes(:intro_txt_sent => true)
    end
    create_txt(message, options)
  end
  
  protected

  def self.normalized_message_head(options={})
    head = options[:head]
    head = "TXT411" if head.blank?
    head.strip.sub(/\:+\z/, '') + ": "
  end
  
  def self.normalized_message_body(body, options={})
    body.to_s.split(' ').join(' ').sub(/\.+\z/, '')
  end
  
  def self.normalized_message_foot(options={})
    message_foot = options[:foot].to_s.split(' ').join(' ').sub(/\A\.+/, '').sub(/\.+\z/, '')
    message_foot = message_foot.blank? ? "" : ". " + message_foot
    message_foot + ". " + common_message_foot(options)
  end
  
  def self.common_message_foot(options={})
    options[:send_intro_txt] ? "Std msg chrgs apply" : "Std msg chrgs apply. T&Cs at txt411.com"
  end
  
  def remember_and_normalize_number
    @number_as_entered = self.number
    self.number = number.phone_digits
  end

  def create_txt(message, options={})
    !opt_out && Txt.create!({ :mobile_number => number, :message => message }.merge(options.except(:head, :foot, :send_intro_txt)))
  end
end
