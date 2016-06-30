class DailyDealOrder < ActiveRecord::Base
  include HasUuid
  uuid_type :random

  belongs_to :consumer
  has_many :daily_deal_purchases
  
  validates_presence_of :consumer
  validates_uniqueness_of :analog_purchase_id, :allow_nil => true 
  validates_uniqueness_of :payment_gateway_id, :allow_nil => true
  
  after_create :set_analog_purchase_id

  delegate :publisher, :to => :consumer, :allow_nil => true
  delegate :currency_symbol, :to => :publisher
  
  named_scope :pending, :conditions => { :payment_status => "executed" }

  state_machine :payment_status, :initial => :pending do
    [:authorized, :captured, :voided, :refunded, :reversed].each do |x|
      state x
    end
  end

  def handle_braintree_sale!(braintree_transaction)
    update_attributes! :payment_gateway_id => braintree_transaction.id
    validate_amounts braintree_transaction
    ensure_only_one_occurrence_of_discount_code
    daily_deal_purchases.each do |daily_deal_purchase|
      if daily_deal_purchase.actual_purchase_price.zero?
        daily_deal_purchase.execute_without_payment!
      else
        daily_deal_purchase.handle_braintree_sale! braintree_transaction
      end
    end
    update_attributes! :payment_status => "captured"
  end
  
  def execute_without_payment!
    ensure_only_one_occurrence_of_discount_code

    where = "#{inspect}#execute_without_payment!"
    raise "Expect zero total price in #{where}" unless 0.0 == total_price
    
    daily_deal_purchases.each do |purchase|
      purchase.execute_without_payment!
    end
    
    update_attributes! :payment_status => "captured"
  end
  
  def validate_amounts(braintree_transaction)
    if total_price != braintree_transaction.amount
      raise "Expect txn amount '#{total_price}' but was '#{braintree_transaction.amount}' in #{self}"
    end
  end

  def analog_purchase_id
    if new_record?
      nil
    else
      "#{id}-DDO"
    end
  end
  
  def set_analog_purchase_id
    self.analog_purchase_id = analog_purchase_id
    # using update attribute without validation because is a method used in after_save (it means already validated)
    update_attribute :analog_purchase_id, analog_purchase_id
  end
  
  def total_price
    # Use to_a to avoid the ActiveRecord sum method
    daily_deal_purchases.to_a.sum(&:total_price)
  end
  
  def total_value
    daily_deal_purchases.to_a.sum(&:value)
  end
  
  def quantity
    daily_deal_purchases.to_a.sum(&:quantity)
  end
  
  def to_param
    uuid
  end

  def item_code
    "DDO-#{id}"
  end

  def executed?
    !pending?
  end
  
  def cleanse!
    daily_deal_purchases.delete(*daily_deal_purchases.select { |ddp| !ddp.daily_deal.available? }) if pending?
    self
  end
  
  def ensure_only_one_occurrence_of_discount_code
    found_discount_ids = []
    daily_deal_purchases.each do |ddp|
      if found_discount_ids.include?( ddp.discount_id )
        ddp.update_attribute(:discount_id, nil)
      else
        found_discount_ids.push(ddp.discount_id)
      end      
    end
    daily_deal_purchases.reload if found_discount_ids.any? # only reload if there were discount codes
  end
end
