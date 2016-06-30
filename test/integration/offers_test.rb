require File.dirname(__FILE__) + "/../test_helper"

class OffersTest < ActionController::IntegrationTest
  test "thumbnail" do
    publisher   = publishers(:houston_press) 
    publisher.update_attribute(:production_host, "coupons.houstonpress.com")    
    advertiser  = publisher.advertisers.create!(:name => "Joe's automotive", :listing => "mylisting")
    
    offer_1       = advertiser.offers.create!( :message => "first offer", :category_names => "Retail" )
    offer_2       = advertiser.offers.create!( :message => "second offer", :category_names => "Cars : Detailing" )
    
    get "/publishers/houstonpress/thumbnail"
    assert_response :success
  end
end