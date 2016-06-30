require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::PrivacyPolicyTest < ActionController::TestCase
  tests DailyDealsController

  def setup
    @valid_attributes = self.class.get_valid_attributes
  end

  def self.get_valid_attributes
    {
      :value_proposition => "$25 value for $12.99",
      :description => "This is a daily deal. Enjoy!",
      :terms => "These are the terms. Obey!",
      :quantity => 100,
      :min_quantity => 1,
      :price => 12.99,
      :value => 25.00,
      :start_at => 10.days.ago,
      :hide_at => Time.zone.now.tomorrow,
      :upcoming => true,
      :account_executive => "Bob Mann"
    }
  end
  
  test "privacy policy" do
    advertiser = advertisers(:changos)
    publisher  = advertiser.publisher
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)
    
    get :privacy_policy, :publisher_id => publisher.id
    
    assert_response :success
    assert_layout   "daily_deals"
    assert_template "daily_deals/privacy_policy"
  end 
  
  test "privacy policy with layout parameter of 'popup'" do
    advertiser = advertisers(:changos)
    publisher  = advertiser.publisher
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)
    
    get :privacy_policy, :publisher_id => publisher.id, :layout => 'popup'
    
    assert_response :success
    assert_layout   false
    assert_template "daily_deals/privacy_policy"    
  end
  
  test "california privacy policy" do
    publisher = Factory(:publisher)
    get :california_privacy_policy, :publisher_id => publisher.to_param
    assert_response :success
    assert_layout   "daily_deals"
    assert_template "daily_deals/california_privacy_policy"
  end
  
  test "timewarnercable california privacy policy" do
    publishing_group = Factory(:publishing_group, :label => "rr")
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    get :california_privacy_policy, :publisher_id => publisher.to_param
    assert_response       :success
    assert_theme_layout   "rr/layouts/daily_deals"
    assert_template       "themes/rr/daily_deals/california_privacy_policy"
  end
end
