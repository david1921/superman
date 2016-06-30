module DailyDealCertificateRefundRelatedUpdates

  def full_refund?(purchase_price, refund_amount)
    return false if refund_amount.nil?
    refund_amount >= purchase_price
  end

  def update_status_and_refund_as_appropriate(purchase, status)
    return 0 if purchase.daily_deal_certificates.size == 0
    marked = 0
    purchase.daily_deal_certificates.each do |cert|
      puts "Marking cert (#{cert.id}) as #{status} for purchase with id #{purchase.id}."
      if status == "refunded"
        cert.refund!
        cert.update_attribute(:refunded_at, purchase.refunded_at)
      else
        cert.status = status
        cert.save!
      end
      marked += 1
    end
    marked
  end

  def update_status_to_redeemed_for_redeemed_certs
    DailyDealCertificate.update_all("status = 'redeemed'", "redeemed_at is NOT NULL and status = 'active'")
  end

end