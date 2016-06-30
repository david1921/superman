xml.instruct!(:xml, :version => '1.0')

xml.advertisers do
  @advertisers.sort_by(&:name).each do |advertiser|
    xml.advertiser(:id => advertiser.id ) do
      xml.advertiser_name(advertiser.name) 
      xml.advertiser_listing(advertiser.listing) if @publisher.advertiser_has_listing?
      xml.advertiser_href(reports_advertiser_path(advertiser, :dates_begin => @dates.begin, :dates_end => @dates.end, :summary => @summary))
      xml.coupons_count(advertiser.offers_count)
      xml.impressions_count(impressions = advertiser.impressions_count.to_i)
      xml.clicks_count(leads = advertiser.clicks_count.to_i)
      xml.facebooks_count(advertiser.facebooks_count)
      xml.twitters_count(advertiser.twitters_count)
      xml.click_through_rate(impressions > 0 ? 100.0 * leads / impressions : 0.0)
      xml.prints_count(advertiser.prints_count)
      xml.txts_count(advertiser.txts_count)
      xml.emails_count(advertiser.emails_count)
      xml.calls_count(advertiser.calls_count)
    end
  end
end
