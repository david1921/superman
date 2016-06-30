class BaseDailyDealPurchase < ActiveRecord::Base
  set_table_name "daily_deal_purchases"

  include HasUuid
  include BaseDailyDealPurchases::Core
  include BaseDailyDealPurchases::Callbacks
  include BaseDailyDealPurchases::PaymentStatus
  include BaseDailyDealPurchases::RefundsAndVoids
  include BaseDailyDealPurchases::Totals
  include BaseDailyDealPurchases::LoyaltyProgram
  include BaseDailyDealPurchases::Fraud
  include DailyDealPurchases::DailyDealVariation
  include DailyDealPurchases::Travelsavers

  belongs_to :consumer
  belongs_to :store
  belongs_to :daily_deal
  belongs_to :market
  has_one :daily_deal_payment, :foreign_key => 'daily_deal_purchase_id'
  has_many :daily_deal_certificates, :dependent => :destroy, :foreign_key => 'daily_deal_purchase_id'
  has_many :recipients, :class_name => "DailyDealPurchaseRecipient", :foreign_key => 'daily_deal_purchase_id'

  uuid_type :random

  serialize :recipient_names

  PAYMENT_STATUSES = %w{ pending authorized captured voided refunded reversed }

  attr_accessible # None

  accepts_nested_attributes_for :recipients

  after_save :save_daily_deal_certificates

  validates_presence_of :daily_deal, :quantity
  validates_numericality_of :quantity, :only_integer => true, :greater_than => 0
  validates_inclusion_of :payment_status, :in => PAYMENT_STATUSES, :allow_blank => false,
                         :message => "'%{value}' is not valid. Must be #{PAYMENT_STATUSES.to_sentence(:last_word_connector => " or ")}."
  validates_immutability_of :daily_deal_id, :quantity, :if => :executed?
  validate do |record|
    # A nil record.quantity isn't valid (record is the DailyDealPurchase), but this validation can
    # fire before validates_presence_of and raise exception
    if (min_quantity = record.daily_deal_variation_or_daily_deal.try(:min_quantity)) && record.quantity && min_quantity > record.quantity
      record.errors.add :quantity, I18n.t("activerecord.errors.custom.is_below_the_min_quantity", :attribute => :quantity, :min_quantity => min_quantity)
    end
  end

  validate :store_belongs_to_advertiser, :if => Proc.new {|record|
    !%w{ voided refunded }.include?(record.payment_status) && record.location_required?
  }
  validates_numericality_of :gross_price, :actual_purchase_price, :credit_used, :greater_than_or_equal_to => 0.0, :allow_nil => false

  named_scope :for_consumer, lambda { |consumer| { :conditions => { :consumer_id => consumer.id }}}
  named_scope :executed, :conditions => "daily_deal_purchases.payment_status <> 'pending'", :order => "created_at ASC, daily_deal_purchases.id ASC"
  named_scope :suspected_frauds,
              :conditions => "daily_deal_purchases.id IN (SELECT DISTINCT suspect_daily_deal_purchase_id FROM suspected_frauds)",
              :include => [:daily_deal_payment, :consumer], 
              :order => %Q{daily_deal_purchases.ip_address ASC, daily_deal_payments.credit_card_last_4 ASC,
                           users.name ASC, users.email ASC, daily_deal_purchases.created_at ASC}
  named_scope :with_no_vouchers,
              :conditions => "ddc.id IS NULL",
              :joins => "LEFT JOIN daily_deal_certificates ddc ON daily_deal_purchases.id = ddc.daily_deal_purchase_id"
                              

  def self.purchases_that_should_have_vouchers_but_dont(options = {})
    query_options = options.merge({
      :conditions => ["executed_at IS NULL OR executed_at <= ?", 10.minutes.ago]
    })
    captured_or_refunded.with_no_vouchers.all(query_options)
  end

  def self.for_company(company = nil)
    if company.present?
      for_companies([company])
    else
      for_companies(nil)
    end
  end

  named_scope :for_companies, lambda { |companies|
    if companies.present?
      sql = []

      if (advertisers = companies.select { |c| c.is_a?(Advertiser) }).present?
        sql << "daily_deals_hack.advertiser_id IN (%s)" % advertisers.map(&:id).join(", ")
      end

      if (publishers = companies.select { |c| c.is_a?(Publisher) }).present?
        sql << "daily_deals_hack.publisher_id IN (%s)" % publishers.map(&:id).join(", ")
      end

      if (publishing_groups = companies.select { |c| c.is_a?(PublishingGroup) }).present?
        sql << "publishers.publishing_group_id IN (%s)" % publishing_groups.map(&:id).join(", ")
      end

      { :conditions => sql.join(" OR "),
        :joins => %Q{
          INNER JOIN daily_deals as daily_deals_hack ON daily_deal_purchases.daily_deal_id = daily_deals_hack.id
          INNER JOIN publishers ON daily_deals_hack.publisher_id = publishers.id
          }
        }
    end
  }

  named_scope :authorized, :conditions => { :payment_status => "authorized" }
  named_scope :with_certificates, :include => :daily_deal_certificates
  named_scope :in_currency, lambda { |currency_unit|
    if currency_unit.present?
      { :conditions => ["publishers.currency_code = ?", currency_unit.to_s.upcase],
        :joins => %Q{
          INNER JOIN daily_deals ON daily_deal_purchases.daily_deal_id = daily_deals.id
          INNER JOIN publishers ON daily_deals.publisher_id = publishers.id
        }
      }
    end
  }
  named_scope :captured, lambda { |dates|
    if dates.nil?
      { :conditions => { :payment_status => "captured" }, :include => :daily_deal_payment }
    else
      sql = "daily_deal_purchases.payment_status = 'captured' AND daily_deal_purchases.executed_at BETWEEN :beg AND :end"
      { :conditions => [sql, { :beg => Time.zone.parse(dates.begin.to_s).beginning_of_day.utc, :end => Time.zone.parse(dates.end.to_s).end_of_day.utc }], :include => :daily_deal_payment  }
    end
  }
  named_scope :refunded, lambda { |dates|
    if dates.nil?
      { :conditions => { :payment_status => "refunded" }}
    else
      sql = "daily_deal_purchases.payment_status = 'refunded' AND daily_deal_purchases.refunded_at BETWEEN :beg AND :end"
      { :conditions => [sql, { :beg => Time.zone.parse(dates.begin.to_s).beginning_of_day.utc, :end => Time.zone.parse(dates.end.to_s).end_of_day.utc }] }
    end
  }
  named_scope :captured_or_refunded, lambda { { :conditions => { :payment_status => %w(captured refunded) } } }

  named_scope :captured_or_refunded_for_dates, lambda { |dates|
    sql = "daily_deal_purchases.payment_status IN ('captured', 'refunded') AND daily_deal_purchases.executed_at BETWEEN :beg AND :end"
    { :conditions => [sql, { :beg => Time.zone.parse(dates.begin.to_s).beginning_of_day.utc, :end => Time.zone.parse(dates.end.to_s).end_of_day.utc }] }
  }

  named_scope :payment_status_updated_for_dates, lambda { |dates|
    sql = "daily_deal_purchases.payment_status_updated_at BETWEEN :beg AND :end"
    { :conditions => [sql, { :beg => Time.zone.parse(dates.begin.to_s).beginning_of_day.utc, :end => Time.zone.parse(dates.end.to_s).end_of_day.utc }] }
  }

  named_scope :in_market, lambda { |market| { :conditions => { :market_id => market.id }}}
  named_scope :not_in_market, :conditions => "daily_deal_purchases.market_id is null"

  named_scope :affiliated, lambda { |dates|
    if dates.present?
      date_clause = "AND daily_deal_purchases.executed_at BETWEEN :beg AND :end"
    end

    sql = "daily_deal_purchases.payment_status = 'captured' #{date_clause} AND affiliate_id IS NOT NULL"
    { :conditions => [sql, { :beg => Time.zone.parse(dates.begin.to_s).beginning_of_day.utc, :end => Time.zone.parse(dates.end.to_s).end_of_day.utc }] }
  }

  named_scope :executed_after_or_on, lambda { |date|
    { :conditions => ["executed_at >= ?", date] }
  }

  named_scope :with_billed_payment_status, :conditions => "payment_status IN ('captured', 'refunded', 'authorized')"

  named_scope :with_positive_actual_purchase_price, :conditions => "actual_purchase_price > 0"

  named_scope :within_increment_timestamps, lambda { |start_at, end_at|
    if start_at.blank?
      { :conditions => ["executed_at <= ?", end_at.utc] }
    else
      { :conditions => ["executed_at > ? AND executed_at <= ?", start_at.utc, end_at.utc] }
    end
  }


  delegate  :advertiser, :expires_on, :to => :daily_deal
  delegate  :certificates_to_generate_per_unit_quantity, :value_proposition, :value_proposition_subhead, :voucher_headline, 
            :value, :price, :line_item_name, :humanize_price, :humanize_value, :terms, :terms_plain, :bar_code_encoding_format, :to => :daily_deal_variation_or_daily_deal
  delegate  :publisher, :location_required?, :to => :daily_deal, :allow_nil => true
  delegate  :pay_using?, :to => :daily_deal, :allow_nil => true
  delegate  :currency_symbol, :to => :publisher
  delegate  :currency_code, :cyber_source_credentials, :country_codes, :to => :publisher

  def daily_deal_variation_or_daily_deal
    daily_deal_variation || daily_deal
  end

  def daily_deal_variation_or_daily_deal_available?
    daily_deal.active? && !daily_deal_variation_or_daily_deal.sold_out?
  end

end
