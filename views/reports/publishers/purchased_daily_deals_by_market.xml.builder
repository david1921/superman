xml.instruct!(:xml, :version => '1.0')

xml.markets do
  @markets.sort_by(&:name).each do |market|
    xml.market(:id => market.id ) do
      xml.market_name(market.name)
      if market.id.present?
        xml.market_href(market_purchased_daily_deals_reports_publisher_path(@publisher.to_param, market.id, :dates_begin => @dates.begin, :dates_end => @dates.end))
      else
        xml.market_href(purchased_daily_deals_reports_publisher_path(@publisher.to_param, :dates_begin => @dates.begin, :dates_end => @dates.end))
      end
      xml.deals_count(market.daily_deals_count)
      xml.currency_code(market.currency_code)
      xml.currency_symbol(market.currency_symbol)
      xml.purchased_deals_count(market.daily_deal_purchases_total_quantity)
      xml.deal_purchasers_count(market.daily_deal_purchasers_count)
      xml.purchased_deals_gross(market.daily_deal_purchases_gross)
      xml.purchased_deals_discount(market.daily_deal_purchases_gross - market.daily_deal_purchases_actual_purchase_price)
      xml.purchased_deals_refund_amount(market.daily_deal_purchases_refund_amount)
      xml.purchased_deals_amount(market.daily_deal_purchases_actual_purchase_price - market.daily_deal_purchases_refund_amount)
    end
  end
end