# Impression: someone views this banner ad
# Clicks: someone clicks on the banner ad and is served a new coupon request page
#
# Destroying a Advertiser will trigger cascading destruction of all of its dependents.
# UI should warn about this. Front-end delete/destroy should probably be a soft-delete,
# but that means that we need to take soft-deleted things into account throughout the application.
class Advertiser < ActiveRecord::Base
  include Report::Advertiser
  include Import::Advertiser
  include HasPublisherDependentAttachments
  include HasListing
  include ActsAsSoftDeletable
  include ThirdPartyBrandingFilter
  include Advertisers::Core
  include Advertisers::Label
  include Advertisers::Status
  include Advertisers::Search

  audited_translations :name, :tagline, :website_url

  belongs_to :publisher
  belongs_to :subscription_rate_schedule

  delegate :send_intro_txt, :allow_gift_certificates?, :allow_daily_deals?, :paypal_checkout_header_image,
           :offer_has_listing?, :currency_code, :currency_symbol, :require_federal_tax_id?, :in_syndication_network?, :to => :publisher, :allow_nil => true

  has_many :stores, :dependent => :destroy
  has_many :user_companies, :as => :company, :dependent => :destroy
  has_many :users, :through => :user_companies
  has_many :daily_deals, :dependent => :destroy
  has_many :offers, :dependent => :destroy
  has_many :txt_offers, :dependent => :destroy
  has_many :gift_certificates
  has_many :purchased_gift_certificates, :through => :gift_certificates, :source => :purchased_gift_certificates
  has_many :daily_deal_purchases, :through => :daily_deals, :source => :daily_deal_purchases
  has_many :daily_deal_certificates, :through => :daily_deal_purchases, :source => :daily_deal_certificates
  has_many :advertiser_signups, :dependent => :destroy
  has_many :paypal_subscription_notifications, :as => :item, :dependent => :destroy
  has_many :notes, :as => :notable
  has_many :advertiser_owners

  blank_out_urls_with_third_party_branding :website_url

  has_attached_file :logo,
                    :bucket => "logos.advertisers.analoganalytics.com",
                    :s3_host_alias => "logos.advertisers.analoganalytics.com",
                    :path => ":rails_env_fallback/:id/:style.:extension",
                    :default_style => :normal,
                    :styles => publisher_dependent_attachment_styles({
                      :full_size => { :geometry => "100x100%", :format => :jpg },
                          :large => { :geometry => "350x550>", :format => :png },
                         :normal => { :geometry => "240x90>",  :format => :png },
                       :facebook => { :geometry => "130x110>", :format => :png },
                       :standard => { :geometry => "110x60>", :format => :png },
                      :thumbnail => { :geometry => "100x30>",  :format => :png },
                         :square => { :geometry => "60x60#", :format => :png}
                    }),
                    :convert_options => { :facebook => "-crop 130x110+0+0! -background white -flatten" }

  accepts_nested_attributes_for :stores, :reject_if => proc { |attributes|
    attributes['address_line_1'].blank? &&
    attributes['address_line_2'].blank? &&
    attributes['city'].blank? &&
    attributes['state'].blank? &&
    attributes['zip'].blank? &&
    attributes['phone_number'].blank? &&
    attributes['country'].nil?
  }

  RECOGNIZED_COUPON_CLIPPING_MODES = [ :email, :txt, :call ]
  serialize :coupon_clipping_modes

  PAYMENT_TYPES = ["ACH", "Check"]
  SIZES = ["SME", "Large", "SoleTrader"]

  PRIMARY_CATEGORY_KEYS = %w(entertainment clothing electrical food_and_drink travel health_and_beauty home_and_garden office_and_business motor other online)
  SECONDARY_CATEGORY_KEYS = { :entertainment =>
                               ["cinema",
                               "theatre",
                               "sport_events",
                               "music_events",
                               "theme_parks",
                               "other"],
                              :clothing => ["mens", "womens", "kids", "jewellery", "shoes", "other"],
                              :electrical => ["mobile", "appliances", "computing", "other"],
                              :food_and_drink =>
                               ["fine_dining",
                               "every_day_dining",
                               "bars_and_pubs",
                               "wine_and_spirits",
                               "grocery"],
                              :kids =>
                               ["clothing",
                               "activities",
                               "toys_games_and_books",
                               "days_out",
                               "places_to_eat",
                               "babies",
                               "other"],
                              :travel =>
                               ["four_star_plus_hotels",
                               "hotels_other",
                               "bb_guest_houses",
                               "transport",
                               "package_holidays"],
                              :health_and_beauty =>
                               ["salons", "spas", "chemists", "fitness_centers", "other"],
                              :home_and_garden => ["diy", "home_services", "home_furnishings", "other"],
                              :office_and_business =>
                               ["office_stationery", "equipment_and_supplies", "professional_services"],
                              :motor => ["auto_rental", "vehicle_sales", "automotive_servicing_and_sales", "petrol"],
                              :other => ["books_and_periodicals", "general_merchandise"]}.with_indifferent_access

  #
  # === Audited
  #
  audited :initial_version => true

  #
  # === Encrypted Attributes
  #
  # see  http://github.com/shuber/attr_encrypted

  attr_encrypted_options.merge!(:key => AppConfig.attr_encrypted_secret, :unless => Rails.env.development? || Rails.env.staging? || Rails.env.nightly?)
  attr_encrypted :bank_account_number
  attr_encrypted :bank_routing_number
  attr_encrypted :federal_tax_id

  #
  # ==== Callbacks
  #
  before_validation :normalize_coupon_clipping_modes
  before_validation :remember_and_normalize_call_phone_number
  before_validation :normalize_urls
  before_validation :set_default_voice_response_code
  before_validation :normalize_txt_keyword_prefix
  before_validation_on_create :generate_label_from_name

  before_save :set_logo_dimensions

  before_destroy :ensure_no_daily_deal_purchases
  before_destroy :destroy_gift_certificates

  validates_presence_of :publisher
  validates_listing :unique_scope => :publisher_id

  validates_numericality_of :voice_response_code, :only_integer => true
  validates_format_of :call_phone_number, :if => :allow_call?, :with => /^1\d{10}$/
  validates_numericality_of :active_coupon_limit, :active_txt_coupon_limit, :greater_than_or_equal_to => 0, :only_integer => true, :allow_nil => true
  validates_uniqueness_of :txt_keyword_prefix, :scope => :publisher_id, :allow_blank => true
  validates_each :website_url, :google_map_url, :allow_blank => true do |record, attr, value|
    uri = URI.parse(value) rescue nil
    record.errors.add attr, "%{attribute} '#{value}' is not a valid HTTP or HTTPS URL" unless uri && (uri.scheme == "http" || uri.scheme == "https")
  end
  validates_each :coupon_clipping_modes, :unless => :new_record? do |record, attr, value|
    if value.include?(:txt) && record.offers.not_deleted.detect { |offer| offer.txt_message.blank? }
      record.errors.add attr, "%{attribute} can't include TXT unless all coupons have a TXT message"
    end
  end
  validates_email :email_address, :allow_blank => true
  validates_immutability_of :paid
  validates_presence_of :subscription_rate_schedule, :if => :paid
  validate :subscription_rate_schedule_belongs_to_publisher, :if => :paid
  validates_uniqueness_of :label, :scope => :publisher_id, :allow_blank => true
  validates_numericality_of :merchant_commission_percentage, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 99, :allow_nil => true, :allow_blank => true
  validates_numericality_of :revenue_share_percentage, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 100, :allow_nil => true, :allow_blank => true
  validates_inclusion_of :payment_type, :allow_nil => true, :allow_blank => true, :in => PAYMENT_TYPES
  validates_presence_of :federal_tax_id, :if => :require_federal_tax_id?
  validates_presence_of :description, :if => :publisher_has_google_offers_feed_enabled?
  validate :at_least_one_store_for_paychex_publisher
  validates_inclusion_of :size, :in => SIZES, :allow_blank => true
  validates_inclusion_of :primary_business_category, :in => PRIMARY_CATEGORY_KEYS, :allow_blank => true
  validate :primary_business_category_includes_secondary_business_cateogory
  
  validates_numericality_of :gross_annual_turnover, :allow_nil => :true
  validates_inclusion_of :registered_with_companies_house, :in => [true, false]
  validates_format_of :company_registration_number, :with => /^[A-Za-z0-9]+[A-Za-z0-9]*[A-Za-z0-9]+$/, :allow_blank => true
  validates_length_of :company_registration_number, :maximum => 20, :allow_blank => true

  default_value_for :name, ""

  named_scope :observable_by, lambda { |user| user.observable_advertisers_scope }
  named_scope :manageable_by, lambda { |user| user.manageable_advertisers_scope }

  named_scope :having_web_offers, :conditions => 'advertisers.id IN (SELECT DISTINCT advertiser_id FROM offers)'
  named_scope :having_txt_offers, :conditions => 'advertisers.id IN (SELECT DISTINCT advertiser_id FROM txt_offers)'
  named_scope :having_active_web_offers, lambda {
    date = Time.zone.now.to_date
    {
      :include => [:offers,:stores],
      :conditions => ["offers.showable AND (offers.show_on IS NULL OR :date >= offers.show_on) AND (offers.expires_on IS NULL OR :date <= offers.expires_on)", { :date => date }]
    }
  }

  named_scope :by_name, lambda {
    {
      :include => [:translations],
      :conditions => 'advertiser_translations.locale = "en"',
      :order    => "advertiser_translations.name asc"
    }
  }

  named_scope :by_most_recent_offers, :order => "offers.created_at desc"

  named_scope :in_zips, lambda { |zips| { :include => :store, :conditions => ["SUBSTR(stores.zip, 1, 5) in (?)", zips] }}
  named_scope :with_text, lambda { |text| {
    :include => [{:offers => :categories}, :translations],
    :conditions => ["(offers.message LIKE :text OR advertiser_translations.name LIKE :text OR categories.name LIKE :text)", {:text => "%#{text}%"}]
  }}
  named_scope :in_categories, lambda { |category_ids| {
    :include => {:offers => :categories},
    :conditions => ["(categories.id in (:category_ids) OR categories.parent_id in (:category_ids))", { :category_ids => category_ids }]
  }}

  named_scope :find_all_with_name_like, lambda { |name|
    {
      :conditions => ["name like ?", "%#{name}%"]
    }
  }


  def self.listing_from_parts(*parts)
    parts.map { |part| part.to_s.gsub(/[-\s]+/, "") }.join("-")
  end

  private

  def primary_business_category_includes_secondary_business_cateogory
    return unless secondary_business_category.present? && primary_business_category && 
      PRIMARY_CATEGORY_KEYS.include?(primary_business_category)
    if !SECONDARY_CATEGORY_KEYS[primary_business_category].include?(secondary_business_category)
      errors.add(:secondary_business_category, "must be a valid selection for the primary business category")
    end
  end

end
