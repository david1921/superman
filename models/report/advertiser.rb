module Report::Advertiser
  def inbound_txts_count(dates)
    joins = :txt_offer
    conditions = { 'txt_offers.advertiser_id' => self.id, 'inbound_txts.accepted_time' => times_for_dates(dates) }
    InboundTxt.count(:joins => joins, :conditions => conditions)
  end
  
  def gift_certificates_counts(dates)
    sql =<<-EOF
      SELECT b.*,
        IF((b.alloc_begin - IFNULL(b.purchased_begin, 0)) > 0, b.alloc_begin - IFNULL(b.purchased_begin, 0), 0) AS available_count_begin,
        (b.price * IF((b.alloc_begin - IFNULL(b.purchased_begin, 0)) > 0, b.alloc_begin - IFNULL(b.purchased_begin, 0), 0)) AS available_revenue_begin,
        IFNULL(b.purchased_later, 0) - IFNULL(b.purchased_begin, 0) AS purchased_count,
        IFNULL(b.revenue, 0.00) AS purchased_revenue,
        IF((b.alloc_later - IFNULL(b.purchased_later, 0)) > 0, b.alloc_later - IFNULL(b.purchased_later, 0), 0) AS available_count_end,
        (b.price * IF((b.alloc_later - IFNULL(b.purchased_later, 0)) > 0, b.alloc_later - IFNULL(b.purchased_later, 0), 0)) AS available_revenue_end
      FROM (
        SELECT g.*,
          g.number_allocated*((g.show_on IS NULL or g.show_on <= :d_begin) AND (g.expires_on IS NULL OR g.expires_on >= :d_begin)) AS alloc_begin,
          g.number_allocated*((g.show_on IS NULL or g.show_on <= :d_later) AND (g.expires_on IS NULL OR g.expires_on >= :d_later)) AS alloc_later,
          SUM(p.paypal_payment_date < :t_begin AND p.payment_status = "completed") AS purchased_begin,
          SUM(p.paypal_payment_date < :t_later AND p.payment_status = "completed") AS purchased_later,
          SUM(p.paypal_payment_gross*(p.paypal_payment_date >= :t_begin AND p.paypal_payment_date < :t_later AND p.payment_status = "completed"))
            AS revenue
        FROM gift_certificates AS g LEFT JOIN purchased_gift_certificates AS p
          ON g.id = p.gift_certificate_id
        GROUP BY g.id
        HAVING g.advertiser_id = :advertiser_id
      ) AS b
      HAVING id IS NOT NULL
      ORDER BY b.id
    EOF
    times = times_for_dates(dates)
    GiftCertificate.find_by_sql([sql, {
      :advertiser_id => id,
      :d_begin => dates.begin,
      :d_later => dates.end + 1,
      :t_begin => times.begin,
      :t_later => times.end + 1
    }])
  end
  
  # Returns all DailyDealCertificate's purchased within the specified date range.
  # This *includes* any certificates that have been refunded.
  # Providing company scopes the deals by publisher or advertiser which is necessary because the publisher
  # using a syndicated deal should not have access to the advertiser data
  def purchased_daily_deal_certificates_for_period(date_range, companies = nil, market = nil)
    companies = companies.is_a?(Array) ? companies : [companies]
    
    scoped_daily_deal_purchases = if companies.present? && companies.any? { |c| company_owns_advertiser?(c) }
      daily_deal_purchases
    else
      daily_deal_purchases.for_companies(companies)
    end
    
    scoped_daily_deal_purchases = if market.present?
      scoped_daily_deal_purchases.in_market(market)
    else
      scoped_daily_deal_purchases.not_in_market
    end
    
    scoped_daily_deal_purchases.captured_or_refunded_for_dates(date_range).with_certificates.collect(&:daily_deal_certificates).flatten.sort_by do |cert|
      cert.consumer_name || "" # do not return nil (used for sorting and there was a mobile app issue 11/23/11)
    end
  end
  
  def refunded_daily_deal_certificates_for_period(date_range, company = nil, market = nil)
    if company_owns_advertiser?(company)
      scoped_daily_deal_purchases = daily_deal_purchases
    else
      scoped_daily_deal_purchases = daily_deal_purchases.for_company(company)
    end
    if market.present?
      scoped_daily_deal_purchases = scoped_daily_deal_purchases.in_market(market)
    else
      scoped_daily_deal_purchases = scoped_daily_deal_purchases.not_in_market
    end
    # N + 1 but not over many N
    certs_in_range = []
    scoped_daily_deal_purchases.captured_or_refunded.with_certificates.each do |purchase|
      refunded_between = purchase.daily_deal_certificates.refunded_between(date_range)
      certs_in_range += refunded_between
    end
    certs_in_range.sort_by { |c| c.daily_deal_purchase.consumer_name || '' } # consumer name is nil for off-platform purchases
  end

  def affiliated_daily_deal_certificates_for_period(date_range, company = nil)
    if company_owns_advertiser?(company)
      scoped_daily_deal_purchases = daily_deal_purchases
    else
      scoped_daily_deal_purchases = daily_deal_purchases.for_company(company)
    end
    scoped_daily_deal_purchases.affiliated(date_range).with_certificates.collect(&:daily_deal_certificates).flatten.sort_by do |cert|
      cert.daily_deal_purchase.consumer_name
    end
  end
  
  private
  
  def company_owns_advertiser?(company)
    company.present? && company.is_a?(Publisher) && company.id == publisher_id
  end
    
  def times_for_dates(dates)
    Time.zone.parse(dates.begin.to_s) .. Time.zone.parse(dates.end.to_s).end_of_day
  end
end
