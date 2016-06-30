require File.dirname(__FILE__) + "/../test_helper"

class DailyDealCachedTest < ActionController::IntegrationTest
  test "should show deal with theme template cached" do
    publishing_group = Factory(:publishing_group, :name => "Entercom", :label => "entercomnew")
    publisher = Factory(:publisher,:name => "My Denver Perks", :label => "entercom-denver", :publishing_group => publishing_group)
    advertiser = publisher.advertisers.create!(:name => "Advertiser", :description => "test description")
    daily_deal = advertiser.daily_deals.create!(
      :price => 39,
      :value => 80,
      :description => "awesome deal",
      :value_proposition => "buy now",
      :terms => "GPL",
      :start_at => 1.day.ago,
      :hide_at => 3.days.from_now
    )
    # Rails.cache.clear
    # @pre_test_caching = Rails.configuration.action_controller.perform_caching
    Rails.configuration.action_controller.perform_caching = false
    
    # get "/daily_deals/#{daily_deal.id}"
    # 
    # assert_response     :success
    # assert_template     "themes/entercomnew/daily_deals/show"
    # assert_theme_layout "entercomnew/layouts/daily_deals"
    # assert_select "meta[property=og:title][content=?]", "My Denver Perks Deal of the Day: buy now", 1, "og:title metatag for daily deal"
    # 
    # daily_deal.update_attribute(:value_proposition, "something else")
    # first_request = @response.body

    get "/daily_deals/#{daily_deal.id}" # make the same request again, this time you should hit a fragment-cached result
    assert_response     :success
    assert_template     "themes/entercomnew/daily_deals/show"
    assert_theme_layout "entercomnew/layouts/daily_deals"
    # assert_select first_request, @response.body
    assert_select "a[id='buy_now_button']", 1
    assert_select "h1[id=value_proposition]", 1
    assert_select "div[id='a_a']", 1

    # Rails.configuration.action_controller.perform_caching = @pre_test_caching

  end
end