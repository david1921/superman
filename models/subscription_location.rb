class SubscriptionLocation < ActiveRecord::Base
  belongs_to :publisher

  validates_presence_of :publisher
  validates_presence_of :name
end
