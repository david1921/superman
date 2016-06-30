xml.instruct! :xml, :version => "1.0"

xml.rss :version => "2.0" do
  xml.channel do
    xml.item do
      xml.date        @publisher.localize_time(@time).to_date.strftime("%A, %B %d %Y")
      xml.title       { xml.cdata!(@daily_deal.value_proposition) }
      xml.dealphoto   @daily_deal.photo.url(:email)
      xml.dealvalue   number_to_currency(@daily_deal.value, :precision => 0, :unit => @daily_deal.currency_symbol)
      xml.dealprice   number_to_currency(@daily_deal.price, :precision => 0, :unit => @daily_deal.currency_symbol)
      xml.yousave     number_to_currency(@daily_deal.value - @daily_deal.price, :precision => 0, :unit => @daily_deal.currency_symbol)
      xml.adlogo      @daily_deal.advertiser.logo.url(:thumbnail)
      xml.adaddress   { xml.cdata!(@daily_deal.advertiser.address.join("<br/>")) }
      xml.highlights  { xml.cdata!(@daily_deal.highlights) }
      xml.description { xml.cdata!(@daily_deal.description) }
    end
  end
end
