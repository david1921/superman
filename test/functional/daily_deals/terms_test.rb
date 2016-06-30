require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::TermsTest < ActionController::TestCase
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

  test "terms" do
    advertiser = advertisers(:changos)
    publisher  = advertiser.publisher
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)
    
    get :terms, :publisher_id => publisher.id
    
    assert_response :success
    assert_layout   "daily_deals"
    assert_template "daily_deals/terms"
  end  
  
  test "terms with layout parameter of 'popup'" do
    advertiser = advertisers(:changos)
    publisher  = advertiser.publisher
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)
    
    get :terms, :publisher_id => publisher.id, :layout => 'popup'
    
    assert_response :success
    assert_layout   false
    assert_template "daily_deals/terms"
  end  
  
end
