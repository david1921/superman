xml.instruct! :xml, :version => '1.0'
xml.rss(:version => '2.0', 'xmlns:geo' => 'http://www.w3.org/2003/01/geo/wgs84_pos#') {
  xml.channel {
    xml.title( "Coupons For #{@publisher.name}" )
    xml.link(render_public_offers_path(@publisher, :skip_trailing_slash => true))
    @offers.each do |offer|
      categories = offer.categories
      xml.item {
        xml.offer( offer.message )
        xml.title( offer.value_proposition )
        xml.text_message( offer.txt_message )
        xml.description( offer.terms_with_expiration )
        xml.store( offer.advertiser_name )
        if categories.size > 0
          xml.category( categories.first.name )
          xml.subcategory( categories.second.name ) if categories.size > 1
        end
        xml.url(render_public_offers_path(@publisher, :offer_id => offer.id))
        xml.image_url( offer.advertiser.logo.url(:standard) )
        store = offer.advertiser.store
        unless store.nil?
          xml.address( store.address.first ) 
          xml.phone( offer.formatted_phone_number )
          xml.city( store.city )
          xml.state( store.state )
          xml.zip_code( store.zip )
        end
        xml.expire_time(offer.expires_on.to_s(:simple)) if offer.expires_on
        xml.show_time(offer.show_on.to_s(:simple)) if offer.show_on
      }
    end
  }
}
