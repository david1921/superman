require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::DealsControllerCalendarTest

class Syndication::DealsControllerCalendarTest < ActionController::TestCase
  
  def setup
    @publisher = Factory(:publisher, :self_serve => true)
    @user = Factory(:user, :company => @publisher, :allow_syndication_access => true)
    @controller = Syndication::DealsController.new
  end
  
  context "login" do
    
    context "with no authenticated user" do
      setup do
        get :calendar
      end
      should redirect_to( "syndication login path" ) { syndication_login_path }
    end
    
    context "with user that does not have syndication access" do
      setup do
        @user = Factory(:user, :allow_syndication_access => false)
        login_as @user
        get :calendar
      end
      should redirect_to( "syndication login path" ) { syndication_login_path }
    end
    
    context "with user that has syndication access" do
      setup do
        login_as @user
        get :calendar
      end
      
      should "render calendar" do
        assert_response :success
        assert_template(:calendar)
        assert_layout(:syndication)
        assert_not_nil assigns(:search_request), "Should assign search request"
        assert_nil assigns(:search_response), "Should NOT assign search response"
        assert_not_nil assigns(:categories), "Should assign search categories"
        assert_not_nil assigns(:publisher), "Should assign publisher"
      end
      
    end
    
  end
    
  context "calendar in js format" do
    
    setup do
      login_as @user
      get :calendar, :format => 'js'
    end
    
    should "render successfully" do
      assert_response :success
      assert_template(:calendar)
      assert_layout(nil)
      assert_nil assigns(:search_request), "Should NOT assign search request"
      assert_nil assigns(:search_response), "Should NOT assign search response"
      assert_not_nil assigns(:publisher), "Should assign publisher"
    end
    
  end
  
  context "calendar in json format" do
    
    should "render json with deals in current to month" do
      deal_1 = Factory(:daily_deal_for_syndication,
                        :value_proposition => 'deal_1',
                        :start_at => 1.days.from_now, 
                        :hide_at => 2.days.from_now)
      deal_2 = Factory(:daily_deal_for_syndication,
                        :value_proposition => 'deal_2',
                        :start_at => 7.days.from_now, 
                        :hide_at => 8.days.from_now)
      deal_3 = Factory(:daily_deal_for_syndication,
                        :value_proposition => 'deal_3',
                        :start_at => 2.weeks.ago, 
                        :hide_at => 1.weeks.ago)
      deal_4 = Factory(:daily_deal, 
                        :value_proposition => 'deal_4',
                        :available_for_syndication => false,
                        :start_at => 7.days.from_now, 
                        :hide_at => 8.days.from_now)
      login_as @user
      get :calendar, {:format => 'json', 
                        :search_request => {
                          :filter => {
                            :start_date => Time.zone.now.to_s(:compact), 
                            :end_date => 30.days.from_now.to_s(:compact) }
                            }
                          }
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)      
      assert_equal 'deal_1', json["daily_deals"][0]['daily_deal']['value_proposition']
      assert_equal 'deal_2', json["daily_deals"][1]['daily_deal']['value_proposition']
      assert json["daily_deals"].length == 2
    end

    should "have specific daily deal data" do
      deal_1 = Factory(:daily_deal_for_syndication,
                       :value_proposition => 'deal_1',
                       :start_at => 1.days.from_now, 
                       :hide_at => 2.days.from_now)
      login_as @user
      get :calendar, :format => 'json'
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      daily_deal_json = json["daily_deals"][0]["daily_deal"]
      assert_equal deal_1.id, daily_deal_json['id']
      assert_equal 'deal_1', daily_deal_json['value_proposition']
      assert_equal false, daily_deal_json['sourceable_by_publisher']
      assert_equal false, daily_deal_json['sourced_by_publisher']
      assert_equal true, daily_deal_json['sourced_by_network']
      assert_equal false, daily_deal_json['distributed_by_publisher']
      assert_equal false, daily_deal_json['distributed_by_network']
      assert_equal syndication_deal_path(deal_1), daily_deal_json['syndication_deal_url']
      assert_equal show_on_calendar_syndication_deal_path(deal_1), daily_deal_json['show_on_calendar_url']
    end

    should "pass request parameters in the syndication_deal_url" do
      deal_1 = Factory(:daily_deal_for_syndication,
                       :value_proposition => 'deal_1',
                       :start_at => 1.days.from_now, 
                       :hide_at => 2.days.from_now)
      login_as @user
      get :calendar, {:format => 'json', :from_view => 'list', :page => 1}
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      daily_deal_json = json["daily_deals"][0]["daily_deal"]
      assert_equal syndication_deal_path(deal_1, {:from_view => 'list', :page => 1}).gsub('&', "&amp;"), daily_deal_json['syndication_deal_url']
    end

  end
  
end