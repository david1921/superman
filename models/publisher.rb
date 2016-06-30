# -*- coding: iso-8859-1 -*-
class Publisher < ActiveRecord::Base
  include ActsAsLabelled  
  include ActsAsLocation
  include Export::Publisher
  include HasConfigurableProperties
  include HasMerchantAccountID
  include MailChimpListManagement
  include Publishers::Core
  include Publishers::Finders
  include Publishers::Localization
  include Publishers::PushNotifications
  include Publishers::DailyDeals
  include Publishers::Yelp
  include ReadyMadeThemes
  include Report::Publisher
  include Publishers::SilverpopMailingManagement
  include Publishers::Silverpop
  include Publishers::SilverpopSync
  include ThirdPartyDealsApi::Publisher
  include TritonLoyaltyListManagement
  include Publishers::Fraud
  extend Publishers::DelegateAttributeToPublishingGroupIfNil
  include HasPublisherThemeableTranslations
  include Publishers::Hosts
  include Publishers::LoyaltyProgram
  include Publishers::VoucherShipping
  include Locales::Enabled
  
  include Publishers::ConfigurableMethods::CyberSource

  TRANSLATE_SCOPE = [:publisher]

  acts_as_location

  translates :brand_name, :daily_deal_brand_name,
    :brand_headline, :brand_txt_header, :brand_twitter_prefix,
    :daily_deal_sharing_message_prefix, :daily_deal_twitter_message_prefix,
    :gift_certificate_disclaimer, :daily_deal_email_signature, :how_it_works,
    :account_sign_up_message, :daily_deal_universal_terms

  delegate :allows_donations?, :to => :publishing_group, :allow_nil => true
  delegate :allow_single_sign_on?, :to => :publishing_group, :allow_nil => true
  delegate :unique_email_across_publishing_group?, :to => :publishing_group, :allow_nil => true
  delegate :allow_publisher_switch_on_login?, :to => :publishing_group, :allow_nil => true
  delegate :consumer_after_update_strategy, :to => :publishing_group, :allow_nil => true
  delegate :uses_paychex?, :to => :publishing_group, :allow_nil => true
  delegate :paychex_initial_payment_percentage, :to => :publishing_group, :allow_nil => true
  delegate :paychex_num_days_after_which_full_payment_released, :to => :publishing_group, :allow_nil => true
  delegate :use_vault, :to => :publishing_group, :allow_nil => true
  delegate :use_vault?, :to => :publishing_group, :allow_nil => true
  delegate :enable_redirect_to_last_seen_deal_on_login?, :to => :publishing_group, :allow_nil => true

  delegate_attribute_to_publishing_group_if_nil :number_sold_display_threshold_default
  delegate_attribute_to_publishing_group_if_nil :consumer_authentication_strategy
  delegate_attribute_to_publishing_group_if_nil :consumer_after_create_strategy
  delegate_attribute_to_publishing_group_if_nil :custom_consumer_password_reset_url
  delegate_attribute_to_publishing_group_if_nil :silverpop_template_identifier
  delegate_attribute_to_publishing_group_if_nil :silverpop_seed_template_identifier
  delegate_attribute_to_publishing_group_if_nil :daily_deals_available_for_syndication_by_default_override, 
                                                {:publishing_group_attribute => :daily_deals_available_for_syndication_by_default, 
                                                 :boolean_attribute => true}

  #
  # === Encrypted Attributes
  #
  # see  http://github.com/shuber/attr_encrypted

  attr_encrypted_options.merge!(:key => AppConfig.attr_encrypted_secret, :unless => Rails.env.development? || Rails.env.staging? || Rails.env.nightly?)
  attr_encrypted :federal_tax_id

  acts_as_textiled :gift_certificate_disclaimer, :how_it_works, :daily_deal_universal_terms

  RE_EMAIL_ADDRESS = /#{Analog::Util::EmailValidator::RE_EMAIL_NAME}@#{Analog::Util::EmailValidator::RE_DOMAIN_HEAD}#{Analog::Util::EmailValidator::RE_DOMAIN_TLD}/i

  THEMES = {
    "enhanced" => "Enhanced",
    "narrow" => "Narrow",
    "simple" => "Simple",
    "standard" => "Standard",
    "sdcitybeat" => "SD CityBeat",
    "businessdirectory" => "Business Directory",
    "withtheme" => "Use Themes Directory"
  }
  COUPON_BORDER_TYPES = %w( solid dotted dashed )
  ALLOWED_PAYMENT_METHODS = {
    "credit" => "Braintree - Credit Card",
    "paypal" => "PayPal",
    "optimal" => "Optimal - Credit Card",
    "cyber_source" => "CyberSource - Credit Card",
    "travelsavers" => "TRAVELSAVERS"
  }
  ALLOWED_CURRENCY_CODES = {
    "USD" => "$",
    "CAD" => "C$",
    "GBP" => "£",
    "EUR" => "€"
  }
  COUPONS_HOMEPAGES = %w{ grid map }

  DEFAULT_QR_CODE_HOST = "FNDG.ME"
    
  belongs_to :publishing_group

  has_attached_file :logo,
                    :bucket => "logos.publishers.analoganalytics.com",
                    :s3_host_alias => "logos.publishers.analoganalytics.com",
                    :default_style => :normal,
                    :styles => {
                      :full_size => { :geometry => "100x100%", :format => :jpg },
                      :normal =>    { :geometry => "240x90>",  :format => :png }
                    }

  has_attached_file :daily_deal_logo,
                    :bucket => "daily-deal-logos.publishers.analoganalytics.com",
                    :s3_host_alias => "daily-deal-logos.publishers.analoganalytics.com",
                    :default_style => :normal,
                    :styles => {
                      :full_size => { :geometry => "100x100%", :format => :jpg },
                      :normal =>    { :geometry => "240x90>",  :format => :png }
                    }

  has_attached_file :paypal_checkout_header_image,
                    :bucket => "paypal-checkout-header-images.publishers.analoganalytics.com",
                    :s3_host_alias => "paypal-checkout-header-images.publishers.analoganalytics.com",
                    :default_style => :normal,
                    :styles => {
                      :normal => { :geometry => "750x90>", :format => :png },
                       :small => { :geometry => "250x30>", :format => :png },
                    }

  has_many :advertisers do
    def find_by_listing_parts(*parts)
      find_by_listing(Advertiser.listing_from_parts(*parts))
    end

    def find_or_initialize_by_listing_parts(*parts)
      find_or_initialize_by_listing(Advertiser.listing_from_parts(*parts))
    end
  end

  has_many :markets
  has_many :market_zip_codes, :through => :markets
  has_many :advertiser_signups, :through => :advertisers
  has_many :call_api_requests
  has_many :consumers
  has_many :daily_deals
  has_many :daily_deal_categories, :dependent => :destroy
  has_many :daily_deal_purchases, :through => :daily_deals
  has_many :off_platform_daily_deal_certificates, :through => :consumers
  has_many :suggested_daily_deals
  has_many :discounts, :dependent => :destroy
  has_many :sweepstakes, :dependent => :destroy
  has_many :email_api_requests
  has_many :gift_certificates, :through => :advertisers
  has_many :jobs
  has_many :leads, :through => :offers
  has_many :offers, :through => :advertisers
  has_many :placed_offers, :source => :offer, :through => :placements
  has_many :placements, :dependent => :destroy
  has_many :publisher_zip_codes, :dependent => :destroy
  has_many :report_api_requests
  has_many :subscribers
  has_many :subscription_rate_schedules, :as => :item_owner, :dependent => :destroy
  has_many :txt_api_requests
  has_many :txt_coupon_api_requests
  has_many :txt_offers, :through => :advertisers
  has_many :user_companies, :as => :company, :dependent => :destroy
  has_many :users, :through => :user_companies
  has_many :web_coupon_api_requests
  has_and_belongs_to_many :countries
  has_many :affiliate_placements, :as => :affiliate
  has_many :markets, :dependent => :destroy
  has_and_belongs_to_many :publishers_excluded_from_distribution, :join_table => 'publishers_publishers_excluded_from_distribution', :class_name => 'Publisher', :association_foreign_key => 'publisher_excluded_from_distribution_id'
  has_and_belongs_to_many :publishers_unavailable_for_distribution, :join_table => 'publishers_publishers_excluded_from_distribution', :class_name => 'Publisher', :association_foreign_key => 'publisher_id', :foreign_key => 'publisher_excluded_from_distribution_id'
  has_many :platform_revenue_sharing_agreements, :as => :agreement, :class_name => "Accounting::PlatformRevenueSharingAgreement", :dependent => :destroy
  has_many :syndication_revenue_sharing_agreements, :as => :agreement, :class_name => "Accounting::SyndicationRevenueSharingAgreement", :dependent => :destroy
  has_many :publisher_membership_codes

  serialize :excluded_clipping_modes
  serialize :enabled_locales, Array
  
  has_many :subscription_locations, :dependent => :destroy
  has_many :push_notification_devices, :dependent => :destroy
  before_validation :normalize_excluded_clipping_modes
  before_validation :normalize_brand_txt_header
  before_validation :normalize_txt_keyword_prefix
  before_validation :set_countries_if_not_set

  validates_uniqueness_of :name, :message => "'%{value}' has already been taken"
  validates_presence_of :time_zone
  validates_presence_of :name
  # validates_presence_of :federal_tax_id
  validates_presence_of :label, :if => :standard_theme?
  validates_inclusion_of :theme, :in => THEMES, :allow_blank => false
  validates_inclusion_of :coupon_border_type, :in => COUPON_BORDER_TYPES, :if => :simple_or_narrow_layout?
  validates_inclusion_of :email_blast_day_of_week, :allow_nil => true, :in => VALID_EMAIL_BLAST_DAY_NAMES, :message => "%{attribute} is not one of #{Date::DAYNAMES.join(', ')}"
  with_options :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true do |publisher_class|
    publisher_class.validates_numericality_of :active_coupon_limit
    publisher_class.validates_numericality_of :active_txt_coupon_limit
  end
  validates_each :support_phone_number, :allow_blank => true do |record, attr, value|
    record.errors.add(attr, ::I18n.translate("activerecord.errors.messages.invalid")) unless PhoneNumber.new(value, record.country_code).valid?
  end
  validate :publishing_group_not_set_by_id_and_name
  validates_length_of :brand_txt_header, :maximum => 15, :allow_blank => true
  validates_presence_of :production_subdomain
  validates_inclusion_of :payment_method, :in => ALLOWED_PAYMENT_METHODS, :allow_blank => true, :allow_nil => true
  validates_presence_of :require_billing_address, :if => lambda { |publisher| publisher.payment_method == "cyber_source" }, :message => "%{attribute} must be set if CyberSource is used as the payment method."
  validates_inclusion_of :currency_code, :in => ALLOWED_CURRENCY_CODES
  validates_numericality_of :daily_deal_referral_credit_amount, :greater_than => 0.00, :allow_nil => false
  validates_numericality_of :email_blast_hour, :only_integer => true, :greater_than_or_equal_to => 0, :less_than => 24
  validates_numericality_of :email_blast_minute, :only_integer => true, :greater_than_or_equal_to => 0, :less_than => 60
  validates_format_of :market_name, :with => /\A[a-zA-Z\-\s\.]+\z/, :message => "%{attribute} can only contain letters, periods, hyphens and spaces.", :allow_blank => true
  validates_length_of :countries, :minimum => 1, :message => "%{attribute} must be set"
  validates_inclusion_of :coupons_homepage, :in => COUPONS_HOMEPAGES
  validates_format_of :google_analytics_account_ids, :with => /^((UA-\d+-\d{1,2})(, ?UA-\d+-\d{1,2})*)?$/

  validate :valid_support_email_address
  def valid_support_email_address
    if support_email_address.present? && !support_email_address.match(RE_EMAIL_ADDRESS)
      errors.add :support_email_address, ::I18n.translate(:invalid_email_message)
    end
  end

  validates_presence_of :email_blast_day_of_week, :email_blast_hour, :email_blast_minute, :if => :silverpop_weekly_email_configured?
  validates_presence_of :silverpop_list_identifier, :silverpop_template_identifier, :if => :send_weekly_email_blast_to_contact_list?
  validates_presence_of :silverpop_seed_database_identifier, :silverpop_seed_template_identifier, :if => :send_weekly_email_blast_to_seed_list?

  validates_presence_of :notification_email_address, :if => :send_daily_deal_notification

  validate :valid_main_publisher
  validate :enabled_locales_exist

  def silverpop_weekly_email_configured?
    send_weekly_email_blast_to_contact_list || send_weekly_email_blast_to_seed_list
  end

  before_validation_on_create :set_production_subdomain
  before_destroy :ensure_no_daily_deal
  before_destroy :destroy_advertisers

  audited :only => :merchant_account_id

  named_scope :observable_by, lambda { |user| user.observable_publishers_scope }
  named_scope :manageable_by, lambda { |user| user.manageable_publishers_scope }
  named_scope :launched, :conditions => { :launched => true }
  named_scope :no_publishing_group, :conditions => { :publishing_group_id => nil }
  named_scope :allow_daily_deals, :conditions => { :allow_daily_deals => true }
  named_scope :any_daily_deals, :conditions => %Q{ publishers.id in
        (select publisher_id from advertisers where advertisers.id in
          (select advertiser_id from daily_deals)
        ) }

  named_scope :with_third_party_deals_api_configs, :conditions => %Q{
    publishers.id IN (SELECT publisher_id FROM third_party_deals_api_configs)
  }

  named_scope :with_active_daily_deals, lambda {
    { :conditions => [ "EXISTS (SELECT id
                             FROM daily_deals
                             WHERE publisher_id = publishers.id
                               AND deleted_at IS NULL
                               AND start_at <= :now AND hide_at > :now)",
                    { :now => Time.zone.now } ] }
  }

  named_scope :with_current_or_future_daily_deals, lambda {
    { :conditions => [ "EXISTS (SELECT id
                             FROM daily_deals
                             WHERE publisher_id = publishers.id
                               AND deleted_at IS NULL
                               AND start_at IS NOT NULL
                               AND ((start_at <= :now AND hide_at > :now) OR start_at > :now))",
                    { :now => Time.zone.now } ] }
  }

  named_scope :with_active_offers, lambda { {
                :select => "distinct publishers.*", 
                :joins => [ :advertisers, :offers ], 
                :conditions => [ "launched = :launched and (offers.expires_on IS NULL OR :date <= offers.expires_on)", { :launched => true, :date => Time.zone.now } ] 
              }
  }

  named_scope :by_zip_code, lambda { |zip_code|
    {
      :include => :publisher_zip_codes,
      :conditions => ["publisher_zip_codes.zip_code = ?", zip_code],
      :limit => 1
    }
  }

  named_scope :included_in_market_selection, :conditions => "NOT exclude_from_market_selection"

  named_scope :with_advertisers, :include => :advertisers
  named_scope :with_publishing_group, :include => :publishing_group
  named_scope :with_users, :include => :users

  named_scope :not_in_publishing_groups, lambda { |publishing_groups|
    if publishing_groups.present?
      { :conditions => [ "(publishing_group_id is null or publishing_group_id not in (?))", publishing_groups.map(&:id) ] }
    end
  }

  named_scope :in_syndication_network, :conditions => { :in_syndication_network => true }
  named_scope :not_in_syndication_network, :conditions => { :in_syndication_network => false }
  named_scope :in_travelsavers_syndication_network, :conditions => { :in_travelsavers_syndication_network => true }

  configurable_property_parent :publishing_group
  configurable_property :attachment_style_geometries, :merchant_account_ids, :bit_ly_path_formats, :display_text
  
  # A bit more verbose than you might like because of Rails class-reloading
  def self.find_by_label!(label)
    raise ActiveRecord::RecordNotFound if label.blank?
    publisher = Publisher.find_by_label(label)
    raise ActiveRecord::RecordNotFound unless publisher
    publisher
  end

  def self.currency_symbol_for(currency_code)
    ALLOWED_CURRENCY_CODES[ currency_code.to_s.upcase ] if currency_code.present?
  end

  def self.currencies_in_use
    currency_codes = connection.execute "SELECT DISTINCT(currency_code) FROM publishers"
    currency_codes.all_hashes.map { |r| r["currency_code"].downcase.to_sym }
  end

  def find_market_by_zip_code(zip_code)
    self.markets.first(
      :joins      => :market_zip_codes,
      :conditions => ["market_zip_codes.zip_code = ?", zip_code])
  end

  def markets_with_deals_for_state(state_code)
    joins = %Q{
      INNER JOIN market_zip_codes mzc ON markets.id = mzc.market_id
      INNER JOIN daily_deals_markets ddm ON markets.id = ddm.market_id 
    }
    self.markets.all(
      :joins => joins,
      :conditions => ["mzc.state_code = ?", state_code],
      :group => "markets.id"
    )
  end

  def import_subscriber_emails_from_file(subscriber_filename)
    unless File.exists?(subscriber_filename)
      raise ArgumentError, "No such file or directory: #{subscriber_filename}"
    end

    email_addresses = nil
    File.open(subscriber_filename) do |subscribers_file|
      email_addresses = subscribers_file.
        readlines.
        select { |email| email.include? "@" }.
        map { |email| email.strip.chomp }
    end

    num_added = 0
    errors = []
    email_addresses.each do |email_addy|
      begin
        Subscriber.create! :email => email_addy, :publisher_id => id
        num_added += 1
      rescue ActiveRecord::RecordInvalid
        errors << email_addy
      end
    end

    return { :num_added => num_added, :errors => errors }
  end

  def import_subscriber_emails_from_csv(subscriber_filename, opts = {})
    unless File.exists?(subscriber_filename)
      raise ArgumentError, "No such file or directory: #{subscriber_filename}"
    end

    if File.extname(subscriber_filename) != '.csv'
      raise ArgumentError, "Invalid file extension: #{subscriber_filename}"
    end

    email_addresses = nil

    num_added = 0
    errors = []
    FasterCSV.foreach(subscriber_filename, :headers => true) do |row|
      next unless row['Email']

      subscriber = Subscriber.new(:publisher_id   => id,
                                  :email          => row['Email'].try(:strip),
                                  :first_name     => row['First Name'].try(:strip),
                                  :last_name      => row['Last Name'].try(:strip),
                                  :address_line_1 => row['Address'].try(:strip),
                                  :city           => row['City'].try(:strip),
                                  :state          => row['State'].try(:strip),
                                  :zip_code       => row['Zip Code'].try(:strip))

      if opts[:ignore_invalid_zip_codes] and not subscriber.valid?
        subscriber.zip_code = nil
      end

      if subscriber.save
        num_added += 1
      else
        errors << row['Email']
      end
    end

    return { :num_added => num_added, :errors => errors }
  end

  def launch!
    self.update_attributes :launched => true
  end

  def disable!
    self.update_attributes :launched => false
  end

  def analytics_service_provider
    @analytics_service_provider ||= AnalyticsProvider.new(:id => self.analytics_provider_id, :site_id => self.analytics_site_id)
  end

  def analytics_service_provider_id
    analytics_service_provider.valid? ? analytics_service_provider.id : nil
  end

  def analytics_service_provider_id=(val)
    self.analytics_provider_id = val.to_i
  end

  def using_analytics_provider?
    self.analytics_provider_id.to_i > 0
  end

  def ensure_no_daily_deal
    if daily_deals.any?
      errors.add "Can't delete publisher #{label} because it has daily deals."
      return false
    end
    true
  end

  def destroy_advertisers
    advertisers.all?(&:destroy)
  end

  def short_name
    name.underscore.gsub(" ", "_")
  end

  def publishing_group_name
    publishing_group.try(:name)
  end

  def publishing_group_name=(value)
    if value.present?
      self.publishing_group = PublishingGroup.find_or_initialize_by_name(value)
      @publishing_group_set_by_name = true
    end
  end

  def publishing_group_id=(value)
    super(value)
    @publishing_group_set_by_id = value.present?
  end

  def observable_publishers_scope(not_used = nil)
    { :conditions => { :id => id }}
  end

  def manageable_publishers_scope(not_used = nil)
    self_serve ? observable_publishers_scope : User::EMPTY_SCOPE
  end

  def observable_advertisers_scope(not_used = nil)
    { :include => :publisher, :conditions => { 'publishers.id' => id }}
  end

  def manageable_advertisers_scope(not_used = nil)
    self_serve ? observable_advertisers_scope : User::EMPTY_SCOPE
  end

  def active_offers_count(city = nil, state = nil)
    unless search_by_publishing_group?
      active_offers_count_based_on_city_and_state(offers, city, state)
    else
      active_offers_count_based_on_city_and_state(Offer.in_publishers( publishers_in_publishing_group.collect(&:id)))
    end
  end

  def active_placed_offers_count(city = nil, state = nil)
    unless search_by_publishing_group?
      active_offers_count_based_on_city_and_state(placed_offers, city, state)
    else
      active_offers_count_based_on_city_and_state(Offer.placed_in_publishers( publishers_in_publishing_group.collect(&:id)), city, state)
    end
  end

  def active_offers_count_based_on_city_and_state(offers_or_placed_offers, city = nil, state = nil)
    Publisher.benchmark "Publisher#active_offers_count_based_on_city_and_state" do
      offers_scope = offers_or_placed_offers
      if city.present? && state.present?
        zips = ZipCode.zips_near(city, state, default_offer_search_distance)
        offers_scope = offers_scope.active_on(Time.zone.now).in_zips(zips)
      else
        offers_scope = offers_scope.active_on(Time.zone.now)
      end
      offers_scope.count
    end
  end
  
  def side_deals_in_custom_entercom_order(deal_to_exclude=nil)
    daily_deals.active.side.filtered_for_entercom(deal_to_exclude)
  end

  def purchased_gift_certificates_shown_between(dates)
    PurchasedGiftCertificate.find_by_sql(['SELECT pgc.* FROM
    purchased_gift_certificates as pgc
    INNER JOIN gift_certificates as gc ON gc.id = pgc.gift_certificate_id
    INNER JOIN advertisers ON advertisers.id = gc.advertiser_id
    LEFT JOIN advertiser_translations ON advertisers.id = advertiser_translations.advertiser_id AND advertiser_translations.locale = "en"
    WHERE advertisers.publisher_id = :id
    AND (show_on IS NULL OR show_on between :begin_date and :end_date) AND NOT deleted
    AND pgc.purchased_at IS NOT NULL ORDER BY advertiser_translations.name asc', {:id => id, :begin_date => dates.first, :end_date => dates.end}])
  end

  def advertisers_with_web_offers(search_request)
    if search_request.postal_code.blank?
      search_text   = search_request.text
      category_ids  = search_request.categories.collect(&:id).uniq

      advertisers = self.advertisers.having_active_web_offers
      advertisers = advertisers.in_categories(category_ids) if category_ids.present?
      advertisers = advertisers.with_text(search_text) if search_text.present?

      sort = search_request.sort
      case sort
      when "Most Recent"
        advertisers = advertisers.by_most_recent_offers
      else
        advertisers = advertisers.by_name
      end
    else
      options = {}
      options[:radius] = search_request.radius unless search_request.radius.nil?
      options[:sort]   = search_request.sort
      advertisers = advertisers_with_active_web_offers_near(search_request.postal_code, options)
    end

    advertisers
  end

  def group_label_or_label
    publishing_group.try(:label).if_present || label
  end

  def advertiser_count_for_category(category)
    if enable_search_by_publishing_group? && publishing_group.present?
      publishing_group.advertisers.having_active_web_offers.in_categories([category.id]).count
    else
      advertisers.having_active_web_offers.in_categories([category.id]).count
    end
  end

  def find_category_by_category_label(category_label)
    Category.find_publisher_category_based_on_category_label(self, category_label)
  end

  def find_category_by_path(path)
    find_category_by_category_label(path.last) || Category.find_by_path(path)
  end

  def brand_name_or_name
    brand_name.present? ? brand_name : name
  end

  def name_for_daily_deals
    daily_deal_brand_name.to_s.strip.if_present || "#{brand_name_or_name} #{daily_deal_name}"
  end

  def email_only_from_support_email_address
    return support_email_address if support_email_address.blank?
    support_email_address.match(RE_EMAIL_ADDRESS).to_s
  end

  # used to start of the twitter status.
  def twitter_handle
    brand_twitter_prefix.present? ? brand_twitter_prefix : "[#{brand_name_or_name} Coupon]"
  end

  def coupon_headline
    brand_headline.present? ? brand_headline : "#{brand_name_or_name} Coupon"
  end

  def standard_theme?
    self.theme == 'standard'
  end

  def simple_or_narrow_layout?
    %w( simple narrow ).include? theme
  end

  def theme_options
    case theme
    when "standard", "sdcitybeat", "withtheme"
      [ :advanced_search_link_target, :coupons_home_link, :show_call_button, :show_gift_certificate_button ]
    when "simple", "narrow"
      [ :coupon_border_type, :show_bottom_pagination, :show_phone_number, :show_small_icons ]
    else
      [ :show_bottom_pagination, :show_small_icons ]
    end
  end

  def generate_coupon_codes(force = false)
    self.offers.each do |offer|
      offer.generate_coupon_code force
    end
  end

  def excludes_clipping_via(mode)
    normalize_excluded_clipping_modes unless excluded_clipping_modes.is_a?(Set)
    excluded_clipping_modes.include?(mode.to_sym)
  end

  def txt_offers_enabled?
    txt_keyword_prefixes.present?
  end

  def txt_keyword_prefixes
    txt_keyword_prefix.present? ? [txt_keyword_prefix] : []
  end

  def next_keyword_suffix(prefix)
    if txt_keyword_prefixes.include?(prefix)
      reload.update_attributes! :txt_keyword_number => txt_keyword_number + 1
      txt_keyword_number.to_s
    end
  end

  def has_default_offer_search_params?
    (default_offer_search_postal_code.blank? || default_offer_search_distance.blank?) ? false : true
  end

  def search_by_publishing_group?
    self.enable_search_by_publishing_group? && self.publishing_group.present?
  end

  def publishers_in_publishing_group
    self.publishing_group.present? ? self.publishing_group.publishers : []
  end

  def subscriber_report_interval
    if "vcreporter" == label
      7.day if Time.zone.now.to_date.wday == 5 # Friday
    else
      1.day
    end
  end

  def default_terms
    try(:publishing_group).try(:terms_default)
  end

  def deliver_advertisers_categories
    PublishersMailer.deliver_advertisers_categories(self) if categories_recipients.present?
  end

  def default_daily_deal_categories
    DailyDealCategory.analytics
  end

  def allowable_daily_deal_categories
    if publishing_group && publishing_group.daily_deal_categories.present?
      publishing_group.daily_deal_categories
    elsif daily_deal_categories.present?
      daily_deal_categories
    else
      default_daily_deal_categories
    end
  end

  def purchased_gift_certificates_completed(dates)
    sql =<<-EOF
      SELECT purchased_gift_certificates.*, advertiser_translations.name AS advertiser_name
      FROM purchased_gift_certificates
        INNER JOIN gift_certificates ON purchased_gift_certificates.gift_certificate_id = gift_certificates.id
        INNER JOIN advertisers ON gift_certificates.advertiser_id = advertisers.id
        LEFT JOIN advertiser_translations ON advertisers.id = advertiser_translations.advertiser_id AND advertiser_translations.locale = "en"
      WHERE purchased_gift_certificates.payment_status = 'completed'
        AND purchased_gift_certificates.paypal_payment_date BETWEEN :t_begin AND :t_end AND advertisers.publisher_id = :publisher_id
    EOF
    PurchasedGiftCertificate.find_by_sql([sql, { :t_begin => dates.begin.beginning_of_day, :t_end => dates.end.end_of_day, :publisher_id => id }])
  end

  def require_address_or_phone?
    false
  end

  # Overwrites ActsAsLocation#validate_full_address?
  # TODO: Uncomment this after existing publishers have been updated with the
  # required information
  # def validate_full_address?
    # true
  # end

  # responsible for returning an array of publishers
  # that should also be placed with the offer for
  # this instance of publisher.
  #
  # If a publisher has a setting of true for place_offers_with_group, then
  # all the publishing group publishers should receive the offer as well.
  #
  # If a related publisher (via Publishing Group), has a setting of true
  # for place_all_group_offers, then that publisher should be returned as
  # well as the current instance.
  #
  # If neither of these cases are true, then just the current instance is
  # returned.
  def place_offers_with
    publishers = []
    if publishing_group
      if place_offers_with_group
        publishers = publishing_group.publishers
      else place_all_group_offers
        publishers = publishing_group.publishers.collect do |pub|
          pub if pub.place_all_group_offers?
        end.compact # remove nils
        publishers << self # we also need to include self
      end
    end
    publishers.empty? ? [self] : publishers.uniq
  end

  def calculate_offers_popularity!
    self.offers.each(&:update_popularity!)
  end

  def to_s
    "#<Publisher #{id} #{name} #{label} #{theme}>"
  end

  def coupon_changed!(coupon)
    if coupon && notify_via_email_on_coupon_changes?
      PublishersMailer.deliver_coupon_changed(self, coupon) unless approval_email_address.blank?
    end
  end

  def pay_using?(method)
    payment_method == method.to_s
  end

  def with_logo(type = nil)
    url = nil
    SystemTimer.timeout_after(10.seconds) do
      if block_given? && (url = logo_for(type).try(:url, :full_size))
        open(url) { |io| yield io }
      end
    end
  rescue Timeout::Error => e
    # notify exceptional and keep going
    Exceptional.handle(e)
  end

  def checkout_discount_codes?
    allow_discount_codes? && discounts.usable.at_checkout.count > 0
  end

  def signup_discount
    discounts.usable.find_by_code "SIGNUP_CREDIT"
  end

  def signup_discount_amount
    signup_discount.try(:amount)
  end

  def find_usable_discount_by_code(code)
    discounts.usable.find_by_code(code)
  end

  def attachment_style_geometry(*args)
    attachment_style_geometries && args.inject(attachment_style_geometries) { |val, arg| val.try(:fetch, arg.to_s, nil) }
  end

  def bit_ly_path_format(type)
    bit_ly_path_formats && bit_ly_path_formats[type.to_s]
  end

  def find_braintree_credentials!
    BraintreeCredentials.find(label, publishing_group.try(:label))
  end
  
  def cyber_source_credentials(options = {})
    CyberSource::Credentials.find(label, publishing_group.try(:label), options)
  end

  def allow_consumer_show_action?
    return true if publishing_group && publishing_group.allow_consumer_show_action?
    allow_consumer_show_action
  end

  def to_liquid
    Drop::Publisher.new(self)
  end

  def daily_deal_referral_message_head
    read_attribute(:daily_deal_referral_message_head).if_present || "Check out #{name.possessive} daily deal"
  end

  def daily_deal_referral_message_body
    read_attribute(:daily_deal_referral_message_body).if_present || "Check out #{name.possessive} daily deal - huge discounts on the coolest stuff!"
  end

  def daily_deal_name
    display_text_for(:daily_deal_name)
  end

  def send_todays_email_blast_at
    Time.now.in_time_zone(time_zone).beginning_of_day + email_blast_hour.hours + email_blast_minute.minutes
  end

  def zip_codes
    my_zip_codes = publisher_zip_codes.map(&:zip_code)
    my_zip_codes.present? ? my_zip_codes : nil
  end

  def country_codes
    @country_codes ||= countries.map{ |country| country.code.upcase }
  end

  def available_country_code?(code)
    code = code.to_s.strip.upcase
    country_codes.include? code
  end

  def market_name_or_city
    if market_name.blank?
      city
    else
      market_name
    end
  end

  def market_base_uri
    if !market_name_or_city.blank?
      base_uri = ""
      base_uri << "/"
      base_uri << market_name_or_city.downcase.gsub(" ", "-").gsub(".", "")
    end
  end

  def formatted_support_phone_number
    formatted_phone_number(:support_phone_number)
  end

  def default_voucher_steps(advertiser_name = "merchant")
    steps = (1..3).map do |i|
      step_symbol = :"how_to_use_deal_certificate_step#{i}"
      default_step = translate_with_theme(step_symbol, :scope => TRANSLATE_SCOPE, :advertiser_name => advertiser_name)
      display_text_for(step_symbol, default_step)
    end

    steps.join("\n")
  end

  def daily_deal_email_subject
    daily_deal_sharing_message_prefix.to_s.strip.if_present || name_for_daily_deals
  end

  def google_analytics_ids(market_label = nil)
    pattern = /, ?/
    if market_label.present? && markets.present?
      found_market = markets.to_ary.find{|m| m.label.downcase == market_label.downcase}
     # raise "#{found_market.inspect}" if !found_market.google_analytics_account_ids.present?
      market_ids = found_market[:google_analytics_account_ids] if found_market.present?
    end
    group_ids = publishing_group.try(:google_analytics_account_ids) || ""
    pub_ids = google_analytics_account_ids || ""
    ret = [AppConfig.google_analytics_system_account_id] + group_ids.split(pattern) + pub_ids.split(pattern)
    ret += market_ids.split(pattern) if market_ids.present?
    ret
  end
  
  def has_google_map_settings?
    if google_map_zoom_level && google_map_latitude && google_map_longitude
      true
    else
      false
    end
  end

  def advertiser_financial_detail?
    publishing_group.advertiser_financial_detail if publishing_group.present?
  end

  def require_federal_tax_id?
    publishing_group.require_federal_tax_id if publishing_group.present?
  end

  def deals_in_market(market)
    daily_deals.in_market(market)
  end

  def deals_without_market()
    daily_deals.without_market
  end
  
  def notify_third_parties_of_consumer_creation?
    if self.publishing_group.present? && self.publishing_group.notify_third_parties_of_consumer_creation == true
      return true
    else
      return self.notify_third_parties_of_consumer_creation
    end
  end

  def make_current_and_future_deals_available_for_syndication
    unless in_syndication_network?
      raise "Publisher #{self.name} must be in syndication network to make all current and future deals available for syndication"
    end
    DailyDeal.transaction do
      daily_deals.current_or_future.each do |deal|
        unless deal.syndicated?
          deal.available_for_syndication = true
          deal.save!
        end
      end
    end
  end
  
  def force_password_reset?(email)
    self.consumers.find_by_email_and_force_password_reset(email, true).present?
  end
  
  def syndication_allowed_to_publisher?(_publisher)
    (_publisher.id != id) &&
    ((publishing_group.try(:id) == _publisher.publishing_group.try(:id)) ||
      !(publishing_group.try(:restrict_syndication_to_publishing_group) ||
       _publisher.publishing_group.try(:restrict_syndication_to_publishing_group)))
  end

  def daily_deal_categories_with_deals
    daily_deal_categories = DailyDealCategory.for_publisher(self).with_active_deals_for_publisher(self)

    if default_daily_deal_zip_radius > 0
      daily_deal_categories.with_deals_in_zip_radius(User.current.try(:zip_code), default_daily_deal_zip_radius)
    end

    daily_deal_categories
  end

  def require_membership_codes?
    publishing_group.try(:require_publisher_membership_codes?) || false
  end
  
  def effective_qr_code_host
    qr_code_host.if_present || publishing_group.try(:qr_code_host).if_present || DEFAULT_QR_CODE_HOST
  end

  def bcbsa_national?
    self.label == 'bcbsa-national'
  end

  def enabled_locales_for_consumer
    publishing_group_locales = publishing_group.try(:enabled_locales) || []
    publisher_locales = enabled_locales || []
    (publisher_locales + publishing_group_locales).uniq
  end

  def enabled_locales
    attributes["enabled_locales"]
  end

  private

  def normalize_brand_txt_header
    self.brand_txt_header = brand_txt_header.to_s.split(' ').join(' ')
  end

  def normalize_txt_keyword_prefix
    self.txt_keyword_prefix = txt_keyword_prefix.to_s.gsub(/\s/, "").upcase
  end

  def set_countries_if_not_set
    if countries.empty?
      countries << [Country::US]
    end
  end

  def publishing_group_not_set_by_id_and_name
    if @publishing_group_set_by_name && @publishing_group_set_by_id
      errors.add(:publishing_group, "%{attribute} can't be set both as existing and new")
    end
  end

  def normalize_excluded_clipping_modes
    self.excluded_clipping_modes = returning(Set.new) do |set|
      if self.excluded_clipping_modes.respond_to?(:each)
        self.excluded_clipping_modes.each do |m|
          set << m.to_sym if m.respond_to?(:to_sym) && Advertiser::RECOGNIZED_COUPON_CLIPPING_MODES.include?(m.to_sym)
        end
      end
    end
  end

  def set_production_subdomain
    if production_subdomain.blank?
      index = rand(9)
      # We use sb0-sb9, but sb1 is over-subscribed
      index = 9 if index == 1
      self.production_subdomain = "sb#{index}"
    end
    production_subdomain
  end

  # responsible for finding all advertisers with active web offers that
  # are near the given zip code.
  def advertisers_with_active_web_offers_near(zip, options = {})
    radius = options[:radius] || default_offer_search_distance || 10
    sort   = options[:sort]
    case sort
    when 'Name'
      order_by = 'advertiser_translations.name'
    when 'Most Recent'
      order_by = 'offers.show_on desc'
    when
      order_by = 'Distance'
    end


    Advertiser.find_by_sql(["
      SELECT advertisers.*, ROUND(ACOS(SIN(RADIANS(orig.latitude)) * SIN(RADIANS(dest.latitude)) + COS(RADIANS(orig.latitude)) * COS(RADIANS(dest.latitude)) * COS(RADIANS(dest.longitude) - RADIANS(orig.longitude))) * 3956, 9) AS Distance
      FROM zip_codes orig, zip_codes dest
      INNER JOIN advertisers ON advertisers.publisher_id = :publisher_id
      LEFT JOIN advertiser_translations ON advertisers.id = advertiser_translations.advertiser_id AND advertiser_translations.locale = 'en'
      INNER JOIN stores ON stores.advertiser_id = advertisers.id
      AND stores.zip = dest.zip
      INNER JOIN offers on offers.advertiser_id = advertisers.id
      WHERE orig.zip = :zip AND ACOS(SIN(RADIANS(orig.latitude)) * SIN(RADIANS(dest.latitude)) + COS(RADIANS(orig.latitude)) * COS(RADIANS(dest.latitude))  * COS(RADIANS(dest.longitude) - RADIANS(orig.longitude))) * 3956 <= :radius  AND (offers.showable AND (offers.show_on IS NULL OR :date >= offers.show_on) AND (offers.expires_on IS NULL OR :date <= offers.expires_on))
      ORDER BY #{order_by};",
      {:publisher_id => self.id, :zip => zip, :radius => radius, :date => Time.zone.now.to_date}])
  end

  def logo_for(type)
    case type
    when :daily_deal
      daily_deal_logo.file? ? daily_deal_logo : logo
    else
      logo
    end
  end

  def <=>(other)
    return -1 unless other
    name <=> other.name
  end

  def valid_main_publisher
    if main_publisher?
      if !publishing_group
        errors.add(:main_publisher, "Publisher must be in a publishing group to be a main publisher")
      elsif publishing_group.main_publisher && publishing_group.main_publisher != self
        errors.add(:main_publisher, "Publishing group can't have more than one main publisher")
      end
    end
  end

end
