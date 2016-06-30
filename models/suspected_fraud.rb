class SuspectedFraud < ActiveRecord::Base
  belongs_to :suspect_daily_deal_purchase, :class_name => "DailyDealPurchase"
  belongs_to :matched_daily_deal_purchase, :class_name => "DailyDealPurchase"
  belongs_to :job
  
  validates_presence_of   :suspect_daily_deal_purchase_id, :matched_daily_deal_purchase_id
  validates_uniqueness_of :suspect_daily_deal_purchase_id
  
  named_scope :for_deal, lambda { |deal| 
    raise "must be called with a DailyDeal" unless deal.present? && deal.is_a?(DailyDeal)
    { :include => :suspect_daily_deal_purchase, :conditions => ["daily_deal_purchases.daily_deal_id = ?", deal.id] }
  }
  named_scope :for_publisher, lambda { |publisher| 
    raise "must be called with a Publisher" unless publisher.try(:is_a?, Publisher)
    { :include => { :suspect_daily_deal_purchase => :daily_deal }, :conditions => ["daily_deals.publisher_id = ?", publisher.id] }
  }
  named_scope :from_job, lambda { |job| { :conditions => { :job_id => job.id }}}
end
