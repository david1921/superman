xml.instruct!(:xml, :version => '1.0')

xml.gift_certificates do
  @gift_certificates.sort_by(&:item_number).each do |gift_certificate|
    xml.gift_certificate(:id => gift_certificate.id ) do
      xml.item_number(gift_certificate.item_number)
      xml.available_count_begin(gift_certificate.available_count_begin)
      xml.available_revenue_begin(gift_certificate.available_revenue_begin)
      xml.currency_symbol(gift_certificate.currency_symbol)
      xml.purchased_count(gift_certificate.purchased_count)
      xml.purchased_revenue(gift_certificate.purchased_revenue)
      xml.available_count_end(gift_certificate.available_count_end)
      xml.available_revenue_end(gift_certificate.available_revenue_end)
    end
  end
end


