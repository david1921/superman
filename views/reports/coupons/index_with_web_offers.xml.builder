xml.instruct!(:xml, :version => '1.0')

xml.offers do
  @offers.sort_by(&:message).each do |offer|
    xml.offer(:id => offer.id ) do
      xml.offer_name(offer.message)
      xml.listing(offer.listing) if @advertiser.offer_has_listing?
      xml.impressions_count(impressions = offer.impressions_count(@dates))
      xml.clicks_count(clicks = offer.clicks_count(@dates))
      xml.click_through_rate(impressions > 0 ? 100.0 * clicks / impressions : 0.0)
      xml.prints_count(offer.prints_count(@dates))
      xml.txts_count(offer.txts_count(@dates))
      xml.emails_count(offer.emails_count(@dates))
      xml.calls_count(offer.calls_count(@dates))
      xml.facebooks_count(offer.facebooks_count(@dates))
      xml.twitters_count(offer.twitters_count(@dates))
      xml.account_executive(offer.account_executive)
    end
  end
end
