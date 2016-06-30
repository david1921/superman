xml.instruct! :xml, :version => '1.0'

root_attrs = { :type => @service_name }
root_attrs[:dates_begin] = @api_request.dates_begin.to_formatted_s if @api_request.dates_begin
root_attrs[:dates_end] = @api_request.dates_end.to_formatted_s if @api_request.dates_end

dates = @api_request.dates

xml.service_response(root_attrs) do
   xml.publisher(:label => @publisher.label) do
    hash = @api_request.advertisers_with_offers_and_txt_offers
    hash.keys.sort_by(&:listing).each do |advertiser|
      objects_by_type = hash[advertiser]
      xml.advertiser(:client_id => advertiser.listing_parts[0], :location_id => advertiser.listing_parts[1]) do
        objects_by_type[:offers].try(:each) do |offer|
          xml.web_coupon( :web_coupon_id => offer.id ) do
            xml.tag! :impressions, offer.impressions_count( dates )
            xml.tag! :clicks, offer.clicks_count( dates )
            xml.tag! :prints, offer.prints_count( dates )
            xml.tag! :txts, offer.txts_count( dates )
            xml.tag! :emails, offer.emails_count( dates )
            xml.tag! :fb_shares, offer.facebooks_count( dates )
            xml.tag! :twitter_shares, offer.twitters_count( dates )
          end
        end
        objects_by_type[:txt_offers].try(:each) do |txt_offer|
          xml.txt_coupon( :txt_coupon_id => txt_offer.id ) do
            xml.tag! :inbound_txts, txt_offer.inbound_txts_count( dates )
          end
        end
      end
    end
  end
end
