class OffPlatformDailyDealPurchase < BaseDailyDealPurchase
  include OffPlatformDailyDealPurchases::Core
  include OffPlatformDailyDealPurchases::Validations
  include OffPlatformDailyDealPurchases::MultiVoucherDeals

  belongs_to :api_user, :class_name => 'User'

  validates_presence_of :api_user
  validate :recipient_names_match_quantity
  validate :consumer_is_nil
end
