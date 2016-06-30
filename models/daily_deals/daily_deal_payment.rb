class DailyDealPayment < ActiveRecord::Base
  belongs_to :daily_deal_purchase
  before_validation :initialize_analog_purchase_id

  before_save :populate_billing_first_and_billing_last_from_name_on_card

  include DailyDealPayments::Travelsavers

  with_options :if => Proc.new { |record| record.payment_gateway_id.present? } do |this|
    this.validates_numericality_of :amount, :greater_than_or_equal_to => 0.00, :allow_nil => false
    this.validates_uniqueness_of :analog_purchase_id
    this.validates_presence_of :payment_at
  end
  validates_uniqueness_of :payment_gateway_id, :if => Proc.new { |record| record.daily_deal_purchase.try(:daily_deal_order_id).nil? }, :allow_nil => true
  validates_presence_of :daily_deal_purchase, :analog_purchase_id

  named_scope :missing_sanctions_data, :conditions => ["billing_first_name is NULL OR billing_first_name = '' OR billing_last_name is NULL OR billing_last_name = ''"]
  named_scope :has_name_on_card, :conditions => ["name_on_card is NOT NULL AND name_on_card != ''"]

  def initialize_analog_purchase_id
    if self.analog_purchase_id.blank?
      self.analog_purchase_id = daily_deal_purchase.analog_purchase_id  unless daily_deal_purchase.id.nil?
    end
  end

  def analog_purchase_id=(new_id)
    if !self.new_record? && self.analog_purchase_id.present?
      raise "Analog id must not be changed"
    end
    self.write_attribute(:analog_purchase_id, new_id)
  end

  def void_or_full_refund!(admin)
    raise NotImplementedError, "subclasses must implement"
  end

  def partial_refund!(admin, partial_refund_amount)
    raise NotImplementedError, "subclasses must implement"
  end

  def refundable?
    raise NotImplementedError, "subclasses must implement"
  end

  def submit_for_settlement!
    raise NotImplementedError, "subclasses must implement"
  end

  def populate_billing_address_from_shipping_address
    unless daily_deal_purchase.recipients.length > 1
      recipient = daily_deal_purchase.recipients.first
      self.billing_address_line_1 = recipient.address_line_1
      self.billing_address_line_2 = recipient.address_line_2
      self.billing_city           = recipient.city
      self.billing_state          = recipient.state
      self.billing_country_code   = recipient.country.code
      self.payer_postal_code      = recipient.zip
    else
      false
    end
  end

  def populate_billing_first_and_billing_last_from_name_on_card
    return if billing_first_name.present? && billing_last_name.present?
    return if name_on_card.blank?
    bits_on_name = name_on_card.split(' ')
    self.billing_first_name = bits_on_name.first
    self.billing_last_name = bits_on_name.last
  end

end
