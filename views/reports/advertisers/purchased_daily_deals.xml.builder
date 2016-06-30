xml.instruct!(:xml, :version => '1.0')

xml.daily_deal_certificates do
  @daily_deal_certificates.each do |daily_deal_certificate|
    xml.daily_deal_certificate(:daily_deal_certificate_id => daily_deal_certificate.id) do
      xml.customer_name     daily_deal_certificate.consumer_name
      xml.recipient_name    daily_deal_certificate.redeemer_name
      xml.serial_number     daily_deal_certificate.serial_number
      xml.bar_code          daily_deal_certificate.bar_code
      xml.redeemed_at       daily_deal_certificate.redeemed_at.present? ? daily_deal_certificate.redeemed_at.to_date : ""
      xml.currency_symbol   daily_deal_certificate.currency_symbol
      xml.store_name        daily_deal_certificate.store_name
      xml.value_proposition daily_deal_certificate.value_proposition
      xml.value             "%.2f" % daily_deal_certificate.value
      xml.price             "%.2f" % daily_deal_certificate.price
      xml.purchased_price   "%.2f" % daily_deal_certificate.actual_purchase_price
      xml.purchased_date    daily_deal_certificate.executed_at.to_date
    end
  end
end
