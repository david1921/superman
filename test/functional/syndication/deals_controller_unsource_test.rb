require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::DealsControllerUnsourceTest

class Syndication::DealsControllerUnsourceTest < ActionController::TestCase
  
  include ActionView::Helpers::TextHelper
  
  def setup
    @controller = Syndication::DealsController.new
    @publisher = Factory(:publisher, :self_serve => true)
    @user = Factory(:user, :company => @publisher, :allow_syndication_access => true)
  end
  
  context "unsource" do
    
    setup do
      @deal = Factory(:daily_deal_for_syndication, :publisher => @publisher)
    end

    context "with no authenticated account" do
      setup do
        get :unsource, :id => @deal.to_param
      end
      should redirect_to( "syndication login path" ) { syndication_login_path }
    end
    
    context "without syndication access" do
      setup do
        @user = Factory(:user, :company => @publisher, :allow_syndication_access => false)
        login_as @user
        get :unsource, :id => @deal.to_param
      end
      should redirect_to( "syndication login path" ) { syndication_login_path }
    end
    
    context "with syndication access" do
      setup do
        login_as @user
      end
      
      should "make deal unavailable for distribution" do
        assert @deal.available_for_syndication?
        get :unsource, :id => @deal.to_param
        assert !@deal.reload.available_for_syndication?, "Should make deal unavailable for syndication."
        assert_equal "Unsyndicated deal.", flash[:notice]
        assert_redirected_to syndication_deal_path(@deal)
      end
    end
    
    context "not make deal unavailable for distribution when deal owned by other publisher" do
      setup do
        @deal = Factory(:daily_deal_for_syndication)
        login_as @user
      end
      
      should "redirect" do
        assert @deal.available_for_syndication?
        get :unsource, :id => @deal.to_param
        assert @deal.available_for_syndication?
        assert_equal "Can not unsource a deal that already has distributed deals or is not sourced by you.", flash[:error]
        assert_redirected_to syndication_deal_path(@deal)
      end
    end
    
    context "not make deal unavailable for distribution when deal has distributed deals" do
      setup do
        @deal.syndicated_deals.build(:publisher_id => Factory(:publisher).id)
        @deal.save!
        login_as @user
      end
      should "display error" do
        assert @deal.available_for_syndication?
        get :unsource, :id => @deal.to_param
        assert @deal.available_for_syndication?
        assert_equal "Can not unsource a deal that already has distributed deals or is not sourced by you.", flash[:error]
        assert_redirected_to syndication_deal_path(@deal)
      end
    end
    
  end
  
  context "request parameters" do
    setup do
      @deal = Factory(:daily_deal_for_syndication, :publisher => @publisher)
      login_as @user
      get :unsource,
          :id => @deal.to_param, 
          :sort => 'start_date_desc', 
          :search_request => { "filter"=> {"location"=>"98671"} }
    end
    
    should "pass parameters through on redirect" do
      assert_redirected_to syndication_deal_path(@deal, 
        {:sort => 'start_date_desc', :search_request => { "filter"=> {"location"=>"98671"} }})
    end
  end
  
end