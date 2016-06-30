xml.instruct!(:xml, :version => '1.0')

xml.daily_deals do
  @daily_deals.each do |daily_deal|
    xml.daily_deal(:id => daily_deal.daily_deal_or_variation_listing) do
      xml.started_at                daily_deal.start_at.to_date.to_s(:compact)
      xml.ended_at                  daily_deal.hide_at.to_date.to_s(:compact)
      if admin?
        xml.source_publisher          daily_deal.source_publisher.try(:name)
      end
      xml.advertiser_name           daily_deal.advertiser_name
      if @market.present?
        xml.advertiser_href market_purchased_daily_deals_reports_advertiser_path(daily_deal.advertiser, @market, :dates_begin => @dates.begin, :dates_end => @dates.end)
      else
        xml.advertiser_href purchased_daily_deals_reports_advertiser_path(daily_deal.advertiser, :dates_begin => @dates.begin, :dates_end => @dates.end)
      end
      xml.publisher_advertiser_id   daily_deal.advertiser.try(:listing)
      xml.accounting_id             daily_deal.daily_deal_or_variation_accounting_id
      xml.listing                   daily_deal.daily_deal_or_variation_listing
      xml.value_proposition         daily_deal.daily_deal_or_variation_value_proposition
      xml.currency_code             daily_deal.currency_code
      xml.currency_symbol           daily_deal.currency_symbol
      xml.purchases_count           daily_deal.daily_deal_purchases_total_quantity
      xml.purchasers_count          daily_deal.daily_deal_purchasers_count
      xml.purchases_gross           daily_deal.daily_deal_purchases_gross
      xml.purchases_discount        daily_deal.daily_deal_purchases_gross - daily_deal.daily_deal_purchases_amount
      xml.refunds_total_quantity    daily_deal.daily_deal_refunded_voucher_count
      xml.refunds_total_amount      daily_deal.daily_deal_refunds_total_amount
      xml.account_executive         daily_deal.account_executive
      xml.purchases_amount          daily_deal.daily_deal_purchases_amount - daily_deal.daily_deal_refunds_total_amount

      xml.advertiser_revenue_share_percentage daily_deal.advertiser_revenue_share_percentage
      xml.advertiser_credit_percentage        daily_deal.advertiser_credit_percentage 
    end
  end
end

