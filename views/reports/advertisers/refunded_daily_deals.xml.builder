xml.instruct!(:xml, :version => '1.0')

xml.daily_deal_certificates do
  @daily_deal_certificates.select(&:refunded?).each do |daily_deal_certificate|
    xml.daily_deal_certificate(:daily_deal_certificate_id => daily_deal_certificate.id) do
      xml.customer_name     daily_deal_certificate.consumer_name
      xml.recipient_name    daily_deal_certificate.redeemer_name
      xml.serial_number     daily_deal_certificate.serial_number
      xml.currency_symbol   daily_deal_certificate.currency_symbol
      xml.store_name        daily_deal_certificate.store_name
      xml.value_proposition daily_deal_certificate.value_proposition
      xml.value             daily_deal_certificate.value
      xml.price             daily_deal_certificate.price
      xml.refund_amount     "%.2f" % (daily_deal_certificate.refund_amount)
      xml.refund_date       daily_deal_certificate.refunded_at.to_date
    end
  end
end
