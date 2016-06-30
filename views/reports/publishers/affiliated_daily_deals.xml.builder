xml.instruct!(:xml, :version => '1.0')

xml.daily_deals do
  @daily_deals.each do |daily_deal|
    xml.daily_deal(:id => daily_deal.id) do
      xml.advertiser_name(daily_deal.advertiser_name)
      xml.advertiser_href(affiliated_daily_deals_reports_advertiser_url(daily_deal.advertiser, :dates_begin => @dates.begin, :dates_end => @dates.end))
      xml.value_proposition(daily_deal.value_proposition)
      xml.accounting_id(daily_deal.accounting_id)
      xml.listing(daily_deal.listing)
      xml.currency_code(daily_deal.currency_code)
      xml.currency_symbol(daily_deal.currency_symbol)
      xml.purchases_count(daily_deal.daily_deal_affiliate_total_quantity)
      xml.purchasers_count(daily_deal.daily_deal_purchasers_count)
      xml.affiliate_gross(daily_deal.daily_deal_affiliate_gross)
      xml.affiliate_rev_share(daily_deal.affiliate_revenue_share_percentage)
      xml.affiliate_payout(daily_deal.daily_deal_affiliate_payout)
      xml.affiliate_total(daily_deal.daily_deal_affiliate_gross - daily_deal.daily_deal_affiliate_payout)
      xml.started_at(daily_deal.start_at.to_date.to_s(:compact))
    end
  end
end


