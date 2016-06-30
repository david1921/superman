require File.dirname(__FILE__) + "/../test_helper"

class SideDealsTest < ActionController::IntegrationTest
  test "customer should be able to purchase side and main deal one same day" do
    featured_deal = Factory(:daily_deal)

    publisher = featured_deal.publisher
    advertiser = Factory(:advertiser, :publisher => publisher)
    side_deal = Factory(
      :side_daily_deal, :publisher => publisher, :advertiser => advertiser,
      :value_proposition => "I'd buy that for a dollar"
    )
    
    get "/publishers/#{publisher.label}/deal-of-the-day"
    assert_response :success
    
    assert_select "h1 span.value_proposition", featured_deal.value_proposition
    assert_select ".side_deals" do
      assert_select "span.value_proposition", :text => featured_deal.value_proposition, :count => 0
      assert_select "span.value_proposition", :text => side_deal.value_proposition, :count => 1
    end
    assert_select "h3", "Side Deals"
    
    get "/daily_deals/#{side_deal.id}"
    assert_response :success
    
    assert_select "h1 span.value_proposition", side_deal.value_proposition
    assert_select ".side_deals" do
      assert_select "span.value_proposition", :text => featured_deal.value_proposition, :count => 1
      assert_select "span.value_proposition", :text => side_deal.value_proposition, :count => 0
    end
    assert_select "h3", "Side Deals"
    
    get "/daily_deals/#{side_deal.id}/daily_deal_purchases/new"
    assert_response :success

    assert_select "form[action='#{daily_deal_daily_deal_purchases_path(side_deal)}'][method=post]", 1
    
    post daily_deal_daily_deal_purchases_path(side_deal), :daily_deal_purchase => {
      :quantity => "1",
      :gift => "0"
    }, :consumer => {
      :name => "Chih Chow",
      :email => "chih.chow@example.com",
      :password => "sandiego",
      :password_confirmation => "sandiego",
      :agree_to_terms => "1"
    }
    assert_not_nil(daily_deal_purchase = assigns(:daily_deal_purchase), "Assignment of @daily_deal_purchase")
    assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)
    assert_equal side_deal, daily_deal_purchase.daily_deal, "Should assign side deal to purchase"
    
    # Go back and buy the main deal
    get "/publishers/#{publisher.label}/deal-of-the-day"
    assert_response :success
    
    assert_select "h1 span.value_proposition", featured_deal.value_proposition
    assert_select ".side_deals" do
      assert_select "span.value_proposition", :text => featured_deal.value_proposition, :count => 0
      assert_select "span.value_proposition", :text => side_deal.value_proposition, :count => 1
    end
    assert_select "h3", "Side Deals"
    
    get "/daily_deals/#{featured_deal.id}/daily_deal_purchases/new"
    assert_response :success

    assert_select "form[action='#{daily_deal_daily_deal_purchases_path(featured_deal)}'][method=post]", 1
    
    post daily_deal_daily_deal_purchases_path(featured_deal), :daily_deal_purchase => {
      :quantity => "1",
      :gift => "0"
    }, :consumer => {
      :name => "Chih Chow",
      :email => "chih.chow@example.com",
      :password => "sandiego",
      :password_confirmation => "sandiego",
      :agree_to_terms => "1"
    }
    assert_not_nil(daily_deal_purchase = assigns(:daily_deal_purchase), "Assignment of @daily_deal_purchase")
    assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)
    assert_equal featured_deal, daily_deal_purchase.daily_deal, "Should assign correct deal to purchase"
  end
end
