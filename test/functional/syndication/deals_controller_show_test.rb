require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::DealsControllerShowTest

class Syndication::DealsControllerShowTest < ActionController::TestCase
  
  def setup
    @controller = Syndication::DealsController.new
    @publisher = Factory(:publisher, :self_serve => true)
    @user = Factory(:user, :company => @publisher, :allow_syndication_access => true)
  end
  
  context "navigation" do
    setup do
      @deal = Factory(:daily_deal_for_syndication)
      login_as @user
      get :show, :id => @deal.to_param, :from_view => :list
    end
    
    should "render correct context" do
      assert_select "#site_nav" do
        assert_select "li.current:nth-child(1)" do
          assert_select "a[href='#{list_syndication_deals_path}']", :text => I18n.t('browse_deals')
        end
        assert_select "li:nth-child(2)" do
          assert_select "a[href='#{edit_syndication_user_path(@user.id)}']", :text => I18n.t('my_account')
        end
        assert_select "li:nth-child(3)" do
          assert_select "a[href='#{syndication_logout_path}']", :text => I18n.t('logout')
        end
        assert_select "a[href='#{root_path}']", :text => "Manage Deals"
      end
    end
    
    should "render the back to" do
      assert_select "a[href='#{list_syndication_deals_path}']", :text => "Browse Deals", :count => 1
    end
    
  end
  
  context "national deal" do
    setup do
      @national_deal = Factory(:daily_deal_for_syndication, :national_deal => true)
      login_as @user
      get :show, :id => @national_deal.to_param
    end
    
    should "display national indicator" do
      assert_select "span", :text => "National Deal"
    end
  end
  
  context "local deal" do
    setup do
      @local_deal = Factory(:daily_deal_for_syndication, :publisher => @publisher, :national_deal => false)
      login_as @user
      get :show, :id => @local_deal.to_param
    end
    
    should "not display national indicator" do
      assert_select "span", :text => "National Deal", :count => 0
    end
  end
  
  context "deal buttons and status" do
    
    setup do
      login_as @user
    end
    
    context "not available for syndication" do 
      setup do
        @deal_not_available_for_syndication = Factory(:daily_deal, :publisher => @publisher)
        get :show, :id => @deal_not_available_for_syndication.to_param
      end
      should "display syndicate this deal button" do
        assert_select "a[href='#{distribute_syndication_deal_path(@deal_not_available_for_syndication)}']", :text => "Take This Deal", :count => 0
        assert_select "a[href='#{source_syndication_deal_path(@deal_not_available_for_syndication)}']", :text => "SyndicateThis Deal", :count => 1
        assert_select "a[href='#{unsource_syndication_deal_path(@deal_not_available_for_syndication)}']", :text => "Unsyndicate This Deal", :count => 0
      end
      should "display status" do
        assert_select "img[src^='/images/syndication/graphics/deal_key_sourced_by_publisher.png']", :count => 0
        assert_select "img[src^='/images/syndication/graphics/deal_key_sourced_by_network.png']", :count => 0
        assert_select "img[src^='/images/syndication/graphics/deal_key_distributed_by_publisher.png']", :count => 0
        assert_select "img[src^='/images/syndication/graphics/deal_key_distributed_by_network.png']", :count => 0
      end
    end
    
    context "sourced by publisher and not distributed" do 
      setup do
        @sourced_deal = Factory(:daily_deal_for_syndication, :publisher => @publisher)
        get :show, :id => @sourced_deal.to_param
      end
      should "display take this deal button" do
        assert_select "a[href='#{distribute_syndication_deal_path(@sourced_deal)}']", :text => "Take This Deal", :count => 0
        assert_select "a[href='#{source_syndication_deal_path(@sourced_deal)}']", :text => "SyndicateThis Deal", :count => 0
        assert_select "a[href='#{unsource_syndication_deal_path(@sourced_deal)}']", :text => "Unsyndicate This Deal", :count => 1
      end
      should "display status" do
        assert_select "img[src^='/images/syndication/graphics/deal_key_sourced_by_publisher.png']", :count => 1
        assert_select "img[src^='/images/syndication/graphics/deal_key_sourced_by_network.png']", :count => 0
        assert_select "img[src^='/images/syndication/graphics/deal_key_distributed_by_publisher.png']", :count => 0
        assert_select "img[src^='/images/syndication/graphics/deal_key_distributed_by_network.png']", :count => 0
      end
    end
    
    context "sourced by publisher and distributed" do 
      setup do
        @distributing_publisher = Factory(:publisher)
        @sourced_deal = Factory(:daily_deal_for_syndication, :publisher => @publisher)
        @sourced_deal.syndicated_deals.build(:publisher_id => @distributing_publisher.id)
        @sourced_deal.save!
        get :show, :id => @sourced_deal.to_param
      end
      should "not display buttons" do
        assert_select "a[href='#{distribute_syndication_deal_path(@sourced_deal)}']", :text => "Take This Deal", :count => 0
        assert_select "a[href='#{source_syndication_deal_path(@sourced_deal)}']", :text => "SyndicateThis Deal", :count => 0
        assert_select "a[href='#{unsource_syndication_deal_path(@sourced_deal)}']", :text => "Unsyndicate This Deal", :count => 0
      end
      should "display status" do
        assert_select "img[src^='/images/syndication/graphics/deal_key_sourced_by_publisher.png']", :count => 1
        assert_select "img[src^='/images/syndication/graphics/deal_key_sourced_by_network.png']", :count => 0
        assert_select "img[src^='/images/syndication/graphics/deal_key_distributed_by_publisher.png']", :count => 0
        assert_select "img[src^='/images/syndication/graphics/deal_key_distributed_by_network.png']", :count => 1
      end
    end
    
    context "sourced by other publisher" do 
      setup do
        @sourced_deal = Factory(:daily_deal_for_syndication)
        get :show, :id => @sourced_deal.to_param
      end
      should "display take this deal button" do
        assert_select "form[action='#{distribute_syndication_deal_path(@sourced_deal)}']" do              
          assert_select "input[type=submit][value='Take This Deal']"
          assert_select "input[type=text][name='daily_deal[start_at]']"
          assert_select "input[type=text][name='daily_deal[hide_at]']"
          assert_select "input[type=checkbox][name='daily_deal[featured]']"
        end        
        assert_select "a[href='#{source_syndication_deal_path(@sourced_deal)}']", :text => "SyndicateThis Deal", :count => 0
        assert_select "a[href='#{unsource_syndication_deal_path(@sourced_deal)}']", :text => "Unsyndicate This Deal", :count => 0
      end
      should "display status" do
        assert_select "img[src^='/images/syndication/graphics/deal_key_sourced_by_publisher.png']", :count => 0
        assert_select "img[src^='/images/syndication/graphics/deal_key_sourced_by_network.png']", :count => 1
        assert_select "img[src^='/images/syndication/graphics/deal_key_distributed_by_publisher.png']", :count => 0
        assert_select "img[src^='/images/syndication/graphics/deal_key_distributed_by_network.png']", :count => 0
      end
    end
    
    context "sourced by other publisher and distributed by publisher" do 
      setup do
        @sourced_deal = Factory(:daily_deal_for_syndication)
        @sourced_deal.syndicated_deals.build(:publisher_id => @publisher.id)
        @sourced_deal.save!
        get :show, :id => @sourced_deal.to_param
      end
      should "display take this deal button" do
        assert_select "a[href='#{distribute_syndication_deal_path(@sourced_deal)}']", :text => "Take This Deal", :count => 0
        assert_select "a[href='#{source_syndication_deal_path(@sourced_deal)}']", :text => "SyndicateThis Deal", :count => 0
        assert_select "a[href='#{unsource_syndication_deal_path(@sourced_deal)}']", :text => "Unsyndicate This Deal", :count => 0
      end
      should "display status" do
        assert_select "img[src^='/images/syndication/graphics/deal_key_sourced_by_publisher.png']", :count => 0
        assert_select "img[src^='/images/syndication/graphics/deal_key_sourced_by_network.png']", :count => 1
        assert_select "img[src^='/images/syndication/graphics/deal_key_distributed_by_publisher.png']", :count => 1
        assert_select "img[src^='/images/syndication/graphics/deal_key_distributed_by_network.png']", :count => 1
      end
    end
    
    context "distributed by publisher" do
      setup do
        @sourced_deal = Factory(:daily_deal_for_syndication)
        @distributed_deal = @sourced_deal.syndicated_deals.build(:publisher_id => @publisher.id)
        @sourced_deal.save!
        get :show, :id => @distributed_deal.to_param
      end
      should "not display buttons" do
        assert_select "a[href='#{distribute_syndication_deal_path(@distributed_deal)}']", :text => "Take This Deal", :count => 0
        assert_select "a[href='#{source_syndication_deal_path(@distributed_deal)}']", :text => "SyndicateThis Deal", :count => 0
        assert_select "a[href='#{unsource_syndication_deal_path(@distributed_deal)}']", :text => "Unsyndicate This Deal", :count => 0
      end
      should "display status" do
        assert_select "img[src^='/images/syndication/graphics/deal_key_sourced_by_publisher.png']", :count => 0
        assert_select "img[src^='/images/syndication/graphics/deal_key_sourced_by_network.png']", :count => 0
        assert_select "img[src^='/images/syndication/graphics/deal_key_distributed_by_publisher.png']", :count => 1
        assert_select "img[src^='/images/syndication/graphics/deal_key_distributed_by_network.png']", :count => 0
      end
    end
    
    context "distributed by other publisher" do
      setup do
        @distributing_publisher = Factory(:publisher)
        @sourced_deal = Factory(:daily_deal_for_syndication)
        @distributed_deal = @sourced_deal.syndicated_deals.build(:publisher_id => @distributing_publisher.id)
        @sourced_deal.save!
        get :show, :id => @distributed_deal.to_param
      end
      should "not display buttons" do
        assert_select "a[href='#{distribute_syndication_deal_path(@distributed_deal)}']", :text => "Take This Deal", :count => 0
        assert_select "a[href='#{source_syndication_deal_path(@distributed_deal)}']", :text => "SyndicateThis Deal", :count => 0
        assert_select "a[href='#{unsource_syndication_deal_path(@distributed_deal)}']", :text => "Unsyndicate This Deal", :count => 0
      end
      should "display status" do
        assert_select "img[src^='/images/syndication/graphics/deal_key_sourced_by_publisher.png']", :count => 0
        assert_select "img[src^='/images/syndication/graphics/deal_key_sourced_by_network.png']", :count => 0
        assert_select "img[src^='/images/syndication/graphics/deal_key_distributed_by_publisher.png']", :count => 0
        assert_select "img[src^='/images/syndication/graphics/deal_key_distributed_by_network.png']", :count => 1
      end
    end
    
  end
  
end