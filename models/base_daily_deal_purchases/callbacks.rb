module BaseDailyDealPurchases::Callbacks

  def save_daily_deal_certificates
    daily_deal_certificates.each do |cert|
      if (!cert.save)
        logger.warn("Could not save daily daily certificate (id=#{cert.id}) from daily_deal_purchase (id=#{id})")
      end
    end
  end

end
