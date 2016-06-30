xml.instruct!(:xml, :version => '1.0')

xml.purchased_gift_certificates do
  @purchased_gift_certificates.each do |purchased_gift_certificate|
    xml.purchased_gift_certificate(:id => purchased_gift_certificate.id) do
      xml.id(purchased_gift_certificate.id)
      xml.publisher_name(purchased_gift_certificate.publisher.name)
      xml.item_number(purchased_gift_certificate.item_number)
      xml.value("%.2f" % purchased_gift_certificate.value)
      xml.currency_code(purchased_gift_certificate.currency_code)
      xml.currency_symbol(purchased_gift_certificate.currency_symbol)
      xml.serial_number(purchased_gift_certificate.serial_number)
      xml.paypal_payment_date(purchased_gift_certificate.paypal_payment_date.to_date)
      xml.paypal_txn_id(purchased_gift_certificate.paypal_txn_id)
      xml.paypal_payment_gross("%.2f" % purchased_gift_certificate.paypal_payment_gross)
      xml.recipient_name(purchased_gift_certificate.recipient_name)
      xml.paypal_payer_email(purchased_gift_certificate.paypal_payer_email)
      xml.status(purchased_gift_certificate.status)
    end
  end
end
