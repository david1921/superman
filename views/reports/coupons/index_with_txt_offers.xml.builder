xml.instruct!(:xml, :version => '1.0')

xml.txt_offers do
  @txt_offers.sort_by(&:keyword).each do |txt_offer|
    xml.txt_offer(:id => txt_offer.id ) do
      xml.keyword(txt_offer.keyword)
      xml.inbound_txts_count(txt_offer.inbound_txts_count(@dates))
      xml.outbound_txts_count(txt_offer.txts_count(@dates))
    end
  end
end
