class PaypalSubscriptionNotification < ActiveRecord::Base
  belongs_to :item, :polymorphic => true

  validates_presence_of :item
  validates_numericality_of :paypal_mc_amount3, :greater_than_or_equal_to => 0.00, :allow_nil => false
  validates_email :paypal_payer_email, :allow_blank => false
  
  after_create :notify_item
  
  named_scope :starting, { :conditions => { :paypal_txn_type => "subscr_signup" }}
  named_scope :stopping, { :conditions => { :paypal_txn_type => "subscr_eot" }}

  [:paypal_subscr_date, :paypal_subscr_effective].each { |attr| class_eval %Q(def #{attr}=(value) set_paypal_date('#{attr}', value); end)}
  
  def self.handle_ipn(params)
    build_from_ipn_params(params).save!
  end

  private
  
  def self.build_from_ipn_params(params)
    item = item_from_ipn_params(params)
    attributes = { :item => item }.tap do |hash|
      column_names.grep(/^paypal_/).each do |attr|
        hash[attr] = params[attr.sub(/^paypal_/, '')]
      end
    end
    new(attributes)
  end
  
  def self.item_from_ipn_params(params)
    begin
      params['custom'].to_s.downcase.camelize.constantize.find(params['item_number'])
    rescue
      raise %Q(no subscription item matches IPN type '#{params["custom"]}' id '#{params["item_number"]}')
    end
  end
  
  def set_paypal_date(attr, value)
    write_attribute(attr, DateTime.strptime(value, "%H:%M:%S %b %d, %Y %Z").utc) if value.present?
  end
  
  def notify_item
    item.paypal_subscription_notification_added
  end
end
