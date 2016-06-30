xml.instruct!(:xml, :version => '1.0')

xml.advertisers do
  @advertisers.sort_by(&:name).each do |advertiser|
    xml.advertiser(:id => advertiser.id ) do
      xml.advertiser_name(advertiser.name)
      xml.advertiser_href(reports_advertiser_path(advertiser, :dates_begin => @dates.begin, :dates_end => @dates.end, :summary => @summary))
      xml.txt_coupons_count(advertiser.txt_offers.count)
      xml.inbound_txts_count(advertiser.inbound_txts_count(@dates))
    end
  end
end
