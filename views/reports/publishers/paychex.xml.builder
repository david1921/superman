xml.instruct!(:xml, :version => '1.0')

xml.daily_deals do
  @daily_deals.each do |daily_deal|
    xml.daily_deal(:id => daily_deal.id) do
      xml.currency_symbol(daily_deal.publisher.currency_symbol)
      xml.payment_calc_date(@date.to_formatted_s(:db_date))
      xml.merchant_id(daily_deal.advertiser.id)
      xml.merchant_name(daily_deal.advertiser.name)
      xml.merchant_tax_id(daily_deal.advertiser.federal_tax_id)
      xml.advertiser_split(daily_deal.advertiser_revenue_share_percentage)
      xml.advertiser_share("%.2f" % daily_deal.paychex_advertiser_share.round(2))
      xml.deal_id(daily_deal.id)
      xml.deal_headline(daily_deal.value_proposition)
      xml.deal_start_date(daily_deal.start_at.to_formatted_s(:db_date))
      xml.deal_end_date(daily_deal.hide_at.to_formatted_s(:db_date))
      xml.last_modified_by("")
      xml.number_sold(daily_deal.number_sold(@date))
      xml.number_refunded(daily_deal.number_refunded(@date))
      xml.gross("%.2f" % daily_deal.gross_revenue_to_date.round(2))
      xml.refunds("%.2f" % daily_deal.daily_deal_refunds_total_amount.round(2))
      xml.credit_card_fee("%.2f" % daily_deal.paychex_credit_card_fee.round(2))
      xml.total_payment_due("%.2f" % daily_deal.paychex_total_payment_due(@date).round(2))
    end
  end
end


