xml.instruct!(:xml, :version => '1.0')

xml.publishers do
  @publishers.sort_by(&:name).each do |publisher|
    # We check that a publisher has placements, active offers, or impressions
    # because if they don't then there is no reason to display them
    
    active_coupons_in_range = publisher.offers.active_between(@dates)
    counts = {
      :advertisers => active_coupons_in_range.map(&:advertiser_id).uniq.size,
      :coupons     => active_coupons_in_range.size,
      :impressions => publisher.impressions_count(@dates)
    }

    if counts.detect { |k,v| !v.nil? and v > 0 }
      xml.publisher(:id => publisher.id ) do
        xml.publisher_name(publisher.name)
        xml.publisher_href(reports_publisher_path(publisher))
        xml.advertisers_count(counts[:advertisers])
        xml.coupons_count(counts[:coupons])
        xml.impressions_count(impressions = counts[:impressions])
        xml.clicks_count(leads = publisher.clicks_count(@dates, 'Offer'))
        xml.click_through_rate(impressions > 0 ? 100.0 * leads / impressions : 0.0)
        xml.prints_count(publisher.prints_count(@dates))
        xml.txts_count(publisher.txts_count(@dates))
        xml.emails_count(publisher.emails_count(@dates))
        xml.calls_count(publisher.calls_count(@dates))
        xml.facebooks_count(publisher.facebooks_count(@dates, 'Offer'))
        xml.twitters_count(publisher.twitters_count(@dates, 'Offer'))
      end
    end
  end
end
