xml.instruct!(:xml, :version => '1.0')

xml.publishers do
  @publishers.sort_by(&:name).each do |publisher|
    xml.publisher(:id => publisher.id ) do
      xml.publisher_name(publisher.name)
      if publisher.markets.present?
        xml.publisher_href(purchased_daily_deals_by_market_reports_publisher_path(publisher))
      else
        xml.publisher_href(purchased_daily_deals_reports_publisher_path(publisher))
      end
      xml.deals_count(publisher.daily_deals_count)
      xml.currency_code(publisher.currency_code)
      xml.currency_symbol(publisher.currency_symbol)
      xml.purchased_deals_count(publisher.daily_deal_purchases_total_quantity)
      xml.deal_purchasers_count(publisher.daily_deal_purchasers_count)
      xml.purchased_deals_gross(publisher.daily_deal_purchases_gross)
      xml.purchased_deals_discount(publisher.daily_deal_purchases_gross - publisher.daily_deal_purchases_actual_purchase_price)
      xml.purchased_deals_refund_amount(publisher.daily_deal_purchases_refund_amount)
      xml.purchased_deals_amount(publisher.daily_deal_purchases_actual_purchase_price - publisher.daily_deal_purchases_refund_amount)
    end
  end
end
