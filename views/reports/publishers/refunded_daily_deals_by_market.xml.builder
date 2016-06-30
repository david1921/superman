xml.instruct!(:xml, :version => '1.0')

xml.markets do
  @markets.sort_by(&:name).each do |market|
    xml.market(:id => market.id ) do
      xml.market_name(market.name)
      if market.id.present?
        xml.market_href(market_refunded_daily_deals_reports_publisher_path(@publisher.to_param, market.id, :dates_begin => @dates.begin, :dates_end => @dates.end))
      else
        xml.market_href(refunded_daily_deals_reports_publisher_path(@publisher.to_param, :dates_begin => @dates.begin, :dates_end => @dates.end))
      end
      xml.deals_count(market.daily_deals_count)
      xml.currency_code(market.currency_code)
      xml.currency_symbol(market.currency_symbol)
      xml.refunded_vouchers_count(market.daily_deal_refunded_vouchers_count)
      xml.deal_purchasers_count(market.daily_deal_purchasers_count)
      xml.refunded_deals_gross(market.daily_deal_refunded_vouchers_gross)
      xml.refunded_deals_discount(market.daily_deal_refunded_vouchers_gross - market.daily_deal_refunded_vouchers_amount)
      xml.refunded_deals_amount(market.daily_deal_refunded_vouchers_amount)
    end
  end
end