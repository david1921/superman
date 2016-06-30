# Removed login attribute, since we always use email as the login/username
class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include ::Users::Core
  include ::Users::Lockable
  include ::Users::Loggable
  include ::Users::SilverpopSync
  include ::Users::ActiveSession

  PASSWORD_CHARACTERS = ('a'..'z').to_a + ('0'..'9').to_a

  attr_accessor :remember_me_flag
  attr_accessor :require_password
  attr_reader :email_account_setup_instructions

  attr_accessible :login, :name, :email, :password, :password_confirmation, :remember_me_flag, :gender, :birth_year
  attr_accessible :label, :session_timeout, :email_account_setup_instructions, :allow_syndication_access, :allow_offer_syndication_access, :manageable_publishers_attributes
  attr_accessible :can_manage_consumers
  attr_accessible :preferred_locale
  validates_inclusion_of :admin_privilege, :in => [FULL_ADMIN = "F", RESTRICTED_ADMIN = "R"], :allow_blank => true
  # Had to add these for consumer creation via fb connect. Can we not mass assign these w/ sti?
  attr_accessible :facebook_id, :agree_to_terms, :crypted_password, :timezone, :last_name, :link, :first_name, :publisher_id, :token, :activated_at

  has_many :user_companies
  has_one :advertiser_signup
  has_many :manageable_publishers
  has_many :user_logs

  before_validation :set_default_password, :if => :email_account_setup_instructions

  with_options :unless => :use_email_as_login? do |this|
    this.validates_presence_of :login
    this.validates_format_of :login, :with => ::Authentication.login_regex, :message => ::Authentication.bad_login_message
    this.validates_uniqueness_of :login, :case_sensitive => false, :scope => :type
  end
  with_options :if => :use_email_as_login? do |this|
    this.validates_presence_of :email
    this.validates_length_of :email, :within => 6..100, :allow_blank => true #r@a.wk
    this.validates_email :email, :allow_blank => true
  end
  validates_presence_of :email, :if => :email_account_setup_instructions

  validates_format_of :name, :with => ::Authentication.name_regex, :message => ::Authentication.bad_name_message, :allow_blank => true
  validates_length_of :name, :maximum => 100, :allow_blank => true
  validates_numericality_of :session_timeout, :only_integer => true

  validate :gender_is_valid

  before_create :reset_perishable_token
  before_save Proc.new { |record| record.login = record.email if record.use_email_as_login? }
  after_create :deliver_account_setup_instructions!, :if => :email_account_setup_instructions
  before_destroy :prevent_destroy

  EMPTY_SCOPE = { :conditions => "FALSE" }

  named_scope :with_admin_privilege, :conditions => "admin_privilege IS NOT NULL AND admin_privilege != ''"
  named_scope :with_restricted_admin_privilege, :conditions => "admin_privilege = 'R'"
  named_scope :with_off_platform_purchases, :joins => 'INNER JOIN daily_deal_purchases ddp on ddp.api_user_id = users.id'
  named_scope :with_id, lambda{|user_id|  {:conditions => {:id => user_id}} }

  delegate :self_serve?, :to => :company, :allow_nil => true

  delegate :in_syndication_network?, :to => :publisher, :allow_nil => true
  
  def self.authenticate(login, password, publisher=nil)
    user = find_by_login(login)

    return :locked if user.try(:access_locked?)

    if user
      authenticated = user.authenticated?(password)

      if authenticated
        user.successful_login!
      else
        user.failed_login!
      end

      return :locked if user.access_locked?
      return authenticated ? user : nil
    end
  end
  
  def companies
    user_companies.present? ? user_companies.map(&:company) : []
  end

  def self.authenticate_locm(token)
    text = decrypt_locm_token(token)
    _, magic, _, login, _, listing = text.sub(/\000+\z/, '').split
    logger.info "User#authenticate_locm #{Time.now.to_s(:db)} find User by login #{login} for listing #{listing}"
    user = find_by_login(login) if "Local" == magic

    advertiser = nil
    if user
      company = user.company
      if company.is_a?(PublishingGroup) || company.is_a?(Publisher)
        advertiser = company.advertisers.find_by_listing(listing) # listing is unique within publisher scope
        advertiser = Advertiser.manageable_by(user).find_by_id(advertiser.id) if advertiser # permission check
      end
    end
    [user, advertiser]
  end

  def self.demo_user_exists?
    User.exists? :login => "demo@analoganalytics.com"
  end

  def self.current
    Thread.current[:user]
  end

  def self.current=(u)
    Thread.current[:user] = u
  end

  def use_email_as_login?
    false
  end

  def demo?
    login == "demo@analoganalytics.com"
  end

  def to_s
    "#<User #{id} #{login} #{name}>"
  end

  def to_liquid
    Drop::User.new(self)
  end

  def has_admin_privilege?
    admin_privilege.present?
  end

  def has_full_admin_privileges?
    admin_privilege == FULL_ADMIN
  end
  
  def has_restricted_admin_privileges?
    admin_privilege == RESTRICTED_ADMIN
  end

  def can_manage_consumers?
    has_admin_privilege? || can_manage_consumers
  end

  def can_manage_consumer?(consumer)
    can_manage_consumers? && Consumer.with_id(consumer.id).manageable_by(self).present?
  end

  def observable_publishers_scope
    return if has_full_admin_privileges?

    if has_restricted_admin_privileges?
      { :conditions => ["publishers.id IN (?)", publisher_ids_related_to_user_companies] }      
    else
      company.observable_publishers_scope(self)
    end
  rescue
    EMPTY_SCOPE    
  end
  
  def manageable_consumers_scope
    return if has_full_admin_privileges?

    if has_restricted_admin_privileges? || can_manage_consumers?
      { :conditions => ["users.publisher_id IN (?)", publisher_ids_related_to_user_companies] }      
    else
      EMPTY_SCOPE
    end
  rescue
    EMPTY_SCOPE
  end

  def manageable_publishers_scope
    return {} if has_full_admin_privileges?

    if has_restricted_admin_privileges?
      { :conditions => ["publishers.id IN (?)", publisher_ids_related_to_user_companies] }
    else
      company.manageable_publishers_scope(self)
    end
  rescue
    EMPTY_SCOPE
  end
  
  def manageable_publishing_groups_scope
    return {} if has_full_admin_privileges?
    
    if has_restricted_admin_privileges?
      pg_ids = connection.execute(%Q{
        SELECT DISTINCT(pg.id) AS id
        FROM publishing_groups pg
          INNER JOIN user_companies uc ON uc.company_type = 'PublishingGroup' AND uc.company_id = pg.id
        WHERE uc.user_id = %d
        
        UNION
        
        SELECT DISTINCT(p.publishing_group_id) AS id
        FROM publishers p
          INNER JOIN user_companies uc ON uc.company_type = 'Publisher' AND uc.company_id = p.id
        WHERE uc.user_id = %d
      } % [id, id]).all_hashes.map { |r| r["id"].to_i }.uniq
      
      { :conditions => ["publishing_groups.id IN (?)", pg_ids] }      
    else
      EMPTY_SCOPE
    end
  rescue
    EMPTY_SCOPE
  end

  def observable_advertisers_scope
    self.company.observable_advertisers_scope(self) rescue EMPTY_SCOPE unless has_admin_privilege?
  end

  def manageable_advertisers_scope
    return {} if has_full_admin_privileges?
    
    if has_restricted_admin_privileges?
      a_ids = connection.execute(%Q{
        SELECT a.id AS id
        FROM advertisers a INNER JOIN user_companies uc ON uc.company_id = a.publisher_id
        WHERE uc.company_type = 'Publisher' AND uc.user_id = %d
        
        UNION
        
        SELECT a.id AS id
        FROM advertisers a 
          INNER JOIN publishers p ON a.publisher_id = p.id
          INNER JOIN publishing_groups pg ON p.publishing_group_id = pg.id
          INNER JOIN user_companies uc ON uc.company_id = pg.id
        WHERE uc.company_type = 'PublishingGroup' AND uc.user_id = %d
      } % [id, id]).all_hashes.map { |r| r["id"].to_i }.uniq
      
      { :conditions => ["advertisers.id IN (?)", a_ids] }
    else
      company.manageable_advertisers_scope(self)
    end
  rescue
    EMPTY_SCOPE
  end

  def publisher_ids_related_to_user_companies
    connection.execute(%Q{
      SELECT DISTINCT(p.id)
        FROM publishers p
          INNER JOIN user_companies uc ON (
            (uc.company_type = 'Publisher' AND uc.company_id = p.id) OR
            (uc.company_type = 'PublishingGroup' AND uc.company_id = p.publishing_group_id))
        WHERE uc.user_id = %d
    } % id).all_hashes.map { |r| r["id"].to_i }
  end
  
  def set_companies(options = {})
    unless has_restricted_admin_privileges?
      raise "User#set_companies can only be called on a user that has restricted admin privileges. Try User#company= for regular users."
    end

    options.assert_valid_keys(:publisher_ids, :publishing_group_ids)
    publisher_ids = options[:publisher_ids]
    publishing_group_ids = options[:publishing_group_ids]
    
    User.transaction do
      user_companies.clear
      if publisher_ids.present?
        connection.execute "INSERT INTO user_companies (company_type, company_id, user_id) VALUES %s" % publisher_ids.map { |p_id| "('Publisher', %d, %d)" % [p_id, id] }.join(", ")
      end      
      if publishing_group_ids.present?
        connection.execute "INSERT INTO user_companies (company_type, company_id, user_id) VALUES %s" % publishing_group_ids.map { |pg_id| "('PublishingGroup', %d, %d)" % [pg_id, id] }.join(", ")
      end
    end
  end

  def add_company(c)
    UserCompany.create! :user => self, :company => c
  end

  def can_observe?(advertiser_or_publisher)
    !demo? && advertiser_or_publisher && advertiser_or_publisher.class.observable_by(self).find_by_id(advertiser_or_publisher).present?
  end

  def can_manage?(advertiser_or_publisher)
    !demo? && advertiser_or_publisher && advertiser_or_publisher.class.manageable_by(self).find_by_id(advertiser_or_publisher).present?
  end

  def set_manageable_publishers_from_ids(publisher_ids)
    publisher_ids = [publisher_ids] unless publisher_ids.is_a?(Array)
    manageable_publishers.destroy_all
    publisher_ids.each do |pub_id|
      return false unless ManageablePublisher.create(:publisher_id => pub_id, :user_id => id)
    end
  end

  def manageable_publisher_ids
    manageable_publishers.map(&:publisher_id)
  end

  def has_restricted_access_to_publishing_group?
    !has_full_access_to_publishing_group?
  end

  def has_full_access_to_publishing_group?
    manageable_publishers.blank?
  end

  def self.random_password(length = 16)
    Array.new(length) { PASSWORD_CHARACTERS.sample }.join
  end

  def randomize_password!
    password = User.random_password
    update_attributes! :password => password, :password_confirmation => password
  end

  def advertiser
    company if company.is_a?(Advertiser)
  end

  def publisher
    Publisher.find_by_id(publisher_id) || (company if company.is_a?(Publisher)) || (company.publisher if company.is_a?(Advertiser))
  end

  def email_account_setup_instructions=(value)
    @email_account_setup_instructions = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
  end

  def reset_perishable_token!(length=16)
    reset_perishable_token(length)
    save_with_validation(false)
  end

  def administrator?
    has_admin_privilege? || user_companies.present?
  end

  %w{ publishing_group publisher advertiser}.each { |type| class_eval "def #{type}?; company.is_a?(#{type.camelize}); end", "app/models/user.rb", 310 }

  def affiliate?
    self.type == 'Affiliate'
  end
  
  def company
    if user_companies.size > 1
      logger.warn "User#company called on a user associated to multiple companies. Please use User#companies instead."
    end
    user_companies.try(:first).try(:company)
  end
  
  def company=(c)
    if user_companies.present?
      raise "Cannot assign a company to a user that is already assigned to one or more companies"
    end
    
    user_companies << UserCompany.new(:company => c)
  end
  
  def consumer?
    false
  end

  def consumer_for_publisher?(publisher)
    false
  end

  def consumer_for_publishing_group?(publishing_group)
    false
  end

  def gender=(g)
    if ["m", "M", "male", "MALE", "Male"].include?(g)
      g = "M"
    elsif ["f", "F", "female", "FEMALE", "Female"].include?(g)
      g = "F"
    end
    write_attribute(:gender, g)
  end

  def available_daily_deal_placements
    case company
    when Publisher
      company.affiliate_placements.select do |placement|
        DailyDeal === (daily_deal = placement.placeable) && daily_deal.active_now_or_in_future?
      end
    else
      []
    end
  end

  def force_destroy
    @allow_destroy = true
    destroy()
  end

  def status_message
    if access_locked?
      "Locked"
    else
      "Active"
    end
  end

  def deliver_account_setup_instructions!
    reset_perishable_token!
    UserMailer.deliver_account_setup_instructions(self)
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    UserMailer.deliver_password_reset_instructions(self)
  end

  def deliver_account_reactivation_instructions!
    reset_perishable_token!
    UserMailer.deliver_account_reactivation_instructions(self)
  end

  def publisher_or_company
    publisher || company
  end

  def organization_name
    publisher_or_company.try(:name) || "Analog Analytics"
  end

  private

  def self.blowfish
    @blowfish ||= Crypt::Blowfish.new(AppConfig.locm_login_token_key || "o7416P.i@8No9)wlx%'dQ")
  end

  def self.decrypt_locm_token(token)
    token = token.to_s
    returning("") do |str|
      while token.size >= 8
        str << blowfish.decrypt_block(token)
        token = token[8..-1]
      end
    end
  end

  RANDOM_CODE_ALPHABET = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a

  def self.make_token(length=16)
    Array.new(length) { RANDOM_CODE_ALPHABET[rand(RANDOM_CODE_ALPHABET.size)] }.join
  end

  def reset_perishable_token(length=16)
    self.perishable_token = self.class.make_token(length)
  end

  def password_required?
    crypted_password.blank? || password.present? || require_password
  end

  def set_default_password
    self.password_confirmation = self.password = User.random_password
  end

  def gender_is_valid
    errors.add(:gender, "%{attribute} must be one of M or F") unless [nil, "", "M", "F"].include?(gender)
  end

  def prevent_destroy
    if @allow_destroy
      true
    else
      errors.add_to_base('Cannot be deleted')
      false
    end
  end
end
