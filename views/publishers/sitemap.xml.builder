xml.instruct! :xml, :version => '1.0'
xml.urlset :'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance", :'xsi:schemaLocation' => "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd", :xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9" do
  @publishers.each do |publisher|
    static_pages = [:how_it_works, :contact, :faqs, :feature_your_business, :about_us, :affiliate, :terms, :privacy_policy]
    static_pages.each do |page|
      xml.url do
        xml.loc try("#{page}_publisher_daily_deals_url".to_sym, publisher.id)
        xml.changefreq "monthly"
        xml.priority 0.5
      end
    end
    xml.url do
      xml.loc public_deal_of_day_url publisher.label
      xml.changefreq "hourly"
      xml.priority(0.8)
    end
  end
end