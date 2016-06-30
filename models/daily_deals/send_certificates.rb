class SendCertificates

  @queue = :send_certificates

  def self.perform(daily_deal_purchase_id)
    purchase = find_purchase(daily_deal_purchase_id)
    purchase.send_email!
  end

  private

  def self.find_purchase(daily_deal_purchase_id)
    DailyDealPurchase.find(daily_deal_purchase_id)
  end

end
