require File.dirname(__FILE__) + "/../test_helper"

class PublishersTest < ActionController::IntegrationTest
  def test_routing
    assert_routing({ :method => "put", :path => "/publishers/123" }, { :controller => "publishers", :action => "update", :id => "123" })
    assert_routing({ :method => "get", :path => "/publishers/1t3" }, { :controller => "publishers", :action => "show", :label => "1t3" })
  end

  # Routes with :label param can sabotage REST routes
  def test_public_urls
    publisher = publishers(:my_space)
  
    get "/publishers/#{publisher.label}/coupon_ad"
    assert_response :success
    assert_select "a", "Click to see these and more on our new coupons page"
  
    get "/publishers/#{publisher.to_param}/offers"
    assert_response :success
    assert_select "h3", "Search"
    assert_select "h3", "Categories"
    assert_select "title", "MySpace: Coupons"
  
    get "/publishers/#{publisher.label}/index_coupons"
    assert_redirected_to "/publishers/#{publisher.to_param}/offers?iframe_height=750&iframe_width=936&page_size=4"
  
    get "/publishers/#{publisher.label}/embed_coupons.js"
    assert_response :success
    assert @response.body["document.write"]
    assert @response.body["iframe"]
  
    get "/publishers/#{publisher.label}/embed_coupon_ad.js"
    assert_response :success
    assert @response.body["document.write"]
    assert @response.body["analog-analytics-ad"]
  
    get "/publishers/#{publishers(:tucsonweekly).label}"
    assert_response :success
    assert_select "h1", "Coupons and Discounts"
  
    get "/publishers/#{publishers(:tucsonweekly).label}/daily_deals"
    assert_response :success
  end
  
  def test_admin_urls
    post session_path, :user => { :login => "aaron", :password => "monkey", :remember_me_flag => true }
    assert_redirected_to root_path
  
    get "/publishers/new"
    assert_response :success
    assert_select "label", "Name:"
    assert_select "label", "Theme:"
  
    publisher = publishers(:my_space)
    get "/publishers/#{publisher.label}/coupons_page"
    assert_response :success
    assert_select "h1", "#{publisher.name} Coupons"
  
    get "/publishers/#{publisher.label}/coupon_ad_page"
    assert_response :success
    assert_select "h1", "#{publisher.name} Coupon Ad"
  
    get "/publishers"
    assert_response :success
    assert_select "h2", "Publishers"
    
    get "/publishers/#{publisher.to_param}/advertisers"
    assert_response :success
    assert_select "h2", /Publishers.*MySpace.*Advertisers/
    
    put "/publishers/#{publisher.to_param}", :publisher => { :label => "foobar" }
    assert_redirected_to edit_publisher_path(publisher)
    assert_equal "foobar", publisher.reload.label

    get "/publishers/#{publishers(:tucsonweekly).to_param}/daily_deals"
    assert_response :success
  end
end
