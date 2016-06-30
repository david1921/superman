xml.instruct!(:xml, :version => '1.0')

xml.daily_deal_certificates do
  @daily_deal_certificates.each do |daily_deal_certificate|
    xml.daily_deal_certificate(:daily_deal_certificate_id => daily_deal_certificate.id) do
      xml.customer_name         daily_deal_certificate.consumer_name
      xml.recipient_name        daily_deal_certificate.redeemer_name
      xml.serial_number         daily_deal_certificate.serial_number
      xml.currency_symbol       daily_deal_certificate.currency_symbol
      xml.value_proposition     daily_deal_certificate.value_proposition
      xml.accounting_id         daily_deal_certificate.daily_deal.accounting_id
      xml.listing               daily_deal_certificate.daily_deal.listing
      xml.price                 "%.2f" % daily_deal_certificate.price
      xml.purchased_price       "%.2f" % daily_deal_certificate.actual_purchase_price
      xml.purchased_date        daily_deal_certificate.executed_at.to_date
      xml.affiliate_rev_share   "%.2f" % daily_deal_certificate.daily_deal.affiliate_revenue_share_percentage
      xml.affiliate_payout      "%.2f" % daily_deal_certificate.affiliate_payout
      xml.affiliate_total       "%.2f" % (daily_deal_certificate.price - daily_deal_certificate.affiliate_payout)
      xml.affiliate_name        daily_deal_certificate.affiliate_name
    end
  end
end

