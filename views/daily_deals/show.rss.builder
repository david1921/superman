xml.instruct! :xml, :version => "1.0"

xml.rss :version => "2.0" do
  xml.channel do       

    xml.title         "#{@publisher.brand_name} Daily Deals RSS" 
    xml.link          "http://#{@publisher.host}"
    xml.lastBuildDate @publisher.localize_time(@time).rfc822

    xml.item do
      xml.pubDate     @publisher.localize_time(@daily_deal.start_at).rfc822
      xml.title       { xml.cdata!(@daily_deal.value_proposition) }
      xml.description { xml.cdata!(@daily_deal.description) }
      xml.link        daily_deal_url( @daily_deal, :host => @publisher.host )
      if @daily_deal.photo.file?
        xml.enclosure( :url => @daily_deal.photo.url, :length => @daily_deal.photo.size, :type => @daily_deal.photo.content_type )
      end

      xml.subhead(@daily_deal.value_proposition_subhead)
      xml.short_description(@daily_deal.short_description)

      xml.price(@daily_deal.price)
      xml.quantity(@daily_deal.quantity)
      xml.value(@daily_deal.value)
      xml.hide_at(@daily_deal.hide_at.utc.to_s(:iso8601)) if @publisher.publishing_group.try(:label) == "entercomnew"
      xml.highlights { xml.cdata!(@daily_deal.highlights) }
      xml.terms { xml.cdata!(@daily_deal.terms) }
      xml.reviews { xml.cdata!(@daily_deal.reviews) }

      xml.twitter_status_text(@daily_deal.twitter_status_text)
      xml.facebook_title_text(@daily_deal.facebook_title_text)

      xml.min_quantity(@daily_deal.min_quantity)
      xml.max_quantity(@daily_deal.max_quantity)

      xml.listing(@daily_deal.listing)

      advertiser = @daily_deal.advertiser
      xml.advertiser do
        xml.name(advertiser.name)
        xml.website_url(advertiser.website_url)

        advertiser.stores.each do |store|
          xml.store do
            xml.address_line_1(store.address_line_1)
            xml.address_line_2(store.address_line_2)
            xml.city(store.city)
            xml.state(store.state)
            xml.zip_code(store.zip_code)
            xml.phone_number(store.phone_number)
          end
        end

        if (advertiser_logo = advertiser.logo) && advertiser_logo.file?
          xml.advertiser_logo(advertiser_logo.url(:normal))
        end
      end
    end

  end
end
