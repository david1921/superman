module OffPlatformDailyDealPurchases::Core

  def capture!
    set_payment_status!('captured')
  end

  def origin_name
    api_user.name
  end

end
