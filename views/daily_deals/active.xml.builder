xml.instruct! :xml, :version => '1.0'

# Array of active daily deals?
xml.active_daily_deals do
  xml.daily_deal(:uuid => @daily_deal.uuid) do
    xml.updated_at @daily_deal.updated_at
    xml.value_proposition @daily_deal.value_proposition
    xml.description @daily_deal.description
    xml.highlights @daily_deal.reviews
    xml.terms @daily_deal.terms
    xml.photo @daily_deal.photo
    xml.price @daily_deal.price
    xml.value @daily_deal.value
    xml.starts_at @daily_deal.start_at
    xml.ends_at @daily_deal.hide_at
    xml.expires_on @daily_deal.expires_on
    xml.minimum_purchase_quantity @daily_deal.min_quantity
    xml.maximum_purchase_quantity @daily_deal.max_quantity
    xml.total_quantity_available @daily_deal.quantity
    xml.connection do
      xml.status "http://api.analoganalytics.com/daily_deals/#{@daily_deal.uuid}/status.xml"
      xml.advertiser "http://api.analoganalytics.com/advertisers/#{@daily_deal.uuid}.xml"
      xml.publisher "http://api.analoganalytics.com/publishers/#{@daily_deal.uuid}.xml"
    end
  end
end