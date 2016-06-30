require File.dirname(__FILE__) + "/../test_helper"

class HomePageTest < ActionController::IntegrationTest
  test "home page for publisher with production host" do
    publisher = Factory(:publisher, :label => "macombdaily", :production_host => "macombdaily.deals2click4.com")
    get "/", nil, :host => "macombdaily.deals2click4.com"
    assert_redirected_to public_offers_path(publisher)
  end

  test "home page for publisher without production host" do
    publisher = Factory(:publisher, :self_serve => true)
    get "/", nil, :host => "sb1.analoganalytics.com"
    assert_redirected_to new_session_path
    
    user = Factory(:user, :company => publisher)
    post session_path, :user => { :login => user.login, :password => "test" }, :host => "sb1.analoganalytics.com"
    assert_redirected_to root_path
    
    get "/", nil, :host => "sb1.analoganalytics.com"
    assert_redirected_to publisher_advertisers_path(publisher)
  end
  
  test "home page for coupon portals" do
      # by coupon portals I mean the cnhi ones pointing to coupons.analoganalytics.com
    pg = Factory(:publishing_group)
    publisher = Factory(:publisher, :production_host => "coupons.clintonherald.com", :publishing_group => pg)
  
    get "/", nil, :host => "coupons.clintonherald.com"
    assert_redirected_to "http://coupons.clintonherald.com/publishers/#{publisher.id}/offers"

  end
end
