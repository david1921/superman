require File.dirname(__FILE__) + "/../test_helper"

class CookieStoriesTest < ActionController::IntegrationTest

  test "referer is from time warner cable sites on initial request with no show_twc_logo cookie value set" do
    
    publishing_group = Factory(:publishing_group, :label => "rr")
    publisher        = Factory(:publisher, :label => "clickedin-austin", :publishing_group => publishing_group, :production_host => "deals.clickedin.com")
    daily_deal       = Factory(:daily_deal, :publisher => publisher)
    
    ["www.rr.com", "www.timewarnercable.com", "www.ny1.com", "www.ynn.com", "www.news14.com"].each do |refering_site|
      
      cookies["show_twc_logo"] = nil
      
      headers = {
        :referer => "http://#{refering_site}/"
      }
      
      assert_nil cookies["show_twc_logo"], "should not have show_twc_logo set to any value initially"      
      get "/publishers/#{publisher.label}/deal-of-the-day", {}, headers  
      assert_equal "true", cookies["show_twc_logo"], "should set show_twc_logo to true"            
      
    end    
  end
  
  test "referer is from a 3rd party site that is not a timewarner cable site and the initial show_twc_logo is set to true" do
    
    publishing_group = Factory(:publishing_group, :label => "rr")
    publisher        = Factory(:publisher, :label => "clickedin-austin", :publishing_group => publishing_group, :production_host => "deals.clickedin.com")
    daily_deal       = Factory(:daily_deal, :publisher => publisher)
    
    ["www.yahoo.com", "www.some3rdparty.com"].each do |refering_site|
      
      cookies["show_twc_logo"] = "true"
      
      headers = {
        :referer => "http://#{refering_site}/"
      }
      
      assert_equal "true", cookies["show_twc_logo"], "should have show_twc_logo initially set to true"      
      get "/publishers/#{publisher.label}/deal-of-the-day", {}, headers      
      assert_equal "", cookies["show_twc_logo"], "should delete show_twc_logo cookie"
    end
    
  end
  
  test "referer is from our domain and the initial show_twc_logo is set to true" do
  
    publishing_group = Factory(:publishing_group, :label => "rr")
    publisher        = Factory(:publisher, :label => "clickedin-austin", :publishing_group => publishing_group, :production_host => "deals.clickedin.com")
    daily_deal       = Factory(:daily_deal, :publisher => publisher)
    
    cookies['show_twc_logo'] = 'true'
    
    headers = {
      :referer => "http://#{publisher.production_host}"
    }
    
    assert_equal "true", cookies["show_twc_logo"], "should have show_twc_logo initially set to true"
    get "/publishers/#{publisher.label}/deal-of-the-day", {}, headers      
    assert_equal "true", cookies["show_twc_logo"], "should stil have show_twc_logo set to true"
    
  end
  
  test "referrer is from our domain and the initial show_twc_logo is not set" do

    publishing_group = Factory(:publishing_group, :label => "rr")
    publisher        = Factory(:publisher, :label => "clickedin-austin", :publishing_group => publishing_group, :production_host => "deals.clickedin.com")
    daily_deal       = Factory(:daily_deal, :publisher => publisher)
    
    cookies['show_twc_logo'] = nil
    
    headers = {
      :referer => "http://#{publisher.production_host}"
    }
    
    assert_nil cookies["show_twc_logo"], "should not have show_twc_logo initially set"
    get "/publishers/#{publisher.label}/deal-of-the-day", {}, headers      
    assert_nil cookies["show_twc_logo"], "should stil not have show_twc_logo set"    
    
  end
    
end
