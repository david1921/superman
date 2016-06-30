xml.instruct! :xml, :version => '1.0'
xml.rss(:version => '2.0', 'xmlns:geo' => 'http://www.w3.org/2003/01/geo/wgs84_pos#') {
  xml.channel {
    xml.title( "Coupons For #{@publishing_group.name}" )
    xml.link( request.url )
    @offers.each do |offer|
      categories = offer.categories
      publisher  = offer.publisher
      xml.item {
        xml.title( offer.value_proposition )
        xml.description( offer.terms_with_expiration )
        xml.store( offer.advertiser_name )
        if categories.size > 0
          xml.category( categories.first.name )
          xml.subcategory( categories.second.name ) if categories.size > 1
        end
        xml.url render_public_offers_path(publisher, :offer_id => offer.id)
        store = offer.advertiser.store
        unless store.nil?
          xml.address( store.address.first ) 
          xml.phone( offer.formatted_phone_number )
          xml.city( store.city )
          xml.state( store.state )
          xml.zip_code( store.zip )
        end
        xml.expire_time(offer.expires_on.to_s(:simple)) if offer.expires_on
      }
    end
  }
}