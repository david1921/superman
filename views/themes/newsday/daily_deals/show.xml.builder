xml.instruct! :xml, :version => '1.0'
xml.deal(:id => @daily_deal.id) do
  xml.site("Newsday")
  xml.title(@daily_deal.value_proposition)
  xml.advertiser_name(@daily_deal.advertiser_name)
  xml.link(daily_deal_url(@daily_deal, :host => @daily_deal.publisher.daily_deal_host))

  if (photo = @daily_deal.photo) && photo.file?
    xml.image(photo.url(:widget))
  end
end