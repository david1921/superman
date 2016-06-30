xml.daily_deal {
  xml.id daily_deal.id
  xml.updated_at daily_deal.updated_at.utc.iso8601
  xml.deal_url daily_deal_url(daily_deal, :host => daily_deal.publisher.production_daily_deal_host)
  xml.url daily_deal.website_url
  xml.listing daily_deal.listing
  xml.category daily_deal.analytics_category.try(:name)
  xml.value_proposition daily_deal.value_proposition
  xml.value_proposition_subhead daily_deal.value_proposition_subhead
  xml.description do |description|
    description.cdata!(daily_deal.description)
  end
  xml.short_description daily_deal.short_description
  xml.highlights do |highlights|
    highlights.cdata!(daily_deal.highlights)
  end
  xml.reviews do |reviews|
    reviews.cdata!(daily_deal.reviews)
  end
  xml.terms do |terms|
    terms.cdata!(daily_deal.terms)
  end
  xml.photo_url daily_deal.photo.try(:url)
  xml.value daily_deal.value
  xml.price daily_deal.price
  xml.starts_at daily_deal.start_at.utc.iso8601
  xml.ends_at daily_deal.hide_at.utc.iso8601
  xml.expires_on daily_deal.expires_on
  xml.facebook_title_text daily_deal.facebook_title_text
  xml.twitter_status_text daily_deal.twitter_status_text
  xml.featured daily_deal.featured
  xml.quantity_available daily_deal.quantity
  xml.min_purchase_quantity daily_deal.min_quantity
  xml.max_purchase_quantity daily_deal.max_quantity
  xml.custom_1 daily_deal.custom_1
  xml.custom_2 daily_deal.custom_2
  xml.custom_3 daily_deal.custom_3
  xml.time_zone daily_deal.publisher.time_zone
  xml.quantity daily_deal.quantity

  if defined?(include_publisher_label) && include_publisher_label
    xml.publisher_label(daily_deal.publisher.label)
  end

  xml.merchant {
    xml.listing daily_deal.advertiser.try(:listing)
    xml.brand_name daily_deal.advertiser.try(:name)
    xml.logo_url daily_deal.advertiser.try(:logo).try(:url)
    xml.website_url daily_deal.advertiser.try(:website_url)

    if daily_deal.advertiser.stores.empty?
      xml.locations
    else
      xml.locations {
        daily_deal.advertiser.stores.each do |store|
          xml.location {
            xml.listing store.listing
            xml.address_line_1 store.address_line_1
            xml.address_line_2 store.address_line_2
            xml.city store.city
            xml.state store.state
            xml.zip store.zip
            xml.latitude store.latitude
            xml.longitude store.longitude
            xml.phone_number store.phone_number
          }
        end
      }
    end
  }

  if daily_deal.markets.empty?
    xml.markets
  else
    xml.markets {
      daily_deal.markets.each do |market|
        xml.market {
          xml.id market.id
          xml.name market.name
        }
      end
    }
  end
}
