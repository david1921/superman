class Lead < ActiveRecord::Base
  include HasPublisherThemeableTranslations

  attr_reader :number_as_entered, :opted_out
  serialize :query_parameters

  has_one :advertiser, :through => :offer
  belongs_to :offer
  belongs_to :publisher
  has_many :txts, :as => :source, :dependent => :destroy
  has_many :voice_messages, :dependent => :destroy

  validates_presence_of :offer
  validates_presence_of :publisher
  validates_presence_of :email, :if => Proc.new { |lead| lead.email_me }
  validates_email :email, :allow_nil => true, :allow_blank => true
  validates_presence_of :mobile_number, :if => Proc.new { |lead| lead.call_me || lead.txt_me }
  validates_format_of :mobile_number, :with => /^1\d{10}$/, :allow_blank => true, :allow_nil => true
  validate :print_me_call_me_email_me_or_txt_me_present
  validate :recipient_opted_in
  validate :can_clip_coupon

  before_validation :remember_number
  before_validation :normalize_mobile_number

  after_create :send_txt_or_call
  after_create :send_email

  def self.find_by_name(name)
    Lead.find(:first, :conditions => [%Q{CONCAT(CONCAT(first_name, ' '), last_name) = ?}, name])
  end

  def name
    [first_name, last_name].delete_if(&:blank?).join(" ")
  end

  def name=(value)
    return unless value
    words = value.split(" ")
    words.push("") while words.size < 2
    self.last_name = words.pop
    self.first_name = words.join(" ")
  end

  def first_name=(value)
    self[:first_name] = value.squeeze(" ") if value
  end

  def last_name=(value)
    self[:last_name] = value.squeeze(" ") if value
  end

  def delivery
    if txt_me?
      "txt"
    elsif call_me?
      "call"
    else
      "email"
    end
  end

  def normalize_mobile_number
    self.mobile_number = mobile_number.phone_digits
  end

  def remember_number
    @number_as_entered = mobile_number
  end

  def send_txt_or_call
    if txt_me?
      MobilePhone.send_txt_to_number(mobile_number, offer.txt_body, :head => offer.txt_head, :foot => offer.txt_foot, :source => self)
    elsif call_me?
      voice_messages.create!(
        :mobile_number => mobile_number,
        :voice_response_code => advertiser.voice_response_code,
        :send_at => Time.now
      )
    end
  end

  def send_email
    CouponMailer.deliver_coupon(self) if email_me
  end

  # Callback
  def after_sent(txt)
    voice_messages.create!(
      :mobile_number => mobile_number,
      :voice_response_code => advertiser.voice_response_code,
      :send_at => txt.sent_at + AppConfig.voice_message_delay_seconds
    ) if call_me
  end
  
  protected

  def print_me_call_me_email_me_or_txt_me_present
    if print_me.blank? && call_me.blank? && email_me.blank? && txt_me.blank?
      errors.add(:txt_me, "%{attribute}, email me, call me and print me can't all be blank")
    end
  end

  def recipient_opted_in
    if (call_me.present? || txt_me.present?) && MobilePhone.number_opted_out?(self.mobile_number)
      errors.add_to_base "Cannot call or send text to this number: opted out"
      @opted_out = true
    end
    if email_me.present? && EmailRecipient.address_opted_out?(self.email)
      errors.add_to_base "Cannot send email to this address: opted out"
      @opted_out = true
    end
  end

  def count_like_me
    return 0 if offer_id.blank? || remote_ip.blank?
    sql = "offer_id = ? AND remote_ip = ? AND created_at > ?"
    params = [ offer_id, remote_ip, 24.hours.ago ]
    if id
      sql += " AND id <> ?"
      params << id
    end
    Lead.count(:conditions => [sql, *params])
  end

  def can_clip_coupon
    return true unless %{ test development production }.include?(Rails.env)
    
    if 10 <= count_like_me
      errors.add_to_base translate_with_theme("activerecord.errors.custom.cannot_clip_coupon_again_today")
    end
    #
    # Before lead is saved, need to user offer.advertiser instead of advertiser :through => :offer
    #
    if (total_limit = offer.advertiser.coupon_limit) && 0 < total_limit
      if total_limit <= count_like_me
        errors.add_to_base(
          translate_with_theme("activerecord.errors.custom.coupon_may_only_be_clipped_n_times",
                 :n_times => 1 == total_limit ? 'once' : total_limit.to_s + ' times'))
      end
    end
  end
end
