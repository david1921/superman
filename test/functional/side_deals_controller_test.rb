require File.dirname(__FILE__) + "/../test_helper"

class SideDealsControllerTest < ActionController::TestCase
  context "index" do
    setup do
      @featured_deal = Factory(:daily_deal, :value_proposition => "featured deal")
      @side_deal_1 = Factory(:side_daily_deal,
                             :publisher => @featured_deal.publisher,
                             :value_proposition => "side deal 1",
                             :start_at => 1.days.ago,
                             :hide_at => 4.days.from_now)
      @side_deal_2 = Factory(:side_daily_deal,
                             :publisher => @featured_deal.publisher,
                             :value_proposition => "side deal 2",
                              :start_at => 2.days.ago,
                              :hide_at => 3.days.from_now)
      @side_deal_3 = Factory(:side_daily_deal,
                             :publisher => @featured_deal.publisher,
                             :value_proposition => "side deal 3",
                             :start_at => 5.days.ago,
                             :hide_at => 6.days.from_now)
      @featured_deal_other_publisher = Factory(:daily_deal)
    end
    
    should "respond with success" do
      get :index, :format => 'json', :daily_deal_id => @featured_deal.to_param
      assert_response :success
    end
    
    should "respond with not found when daily_deal_id is invalid" do
      get :index, :format => 'json', :daily_deal_id => 99999999
      assert_response :not_found
    end
    
    should "respond with json when side deals present" do
      get :index, :format => 'json', :daily_deal_id => @featured_deal.to_param
      json = ActiveSupport::JSON.decode( @response.body )
      assert_response :success
      assert json.present?, "Should not have an empty response"
      assert_equal  "side deal 2", json[0]['daily_deal']['title']
      assert_equal  "side deal 1", json[1]['daily_deal']['title']
      assert_equal  "side deal 3", json[2]['daily_deal']['title']
    end
    
    should "respond with nothing when no side deals present" do
      get :index, :format => 'json', :daily_deal_id => @featured_deal_other_publisher.to_param
      json = ActiveSupport::JSON.decode( @response.body )
      assert_response :success
      assert_equal false, json.present?, "Should have an empty response"
    end
    
  end
end