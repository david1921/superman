class SubscriptionRateSchedule < ActiveRecord::Base
  include HasUuid
  
  belongs_to :item_owner, :polymorphic => true
  has_many :subscription_rates, :dependent => :destroy

  uuid_type :random
  
  validates_presence_of :name
end

