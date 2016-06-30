class DailyDeal < ActiveRecord::Base

  MIN_QUANTITY_DEFAULT = 1
  MAX_QUANTITY_DEFAULT = 10

  include Report::DailyDeal
  include ActionView::Helpers::NumberHelper
  include ActsAsShareable
  include ActsAsBarCodeAssigner
  include DailyDeals::Syndicatable
  include DailyDeals::Map
  include HasPublisherDependentAttachments
  include HasPublisherThemeableTranslations
  include HasUuid
  include ThirdPartyDealsApi::DailyDeal
  include ActsAsSoftDeletable
  # include ThirdPartyBrandingFilter
  include DailyDeals::OffPlatform
  include DailyDeals::QrCode
  include DailyDeals::Yelp
  include DailyDeals::Fraud
  include DailyDeals::Core
  include DailyDeals::EmailBlast
  include DailyDeals::LoyaltyProgram
  include DailyDeals::PDF
  include DailyDeals::MultiVoucherDeals
  include DailyDeals::Variations
  include DailyDeals::SyndicationVariations
  include DailyDeals::Featured
  include DailyDeals::Travelsavers
  include DailyDeals::VariationsPricing
  include BarCodes::Import
  include HasPublisherThemeableTranslations
  include DailyDeals::Status
  include DailyDeals::Notes
  include DailyDeals::SourceChannel

  uuid_type :timestamp

  translates :value_proposition, :description, :value_proposition_subhead, :highlights,
    :terms, :reviews, :voucher_steps, :email_voucher_redemption_message,
    :twitter_status_text, :facebook_title_text, :short_description, :disclaimer,
    :redemption_page_description, :side_deal_value_proposition, :side_deal_value_proposition_subhead, :custom_1, :custom_2, :custom_3

  acts_as_textiled :description, :highlights, :terms, :reviews, :disclaimer, :redemption_page_description

  attr_writer :yelp_api_business_id

  #
  # === Associations
  #
  belongs_to  :advertiser
  belongs_to  :analytics_category, :class_name => "DailyDealCategory"
  belongs_to  :publishers_category, :class_name => "DailyDealCategory"
  has_many    :click_counts, :as => :clickable, :dependent => :destroy
  has_many    :daily_deal_purchases, :class_name => 'BaseDailyDealPurchase', :extend => DailyDeals::DailyDealPurchasesExtensions
  has_many    :non_voucher_daily_deal_purchases, :class_name => 'NonVoucherDailyDealPurchase', :extend => DailyDeals::DailyDealPurchasesExtensions

  belongs_to  :publisher
  has_many    :affiliate_placements, :as => :placeable
  has_many    :daily_deal_affiliate_redirects
  has_one     :platform_revenue_sharing_agreement, :as => :agreement, :class_name => "Accounting::PlatformRevenueSharingAgreement", :dependent => :destroy
  has_one     :syndication_revenue_sharing_agreement, :as => :agreement, :class_name => "Accounting::SyndicationRevenueSharingAgreement", :dependent => :destroy
  has_one     :syndication_revenue_split, :class_name => "DailyDeals::SyndicationRevenueSplit", :dependent => :destroy
  has_and_belongs_to_many :markets
  belongs_to :email_voucher_offer, :class_name => 'Offer'
  belongs_to  :yelp_business
  has_many :consumer_deal_relevancy_scores
  has_many :consumers, :through => :consumer_deal_relevancy_scores

  # strip_third_party_branding_from_fields :value_proposition, :value_proposition_subhead, :description, :short_description

  #
  # :rails_env_fallback interpolation defined in:
  #   config/initializers/paperclip.rb
  #
  has_attached_file :photo,
                    :bucket           => "photos.daily-deals.analoganalytics.com",
                    :s3_host_alias    => "photos.daily-deals.analoganalytics.com",
                    :path             => ":rails_env_fallback/:id/:style.:extension",
                    :default_style    => :standard,
                    :styles => publisher_dependent_attachment_styles(
                      :standard           => { :geometry => "319x319>", :format => :png },
                      :portrait           => { :geometry => "274x444>", :format => :png },
                      :facebook           => { :geometry => "130x110>", :format => :png },
                      :thumbnail          => { :geometry => "100x30>",  :format => :png },
                      :widget             => { :geometry => "112x112>", :format => :png },
                      :email              => { :geometry => "208x252>", :format => :png },
                      :blast              => { :geometry => "275x357!", :format => :png },
                      :alternate_standard => { :geometry => "385x320#", :format => :png },
                      :syndication        => { :geometry => "132x80#",  :format => :png },
                      :optimized          => { :geometry => "319x319>", :format => :jpg}
                    )

  has_attached_file :secondary_photo,
                    :bucket => "secondary-photos.daily-deals.analoganalytics.com",
                    :s3_host_alias => "secondary-photos.daily-deals.analoganalytics.com",
                    :path => ":rails_env_fallback/:id/:style.:extension",
                    :default_style => :standard,
                    :styles => publisher_dependent_attachment_styles(
                      :standard           => { :geometry => "319x319>", :format => :png },
                      :thumbnail          => { :geometry => "100x30>",  :format => :png },
                      :optimized          => { :geometry => "319x319>", :format => :jpg}
                    )

  #
  # == Validations
  #
  validates_presence_of     :advertiser
  validates_presence_of     :publisher
  validate                  :cobrand_deal_vouchers_must_be_nil, :if => :syndicated?
  validate                  :start_hide_expires_order
  validate                  :side_deal_schedule
  validate                  :one_featured_deal_at_a_time
  validate                  :advertiser_revenue_share_editable
  validates_numericality_of :price, :value, :allow_nil => false
  validates_numericality_of :price, :equal_to => 0, :if => :non_voucher_deal?
  validates_numericality_of :quantity, :only_integer => true, :greater_than => 0, :allow_nil => true

  validates_numericality_of :min_quantity, :only_integer => true, :allow_nil => false
  validates_numericality_of :min_quantity, :greater_than_or_equal_to => 0, :unless => :non_voucher_deal?
  validates_numericality_of :min_quantity, :equal_to => 1, :if => :non_voucher_deal?

  validates_numericality_of :max_quantity, :only_integer => true, :allow_nil => false
  validates_numericality_of :max_quantity, :greater_than => 0, :less_than_or_equal_to => 25, :unless => :non_voucher_deal?
  validates_numericality_of :max_quantity, :equal_to => 1, :if => :non_voucher_deal?

  validates_numericality_of :number_sold_display_threshold, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_presence_of     :description, :hide_at, :start_at, :terms, :value_proposition
  validates_presence_of     :analytics_category, :on => :save, :message => "%{attribute} can't be blank", :if => proc { |dd| dd.publisher.require_daily_deal_category? }
  validate                  :number_of_bar_codes_matches_quantity_times_voucher_multiple
  validate                  :short_description_acceptable
  validates_each            :location_required do |record, attr, value|
    record.errors.add attr, I18n.t("activerecord.errors.custom.cannot_be_set_if_fewer_than_two_stores") if value && record.advertiser && !record.advertiser.stores.many?
  end
  validates_numericality_of :advertiser_revenue_share_percentage, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100, :allow_nil => true
  validates_presence_of :advertiser_revenue_share_percentage, :if => :require_advertiser_revenue_share_percentage?
  validates_numericality_of :affiliate_revenue_share_percentage, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 100, :allow_nil => true
  validates_each :affiliate_url, :allow_blank => true do |record, attr, value|
    # we allow urls with %ref% and %sub% as valid
    # see /app/helpers/analog_analytics/referrer.rb method link_to_affiliate_url
    uri = URI.parse(value.gsub(/%.*?%/, '')) rescue nil
    record.errors.add attr, I18n.t("activerecord.errors.custom.not_valid_http_or_https_url", :value => value) unless uri && (uri.scheme == "http" || uri.scheme == "https")
  end
  validates_format_of :campaign_code, :with => /^[A-Za-z0-9]+[A-Za-z0-9]*[A-Za-z0-9]+$/, :allow_blank => true
  validates_uniqueness_of :campaign_code, :allow_blank => true

  validate                  :analytics_category_is_allowed
  validate                  :publishers_category_is_allowed
  validate                  :markets_belong_to_this_deals_publisher

  default_value_for :enable_publisher_tracking, :true

  named_scope :in_order, :order => "start_at ASC"
  named_scope :most_to_least_current, :order => "start_at DESC"
  named_scope :featured_during_lifespan, :conditions => "(side_start_at IS NULL AND side_end_at IS NULL) OR (side_start_at != start_at OR side_end_at != hide_at )"
  named_scope :featured, lambda {
    { :conditions => [%Q{daily_deals.deleted_at IS NULL AND
                        start_at <= :now AND
                        hide_at > :now AND
                        ((side_start_at IS NULL AND side_end_at IS NULL) OR
                          (:now NOT BETWEEN side_start_at AND side_end_at))
                      }, { :now => Time.zone.now } ] }
  }
  named_scope :featured_at, lambda { |time|
    { :conditions => [%Q{daily_deals.deleted_at IS NULL AND
                        start_at <= :time AND
                        hide_at > :time AND
                        ((side_start_at IS NULL AND side_end_at IS NULL) OR
                          (:time NOT BETWEEN side_start_at AND side_end_at))
                      }, { :time => time } ] }
  }

  named_scope :side_during_lifespan, :conditions => "side_start_at IS NOT NULL AND side_end_at IS NOT NULL"
  named_scope :side, lambda {
    { :conditions => [%Q{daily_deals.deleted_at IS NULL AND
                        start_at <= :now AND
                        hide_at > :now AND
                        side_start_at IS NOT NULL AND side_end_at IS NOT NULL AND
                        :now BETWEEN side_start_at AND side_end_at
                      }, { :now => Time.zone.now } ] }
  }
  named_scope :filtered_for_entercom, lambda { |deal_to_exclude|
    deal_filter = deal_to_exclude.present? ? ("daily_deals.id != %d AND" % deal_to_exclude.id) : ""
    { :select => "daily_deals.*, ddc.name AS publisher_category_name",
      :conditions => [
      %Q{
        #{deal_filter}
        (
          (ddc.name IN (
            'Deal 1', 'Deal 2', 'Deal 3', 'Deal 4', 'Deal 5',
            'Deal 6', 'Deal 7', 'Deal 8', 'Deal 9', 'Deal 10',
            'Syndicated')
          )
          OR (
            daily_deals.source_id IS NULL AND daily_deals.publishers_category_id IS NULL
          )
        )
      }],
      :joins => "LEFT JOIN daily_deal_categories ddc ON daily_deals.publishers_category_id = ddc.id",
      :order => "(CASE WHEN publisher_category_name LIKE 'Deal%' THEN 1 WHEN publisher_category_name IS NULL THEN 2 WHEN publisher_category_name = 'Syndicated' THEN 3 END) ASC, LENGTH(publisher_category_name) ASC, publisher_category_name ASC, daily_deals.start_at DESC" }
  }
  named_scope :in_custom_wcax_order, :order => %Q{
    CASE
      WHEN daily_deals.publishers_category_id IS NOT NULL THEN 1
      WHEN daily_deals.source_id IS NOT NULL THEN 2
      WHEN daily_deals.publishers_category_id IS NULL THEN 3
    END ASC, daily_deals.publishers_category_id ASC, daily_deals.id
  }

  named_scope :show_on_landing_page, :conditions => "show_on_landing_page IS true"

  named_scope :ordered_by_next_featured_in_category, :order => "featured_in_category DESC, start_at ASC"

  named_scope :ended_between, lambda { |dates|
    { :conditions => ["hide_at BETWEEN :begin AND :end", { :begin => dates.begin, :end => dates.end }] }
  }

  named_scope :active, lambda {
    { :conditions => ["daily_deals.deleted_at IS NULL AND start_at <= :now AND hide_at > :now", { :now => Time.zone.now } ] }
  }

  named_scope :active_and_recently_finished, lambda {
    { :conditions => ["daily_deals.deleted_at IS NULL AND start_at <= :now AND hide_at >= :two_weeks_ago", { :now => Time.zone.now, :two_weeks_ago => 2.weeks.ago }] }
  }

  named_scope :order_by_finishing_soon_then_most_recently_finished, lambda {
    { :order => "IF(hide_at <= NOW(), 1, 0) ASC, IF(hide_at <= NOW(), -UNIX_TIMESTAMP(hide_at), UNIX_TIMESTAMP(hide_at)) ASC" }
  }

  named_scope :active_at, lambda { |time|
    { :conditions => ["daily_deals.deleted_at IS NULL AND start_at <= :time AND hide_at > :time", { :time => time } ] }
  }

  named_scope :active_before, lambda { |time|
    { :conditions => ["daily_deals.deleted_at IS NULL AND start_at <= :time", { :time => time } ] }
  }

  named_scope :active_tomorrow, lambda {
    { :conditions => ["daily_deals.deleted_at IS NULL AND start_at <= :tomorrow AND hide_at > :tomorrow", { :tomorrow => Time.zone.now.tomorrow } ] }
  }

  named_scope :active_or_qr_code_active, lambda {
    { :conditions => ["daily_deals.deleted_at IS NULL AND (qr_code_active OR (start_at <= :now AND hide_at > :now))", { :now => Time.zone.now } ] }
  }

  named_scope :starting_in_future, lambda {
    { :conditions => ["daily_deals.deleted_at IS NULL AND start_at > :now", { :now => Time.zone.now } ], :order => "start_at ASC" }
  }

  named_scope :active_between, lambda { |dates|
    sql = "daily_deals.deleted_at IS NULL AND ((start_at BETWEEN :bod AND :eod) OR (hide_at BETWEEN :bod AND :eod) OR (start_at <= :bod AND hide_at >= :eod))"
    { :conditions => [sql, { :bod => dates.first.beginning_of_day, :eod => dates.last.end_of_day }] }
  }

  named_scope :started_in_last_24_hours, lambda {
    { :conditions => ["daily_deals.deleted_at IS NULL and start_at BETWEEN :begin and :end", { :begin => Time.zone.now - 24.hours, :end => Time.zone.now}] }
  }

  named_scope :starting_on, lambda { |date|
    {
      :conditions => ["start_at BETWEEN :bod and :eod", {:bod => date.beginning_of_day, :eod => date.end_of_day}]
    }
  }

  named_scope :ending_on, lambda { |date|
    {
      :conditions => ["hide_at BETWEEN :bod and :eod", {:bod => date.beginning_of_day, :eod => date.end_of_day}]
    }
  }
  named_scope :ending_after, lambda { |time|
    {
      :conditions => ["hide_at > :time", {:time => time}]
    }
  }

  named_scope :ordered_by_start_at_ascending, :order => "start_at ASC"
  named_scope :ordered_by_start_at_descending, :order => "start_at DESC"
  named_scope :ordered_by_price_ascending, :order => "price ASC"
  named_scope :ordered_by_price_descending, :order => "price DESC"

  named_scope :upcoming, lambda {
    { :conditions => ["upcoming is true AND start_at > :now AND daily_deals.deleted_at IS NULL", { :now => Time.zone.now } ], :order => "start_at ASC" }
  }

  named_scope :in_categories, lambda { |category_ids| {
    :conditions => ["daily_deals.analytics_category_id in (:category_ids)", { :category_ids => category_ids }]
   }
  }

  named_scope :in_publishers_categories, lambda { |publishers_category_ids| {
    :conditions => ["daily_deals.publishers_category_id in (?)", publishers_category_ids]
  }}

  named_scope :with_publishers_category_name, lambda { |publishers_category_name| {
    :include => [ :publishers_category ],
    :conditions => [ "daily_deal_categories.name = ?", publishers_category_name ]
  }}

  named_scope :national_deals, :conditions => {:national_deal => true}

  named_scope :shopping_mall_or_featured, lambda {
    now = Time.zone.now
    { :select => "*, (daily_deals.deleted_at IS NULL AND start_at <= '#{now}' AND hide_at > '#{now}' AND ((side_start_at IS NULL AND side_end_at IS NULL) OR ('#{now}' NOT BETWEEN side_start_at AND side_end_at))) as featured_now",
      :conditions => "((side_start_at IS NULL AND side_end_at IS NULL) OR (side_start_at != start_at OR side_end_at != hide_at)) OR daily_deals.shopping_mall IS TRUE",
      :order => "featured_now DESC, daily_deals.created_at DESC" }
  }

  named_scope :shopping_mall, :conditions => "daily_deals.shopping_mall IS TRUE"
  named_scope :not_shopping_mall, :conditions => "daily_deals.shopping_mall is false"

  named_scope :in_zips, lambda { |zips| {
    :include => { :advertiser => :stores },
    :conditions => ["SUBSTR(stores.zip, 1, 5) in (?)", zips] }
  }

  named_scope :with_text, lambda { |text| {
    :include => [:analytics_category, :publishers_category, :advertiser, {:advertiser => :translations}, :translations],
    :conditions => ["(daily_deal_translations.description LIKE :text OR daily_deal_translations.value_proposition LIKE :text OR advertiser_translations.name LIKE :text OR daily_deal_categories.name LIKE :text)", {:text => "%#{text}%"}]
    }
  }

  named_scope :for_publisher, lambda { |publisher| {
    :include => :publisher,
    :conditions => ["publishers.id = ?", publisher]
    }
  }

  named_scope :in_market, lambda { | market | {
    :include => [:markets],
    :joins => "inner join daily_deals_markets ddm on daily_deals.id = ddm.daily_deal_id inner join markets m on ddm.market_id = m.id",
    :conditions => [ "ddm.market_id = :market_id", { :market_id => market.id } ] }
  }

  named_scope :without_market, lambda {
    { :include => [:markets],
      :joins => "left outer join daily_deals_markets ddm on daily_deals.id = ddm.daily_deal_id left outer join markets m on ddm.market_id = m.id",
      :conditions => [ "ddm.market_id is null" ] }
  }

  named_scope :national_or_within_zip_radius, lambda { |zip_code, radius|
    conditions = ["national_deal = TRUE"]
    substitutions = {}

    zip_codes = ZipCode.zips_near_zip_and_radius(zip_code, radius) if zip_code.present?

    if zip_codes.present?
      conditions << "SUBSTR(stores.zip, 1, 5) IN (:zips)"
      substitutions[:zips] = zip_codes
    end

    { :conditions => [conditions.join(' OR '), substitutions], :include => {:advertiser => :stores} }
  }

  named_scope :current_or_future, lambda {
    { :conditions => [ "hide_at >= :now", { :now => Time.now.utc } ] }
  }

  named_scope :location_not_required, lambda {
    { :conditions => "location_required IS NULL OR location_required != 1" }
  }

  named_scope :include_advertiser, lambda { {:include => {:advertiser => {:stores => :country}}} }
  named_scope :include_publisher, lambda { {:include => [:publisher]} }

  named_scope :to_notify_consumers, :conditions => "push_notifications_sent_at IS NULL"

  named_scope :not_in, lambda { |daily_deals|
    if daily_deals.present?
      {:conditions => ["id NOT IN (?)", daily_deals.map(&:id)]}
    else
      {}
    end
  }

  named_scope :limit, lambda { |limit| { :limit => limit } }
  named_scope :offset, lambda { |offset| { :offset => offset } }

  named_scope :by_relevancy_score,
              :include => :consumer_deal_relevancy_scores,
              :order => "consumer_deal_relevancy_scores.relevancy_score desc"

  #
  # === Delegation
  #
  delegate :address, :formatted_phone_number, :website_url, :multi_location?, :to => :advertiser
  delegate :currency_code, :currency_symbol, :now, :publishing_group, :to => :publisher
  delegate :in_syndication_network?, :to => :publisher, :allow_nil => true

  #
  # === Callbacks
  #
  before_validation :assign_publisher_from_advertiser
  before_validation :set_defaults_for_defaultable_columns_that_are_nil
  before_validation :update_syndicated_deal_attributes # pulled from module due to order dependency
  before_validation :set_yelp_business
  after_create :generate_default_listing
  before_destroy :ensure_no_daily_deal_purchases
  before_validation_on_create :unfeature_deal_if_overlapping_featured_deal, :if => :syndicated?

  #
  # === Versioning
  #
  VERSIONED_COLUMNS = [ :price, :advertiser_revenue_share_percentage, :deleted_at ]
  audited :only => VERSIONED_COLUMNS

  NUMBER_SOLD_DISPLAY_THRESHOLD_LARGE_FAILSAFE_VALUE = 5000

  def self.build_with_defaults(advertiser)
    advertiser.daily_deals.build(
        :publisher => advertiser.publisher,
        :voucher_steps => advertiser.publisher.default_voucher_steps(advertiser.name),
        :email_voucher_redemption_message => DailyDeal.default_email_voucher_redemption_message(advertiser),
        :terms => advertiser.publisher.default_terms,
        :number_sold_display_threshold => (advertiser.publisher.number_sold_display_threshold_default || NUMBER_SOLD_DISPLAY_THRESHOLD_LARGE_FAILSAFE_VALUE))
  end

  # Old comment when this was in after_initialize:
  # "doing this in after_initialize to make sure we (have?) voucher steps
  # in daily deals that have already been created, instead of
  # assigning in a migration."
  # Moved it out for performance reasons and calling it in only one place, daily deal importer (and in a few tests)
  def assign_defaults
    assign_initial_voucher_steps
    assign_initial_email_voucher_redemption_message
  end

  def self.default_email_voucher_redemption_message(advertiser)
    Analog::Themes::I18n.t(advertiser.try(:publisher), "daily_deal.default_email_voucher_redemption_message", :advertiser_name => advertiser.try(:name))
  end

  # returns the current deal or the previous deal (if there is one)
  def self.current_or_previous
    deal = DailyDeal.active.featured.ordered_by_start_at_descending.first # current, currently featured
    deal = DailyDeal.active.featured_during_lifespan.ordered_by_start_at_descending.first unless deal.present? #current, featured sometime
    deal = DailyDeal.active_before(Time.zone.now).featured_during_lifespan.ordered_by_start_at_descending.first unless deal.present? #inactive, previously featured
    deal
  end

  def self.todays
    now = Time.zone.now
    deals_active_today = "deleted_at IS NULL AND start_at < :end_of_day AND hide_at > :beginning_of_day"
    deals_with_no_side_deal_window = "(side_start_at IS NULL AND side_end_at IS NULL)"
    deals_featured_part_of_the_day = "(side_start_at BETWEEN :beginning_of_day AND :end_of_day OR side_end_at BETWEEN :beginning_of_day AND :end_of_day)"
    deals_that_are_side_in_the_future = "(side_start_at > :end_of_day AND side_end_at > :end_of_day)"
    deals_that_were_side_in_the_past = "(side_start_at < :beginning_of_day AND side_end_at < :beginning_of_day)"

    conditions = %Q{
      #{deals_active_today} AND
      (#{deals_with_no_side_deal_window} OR
        #{deals_featured_part_of_the_day} OR
        #{deals_that_are_side_in_the_future} OR
        #{deals_that_were_side_in_the_past})
    }
    find(:all, :conditions => [ conditions, { :end_of_day => now.end_of_day, :beginning_of_day => now.beginning_of_day }],
                :order => "start_at")
  end

  def self.today
    todays.first
  end

  # warning: this method will not include deals that are running tomorrow but were started earlier.
  def self.tomorrow
    tomorrow = Time.zone.now.tomorrow
    deals_starting_tomorrow = "deleted_at IS NULL AND start_at BETWEEN :tomorrow_beginning_of_the_day AND :tomorrow_end_of_the_day"
    deals_with_no_side_deal_window = "(side_start_at IS NULL AND side_end_at IS NULL)"
    deals_starting_side_turning_featured = "(side_start_at = start_at AND side_end_at != hide_at AND side_end_at BETWEEN :tomorrow_beginning_of_the_day AND :tomorrow_end_of_the_day)"
    deals_featured_part_of_the_day = "(side_start_at != start_at AND (side_start_at BETWEEN :tomorrow_beginning_of_the_day AND :tomorrow_end_of_the_day OR side_end_at BETWEEN :tomorrow_beginning_of_the_day AND :tomorrow_end_of_the_day))"

    conditions = %Q{
      #{deals_starting_tomorrow} AND (
        #{deals_with_no_side_deal_window} OR
        #{deals_starting_side_turning_featured} OR
        #{deals_featured_part_of_the_day}
      )
    }

    find(:first, :conditions => [conditions, {
        :tomorrow_beginning_of_the_day => tomorrow.beginning_of_day,
        :tomorrow_end_of_the_day => tomorrow.end_of_day
    }])
  end

  # Should drop to SQL for efficiency
  def self.past(publisher, number_sold = 10)
    DailyDeal.find(
      :all,
      :include => :daily_deal_purchases,
      :conditions => [ "deleted_at IS NULL AND publisher_id = ? and hide_at < ?", publisher.id, Time.zone.now ],
      :order => "hide_at desc"
    ).sort_by(&:number_sold).select { |dd| dd.number_sold >= number_sold }.reverse[0, 12]
  end

  def line_item_name
    if publisher.enable_daily_deal_voucher_headline? && voucher_headline.present?
      voucher_headline
    else
      translate_with_theme(:line_item_name, :value => number_to_currency(value, :unit => publisher.currency_symbol), :advertiser => advertiser_name.strip)
    end
  end

  def advertiser_name
    advertiser.try(:name).to_s
  end

  def category_name
    analytics_category.try(:name).to_s
  end

  def advertiser_logo_url
    advertiser.try(:logo).url
  rescue
    ""
  end

  def sanitized_website_url
    (website_url.to_s.strip.gsub(/\Ahttps?:\/\//, "").split("/").first || "").downcase
  end

  def cobrand_deal_vouchers
    syndicated? ? source.cobrand_deal_vouchers : read_attribute(:cobrand_deal_vouchers)
  end

  def cobrand_deal_vouchers?
    cobrand_deal_vouchers == true
  end

  def bar_code_encoding_format
    source.try(:bar_code_encoding_format) || self[:bar_code_encoding_format]
  end

  def savings
    value - price
  end

  def savings_as_percentage
    return 0 if value == 0
    (savings / value) * 100
  end

  def with_publisher_logo(type=nil, &block)
    publisher.try(:with_logo, type, &block)
  end

  def with_syndicated_publisher_logo(type=nil, &block)
    unless syndicated?
      logger.warn "called with_syndicated_publisher_logo on a deal that is not syndicated"
      return
    end
    source.publisher.try(:with_logo, type, &block)
  end

  def humanize_value
    number_to_currency(value, :unit => currency_symbol)
  end

  def humanize_price
    number_to_currency(price, :unit => currency_symbol)
  end

  def humanize_start_at
    humanize_date(start_at)
  end

  def humanize_hide_at
    humanize_date(hide_at)
  end

  def humanize_side_start_at
    humanize_date(side_start_at)
  end

  def humanize_side_end_at
    humanize_date(side_end_at)
  end

  def humanize_expires_on
    I18n.localize(expires_on.to_date, :format => :long) if expires_on
  end

  def start_at_date_only
    start_at.present? ? start_at.to_s(:compact_date_only) : ""
  end

  def hide_at_date_only
    hide_at.present? ? hide_at.to_s(:compact_date_only) : ""
  end

  def active?
    !deleted_at && start_at <= Time.zone.now && Time.zone.now < hide_at
  end

  def active_now_or_in_future?
    !deleted_at && Time.zone.now < hide_at
  end

  def sold_out?
    sold_out_at.present? ||
    sold_out_via_third_party? ||
    sold_out_without_sold_out_at?
  end

  def sold_out_without_sold_out_at?
    #!quantity.present? means there is no limit on the number of deals that
    #can be sold
    unless has_variations?
      if !quantity.present?
        false
      elsif (quantity - number_sold_including_syndicated) <= 0
        true
      else
        false
      end
    else
      !daily_deal_variations.collect(&:sold_out?).include?(false)
    end
  end

  def sold_out!(force = false)
    if sold_out_at.blank? && (force || sold_out_without_sold_out_at?)
      update_attributes! :sold_out_at => Time.zone.now
      after_sold_out_hook
    end
  end

  alias_method :is_sold_out, :sold_out?

  def available?
    active? && !sold_out?
  end

  def ended?
    !deleted_at && hide_at < Time.zone.now
  end

  def over?
    ended? || sold_out?
  end

  def expires_on_iso8601
    Time.zone.parse(expires_on.to_s).end_of_day.iso8601 if expires?
  end

  def expires?
    expires_on.present?
  end

  def expired?
    expires_on.present? && Time.zone.parse(expires_on.to_s) < Time.zone.now
  end

  def push_notifications_sent!
    update_attributes!(:push_notifications_sent_at => Time.zone.now)
  end

  def number_left
    if quantity
      quantity - number_sold
    end
  end

  # if we have a hide at time, then we return the millisecond
  # representation of that time, otherwise we return -1
  def ending_time_in_milliseconds
    hide_at.present? ? hide_at.to_i * 1000 : -1
  end

  def utc_ending_time_in_milliseconds
    hide_at.present? ? hide_at.utc.to_i * 1000 : -1
  end

  def starting_time_in_milleconds
    start_at.present? ? start_at.to_i * 1000 : -1
  end

  def utc_starting_time_in_milliseconds
    start_at.present? ? start_at.utc.to_i * 1000 : -1
  end

  alias_method :starting_time_in_millseconds, :starting_time_in_milleconds

  def duration_in_hours
    if start_at && hide_at
      milliseconds = hide_at - start_at
      (milliseconds / 60 / 60).to_i
    end
  end

  def url_for_bit_ly
    "http://#{publisher.daily_deal_host}/daily_deals/#{id}"
  end

  alias :uri :url_for_bit_ly

  def message
    value_proposition
  end

  def publisher_prefix
    publisher.daily_deal_email_subject
  end

  def twitter_publisher_prefix
    publisher.daily_deal_twitter_message_prefix.to_s.strip.if_present || publisher_prefix
  end

  def facebook_title
    title = facebook_title_text.if_present || message.strip
    "#{publisher_prefix}: #{title}"
  end

  def facebook_description
    concat = lambda { |array, separator| array.map { |item| item.to_s.strip.sub(/\.$/, '') }.select(&:present?).join(separator) }
    result = concat.call([concat.call([advertiser_name, advertiser.tagline], ": "), message, terms(:plain)], "; ").gsub(/([^.!])$/, '\1.')
    result.html_safe
  end

  def max_facebook_title_text_size
    118 - publisher_prefix.size
  end

  def twitter_status(with_bitly = true)
    status  = twitter_status_text.if_present || "#{message.strip} at #{advertiser.name.try(:strip)}"
    message = "#{twitter_publisher_prefix}: #{status}"
    message += " #{bit_ly_url}" if with_bitly
    message
  end

  def max_twitter_status_text_size
    117 - publisher_prefix.size
  end

  # mode: twitter, facebook
  def record_click(mode)
    ClickCount.record self, publisher_id, mode
  end

  def facebook_clicks
    click_counts.facebook.sum(:count)
  end

  def twitter_clicks
    click_counts.twitter.sum(:count)
  end

  def mail_to
    "body=#{mail_to_body}&subject=#{mail_to_subject}"
  end

  def mail_to_subject
    "#{publisher_prefix}: #{value_proposition}"
  end

  # %0D%0A forces line breaks for the email body (we have 2 below)
  # see: http://tipicalcharlie.blog-city.com/forcing_a_line_break_in_an_html_email_link.htm
  def mail_to_body
    "#{bit_ly_url}%0D%0A%0D%0A#{description(:plain)}"
  end

  def cobrand_deal_vouchers_must_be_nil
    errors.add(:cobrand_deal_vouchers, "%{attribute} must be nil for syndicated deals") if syndicated? && !read_attribute(:cobrand_deal_vouchers).nil?
  end

  def start_hide_expires_order
    if start_at && hide_at && start_at >= hide_at
      errors.add :hide_at, "Hide at must be after start at"
    end

    if start_at && expires_on && start_at.utc >= Time.zone.parse(expires_on.to_s).utc
      errors.add :expires_on, "Expires on must be after start at"
    end

    if hide_at && expires_on && hide_at.utc >= Time.zone.parse(expires_on.to_s).utc
      errors.add :expires_on, "Expires on must be after hide at"
    end
  end

  def one_featured_deal_at_a_time
    if featured_during_lifespan? && start_at && hide_at && hide_at >= Time.zone.now && publisher
      overlapping_deal = featured_deal_overlapping_with_publisher
      if overlapping_deal
        errors.add(:base, I18n.t("activerecord.errors.custom.overlapping_featured_deal",
                                 :deal_id => overlapping_deal.id,
                                 :publisher_name => overlapping_deal.publisher.name,
                                 :start_at => overlapping_deal.start_at.to_s(:long_ordinal),
                                 :hide_at => overlapping_deal.hide_at.to_s(:long_ordinal)))
      end
    end
  end

  def featured_deal_overlapping_with_publisher
    conditions_hash = { :now => Time.zone.now, :start_at => start_at, :hide_at => hide_at, :id => id }

    if markets.empty?
      market_clause = "(daily_deals_markets.market_id is null)"
    else
      market_clause = "(daily_deals_markets.market_id IN (:market_ids))"
      conditions_hash.merge! :market_ids => markets.map(&:id)
    end

    conditions = %Q{
                    hide_at >= :now and
                    (start_at between :start_at and :hide_at
                      or hide_at between :start_at and :hide_at
                      or :start_at between start_at and hide_at
                      or :hide_at between start_at and hide_at) and
                    (:id is null or daily_deals.id != :id) and
                    #{market_clause} and
                    deleted_at is null
               }

    overlapping_deals = publisher.daily_deals.find(:all, :conditions => [conditions, conditions_hash ], :include => [:markets])

    overlapping_deals.each do |deal|
      self.featured_date_ranges.each do |self_range|
        deal.featured_date_ranges.each do |other_range|
          return deal if date_ranges_overlap(self_range, other_range)
        end
      end
    end
    nil
   end

  def starts_at_localized
    self.publisher.localize_time(self.starts_at)
  end

  def sold_out_at_localized
    publisher.localize_time(sold_out_at)
  end

  def time_remaining_display
    if over?
      "00:00:00"
    elsif active?
      remaining = time_remaining
      days  = (remaining/86400000).to_i
      hours = ((remaining % 86400000) / 3600000).to_i + (days*24)
      mins  = ((remaining % 3600000) / 60000).to_i
      secs  = ((remaining % 60000) / 1000).to_i
      "#{pad(hours)}:#{pad(mins)}:#{pad(secs)}"
    else
      "--:--:--"
    end
  end

  def time_remaining_text_display
    if over?
      "Deal Over"
    elsif active?
      remaining = time_remaining
      days  = (remaining/86400000).floor
      hours = (remaining/3600000).floor
      mins  = ((remaining % 3600000)/60000).floor
      secs  = ((remaining % 60000)/1000).round
      if(hours >= 48)
        return days.to_s << " days"
      elsif (hours >= 24 && hours < 48)
        return days.to_s << " day"
      elsif (hours > 1 && hours < 24)
        return hours.to_s << " hours"
      elsif (hours == 1)
        return hours.to_s << " hour"
      elsif (hours == 0 && mins >= 1)
        return mins == 1 ? mins.to_s << " min" : mins.to_s << " mins"
      elsif (mins == 0 && secs > 0)
        return "0 mins"
      else
        return "Deal Over"
      end
    else
      "Deal Over"
    end
  end

  def time_remaining
    (hide_at - Time.zone.now) * 1000;
  end

  def email_blast_subject
    if short_description.present?
      short_description.squeeze(" ")
    end
  end

  def item_code
    "BBD-#{id}"
  end

  def to_liquid
    Drop::DailyDeal.new(self)
  end

  #We overrode as_json and our version doesn't support :only, :except and :method options.
  #It also forces everything to use the same json whne all fields might not be needed.
  #I am aliasing overridden as_json method and reating a method to be called for syndication
  #calendar view until we can come back and refactor.
  alias_method :default_as_json, :as_json

  def as_json_with_options(options={})
    HashWithIndifferentAccess.new(default_as_json(options))
  end

  #:link is Daily Deal URL. Needs to be passed in from the controller.
  def as_json(options={})
    {
      :daily_deal => {
        :advertiser_name                    => advertiser_name,
        :advertiser_logo_url                => advertiser_logo_url,
        :ending_time_in_milliseconds        => ending_time_in_milliseconds,
        :utc_end_time_in_milliseconds       => utc_ending_time_in_milliseconds,
        :utc_start_time_in_milliseconds     => utc_starting_time_in_milliseconds,
        :id                                 => id,
        :image                              => photo.try(:file?) ? photo.url(:widget) : nil,
        :is_sold_out                        => is_sold_out,
        :link                               => options[:link],
        :number_sold                        => number_sold,
        :total_available                    => quantity,
        :title                              => value_proposition,
        :publisher_host                     => publisher.host,
        :time_zone                          => publisher.time_zone.to_s
      }
    }
  end

  def side_deals(options = {}, &optional_sort_by_block)
    active_deals = if options[:in_shopping_mall]
      publisher.daily_deals.shopping_mall_or_featured.active.include_publisher.include_advertiser
    else
      publisher.daily_deals.active.include_publisher.include_advertiser
    end
    deals = markets.empty? ? active_deals : active_deals.in_market(markets.first) # Debt -- Assuming one market in a HABTM

    if block_given?
      deals = deals.sort_by(&optional_sort_by_block)
    else
      deals = deals.sort_by {|d| d.created_at}.reverse
    end
    Array.wrap(deals.to_a.reject { |dd| dd == self })
  end


  def side_deals_in_custom_entercom_order
    publisher.side_deals_in_custom_entercom_order(self)
  end

  def assign_publisher_from_advertiser
    self.publisher ||= self.advertiser.publisher unless self.advertiser.nil?
  end

  def set_defaults_for_defaultable_columns_that_are_nil
    self.min_quantity       ||= MIN_QUANTITY_DEFAULT
    self.max_quantity       =   max_quantity
    self.enable_daily_email_blast =   false        if self.enable_daily_email_blast.nil?
    self.upcoming           =   false        if self.upcoming.nil?
    self.affiliate_url      =   nil          if self.affiliate_url && self.affiliate_url.empty?

    # callbacks must return true
    true
  end

  # NULL default would be better than 0, but MySQL won't allow
  def max_quantity
    if self[:max_quantity].blank? || self[:max_quantity] == 0
      publisher.try(:publishing_group).try(:max_quantity_default) || MAX_QUANTITY_DEFAULT
    else
      self[:max_quantity]
    end
  end

  def pad(value)
    value <= 9 ? "0#{value}" : value;
  end

  def generate_default_listing
    self.listing = item_code unless listing.present?
  end

  def short_description_acceptable
    if publisher.try(:require_daily_deal_short_description) && !syndicated? && short_description.blank?
        errors.add(:short_description, "%{attribute} cannot have blank content")
    end
    unless publisher.try(:ignore_daily_deal_short_description_size)
      if email_blast_subject.present? && (extra = email_blast_subject.length - 50) > 0
        errors.add(:short_description, "%{attribute} content is too long by #{extra} characters")
      end
    end
  end

  def ensure_no_daily_deal_purchases
    if daily_deal_purchases(true).present?
      errors.add "Can't delete with daily deal purchases"
      return false
    end
    true
  end

  def analytics_category_is_allowed
    if publisher && analytics_category && !DailyDealCategory.analytics.include?(analytics_category)
      errors.add :analytics_category, "%{attribute} must be an allowed category: #{DailyDealCategory.analytics.map(&:name).join(", ")}"
    end
  end

  def publishers_category_is_allowed
    if publisher && publishers_category
      if publisher.enable_publisher_daily_deal_categories?
        unless publisher.allowable_daily_deal_categories.include?(publishers_category)
          errors.add :publishers_category, "%{attribute} must be an allowed category: #{publisher.allowable_daily_deal_categories.map(&:name).join(", ")}"
        end
      else
        errors.add :publishers_category, "%{attribute} must enable publisher daily deal categories on the publisher."
      end
    end
  end

  def assign_initial_voucher_steps
    #
    # NOTE: had to use self.attributes["voucher_steps"] instead of self.voucher_steps,
    # due to issue with associations and after_initialize.
    #
    # see: http://blog.edseek.com/archives/2009/04/16/missingattributeerror-from-within-after_initialize/
    #
    unless self.attributes["voucher_steps"].present? || publisher.blank?
      advertiser_name = advertiser ? advertiser.name : nil
      self.voucher_steps = publisher.default_voucher_steps(advertiser_name)
    else
      # TODO: make advertiser#voucher_steps maybe? this is to avoid a nil returning
      self.voucher_steps = ""
    end
  end

  def assign_initial_email_voucher_redemption_message
    #
    # NOTE: had to use self.attributes["voucher_steps"] instead of self.voucher_steps,
    # due to issue with associations and after_initialize.
    #
    # see: http://blog.edseek.com/archives/2009/04/16/missingattributeerror-from-within-after_initialize/
    #
    unless self.attributes["email_voucher_redemption_message"].present?
      self.email_voucher_redemption_message = DailyDeal.default_email_voucher_redemption_message(advertiser)
    end
  end

  def advertiser_revenue_share_editable
    return true if publisher.nil? or
                   self.advertiser_revenue_share_percentage.nil? or
                   ( !User.current.nil? and !User.current.has_admin_privilege? )

    unless publisher.allow_admins_to_edit_advertiser_revenue_share_percentage
      errors.add :advertiser_revenue_share_percentage,
        "%{attribute} is not editable by Admin due to publisher settings"
    end
  end

  def markets_belong_to_this_deals_publisher
    return if markets.blank?
    markets.each do |market|
      errors.add :markets, "market #{market} does not belong to publisher #{publisher.label}" unless publisher == market.publisher
    end
  end

  def require_advertiser_revenue_share_percentage?
    publisher.try(:require_advertiser_revenue_share_percentage?) || source_publisher_uses_paychex?
  end

  def source_publisher_uses_paychex?
    syndicated? ? source.publisher.uses_paychex? : publisher.try(:uses_paychex?)
  end

  def to_s
    "#<#{self.class.to_s} (#{id || 'nil'}): #{value_proposition.present? ? value_proposition[0..70] : 'untitled'} #{start_at} #{hide_at}>"
  end

  def market_belongs_to_daily_deal?(market_id)
    if market_id.present?
      self.market_ids.include?(market_id)
    else
      true
    end
  end

  def unfeature_deal_if_overlapping_featured_deal
    if syndicated? && featured_deal_overlapping_with_publisher.present?
      self.featured = false
    end
    true
  end

  def parent_syndication_revenue_sharing_agreement
    agreement = publisher.syndication_revenue_sharing_agreements.current
    unless agreement.present?
      publishing_group = publisher.publishing_group
      agreement = publishing_group.syndication_revenue_sharing_agreements.current if publishing_group.present?
    end
    agreement
  end

  def affiliate_url
    affiliate_url = read_attribute(:affiliate_url)
    affiliate_url.gsub("%publisher_label%", publisher.label) if affiliate_url
  end

  def featured=(true_or_false)
    true_or_false_string = true_or_false.to_s
    (true_or_false_string == "true" || true_or_false_string == "1") ? feature! : unfeature!
  end

  def featured?
    return false if start_at.nil? || hide_at.nil?
    (active? && (featured_for_entire_lifespan? || !side?))
  end

  alias_method :featured, :featured?

  def side?
    ((side_start_at.present? && side_end_at.present?) &&
        (side_start_at <= Time.zone.now && side_end_at > Time.zone.now))
  end

  def featured_during_lifespan?
    return false if deleted_at
    return true if side_start_at.nil? && side_end_at.nil?
    return true if side_start_at != start_at || side_end_at != hide_at
    false
  end

  def featured_date_ranges
    return [] if deleted_at
    return [] if side_for_entire_lifespan?
    return [start_at..hide_at] if featured_for_entire_lifespan?
    return [side_end_at..hide_at] if side_start_at == start_at
    return [start_at..side_start_at] if side_end_at == hide_at
    return [start_at..side_start_at, side_end_at..hide_at]
  end

  def side_for_entire_lifespan?
    side_start_at == start_at && side_end_at == hide_at
  end

  def featured_for_entire_lifespan?
    side_start_at.nil? && side_end_at.nil?
  end

  def number_sold_meets_or_exceeds_display_threshold?
    (number_sold || 0) >= (number_sold_display_threshold || NUMBER_SOLD_DISPLAY_THRESHOLD_LARGE_FAILSAFE_VALUE)
  end

 private

  def after_sold_out_hook
    notify_third_party_purchases_api
    send_daily_deal_notification
  end

  def send_daily_deal_notification
    Resque.enqueue(Jobs::SendSoldOutNotificationJob, self.id) if self.publisher.try(:send_daily_deal_notification)
  end

  def notify_third_party_purchases_api
    Resque.enqueue(Api::ThirdPartyPurchases::SoldOutPushNotification, self.id)
  end

  def humanize_date(attr)
    attr.present? ? attr.to_s(:compact_with_tz) : ""
  end

  def feature!
    self.side_start_at = nil
    self.side_end_at = nil
  end

  def unfeature!
    return if start_at.nil? || hide_at.nil?
    self.side_start_at = self.start_at
    self.side_end_at = self.hide_at
  end

  def date_ranges_overlap(first_range, second_range)
    (first_range.first.to_i+1 - second_range.last.to_i) * (second_range.first.to_i+1 - first_range.last.to_i) >= 0
  end

  def side_deal_schedule
    return if side_start_at.blank? && side_end_at.blank?
    validate_both_side_dates_if_either
    validate_side_dates_inside_start_and_hide_at
    validate_side_end_at_follows_side_start_at
  end

  def validate_both_side_dates_if_either
    if !side_start_at.blank? && side_end_at.blank?
      errors.add(:side_end_at, "%{attribute} cannot be blank if a side-start date has been entered")
    elsif !side_end_at.blank? && side_start_at.blank?
      errors.add(:side_start_at, "%{attribute} cannot be blank if a side-end date has been entered")
    end
  end

  def validate_side_dates_inside_start_and_hide_at
    return if start_at.blank? || hide_at.blank?
    return if either_side_date_blank?
    if side_start_at < start_at || side_start_at > hide_at
      errors.add(:side_start_at, "%{attribute} must be between the start at and hide at for the deal")
    end

    if side_end_at < start_at || side_end_at > hide_at
      errors.add(:side_end_at, "%{attribute} must be between the start at and hide at for the deal")
    end
  end

  def validate_side_end_at_follows_side_start_at
    return if either_side_date_blank?
    if side_start_at > side_end_at
      errors.add(:side_end_at, "%{attribute} must follow the side start date")
    end
  end

  def either_side_date_blank?
    side_start_at.blank? || side_end_at.blank?
  end

end
