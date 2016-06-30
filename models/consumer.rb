
# A Consumer instance represents an account on the daily-deal site, in any of these states:
#
#   A. Having signed up for an account but not yet validated the email address;
#   B. Having signed up for an account and validated the email address;
#   C. Having created an account while purchasing a daily deal but before completing the purchase
#   D. Having completed a purchase while in states A or C
#
# In states A and C, the consumer instance is not active and cannot be used to sign in
# with the account credentials, so cannot access the account details and purchased deals.
#
#
# Refer A Friend
#
#   A. referrer_code is set upon consumer creation, and is used to track refer a friend referrals
#   B. referral_code is the referrer_code of the consumer who referred them to the daily deal site
class Consumer < User
  include FacebookAuth
  include ActsAsShareable
  extend Addresses::Validations
  extend Consumers::Core
  extend Consumers::Authentication
  include Consumers::AfterCreate
  include Consumers::AfterUpdate
  include Consumers::Assimilation
  include HasPublisherThemeableTranslations
  include Consumers::ReferralUrls
  include EnqueueAfterCommit

  belongs_to :publisher
  has_many :daily_deal_purchases do
    def redeemable_certificates
      ddp_ids = find(:all, :select => :id)
      DailyDealCertificate.all(
        :conditions => [
          %Q{
            daily_deal_certificates.status = ? AND
            marked_used_by_user != 1 AND
            (daily_deals.expires_on IS NULL OR daily_deals.expires_on >= ?) AND
            daily_deal_purchase_id IN (?)},
          DailyDealCertificate::ACTIVE, Time.zone.now, ddp_ids],
        :joins => { :daily_deal_purchase => { :daily_deal => :publisher } },
        :order => "id ASC").reject { |ddc| ddc.daily_deal_purchase.travelsavers? }
    end

    def refunded_certificates
      ddp_ids = find(:all, :select => :id)
      DailyDealCertificate.all(
        :conditions => [
          "daily_deal_certificates.status = ? AND marked_used_by_user != 1 AND (daily_deals.expires_on IS NULL OR daily_deals.expires_on >= ?) AND daily_deal_purchase_id IN (?)",
          DailyDealCertificate::REFUNDED, Time.zone.now, ddp_ids],
         :joins => { :daily_deal_purchase => :daily_deal },
         :order => "id ASC")
    end
  end
  has_many :non_voucher_daily_deal_purchases, :class_name => "NonVoucherDailyDealPurchase"
  has_many :daily_deal_certificates, :through => :daily_deal_purchases
  has_many :travelsavers_bookings, :through => :daily_deal_purchases

  has_many :off_platform_daily_deal_certificates
  has_many :sweepstake_entries
  belongs_to :signup_discount, :class_name => "Discount"

  has_many :discounts, :through => :daily_deal_purchases, :conditions => { "daily_deal_purchases.payment_status" => %w{ authorized captured }}
  has_many :credits, :after_add => :add_credit_object, :before_remove => :del_credit_object
  has_many :click_counts, :as => :clickable, :dependent => :destroy
  has_many :daily_deal_orders
  has_many :credit_cards

  has_and_belongs_to_many :daily_deal_categories
  belongs_to :publisher_membership_code

  has_many :consumer_referral_urls

  has_many :recipients, :as => :addressable

  has_many :consumer_deal_relevancy_scores
  has_many :daily_deals, :through => :consumer_deal_relevancy_scores

  attr_writer :publisher_membership_code_as_text
  attr_accessor :discount_code
  attr_accessor :zip_code_required, :first_name_required, :last_name_required
  attr_accessor :member_authorization, :member_authorization_required

  attr_accessible :name, :first_name, :last_name, :birth_year, :gender
  attr_accessible :address_line_1, :address_line_2, :billing_city, :state, :zip_code, :country_code, :mobile_number
  attr_accessible :agree_to_terms, :discount_code, :referral_code
  attr_accessible :zip_code_required, :first_name_required, :last_name_required
  attr_accessible :member_authorization, :member_authorization_required
  attr_accessible :daily_deal_category_ids
  attr_accessible :device, :user_agent
  attr_accessible :publisher_membership_code_as_text

  attr_readonly :purchase_auth_token
  default_value_for(:purchase_auth_token) { self.make_token }

  before_validation :assign_publisher_membership_code_and_switch_publisher_as_needed
  before_validation :assign_signup_discount_from_code
  before_validation_on_create :assign_special_deal_discount
  
  validates_presence_of :publisher
  validates_presence_of :address_line_1, :billing_city, :state, :zip_code, :country_code, :if => Proc.new { |c| c.publisher.require_billing_address? }
  validates_presence_of :name, :unless => Proc.new { |c| c.first_name_required? && c.last_name_required? }
  validates_presence_of :first_name, :if => :first_name_required?
  validates_presence_of :last_name, :if => :last_name_required?
  validates_zip_code_according_to_country_code
  validates_presence_of :zip_code, :if => :zip_code_required?
  validates_numericality_of :credit_available, :greater_than_or_equal_to => 0.0
  validate :terms_agreed
  validate :member_authorization_agreed
  validate :not_administrator
  validate :signup_discount_assignment_from_code
  validate :signup_discount_belongs_to_publisher
  validate :country_code_in_publisher_country_codes
  validate :publisher_membership_code_belongs_to_publisher
  validates_presence_of :publisher_membership_code, :if => :require_publisher_membership_code?
  validates_uniqueness_of :purchase_auth_token, :allow_nil => true

  validates_uniqueness_of :email, :case_sensitive => false, :scope => :publisher_id, :unless => :unique_email_across_publishing_group?
  validate :unique_email_across_publishing_group, :if => :unique_email_across_publishing_group?
  validate :preferred_locale_supported

  before_save :init_referrer_code
  before_create :set_preferred_locale
  before_create :reset_activation_code
  after_create :execute_after_create_strategy
  after_update :execute_after_update_strategy
  before_update :clear_force_reset_if_password_changed

  named_scope :active, { :conditions => "activated_at IS NOT NULL" }
  named_scope :manageable_by, lambda { |user| user.manageable_consumers_scope }

  delegate :city, :daily_deal_referral_credit_amount, :daily_deal_referral_message_head, :daily_deal_referral_message_body, :to => :publisher
  delegate :publishing_group, :unique_email_across_publishing_group?, :to => :publisher
  delegate :unique_email_across_publishing_group?, :to => :publisher
  delegate :publishing_group, :to => :publisher

  #
  # Don't assign User attributes only applicable to administrators
  #
  %w{ company company_type company_id admin_privilege }.each { |attr| class_eval "def #{attr}=(value); end" }

  #
  # zip_code_required?, first_name_required?, last_name_required?, member_authorization_required?
  #
  %w{ first_name last_name zip_code member_authorization }.each do |attr|
    define_method "#{attr}_required?" do
      instance_variable_get("@#{attr}_required")
    end
  end

  def self.build_unactivated(publisher, attributes = {})
    consumer = publisher.consumers.build(attributes)

    consumer.name = consumer.email.split("@").first

    password = random_password
    consumer.password = password
    consumer.password_confirmation = password

    consumer.agree_to_terms = true

    if publisher.discounts.present?
      consumer.signup_discount = publisher.discounts.usable.first
    end
    consumer
  end

  def my_daily_deal_purchases
    (daily_deal_purchases.executed.all + off_platform_daily_deal_certificates).sort_by(&:executed_at).reverse
  end

  def credit_available=(value)
    raise "Available credit cannot be assigned"
  end

  # Allows people to refer-a-friend. Also used by Entertainment.com for a completely different purpose.
  # They pass it as a parameter to the landing page (I think) as a way to identify their affilliate,
  # and we store it in the consumer record at signup and report it back to them. It's otherwise opaque to us.
  #
  # referral_code tracks who refer-a-friend'ed you
  def referral_code=(value)
    write_attribute :referral_code, value.to_s.strip.if_present
  end

  def name
    [first_name, last_name].select(&:present?).join(" ")
  end

  def name=(value)
    words = value.to_s.split(" ")
    words.push("") while words.size < 2
    self.first_name, self.last_name = words[0..-2].join(" "), words[-1]
    write_attribute(:name, name)
  end

  def first_name=(value)
    write_attribute(:first_name, value.to_s.squeeze(" "))
  end

  def last_name=(value)
    write_attribute(:last_name, value.to_s.squeeze(" "))
  end

  def use_email_as_login?
    true
  end

  def consumer?
    true
  end

  def consumer_for_publisher?(publisher)
    publisher.id == publisher_id
  end

  def consumer_for_publishing_group?(publishing_group)
    raise unless publishing_group.is_a?(PublishingGroup)
    publishing_group.id == self.publisher.try(:publishing_group).try(:id)
  end

  def billing_address_present?
    address_line_1.present? && billing_city.present? && state.present? && zip_code.present? && country_code.present?
  end

  def update_billing_address(params)
    new_billing_address = {}
    [ :address_line_1, :address_line_2, :billing_city, :state, :zip_code, :country_code ].each do | k |
      new_billing_address[k] = params[k] if params.include?(k)
    end
    update_attributes(new_billing_address)
  end

  def activate!
    activate
    save!
  end

  def recently_activated?
    @activated
  end

  def active?
    activated_at.present?
  end

  def deliver_activation_request
    ConsumerMailer.deliver_activation_request self
  end

  def send_activation_email!
    reset_activation_code!
    deliver_activation_request
  end

  def send_welcome_email!
    ConsumerMailer.deliver_welcome_message self
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    ConsumerMailer.deliver_password_reset_instructions self
  end

  def deliver_api_password_reset_instructions!
    reset_perishable_token!(8)
    ConsumerMailer.deliver_api_password_reset_instructions self
  end

  def daily_deal_purchase_executed!(daily_deal_purchase)
    adjust_credit_available!(-daily_deal_purchase.credit_used)
    #
    # Completing a purchase is an account-activation alternative to responding to the activation-request email.
    #
    activate!
  end

  def daily_deal_purchase_captured!(daily_deal_purchase)
    if referral_code.present? && give_referral_credit? && (referrer = Consumer.find_by_referrer_code(referral_code))
      referrer.create_referral_credit! self, daily_deal_purchase
    end
  end

  def add_credit!
    if signup_discount.nil?
      if publisher.discounts.present?
        self.signup_discount = publisher.discounts.first
        save!
      else
        errors.add("The consumer's publisher: #{publisher.name} does not have any discounts")
      end
    else
      errors.add_to_base(translate_with_theme('activerecord.errors.custom.theres_already_credit'))
    end
  end

  def signup_discount_if_usable
    signup_discount if signup_discount.try(:usable?) && !discounts.exists?(signup_discount)
  end

  def self.find_or_create_by_fb(fb, access_token, publisher, referral_code=nil)
    token = access_token.token
    atts  = {
      :token => token,
      :publisher_id => publisher.id,
      :crypted_password => make_token,
      :activated_at => Time.now,
      :agree_to_terms => 1,
      :referral_code => referral_code
    }
    existing = first(:conditions => { :email => fb["email"],
      :publisher_id => publisher, :token => nil, :facebook_id => nil }
    )
    existing_fb = first(:conditions => { :facebook_id => fb["facebook_id"],
      :publisher_id => publisher }
    )

    if existing
      existing.update_attributes(fb.slice('facebook_id','token','timezone')) && existing
    else
      returning(existing_fb || create(fb.slice(*column_names).merge(atts))) do |consumer|
        consumer.update_attributes(:token => token)
      end
    end
  end

  def post(message)
    oauth_facebook_client.post('/me/feed', :message => message)
  end

  def graph(connection)
    begin
      resp_obj = oauth_facebook_client.get("/me/#{connection}")
      JSON.parse(resp_obj.response.body)
    rescue OAuth2::ErrorWithResponse => resp_err
      logger.error "Error: #{resp_err}. fbgraph connection: #{connection}, facebook_id: #{facebook_id}"
    end
  end

  def post_purchase_to_fb_wall
    city, publish_name = "", publisher.name
    deal = daily_deal_purchases.last.daily_deal

    if publisher.publishing_group.label == 'villagevoicemedia'
      city = "- #{publisher.try(:city)}"
      publish_name = "VOICE Deal of the Day"
    elsif publisher.label == 'newsday'
      city = "- #{publisher.try(:city)}"
      publish_name = "newsday.com daily deal"
    end
    post("#{name} has just purchased #{deal.value_proposition.strip} from #{publish_name} #{city} #{deal.bit_ly_url}")
  end

  def oauth_facebook_client
    OAuth2::AccessToken.new(FacebookAuth.oauth2_client(publisher), token)
  end

  def facebook_user?
    facebook_id? && token?
  end

  def record_click(mode)
    ClickCount.record self, publisher_id, mode
  end

  # Overwrites ActsAsShareable#twitter_status
  def twitter_status(publisher = nil)
    "#{daily_deal_referral_message_body} #{referral_url(publisher)}"
  end

  def facebook_title
    daily_deal_referral_message_head
  end

  def self.update_from_subscribers!(publisher, subscribers)
    #
    # Subscribers should be in increasing order of creation, so updates from later instances overwrite the earlier.
    #
    subscribers.group_by(&:email).each_pair do |email, subscribers|
      unless (consumer = find_or_initialize_by_publisher_id_and_email(publisher.id, email)).active?
        subscribers.each do |subscriber|
          %w{ name first_name last_name birth_year gender mobile_number zip_code }.each do |attr|
            if (value = subscriber.send(attr)).present?
              consumer.send "#{attr}=", value
            end
          end
        end
        #
        # Attributes required for validation
        #
        consumer.agree_to_terms = true unless consumer.agree_to_terms
        consumer.name = "New Member" unless consumer.name.present?
        consumer.password = consumer.password_confirmation = "Sen88tw450TE57rv" unless consumer.crypted_password.present?
      end
      #
      # Clear remote_record_updated_at even if the consumer record hasn't changed. This
      # forces an upload of consumer (no-op in this case) _and_resubscribes_ to Triton.
      #
      consumer.remote_record_updated_at = nil
      consumer.save
    end
  end

  def referred?
    referral_code.present? && Consumer.find_by_referrer_code(referral_code).present?
  end

  def referring_consumer
    Consumer.find_by_referrer_code(referral_code) if referral_code.present?
  end

  def spent_credit
    daily_deal_purchases.captured(nil).sum(:credit_used)
  end

  def signup_discount_code
    signup_discount.code if signup_discount
  end

  def market
    publisher.market_zip_codes.find_by_zip_code(zip_code).try(:market)
  end

  def pending_order
    if (pending_orders = daily_deal_orders.with_payment_status(:pending)).count > 0
      pending_orders.last
    else
      daily_deal_orders.create
    end
  end

  def notify_third_parties_of_consumer_creation
    if publisher.notify_third_parties_of_consumer_creation?
      Resque.enqueue(NotifyPublisherOfConsumerCreation, self.id)
    end
  end

  # before_validation that associates a text representation of the
  # publisher_membership_code with the actual publisher_membership_code.
  # Also switches the consumer's publisher if the new membership code
  # is for a different publisher the consumer's current publisher.
  def assign_publisher_membership_code_and_switch_publisher_as_needed
    return if publisher.nil?
    return if @publisher_membership_code_as_text.blank?
    return if publisher_membership_code.try(:code) == @publisher_membership_code_as_text
    new_code = publisher.publisher_membership_codes.find_by_code(@publisher_membership_code_as_text)
    if publisher.publishing_group.present?
      new_code ||= publisher.publishing_group.publisher_membership_codes.find_by_code(@publisher_membership_code_as_text)
    end
    if new_code.present?
      self.publisher_membership_code = new_code
      if publisher != new_code.publisher
        self.publisher = new_code.publisher
      end
    end
  end

  def publisher_membership_code_as_text
    @publisher_membership_code_as_text.present? ? @publisher_membership_code_as_text : publisher_membership_code.try(:code)
  end
  
  def id_for_vault
    "#{id}-consumer"
  end
  
  def check_vault_id!(braintree_customer_id)
    braintree_customer_id = braintree_customer_id.strip
    raise SecurityError, "Vault ID '#{braintree_customer_id}' received, expected '#{id_for_vault}'" unless braintree_customer_id == id_for_vault
    self.in_vault = true
    save
  end
  
  def create_or_update_credit_card(card_details, billing_details = nil)
    #card_details = transaction.credit_card_details
    #billing_details = transaction.billing_details
    options = {
        :token => card_details.token,
        :card_type => card_details.card_type,
        :bin => card_details.bin,
        :last_4 => card_details.last_4,
        :expiration_date => card_details.expiration_date
    }
    options.merge!(
        :billing_first_name => billing_details.first_name,
        :billing_last_name => billing_details.last_name,
        :billing_country_code => billing_details.country_code_alpha2,
        :billing_address_line_1 => billing_details.street_address,
        :billing_address_line_2 => billing_details.extended_address,
        :billing_city => billing_details.locality,
        :billing_state => billing_details.region,
        :billing_postal_code => billing_details.postal_code
    ) if billing_details
    if (credit_card = CreditCard.find_by_consumer_id_and_bin_and_last_4(id, card_details.bin, card_details.last_4))
      credit_card.update_attributes options
    else
      credit_card = credit_cards.create(options)
    end
    credit_card
  end

  def store_recipient(purchase)
    fields = [:address_line_1, :address_line_2, :city, :country_id, 
              :latitude, :longitude, :name, :phone_number, :region, :state, :zip]
    purchase.recipients.each do |recipient|
      attributes = {}
      fields.each do |field|
        attributes[field] = recipient[field] 
      end
      recipients.create!(attributes)
    end
  end

  # Public: Saves the object adding an error and returning false if there appears
  #         to be a duplicate entry constraint violation.  Re-raises any exception
  #         that does not appear to be a duplicate entry constraint violation.
  #
  # Generally, this method works around flaws in validates_uniqueness_of.
  # If a user accidentally double-clicks submit, there appear to be cases
  # in which the request will simultaneously get to two servers at once.
  # If that happens, the validates_uniqueness constraint on login and/or email
  # may pass for both requests. If that happens, a database constraint will
  # prevent the save and the exception will bubble up. The user will see the
  # the maintenance page.
  # See exceptional: https://www.exceptional.io/exceptions/10114140
  #
  # Returns value of #save or false if there is a constraint violation.
  def save_detecting_duplicate_entry_constraint_violation
    begin
      save
    rescue ActiveRecord::StatementInvalid => e
      # Would that rails gave us the nested exception to check...
      if e.message =~ /.*[Dd]uplicate/
        errors.add_to_base(translate_with_theme('duplicate_entry_please_try_again'))
        false
      else
        raise e
      end
    end
  end

  def reset_credit_available
    new_credit_available = credits.sum(:amount) - daily_deal_purchases.captured(nil).sum(:credit_used)

    # If the credit available is negative it means that the credits are out of balance.
    # We should add 'artificial credit' to balance per the used credit and reset the credit available to zero.
    if new_credit_available < 0
      credits.create! :amount => -new_credit_available, :memo => "Adjustment on #{DateTime.now}" # Here is also adding the credit to the credit available
      reset_credit_available_to_zero
    else
      adjust_credit_available!(new_credit_available-credit_available)
    end

    self.credit_available_reset_at = Time.zone.now
  end

  def has_master_membership_code?
    require_publisher_membership_code? && publisher_membership_code.try(:master?)
  end

  protected

  def reset_credit_available_to_zero
    adjust_credit_available!(-credit_available)
  end

  def create_referral_credit!(referred, daily_deal_purchase)
    #
    # Don't give referral credit if the purchase price was zero, to avoid abuse.
    #
    unless self.id == referred.id || 0 == daily_deal_purchase.total_price_with_discount
      credits.create! :amount => daily_deal_referral_credit_amount, :origin => daily_deal_purchase
    end
  end

  def require_publisher_membership_code?
    publisher.require_membership_codes?
  end

  private

  def not_administrator
    errors.add_to_base(translate_with_theme('activerecord.errors.custom.cannot_be_an_administrator')) if administrator?
  end

  def terms_agreed
    unless agree_to_terms
      errors.add_to_base(translate_with_theme('activerecord.errors.custom.must_agree_to_terms'))
    end
  end

  def member_authorization_agreed
    if member_authorization != "1" && member_authorization_required?
      errors.add_to_base(translate_with_theme('activerecord.errors.custom.must_agree_to_member_authorization'))
    end
  end

  def reset_activation_code
    self.activation_code = self.class.make_token(8)
  end

  def reset_activation_code!
    reset_activation_code
    save_with_validation false
  end

  def activate
    unless active?
      @activated = true
      self.activated_at = Time.now
    end
  end

  def deactivate
    if active?
      @activated = false
      self.activated_at = nil
      reset_activation_code
    end
  end

  def assign_signup_discount_from_code
    if publisher.present? && @discount_code.present?
      self.signup_discount = publisher.discounts.usable.find_by_code(@discount_code)
    end
  end

  def assign_special_deal_discount
    self.signup_discount ||= publisher.signup_discount if publisher && publisher.show_special_deal?
  end

  def signup_discount_assignment_from_code
    if @discount_code.present? && signup_discount.blank?
      errors.add :discount_code, translate_with_theme("activerecord.errors.custom.discount_code_is_not_valid", :discount_code => @discount_code)
    end
  end

  def signup_discount_belongs_to_publisher
    if signup_discount.present? && publisher.try(:id) != signup_discount.publisher_id
      errors.add :discount_code, translate_with_theme("activerecord.errors.custom.discount_code_is_not_valid", :discount_code => @discount_code)
      self.discount = nil
    end
  end

  def country_code_in_publisher_country_codes
    if country_code.present? and not publisher.available_country_code? country_code
      errors.add(:country_code, translate_with_theme("activerecord.errors.custom.not_allowed_by_publisher_settings"))
    end
  end

  def adjust_credit_available!(amount)
    lock!
    write_attribute :credit_available, (credit_available + amount)
    save!
  end

  def add_credit_object(credit)
    Consumer.transaction do
      credit.save!
      adjust_credit_available!(+credit.amount)
    end
  end

  def del_credit_object(credit)
    Consumer.transaction do
      adjust_credit_available!(-credit.amount)
    end
  end

  def set_preferred_locale
    self.preferred_locale = I18n.locale.to_s unless self.preferred_locale
  end

  def give_referral_credit?
    daily_deal_purchases.captured(nil).count <= 1
  end
  #
  # When I refer a friend, their referral_code is set to my referrer_code.
  #
  def init_referrer_code
    self.referrer_code = UUIDTools::UUID.random_create.to_s if referrer_code.blank?
  end

  def publisher_membership_code_belongs_to_publisher
    return unless require_publisher_membership_code?
    if publisher_membership_code.nil? || publisher_membership_code_as_text.blank?
      errors.add(:publisher_membership_code_as_text, translate_with_theme("activerecord.errors.messages.blank"))
    elsif publisher_membership_code.try(:publisher) != publisher
      errors.add(:publisher_membership_code_as_text, translate_with_theme("activerecord.errors.messages.invalid"))
    end
  end

  def clear_force_reset_if_password_changed
    if crypted_password_changed?
      self.force_password_reset = false
    end
    true
  end

  def unique_email_across_publishing_group
    return if publisher.publishing_group.nil?
    existing_consumer = publisher.publishing_group.consumers.find_by_email(email)
    if existing_consumer.present? && existing_consumer != self
      errors.add(:email, translate_with_theme('activerecord.errors.messages.taken'))
    end
  end

  def preferred_locale_supported
    return unless preferred_locale.present?
    if (!publisher.enabled_locales_for_consumer.empty? && !publisher.enabled_locales_for_consumer.include?(preferred_locale)) || 
        (publisher.enabled_locales_for_consumer.empty? && !I18n.available_locales.include?(preferred_locale.to_sym))
      errors.add(:preferred_locale, translate_with_theme("activerecord.errors.custom.locale_not_supported", :preferred_locale => preferred_locale))
    end
  end

end
