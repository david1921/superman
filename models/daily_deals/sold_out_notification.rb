module DailyDeals::SoldOutNotification

  def self.included(base)
    base.alias_method_chain :sold_out!, :purchase_api_sold_out_push_notification
  end

  def sold_out_with_purchase_api_sold_out_push_notification!
    sold_out_without_purchase_api_sold_out_push_notification!
    notify_third_party_purchases_api
  end

  private

  def notify_third_party_purchases_api
    Resque.enqueue(Api::ThirdPartyPurchases::SoldOutPushNotification, self.id)
  end

end