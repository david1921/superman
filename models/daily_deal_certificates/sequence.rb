module DailyDealCertificates::Sequence
  def sequence
    daily_deal_purchase.recipient_names.index(redeemer_name) + 1
  end
end