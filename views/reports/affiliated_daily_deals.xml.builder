xml.instruct!(:xml, :version => '1.0')

xml.publishers do
  @publishers.sort_by(&:name).each do |publisher|
    xml.publisher(:id => publisher.id) do
      xml.publisher_name(publisher.name)
      xml.publisher_href(affiliated_daily_deals_reports_publisher_path(publisher))

      xml.currency_code(publisher.currency_code)
      xml.currency_symbol(publisher.currency_symbol)

      xml.deals_count(publisher.daily_deals_count)
      xml.deal_purchasers_count(publisher.daily_deal_purchasers_count)
      xml.affiliated_deals_count(publisher.daily_deal_purchases_total_quantity)

      xml.affiliated_deals_gross(publisher.daily_deal_affiliate_gross)
      xml.affiliated_deals_payout(publisher.daily_deal_affiliate_payout)
      xml.affiliated_deals_amount(publisher.daily_deal_affiliate_gross - publisher.daily_deal_affiliate_payout)
    end
  end
end
