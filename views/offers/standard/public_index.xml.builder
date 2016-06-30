xml.instruct! :xml, :version => '1.0'

xml.offers do
  @offers.each do |offer|
    xml.offer(:id => offer.id) do
      xml.created_at(offer.created_at.utc.to_formatted_s(:iso8601))
      xml.updated_at(offer.updated_at.utc.to_formatted_s(:iso8601))
      xml.advertiser_name(offer.advertiser.name)
      xml.advertiser_logo(offer.advertiser.logo.try(:file?) ? offer.advertiser.logo.url(:standard) : nil)
      xml.advertiser_address do
        offer.address do |line|
          xml.address_line(line)
        end
      end
      xml.advertiser_phone(offer.formatted_phone_number)
      xml.advertiser_website(offer.publisher.link_to_website? ? offer.website_url : nil)
      xml.headline(offer.value_proposition)
      xml.terms(offer.terms)
      xml.photo(offer.photo.try(:file?) ? offer.photo.url(:standard) : nil)
      xml.expires_on(offer.expires_on ? offer.expires_on.to_formatted_s(:db) : nil)

      offer.categories_to_xml(xml)
    end
  end
end
