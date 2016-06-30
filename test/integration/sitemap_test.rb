require File.dirname(__FILE__) + "/../test_helper"

class SitemapTest < ActionController::IntegrationTest
  context "/sitemap.xml" do
    setup do
      @publisher = Factory(:publisher, :label => "ocregister", :production_host => "dealoftheday.ocregister.com")
    end
    should "be succesful" do
      assert_routing("/sitemap.xml", {:controller => "home", :action => "sitemap"} )
      get "/sitemap.xml", nil, :host => @publisher.production_host
      assert_response :success
    end
    should "include deal of the day" do
      get "/sitemap.xml", nil, :host => @publisher.production_host
      assert_match("http://dealoftheday.ocregister.com/publishers/ocregister/deal-of-the-day", body )
    end
    should "include static pages" do
      static_pages = [:how_it_works, :contact, :faqs, :feature_your_business, :about_us, :affiliate, :terms, :privacy_policy]
      get "/sitemap.xml", nil, :host => @publisher.production_host
      static_pages.each do |page|
        assert_match("http://#{@publisher.production_host}/publishers/#{@publisher.id}/daily_deals/#{page.to_s}", body)
      end
    end
    should "works for multiple publishers using the same domain" do
      @pg = Factory(:publishing_group, :label => "rr")
      @publisher = []
      @publisher << Factory(:publisher, :label => "clickedin-austin", :publishing_group => @pg, :production_host => "clickedin.com")
      @publisher << Factory(:publisher, :label => "clickedin-dallas", :publishing_group => @pg, :production_host => "clickedin.com")
      @publisher << Factory(:publisher, :label => "clickedin-sanantonio", :publishing_group => @pg, :production_host => "clickedin.com")
      get "/sitemap.xml", nil, :host => @publisher.first.production_host
      @publisher.each do |publisher|
        assert_match("http://#{publisher.production_host}/publishers/#{publisher.label}/deal-of-the-day", body )
      end
    end
  end
end