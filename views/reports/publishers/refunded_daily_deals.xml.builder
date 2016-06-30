xml.instruct!(:xml, :version => '1.0')

xml.daily_deals do
  @daily_deals.each do |daily_deal|
    xml.daily_deal(:id => daily_deal.id) do
      xml.advertiser_name(daily_deal.advertiser_name)
      if @market.present?
        xml.advertiser_href market_refunded_daily_deals_reports_advertiser_path(daily_deal.advertiser, @market, :dates_begin => @dates.begin, :dates_end => @dates.end)
      else
        xml.advertiser_href refunded_daily_deals_reports_advertiser_path(daily_deal.advertiser, :dates_begin => @dates.begin, :dates_end => @dates.end)
      end
      xml.advertiser_href()
      xml.accounting_id(daily_deal.accounting_id)
      xml.listing(daily_deal.listing)
      xml.value_proposition(daily_deal.value_proposition)
      xml.currency_code(daily_deal.currency_code)
      xml.currency_symbol(daily_deal.currency_symbol)
      xml.refunded_purchases_count(daily_deal.daily_deal_refunded_purchases_count)
      xml.refunded_purchasers_count(daily_deal.daily_deal_refunded_purchasers_count)
      xml.refunded_vouchers_count(daily_deal.daily_deal_vouchers_refunded_count)
      xml.refunds_gross(daily_deal.daily_deal_refunds_gross)
      xml.refunds_discount(daily_deal.daily_deal_refunds_gross - daily_deal.daily_deal_refunds_amount)
      xml.refunds_amount(daily_deal.daily_deal_refunds_amount)
      xml.started_at(daily_deal.start_at.to_date.to_s(:compact))
      xml.expires_on(daily_deal.expires_on.try(:to_s, :compact))
    end
  end
end

