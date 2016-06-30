require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::DealsControllerDistributeTest

class Syndication::DealsControllerDistributeTest < ActionController::TestCase
  
  include ActionView::Helpers::TextHelper
  
  def setup
    @controller = Syndication::DealsController.new
    @publisher = Factory(:publisher, :self_serve => true)
    @user = Factory(:user, :company => @publisher, :allow_syndication_access => true)
  end
  
  context "distribute" do
    
    setup do
      @user = Factory(:user, :company => @publisher, :allow_syndication_access => true)
    end
    
    context "with no authenticated account" do
      setup do
        @deal = Factory(:daily_deal, :available_for_syndication => true)
        post :distribute, :id => @deal.to_param, :daily_deal => {:start_at => @deal.start_at, :hide_at => @deal.hide_at, :featured => @deal.featured}
      end
      should redirect_to( "syndication login path" ) { syndication_login_path }
    end
    
    context "with user that does not have syndication access" do
      setup do
        @deal = Factory(:daily_deal, :available_for_syndication => true)
        @user = Factory(:user, :company => @publisher, :allow_syndication_access => false)
        login_as @user
        post :distribute, :id => @deal.to_param, :daily_deal => {:start_at => @deal.start_at, :hide_at => @deal.hide_at, :featured => @deal.featured}
      end
      should redirect_to( "syndication login path" ) { syndication_login_path }
    end
    
    context "with user that has syndication access" do
      setup do
        login_as @user
      end
      
      should "distribute deal sourced by network" do
        @deal = Factory(:daily_deal, :available_for_syndication => true)
        assert @deal.syndicated_deals.size == 0, "Should not have syndicated deals."
        post :distribute, :id => @deal.to_param, :daily_deal => {:start_at => @deal.start_at, :hide_at => @deal.hide_at, :featured => @deal.featured}
        assert @deal.reload.syndicated_deals.size == 1, "Should have one syndicated deal."
        assert !flash[:error], "Should not have error, but found #{flash[:error]}"
        distributed_deal = @deal.reload.syndicated_deals.first
        assert_redirected_to syndication_deal_path(distributed_deal)
      end
      
      should "distribute deal owned by another publisher and with a valid, different date range" do
        @deal = Factory(:side_daily_deal, :available_for_syndication => true, :start_at => 1.day.from_now, :hide_at => 20.days.from_now)
        assert @deal.syndicated_deals.size == 0, "Should not have syndicated deals."
        post :distribute, :id => @deal.to_param, :daily_deal => {:start_at => 3.days.from_now, :hide_at => 7.days.from_now, :featured => true}
        assert @deal.reload.syndicated_deals.size == 1, "Should have one syndicated deal."
        assert !flash[:error], "Should not have error, but found #{flash[:error]}"
                
        distributed_deal = @deal.syndicated_deals.first
        assert_not_equal @deal.start_at, distributed_deal.start_at
        assert_not_equal @deal.hide_at, distributed_deal.hide_at
        assert distributed_deal.featured_during_lifespan?
        assert_redirected_to syndication_deal_path(distributed_deal)
      end
      
      should "not distribute deal sourced by you" do
        @deal = Factory(:daily_deal, :publisher => @publisher, :available_for_syndication => true)
        assert @deal.syndicated_deals.size == 0, "Should not have syndicated deals."
        post :distribute, :id => @deal.to_param, :daily_deal => {:start_at => @deal.start_at, :hide_at => @deal.hide_at, :featured => @deal.featured}
        assert @deal.reload.syndicated_deals.size == 0, "Should not have syndicated deals."
        assert_redirected_to syndication_deal_path(@deal)
      end
      
      should "not distribute deal with invalid start_at and hide_at times" do
        @deal = Factory(:daily_deal, :available_for_syndication => true)
        assert @deal.syndicated_deals.size == 0, "Should not have syndicated deals."
        post :distribute, :id => @deal.to_param, :daily_deal => {:start_at => 1.day.ago, :hide_at => 3.days.ago, :featured => @deal.featured}
        assert @deal.reload.syndicated_deals.size == 0, "Should NOT have one syndicated deal."
        assert flash[:error], "Should have error"
        assert_redirected_to syndication_deal_path(@deal)
      end
    end
    
  end  
  
  context "request parameters" do
    setup do
      login_as @user
      @deal = Factory(:daily_deal, :available_for_syndication => true)
      get :distribute,
          :id => @deal.to_param, 
          :sort => 'start_date_desc', 
          :search_request => { "filter"=> {"location"=>"98671"} }
    end
    
    should "be passed in redirect" do
      assert_redirected_to syndication_deal_path(@deal, 
        {:sort => 'start_date_desc', :search_request => { "filter"=> {"location"=>"98671"} }})
    end
  end
  
end