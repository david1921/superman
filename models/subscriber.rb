class Subscriber < ActiveRecord::Base
  extend Addresses::Validations
  include ::Users::SilverpopSync

  has_and_belongs_to_many :categories
  belongs_to :publisher
  belongs_to :publishing_group
  belongs_to :subscriber_referrer_code

  has_and_belongs_to_many :daily_deal_categories
  has_and_belongs_to_many :subscription_locations
  
  serialize :other_options
  
  # validates_presence_of :publisher, :unless => Proc.new {|subscriber| subscriber.publishing_group.present? }
  # validates_presence_of :publishing_group, :unless => Proc.new {|subscriber| subscriber.publisher.present? }
  validates_presence_of :email, :if => :email_required
  validates_email :email, :allow_blank => true, :allow_nil => true
  validates_format_of :mobile_number, :with => /^1\d{10}$/, :allow_blank => true, :allow_nil => true
  validate :email_or_mobile_number_present, :unless => :email_required
  validates_acceptance_of :terms, :allow_nil => false, :if => :must_accept_terms?
  validates_presence_of :zip_code, :if => :zip_code_required
  validates_zip_code_according_to_publisher
  validate :required_other_options   
  validates_presence_of :name, :if => Proc.new { |subscriber| subscriber.required_fields.include? "name" }
  validates_presence_of :age, :if => Proc.new { |subscriber| subscriber.required_fields.include? "age" }
  validates_presence_of :gender, :if => Proc.new { |subscriber| subscriber.required_fields.include? "gender" }
  validates_presence_of :zip_code, :if => Proc.new { |subscriber| subscriber.required_fields.include? "zip_code" }
  validates_presence_of :city, :if => Proc.new{ |subscriber| subscriber.required_fields.include?( "city" ) }
  
  before_validation :normalize_mobile_number  
  before_validation :create_name_from_first_and_last_name
  before_save :set_preferred_locale
  
  delegate :market_name, :to => :publisher
  
  named_scope :created_within, lambda { |interval|
    { :conditions => ["subscribers.created_at >= ?", Time.now.utc.to_date - interval], :include => :categories }
  }
  
  attr_reader :email_required, :zip_code_required, :required_fields
  attr_writer :must_accept_terms, :terms, :first_name, :last_name
  
  def attributes=(new_attributes, guard_protected_attributes=true)
    return if new_attributes.nil?
    attributes = new_attributes.dup
    attributes.stringify_keys!
    
    @required_fields = attributes.delete(:required_fields)
    attributes.keys.grep(/\Arequire_other_options_/).each { |attr| send("#{attr}=", attributes.delete(attr)) }
    super(attributes, guard_protected_attributes)
  end
  
  def self.deliver_latest(options = {})
    custom_interval = options[:custom_interval]
    publishers = options[:only].present? ? options[:only].split(",").collect(&:strip).collect{|label| Publisher.find_by_label(label)} : Publisher.all    
    except     = options[:except].present? ? options[:except].split(",").collect(&:strip) : []
    result = []
    publishers.each do |publisher|
      if publisher.subscriber_recipients.present? && interval = publisher.subscriber_report_interval
        if subscribers = publisher.subscribers.created_within(custom_interval || interval)
          if subscribers.present? && !except.include?( publisher.label )
            result << "[SUBSCRIBERS][#{publisher.name}] found #{subscribers.size} subscriber(s) and delivered to: #{publisher.subscriber_recipients}"
            PublishersMailer.deliver_latest_subscribers(publisher, subscribers) 
          end
        end
      end
    end
    result
  end  
  
  def first_name
    @first_name || split_full_name.first
  end
  
  def last_name
    unless @last_name
      full_name = split_full_name
      full_name.shift # remove the first name
      full_name.join(" ")
    else
      @last_name
    end
  end
  
  def full_name
    warn "Subscriber#full_name has been deprecated. Please use Subscriber#name instead."
    name
  end
  
  def full_name=(value)
    warn "Subscriber#full_name= has been deprecated. Please use Subscriber#name= instead."
    self.name = value
  end
  
  def email_required=(value)
    @email_required = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
  end
  
  def zip_code_required=(value)
    @zip_code_required = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
  end
  
  def method_missing(name, *args, &block)
    if name.to_s =~ /\Arequire_other_options_([[:alnum:]_]+)(=?)\z/
      @other_options_required ||= Set.new
      option, setter = $1, $2.present?
      if setter
        @other_options_required.send(ActiveRecord::ConnectionAdapters::Column.value_to_boolean(args[0]) ? :add : :delete, option)
      else
        @other_options_required.include?(option)
      end
    else
      super
    end
  end
  
  def required_fields
    @required_fields ||= []
  end

  def city
    other_options[:city] if other_options
  end
  
  def city=(city)
    self.other_options ||= {}
    other_options[:city] = city
  end
  
  def referral_code
    other_options[:referral_code] if other_options
  end
  
  def referral_code=(referral_code)
    self.other_options = (other_options || {}).merge(:referral_code => referral_code) if referral_code.present?
  end

  def hashed_id
    verifier = ActiveSupport::MessageVerifier.new(AppConfig.message_verifier_secret)
    verifier.generate(id)
  end

  def self.find_by_hashed_id(hashed_id)
    verifier = ActiveSupport::MessageVerifier.new(AppConfig.message_verifier_secret)
    subscriber_id = verifier.verify(hashed_id)
    self.find_by_id(subscriber_id)
  end

  def to_liquid
    Drop::Subscriber.new(self)
  end
  
  def market
    publisher.market_zip_codes.find_by_zip_code(zip_code).try(:market)
  end

  def set_preferred_locale
    self.preferred_locale = I18n.locale.to_s
  end

  private
  
  def split_full_name
    (name||"").split(" ")
  end
  
  def must_accept_terms?
    @must_accept_terms
  end 
  
  def email_or_mobile_number_present
    if email.blank? && mobile_number.blank?
      errors.add(:email, Analog::Themes::I18n.t(publisher, "activerecord.errors.custom.and_mobile_cant_both_be_blank"))
    end
  end

  def normalize_mobile_number
    self.mobile_number = mobile_number.phone_digits
  end
  
  def create_name_from_first_and_last_name
    unless (@first_name.blank? && @last_name.blank?) 
      self.name = "#{(@first_name||"").strip} #{(@last_name||"").strip}"
    end
  end
  
  def required_other_options
    if @other_options_required
      @other_options_required.each do |option|
        unless other_options.present? && other_options.has_key?(option) && other_options[option].present?
          errors.add_to_base Analog::Themes::I18n.t(publisher, "activerecord.errors.custom.select_or_enter_option", :option => option.to_s.with_indefinite_article)
        end
      end
    end
  end
  
  
end
