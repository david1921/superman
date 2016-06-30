class ThirdPartyEventPurchase < ActiveRecord::Base
  belongs_to :third_party_event
  validates_presence_of :price, :quantity, :product_id
  validates_numericality_of :price, :quantity, :greater_than_or_equal_to => 0.01
end
