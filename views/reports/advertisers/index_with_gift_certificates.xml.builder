xml.instruct!(:xml, :version => '1.0')

xml.advertisers do
  @advertisers.sort_by(&:name).each do |advertiser|
    xml.advertiser(:id => advertiser.id ) do
      xml.advertiser_name(advertiser.name)
      xml.advertiser_href(reports_advertiser_path(advertiser, :dates_begin => @dates.begin, :dates_end => @dates.end, :summary => @summary))
      xml.available_count_begin(advertiser.available_count_begin)
      xml.currency_code(@publisher.currency_code)
      xml.currency_symbol(@publisher.currency_symbol)
      xml.available_revenue_begin(advertiser.available_revenue_begin)
      xml.purchased_count(advertiser.purchased_count)
      xml.purchased_revenue(advertiser.purchased_revenue)
      xml.available_count_end(advertiser.available_count_end)
      xml.available_revenue_end(advertiser.available_revenue_end)
    end
  end
end


