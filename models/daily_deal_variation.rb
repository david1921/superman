class DailyDealVariation < ActiveRecord::Base
	include ActionView::Helpers::NumberHelper
  include ActsAsBarCodeAssigner
  include ActsAsSoftDeletable
  include BarCodes::Import
  include DailyDeals::Travelsavers

  # globolize2 settings
  translates :value_proposition, :value_proposition_subhead, :terms, :voucher_headline


  # Associations
  has_many :daily_deal_purchases
  belongs_to :daily_deal

  # Validations
  validate :ensure_publisher_can_have_variations
  validate :ensure_max_quantity_greater_than_min_quantity
  validate :ensure_min_quantity_is_less_than_quantity
  validates_numericality_of :price, :value, :allow_nil => false
  validates_numericality_of :quantity, :only_integer => true, :greater_than => 0, :allow_nil => true

  # allow nil because we can default to daily deal if min or max quantity are nil.
  validates_numericality_of :min_quantity, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => false
  validates_numericality_of :max_quantity, :only_integer => true, :greater_than => 0, :less_than_or_equal_to => 25, :allow_nil => false

  validate :ensure_daily_deal_is_not_syndicated
  validate_on_update :ensure_daily_deal_is_not_over

  named_scope :available, lambda {
    { :conditions => ["daily_deal_variations.deleted_at IS NULL"] }
  }

  delegate :publisher, :advertiser_name, :currency_symbol, :pay_using?, :translate_with_theme, :syndicated?, :start_at, :hide_at, :expires_on, :source_publisher, :advertiser, :custom_1, :custom_2, :custom_3, :to => :daily_deal

  # Acts as textiled
  acts_as_textiled :terms


  # Callbacks
  after_create      :generate_default_listing
  before_create     :ensure_daily_deal_sequence_id
  before_destroy    :ensure_daily_deal_is_not_syndicated
  before_validation :set_defaults_for_defaultable_columns_that_are_nil

  def line_item_name
    I18n.t(".line_item_name", :value => number_to_currency(value, :unit => publisher.currency_symbol), :advertiser => advertiser_name.strip)
  end

 def humanize_value
    number_to_currency(value, :unit => currency_symbol)
  end

  def humanize_price
    number_to_currency(price, :unit => currency_symbol)
  end

  def sold_out?
    sold_out_at.present? && sold_out_at <= Time.zone.now
  end

  def sold_out!(force = false)
    unless sold_out?
      update_attribute(:sold_out_at, Time.zone.now) if (force || quantity && number_sold >= quantity)
    end
  end

  def ended?
    daily_deal.ended?
  end

  def available?
    daily_deal.active? && !sold_out?
  end

  def item_code
    "DDV-#{id}"
  end

  def number_sold
    daily_deal_purchases.captured_or_refunded.sum(:quantity)
  end

  def syndicated?
    daily_deal && daily_deal.source?
  end

  def started?
    daily_deal.start_at > Date.today
  end

  def delete!
    raise "Can't remove variation because it has already started." if started?
    raise "Can't remove variation because the deal has sales." if number_sold > 0
    super
  end

  private

  def ensure_publisher_can_have_variations
    errors.add_to_base("Publisher must be enabled for daily deal variations") unless daily_deal && daily_deal.publisher && daily_deal.publisher.enable_daily_deal_variations?
  end

  def generate_default_listing
    self.update_attribute(:listing, item_code) unless listing.present?
  end

  def set_defaults_for_defaultable_columns_that_are_nil
    self.min_quantity       ||= DailyDeal::MIN_QUANTITY_DEFAULT
    self.max_quantity       =   default_or_current_max_quantity
  end

  def default_or_current_max_quantity
    if self[:max_quantity].blank? || self[:max_quantity] == 0
      daily_deal.try(:publisher).try(:publishing_group).try(:max_quantity_default) || DailyDeal::MAX_QUANTITY_DEFAULT
    else
      self[:max_quantity]
    end
  end

  def ensure_max_quantity_greater_than_min_quantity
    errors.add(:max_quantity, "must be greater than min_quantity") if max_quantity < min_quantity
  end

  def ensure_min_quantity_is_less_than_quantity
    errors.add(:min_quantity, "must be less than quantity") if quantity && min_quantity > quantity
  end

  def ensure_daily_deal_is_not_syndicated
    if syndicated?
      errors.add_to_base("unable to save variation due to daily deal being syndicated.")
      return false
    end
  end

  def ensure_daily_deal_is_not_over
    # we ignore syndicated deals, since they have their own
    # validation path.
    unless syndicated?
      if daily_deal && daily_deal.over?
        errors.add_to_base("unable to save variation due to daily deal being over.")
        return false
      end
    end
  end

  def ensure_daily_deal_sequence_id
    if daily_deal
      self.daily_deal_sequence_id = (daily_deal.daily_deal_variations_with_deleted.maximum('daily_deal_sequence_id') || 0) + 1
    end
  end


end
