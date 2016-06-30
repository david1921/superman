xml.instruct!(:xml, :version => '1.0')

xml.publishers do
  @publishers.sort_by(&:name).each do |publisher|
    xml.publisher(:id => publisher.id ) do
      xml.publisher_name(publisher.name)
      if publisher.markets.present?
        xml.publisher_href(refunded_daily_deals_by_market_reports_publisher_path(publisher))
      else
        xml.publisher_href(refunded_daily_deals_reports_publisher_path(publisher))
      end
      xml.deals_count(publisher.daily_deals_count)
      xml.currency_code(publisher.currency_code)
      xml.currency_symbol(publisher.currency_symbol)
      xml.refunded_vouchers_count(publisher.daily_deal_refunded_vouchers_count)
      xml.deal_purchasers_count(publisher.daily_deal_purchasers_count)
      xml.refunded_deals_gross(publisher.daily_deal_refunded_vouchers_gross)
      xml.refunded_deals_discount(publisher.daily_deal_refunded_vouchers_gross - publisher.daily_deal_refunded_vouchers_amount)
      xml.refunded_deals_amount(publisher.daily_deal_refunded_vouchers_amount)
    end
  end
end
