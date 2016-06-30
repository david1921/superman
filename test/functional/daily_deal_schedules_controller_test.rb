require File.dirname(__FILE__) + "/../test_helper"

class DailyDealSchedulesControllerTest < ActionController::TestCase
  fast_context "as admin" do
    setup do
      login_as Factory(:admin)
    end
    
    fast_context "on GET :show" do
      setup do
        @daily_deal = Factory(:daily_deal)
        @morning_deal = Factory(:daily_deal, :hide_at => Time.zone.now.midnight + 12.hours)
        @afternoon_deal = Factory(:daily_deal, :start_at => Time.zone.now.midnight + 12.hours + 1.second, :advertiser => @morning_deal.advertiser)
        Factory(:daily_deal, :start_at => 2.days.from_now, :hide_at => 3.days.from_now, :advertiser => @morning_deal.advertiser)
        
        unlaunched_publisher = Factory(:publisher, :launched => false, :allow_daily_deals => true)
        Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => unlaunched_publisher))
        
        Factory(:daily_deal, :deleted_at => 1.day.ago)
        
        # Publisher with no deals
        Factory(:publisher, :allow_daily_deals => true)
        
        get :show
      end
      
      should respond_with(:success)
      should render_template(:show)
      should assign_to(:publishers)

      should "show scheduled deals" do
        assert_same_elements [ @daily_deal.publisher, @morning_deal.publisher ], assigns(:publishers), "Assigned publishers"
        assert_same_elements [ @daily_deal, @morning_deal, @afternoon_deal ], 
                             assigns(:publishers).map(&:advertisers).flatten.map(&:daily_deals).flatten, 
                             "Assigned daily deals"
      end
    end
  end
  
  fast_context "as anonymous" do
    fast_context "on GET :show" do
      setup do
        get :show
      end
      should redirect_to("/session/new")
    end
  end
    
  fast_context "as consumer" do
    setup do
      @consumer = Factory(:consumer)
      login_as @consumer
    end
    
    fast_context "on GET :show" do
      setup do
        get :show
      end
      should redirect_to("/session/new")
    end
  end
end
