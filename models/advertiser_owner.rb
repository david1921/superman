class AdvertiserOwner < ActiveRecord::Base
  belongs_to :advertiser

  validates_presence_of :first_name, :last_name
end
