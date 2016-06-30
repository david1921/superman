require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::DealsControllerSourceTest

class Syndication::DealsControllerSourceTest < ActionController::TestCase
  
  include ActionView::Helpers::TextHelper
  
  def setup
    @controller = Syndication::DealsController.new
    @publisher = Factory(:publisher, :self_serve => true)
    @user = Factory(:user, :company => @publisher, :allow_syndication_access => true)
  end
  
  context "source" do
    
    context "with no authenticated account" do
      setup do
        @deal = Factory(:daily_deal_for_syndication)
        get :source, :publisher_id => @publisher.label, :id => @deal.to_param
      end
      should redirect_to( "syndication login path" ) { syndication_login_path }
    end
    
    context "without syndication access" do
      setup do
        @deal = Factory(:daily_deal_for_syndication)
        @user = Factory(:user, :company => @publisher, :allow_syndication_access => false)
        login_as @user
        get :source, :publisher_id => @publisher.label, :id => @deal.to_param
      end
      should redirect_to( "syndication login path" ) { syndication_login_path }
    end
    
    context "with syndication access" do
      setup do
        @deal = Factory(:daily_deal, :publisher => @publisher)
        login_as @user
      end
      
      should "source deal owned by publisher" do
        assert !@deal.available_for_syndication?
        get :source, :id => @deal.to_param
        assert @deal.reload.available_for_syndication?, "Should make deal available for syndication."
        assert_equal "Syndicated deal.", flash[:notice]
        assert_redirected_to syndication_deal_path(@deal)
      end
    end
    
    context "not source deal owned by other publisher" do
      setup do
        @deal = Factory(:daily_deal)
        login_as @user
      end
      
      should "redirect" do
        assert !@deal.available_for_syndication?
        get :source, :id => @deal.to_param
        assert !@deal.available_for_syndication?
        assert_equal "Can not source a deal that does not belong to you or is a distributed deal.", flash[:error]
        assert_redirected_to syndication_deal_path(@deal)
      end
    end
    
  end
    
  context "request parameters" do
    setup do
      @deal = Factory(:daily_deal, :publisher => @publisher, :available_for_syndication => false)
      login_as @user
      get :source,
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