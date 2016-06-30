module Report::DailyDeal
  
  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
    base.send :include, Paychex
  end

  module ClassMethods
    def publishers_with_purchase_totals_for_24h_and_30d(currency_unit)
      total_sales_by_publisher = lambda do |daily_deal_purchases|
        {}.tap do |hash|
          daily_deal_purchases.group_by(&:publisher).each do |publisher, purchases|
            hash[publisher] = purchases.map(&:total_paid).sum
          end
        end
      end

      yesterday = Time.zone.now.yesterday
      times_24h = yesterday.beginning_of_day .. yesterday.end_of_day
      times_30d = (yesterday.beginning_of_day - 29.days) .. yesterday.end_of_day
  
      totals_by_publisher_in_24h = total_sales_by_publisher.call(::DailyDealPurchase.captured(times_24h).in_currency(currency_unit))
      totals_by_publisher_in_30d = total_sales_by_publisher.call(::DailyDealPurchase.captured(times_30d).in_currency(currency_unit))
      
      [].tap do |array|
        (totals_by_publisher_in_24h.keys + totals_by_publisher_in_30d.keys).uniq.each do |publisher|
          array << [publisher, { :in_24h => totals_by_publisher_in_24h[publisher] || 0.00, :in_30d => totals_by_publisher_in_30d[publisher] || 0.00 }]
        end
      end
    end
  end
  
  module InstanceMethods

    def purchases_count(dates)
      captured_daily_deal_purchases(dates).sum(:quantity)
    end
    
    def purchasers_count(dates)
      captured_daily_deal_purchases(dates).collect(&:consumer_id).uniq.size
    end
    
    def purchases_gross(dates)
      captured_daily_deal_purchases(dates).to_a.sum(&:total_price_without_discount)
    end
    
    def purchases_discount(dates)
      purchases_gross(dates) - purchases_amount(dates)
    end
    
    def purchases_amount(dates)
      captured_daily_deal_purchases(dates).sum(:actual_purchase_price)
    end

    def refunded_certificates(dates)
      sql = <<-REFUNDED_CERTS
        select daily_deal_certificates.* from daily_deal_certificates
                inner join daily_deal_purchases
          on daily_deal_purchase_id = daily_deal_purchases.id
                inner join daily_deals
          on daily_deal_id = daily_deals.id
          where daily_deal_id = :daily_deal_id
                  and daily_deal_certificates.status = "refunded"
                  and daily_deal_certificates.refunded_at BETWEEN :beg AND :end
      REFUNDED_CERTS
      DailyDealCertificate.find_by_sql([sql, { :daily_deal_id => id,
                                               :beg => Time.zone.parse(dates.begin.to_s).beginning_of_day.utc,
                                               :end => Time.zone.parse(dates.end.to_s).end_of_day.utc}])
    end
    
    def refunded_certificates_by_market(dates, market)
      sql = <<-REFUNDED_CERTS
        select daily_deal_certificates.* from daily_deal_certificates
                inner join daily_deal_purchases
          on daily_deal_purchase_id = daily_deal_purchases.id
                inner join daily_deals
          on daily_deal_id = daily_deals.id
          where daily_deal_id = :daily_deal_id
                  and daily_deal_certificates.status = "refunded"
                  and daily_deal_certificates.refunded_at BETWEEN :beg AND :end
                  and daily_deal_purchases.type = 'DailyDealPurchase'
      REFUNDED_CERTS
      market_clause = market.nil? ? " AND daily_deal_purchases.market_id IS NULL" : " AND daily_deal_purchases.market_id = :market_id"
      sql << market_clause
      DailyDealCertificate.find_by_sql([sql, { :daily_deal_id => id,
                                               :market_id => market.try(:id),
                                               :beg => Time.zone.parse(dates.begin.to_s).beginning_of_day.utc,
                                               :end => Time.zone.parse(dates.end.to_s).end_of_day.utc}])
    end

    def captured_daily_deal_purchases(dates, reload = false)
      if reload || @captured_daily_deals_dates != dates
        @captured_daily_deals_dates = dates
        @captured_daily_deals = daily_deal_purchases.captured(dates)
      else
        @captured_daily_deals ||= daily_deal_purchases.captured(dates)
      end
    end

        
  end
end
