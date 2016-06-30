require File.dirname(__FILE__) + "/../test_helper"

class GoogleTrackingTest < ActionController::IntegrationTest

  test "standalone publisher with no markets" do
    publisher = Factory(:publisher, :label => "fox26")
    publisher.update_attribute(:publishing_group, nil)
    daily_deal = Factory(:daily_deal, :publisher => publisher)
 
    get "/daily_deals/#{daily_deal.id}"
    assert_response :success
    assert_match( /UA\-21436942\-1/, body )
    assert_match( /#{publisher.google_analytics_account_ids}/, body )
    
    assert_match("'Publishing_Group', '(none)'", body)
    assert_match("'Publisher', 'fox26'", body )
  end
  test "publisher under publishing group" do
    pg = Factory(:publishing_group, :label => "entercom-group")
    publisher = Factory(:publisher, :label => "entercomnew", :publishing_group => pg)
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :publisher => publisher, :advertiser => advertiser)
  
    assert(daily_deal.publisher == daily_deal.advertiser.publisher)
    get "/daily_deals/#{daily_deal.id}"
    
    assert_response :success
    assert_match( /UA\-21436942\-1/, body )  
    assert_match( /#{pg.google_analytics_account_ids}/, body )
    assert_match( /#{publisher.google_analytics_account_ids}/, body )
    
    assert_match("'Publishing_Group', 'entercom-group'", body)
    assert_match("'Publisher', 'entercomnew'",body)
  end
  
  test "standalone publisher with market" do
    publisher = Factory :publisher, :label => "kowabunga", :publishing_group => nil
    advertiser = Factory :advertiser, :publisher => publisher
    3.times { Factory(:market, :publisher => publisher) }
    daily_deal = Factory(:daily_deal_with_market, :advertiser => advertiser, :market_ids => [publisher.markets.first.id] )
    get "/publishers/#{publisher.label}/#{publisher.markets.first.label}/deal-of-the-day"

    assert_response :success
    assert_match( /UA\-21436942\-1/, body )
    assert_match( /#{publisher.google_analytics_account_ids}/, body )
    assert_match( /#{publisher.markets.first.google_analytics_account_ids}/, body )

    assert_match("'Publishing_Group', 'kowabunga'", body)
    assert_match("'Publisher', 'kowabunga-#{publisher.markets.first.label}'", body )    
  end    
end
