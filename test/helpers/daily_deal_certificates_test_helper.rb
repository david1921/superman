module DailyDealCertificatesTestHelper
  def create_daily_deal_certificate(options={})
  daily_deal = daily_deals(:changos)

  daily_deal_purchase_attrs = {
    :consumer => users(:john_public),
    :quantity => 1,
    :payment_status => "captured",
  }.merge(options)

  daily_deal_purchase = daily_deal.daily_deal_purchases.build
  daily_deal_purchase.daily_deal_payment = BraintreePayment.new
  daily_deal_purchase.daily_deal_payment.payment_gateway_id = "43d6fg"
  daily_deal_purchase.daily_deal_payment.payment_at Time.zone.now
  daily_deal_purchase.daily_deal_payment.amount = daily_deal.price
  daily_deal_purchase.daily_deal_payment.credit_card_last_4 = "4545"
  daily_deal_purchase_attrs.each { |key, val| daily_deal_purchase.send "#{key}=", val }
  daily_deal_purchase.save!

  @daily_deal_certificate = daily_deal_purchase.daily_deal_certificates.create!(:redeemer_name => "John Public")
  end
end