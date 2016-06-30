xml.instruct! :xml, :version => '1.0'
xml.deal(:id => @daily_deal.id) do
  xml.title(@daily_deal.value_proposition)
  # advertiser_name kept for backwards compatibility
  xml.advertiser_name(@daily_deal.advertiser_name)
  xml.link(daily_deal_url(@daily_deal, :host => @daily_deal.publisher.daily_deal_host))

  if (photo = @daily_deal.photo) && photo.file?
    xml.image(photo.url(:widget))
    xml.standard_image(photo.url(:standard))
  end

  xml.subhead(@daily_deal.value_proposition_subhead)
  xml.description { xml.cdata!(@daily_deal.description) }
  xml.short_description(@daily_deal.short_description)

  xml.price(@daily_deal.price)
  xml.quantity(@daily_deal.quantity)
  xml.number_sold(@daily_deal.number_sold)
  xml.value(@daily_deal.value)
  xml.start_at(@daily_deal.start_at.utc.to_s(:iso8601))
  xml.hide_at(@daily_deal.hide_at.utc.to_s(:iso8601))
  xml.updated_at(@daily_deal.updated_at.utc.to_s(:iso8601))
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
        xml.address_line_1(store.try(:address_line_1))
        xml.address_line_2(store.try(:address_line_2))
        xml.city(store.try(:city))
        xml.state(store.try(:state))
        xml.zip_code(store.try(:zip_code))
        xml.phone_number(store.try(:phone_number))
      end
    end

    if (advertiser_logo = advertiser.logo) && advertiser_logo.file?
      xml.advertiser_logo(advertiser_logo.url(:normal))
    end
  end

end
