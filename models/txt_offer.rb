class TxtOffer < ActiveRecord::Base
  attr_accessor :keyword_prefix
  attr_accessor :keyword_suffix
  attr_reader :assign_keyword
  
  belongs_to :advertiser
  has_one :publisher, :through => :advertiser
  has_many :inbound_txts
  has_many :txts, :through => :inbound_txts
  
  before_validation :set_short_code_if_blank
  before_validation :assemble_keyword
  before_validation :normalize_short_code_and_keyword

  validates_numericality_of :short_code, :only_integer => true
  validates_length_of :short_code, :within => 4..6, :allow_blank => false
  validates_length_of :keyword, :within => 1..20, :allow_blank => false
  validates_each :keyword do |record, attr, value|
    sql, params = "#{attr} = ? AND short_code = ? AND NOT deleted", [value, record.short_code]
    unless record.new_record?
      sql << " AND id <> ?"; params << record.id
    end
    record.errors.add(attr, "%{attribute} has already been taken for this short code") if TxtOffer.exists?([sql, *params])
  end
  validates_presence_of :message
  validates_uniqueness_of :label, :scope => :advertiser_id, :allow_blank => true
  validates_immutability_of :advertiser_id, :short_code, :keyword
  validates_each :message do |record, attr, value|
    max_message_size = record.max_message_size
    record.errors.add attr, "%{attribute} is too long (maximum is #{max_message_size} characters)" unless value.to_s.mb_chars.size <= max_message_size
  end
  validates_each :keyword do |record, attr, value|
    if record.advertiser
      if message = record.advertiser.keyword_error(value)
        record.errors.add attr, message
      end
    else
      record.errors.add attr, "%{attribute} cannot be validated without an advertiser"
    end
  end
  validate :active_limit_enforced
  
  named_scope :not_deleted, { :conditions => { :deleted => false }}

  def self.handle_inbound_txt(inbound_txt)
    short_code, keyword = normalized(inbound_txt.server_address), normalized(inbound_txt.keyword)
    if txt_offer = instance_for(short_code, keyword)
      txt_offer.respond_to(inbound_txt) if txt_offer.applies_to(inbound_txt)
    end
  end

  def self.clear_cache
    @cache = nil
  end if "test" == Rails.env

  def applies_to(inbound_txt)
    (appears_at.blank? || appears_at <= inbound_txt.accepted_time) && (expires_at.blank? || inbound_txt.accepted_time <= expires_at)
  end

  def respond_to(inbound_txt)
    inbound_txt.update_attributes! :txt_offer => self
    MobilePhone.send_txt_to_number inbound_txt.originator_address, body, outgoing_message_options.merge(:source => inbound_txt)
  end

  def max_message_size
    MobilePhone.max_body_length(outgoing_message_options)
  end
  
  def full_message
    MobilePhone.message(body, outgoing_message_options)
  end
  
  def inbound_txts_count(dates)
    inbound_txts.count(:conditions => { :accepted_time => Time.zone.parse(dates.begin.to_s) .. Time.zone.parse(dates.end.to_s).end_of_day })
  end
  
  def txts_count(dates)
    txts.count(:conditions => { 'inbound_txts.accepted_time' => dates.begin.beginning_of_day .. dates.end.end_of_day, :status => "sent" })
  end
  
  def assign_keyword=(value)
    @assign_keyword = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
  end

  def active_on?(date)
    (appears_on.nil? || date >= appears_on) && (expires_on.nil? || date <= expires_on)
  end
        
  def delete!
    self.deleted = true
    save_with_validation(false)
  end
  
  private
  
  def self.normalized(value)
    value.to_s.gsub(/\s+/, '').upcase
  end
  
  def self.cache
    if @cache.nil? || @cached_at + 60 < Time.now
      @cache = {}
      @cached_at = Time.now
    end
    @cache
  end
  
  def self.instance_for(short_code, keyword)    
    if (instance = cache[[short_code, keyword]]).nil?
      instance = not_deleted.find_by_short_code_and_keyword(short_code, keyword)
      cache[[short_code, keyword]] = (instance ? instance : false)
    end
    instance
  end
  
  def outgoing_message_options
    { :head => head, :foot => foot, :send_intro_txt => send_intro_txt }
  end

  def head
    advertiser.try(:publisher).try(:brand_txt_header)
  end
  
  def body
    message
  end
  
  def foot
    "Exp#{expires_on.strftime('%m/%d/%y')}" if expires_on
  end
  
  def send_intro_txt
    advertiser.try(:send_intro_txt)
  end
  
  def assemble_keyword
    if keyword.blank? && keyword_prefix.present?
      self.keyword_suffix = advertiser.try(:next_keyword_suffix, keyword_prefix) if keyword_suffix.blank? && assign_keyword
      self.keyword = keyword_prefix + keyword_suffix.to_s
    end
  end
  
  def normalize_short_code_and_keyword
    self.short_code, self.keyword = [short_code, keyword].map { |value| self.class.normalized(value) }
  end
  
  def appears_at
    #
    # Cached value may be out of date, but this instance shouldn't live long anyway
    #
    @appears_at ||= beginning_of_day_in_zone(appears_on, time_zone)
  end
  
  def expires_at
    #
    # Cached value may be out of date, but this instance shouldn't live long anyway
    #
    @expires_at = end_of_day_in_zone(expires_on, time_zone)
  end
  
  def time_zone
    #
    # Placeholder for advertiser's (store's) time zone
    #
    "UTC"
  end
  
  def beginning_of_day_in_zone(date, zone)
    ActiveSupport::TimeZone.new(zone).parse(date.to_s) if date
  end

  def end_of_day_in_zone(date, zone)
    ActiveSupport::TimeZone.new(zone).parse(date.to_s).end_of_day if date
  end

  def message_length
    if message.to_s.length > (max_length = MobilePhone.max_body_length(head, foot))
      errors.add :message, '%{attribute} is too long (maximum is %d characters)' % max_length
    end
  end

  def active_count_less_than(txt_offers, limit)
    #
    # 1: Total txt_offer count is less than N
    #
    return true if txt_offers.size < limit
    #
    # 2: N or more txt_offers unbounded in the future
    #
    return false if txt_offers.select { |txt_offer| txt_offer.expires_on.nil? }.size >= limit
    #
    # 3: N or more txt_offers unbounded in the past and ending today or later
    #
    today = Time.zone.now.to_date
    return false if txt_offers.select do |txt_offer|
      txt_offer.appears_on.nil? && (txt_offer.expires_on.nil? || txt_offer.expires_on >= today)
    end.size >= limit
    
    min_date, max_date = [[:appears_on, :min], [:expires_on, :max]].map { |attr, func| txt_offers.map(&attr).compact.send(func) }
    #
    # 4: Latest end date is before today: check 2 covers false-return case
    #
    return true if max_date < today # !max_date.nil? after checks 1 and 2
    
    min_date = today unless min_date && min_date >= today
    min_date, max_date = max_date, min_date if min_date > max_date
    (min_date..max_date).all? { |date| txt_offers.sum { |txt_offer| txt_offer.active_on?(date) ? 1 : 0 } < limit }
  end
  
  def active_limit_enforced
    if (limit = advertiser.try(:effective_active_txt_coupon_limit)).present?
      txt_offers = Set.new(advertiser.txt_offers.not_deleted.reject { |txt_offer| txt_offer.id == id }).add(self)
      unless active_count_less_than(txt_offers, limit.succ)
        many = case limit; when 0: "any active TXT coupons"; when 1: "more than 1 active TXT coupon"; else "more than #{limit} active TXT coupons"; end
        errors.add_to_base "Can't have #{many}"
      end
    end
  end
  
  def set_short_code_if_blank
    self.short_code ||= (AppConfig.txt_short_code || "898411") 
  end
end
