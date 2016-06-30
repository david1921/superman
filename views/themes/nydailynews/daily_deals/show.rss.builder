xml.instruct! :xml, :version => "1.0"

xml.rss :version => "2.0" do
  xml.channel do
    xml.item do
      xml.date        @publisher.localize_time(@time).to_date.strftime("%A, %B %d, %Y")
      xml.date_utc    @time.utc.to_date.strftime("%A, %B %d, %Y")
      xml.title       { xml.cdata!(@daily_deal.value_proposition) } 
      xml.dealurl     daily_deal_url(@daily_deal, :host => @daily_deal.publisher.production_host) 
      xml.facebook_dealurl     daily_deal_url(@daily_deal, :host => @daily_deal.publisher.production_host)
      xml.twitter_dealurl     daily_deal_url(@daily_deal, :host => @daily_deal.publisher.production_host)
      xml.start_at_utc    @daily_deal.start_at.utc.to_s
      xml.hide_at_utc    @daily_deal.hide_at.utc.to_s
      xml.dealphoto   @daily_deal.photo.url(:email)
      #
      # Kludge requested by NY Daily News to make their widget work
      #
      xml.pubDate     @daily_deal.photo.url(:email)
      
      xml.dealvalue   number_to_currency(@daily_deal.value, :precision => 0)
      xml.dealprice   number_to_currency(@daily_deal.price, :precision => 0)
      xml.yousave     number_to_currency(@daily_deal.value - @daily_deal.price, :precision => 0) 
      xml.advertiser_name @daily_deal.advertiser.name
      xml.adlogo      @daily_deal.advertiser.logo.url(:thumbnail)
      xml.adaddress   { xml.cdata!(@daily_deal.advertiser.address.join("<br/>")) }
      xml.locations do
        @daily_deal.advertiser.stores.each do |store|
          xml.location do
            xml.address_line_1 store.address_line_1
            xml.address_line_2 store.address_line_2
            xml.city           store.city              
            xml.state          store.state
            xml.zip            store.zip
            xml.latitude       store.latitude
            xml.longitude      store.longitude
          end
        end
      end
      xml.highlights  { xml.cdata!(@daily_deal.highlights) }
      xml.description { xml.cdata!(@daily_deal.description) }
    end
  end
end
