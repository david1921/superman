xml.instruct! :xml, :version => '1.0'

xml.web_coupons do
  @request.offers.each do |offer|
    xml.web_coupon(:id => "#{offer.id}-offer") do
      xml.value_proposition(offer.value_proposition.to_s.strip)
      xml.terms(offer.terms.to_s.strip)
      xml.show_at(Time.zone.parse(offer.show_on.to_s).utc.to_formatted_s(:iso8601)) if offer.show_on
      xml.hide_at(Time.zone.parse(offer.expires_on.to_s).end_of_day.utc.to_formatted_s(:iso8601)) if offer.expires_on
      offer.categories_to_xml(xml, "-category")
      xml.photo_url(offer.photo.url(:large)) if offer.photo.file?

      advertiser = offer.advertiser
      xml.advertiser(:id => "#{advertiser.id}-advertiser") do
        xml.name(advertiser.name.to_s.strip)
        if (store = advertiser.store)
          xml.address do
            xml.address_line_1(store.address_line_1)
            xml.address_line_2(store.address_line_2) if store.address_line_2.present?
            xml.city(store.city)
            xml.state(store.state)
            xml.zip(store.zip)
          end
        end
        xml.phone(advertiser.formatted_phone_number) if advertiser.phone_number?
        xml.website_url(advertiser.website_url) if advertiser.website_url.present?
      end
      
      xml.content(:type => "xhtml") do
        xml << @xhtml[offer.id]
      end
    end
  end
end
