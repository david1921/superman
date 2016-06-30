class DailyDealPurchaseRecipient < ActiveRecord::Base
  include ActsAsLocation
  acts_as_location
  belongs_to :daily_deal_purchase
  validates_presence_of :name
end
