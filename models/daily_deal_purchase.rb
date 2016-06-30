
class DailyDealPurchase < BaseDailyDealPurchase
  include BraintreePurchase
  include OptimalPurchase
  include PaypalPurchase
  include DailyDealPurchases::PDF
  include DailyDealPurchases::Validations
  include DailyDealPurchases::Discount
  include DailyDealPurchases::PromotionDiscounts
  include HasPublisherThemeableTranslations
  include DailyDealPurchases::VoucherShipping
  include DailyDealPurchases::Callbacks
  include DailyDealPurchases::Core
  include DailyDealPurchases::CyberSource
  include DailyDealPurchases::Recipients

  # Required for STI to work with cache_classes off.
  # See: http://bjhess.com/blog/when_single_table_inheritance_attacks/
  require_dependency 'non_voucher_daily_deal_purchase'

  belongs_to :daily_deal_order
  belongs_to :discount
  belongs_to :affiliate, :polymorphic => true
  belongs_to :mailing_address, :class_name => 'Address'
  accepts_nested_attributes_for :mailing_address
  has_one :travelsavers_booking

  attr_accessor :discount_code

  before_validation :assign_discount_from_code, :set_gross_price_if_blank_or_not_executed, :set_actual_purchase_price_if_blank_or_not_executed,
                    :clear_mailing_address_unless_required
  after_save :mark_discount_as_used_if_necessary

  validates_presence_of :consumer
  validates_immutability_of :consumer_id,:if => :executed?
  validate :maximum_purchase_limit, :if => :should_validate_maximum_purchase_limit?
  validate :executed_via_payment_unless_free
  validate :discount_assignment_from_code
  validate :discount_belongs_to_publisher
  validate :consumer_has_not_executed_with_discount
  validate :market_belongs_to_daily_deal
  validate :consumer_publisher_is_daily_deal_publisher
  validate :quantity_must_be_one_for_travelsavers_purchases
  validate :travelsavers_purchases_cannot_be_gifted
  validate :recipient_names_match_quantity_times_voucher_multiple
  validate :recipients_match_quantity_times_voucher_multiple
  validate :discount_code_unique_within_shopping_cart, :if => :in_shopping_cart?
  validates_presence_of :mailing_address, :if => :require_mailing_address?
  validate :validate_mailing_address, :if => :validate_mailing_address?

  delegate :facebook_user?, :post_purchase_to_fb_wall, :credit_available, :to => :consumer, :allow_nil => true
  delegate :payment_gateway_id, :payment_gateway_receipt_id, :credit_card_last_4, :amount, :payment_at, :payer_postal_code, :payer_email, :payer_status, :to => :daily_deal_payment, :allow_nil => true
  delegate :item_code, :to => :daily_deal, :allow_nil => true

  def analog_purchase_id
    "#{self.id}-BBP"
  end

  def self.setup_with(settings = {})
    daily_deal = settings[:daily_deal]
    consumer = settings[:consumer]
    raise ArgumentError, "daily deal and consumer are required" unless daily_deal && consumer
    daily_deal_purchase = self.new
    daily_deal_purchase.daily_deal = daily_deal
    daily_deal_purchase.consumer = consumer
    daily_deal_purchase.discount = settings[:discount]
    daily_deal_purchase.credit_used = daily_deal_purchase.credit_usable
    daily_deal_purchase.mailing_address = settings[:mailing_address]
    daily_deal_purchase.daily_deal_variation = settings[:daily_deal_variation]
    daily_deal_purchase.quantity    = daily_deal_purchase.daily_deal_variation_or_daily_deal.min_quantity
    daily_deal_purchase
  end

  def humanize_created_on
    I18n.localize(created_at.to_date, :format => :long)
  end
  
  def humanize_created_at
    I18n.localize(created_at, :format => :long)
  end

  def humanize_expires_on
    I18n.localize(expires_on.to_date, :format => :long) if expires_on
  end
  
  def humanize_executed_at
    I18n.localize(executed_at, :format => :long) if executed_at
  end

  def redeemer_names
    gift ? (recipient_names || []).uniq.join(", ") : consumer_name
  end

  def affiliate_name
    affiliate.try(:name).to_s
  end

  def daily_deal_certificates_file_name
    [ consumer_name, advertiser.name, id.to_s ].join("_").to_ascii.split.join('_').downcase << ".pdf"
  end


  def toggle_allow_execution!
    if toggle_allow_execution?
      self.allow_execution = !self.allow_execution
      save!
    end
  end

  def toggle_allow_execution?
    voided? && daily_deal_variation_or_daily_deal.ended?
  end

  def in_shopping_cart?
    daily_deal_order.present?
  end

  def set_affiliate_from_placement_code(placement_code)
    unless daily_deal.present?
      raise "Can't call set_affiliate_from_placement_code on a DailyDealPurchase whose daily_deal is blank"
    end

    return unless placement_code.present?

    affiliate_placement = AffiliatePlacement.not_deleted.find_by_uuid(placement_code)
    if affiliate_placement.placeable == daily_deal
      self.affiliate = affiliate_placement.affiliate
    end
  end

  def to_liquid
    Drop::DailyDealPurchase.new(self)
  end

  def execute_without_payment!
    where = "#{inspect}#execute_without_payment!"

    raise "Expect zero total price in #{where}" unless 0.0 == total_price
    if !executed?
      self.executed_at = Time.zone.now
      set_payment_status! "captured"
    else
      raise "Purchase already executed in #{where}"
    end
  end

  # Common interface for views. Also implemented by OffPlatformDailyDealCertificate.
  def has_deal_information?
    daily_deal.present?
  end

  def has_custom_template?
    custom_voucher_template_exists?
  end

  def custom_voucher_template_path
    unless @custom_voucher_template_path
      @custom_voucher_template_path = Rails.root.join( "app/views/themes/#{publisher_for_voucher_rendering.label}/daily_deal_purchases/_certificate_body.html.erb" )
      if publisher_for_voucher_rendering.publishing_group
        unless File.exists?( @custom_voucher_template_path )
          @custom_voucher_template_path = Rails.root.join( "app/views/themes/#{publisher_for_voucher_rendering.publishing_group.label}/daily_deal_purchases/_certificate_body.html.erb" )
        end
      end
    end
    @custom_voucher_template_path
  end

  def custom_voucher_template_layout_path
    unless @custom_voucher_template_layout_path
      @custom_voucher_template_layout_path = Rails.root.join( "app/views/themes/#{publisher_for_voucher_rendering.label}/daily_deal_purchases/certificate_layout.html.erb" )
      if publisher_for_voucher_rendering.publishing_group
        unless File.exists?( @custom_voucher_template_layout_path )
          @custom_voucher_template_layout_path = Rails.root.join( "app/views/themes/#{publisher_for_voucher_rendering.publishing_group.label}/daily_deal_purchases/certificate_layout.html.erb" )
        end
      end
    end
    @custom_voucher_template_layout_path
  end

  def custom_voucher_template_exists?
    File.exists? custom_voucher_template_path
  end

  def custom_voucher_template
    @custom_voucher_template ||= File.read(custom_voucher_template_path)
  end

  def custom_voucher_template_layout
    @custom_voucher_template_layout ||= File.read(custom_voucher_template_layout_path)
  end

  def publisher_for_voucher_rendering
    @publisher_for_voucher_rendering ||= daily_deal.syndicated? ? daily_deal.source.publisher : daily_deal.publisher
  end

  def self.send_unsent_certificate_email(count, start_time)
    sent = 0
    conditions = [%{payment_status = 'captured' AND certificate_email_sent_at IS NULL AND executed_at > ?}, start_time]
    DailyDealPurchase.all(:conditions => conditions, :order => "executed_at ASC", :limit => count).each do |daily_deal_purchase|
      SendCertificates.perform daily_deal_purchase.id
      yield daily_deal_purchase.reload if block_given?
      sent += 1
    end
    sent
  end

  private

  def executed_via_payment_unless_free
    if executed? && total_price > 0.0 && creates_payment? && daily_deal_payment.nil?
      errors.add(:daily_deal_payment, "%{attribute} must be present if executed")
    end
  end

  def set_actual_purchase_price_if_blank_or_not_executed
    set_actual_purchase_price! if actual_purchase_price.blank? || !executed?
  end

  def set_actual_purchase_price!
    self.actual_purchase_price = calculate_actual_purchase_price
  end

  def calculate_actual_purchase_price
    return 0 unless quantity.present? && daily_deal.present?

    credit_amount = credit_used.present? ? credit_used : 0
    discount_amount = discount.present? ? discount.amount : 0

    purchase_price = (price * quantity) - credit_amount - discount_amount + (voucher_shipping_amount || 0)
    purchase_price > 0 ? purchase_price : 0
  end

  def set_gross_price_if_blank_or_not_executed
    set_gross_price! if gross_price.blank? || !executed?
  end

  def set_gross_price!
    return unless quantity.present? && daily_deal.present?
    self.gross_price = (price * quantity)
  end

  def market_belongs_to_daily_deal
    return if market.nil?
    unless daily_deal_variation_or_daily_deal.markets.include?(market)
      errors.add :market, translate_with_theme("activerecord.errors.custom.market_does_not_belong_to_deal",
                                               :market => market, :value_proposition => value_proposition)
    end
  end

  def consumer_publisher_is_daily_deal_publisher
    unless allow_purchase_for_publisher?
      errors.add_to_base "This consumer account is not allowed to purchase deals from this publisher"
    end
  end

  def allow_purchase_for_publisher?
    return false if consumer.nil?
    return false if daily_deal.nil?
    return false if daily_deal.publisher.nil?
    return daily_deal.publisher.allow_consumer_access?(consumer)
  end

  def should_validate_maximum_purchase_limit?
    if executed?
      return false
    elsif transitioning_from_non_executed_to_executed_state?
      return false
    else
      return true
    end
  end
  
  def transitioning_from_non_executed_to_executed_state?
    payment_status_changed? && executed? && payment_status_was == "pending"
  end

  def maximum_purchase_limit
    if daily_deal && consumer && quantity
      purchases = daily_deal_variation_or_daily_deal.daily_deal_purchases.for_consumer(consumer).executed.reject { |purchase| purchase.id == id }
      remaining_quantity = [0, daily_deal_variation_or_daily_deal.max_quantity - purchases.sum(&:quantity)].max
      if quantity > remaining_quantity
        errors.add :quantity, translate_with_theme("activerecord.errors.custom.cannot_exceed_remaining_quantity",
                                                   :attribute => translate_with_theme("activerecord.attributes.daily_deal_purchase.quantity"),
                                                   :remaining_quantity => remaining_quantity)
      end
    end
  end
end
