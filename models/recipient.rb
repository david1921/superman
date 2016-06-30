class Recipient < ActiveRecord::Base
  include ActsAsLocation
  acts_as_location
  belongs_to :addressable, :polymorphic => true
  validates_presence_of :name
end
