require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::DealsControllerNavigationTest

class Syndication::DealsControllerNavigationTest < ActionController::TestCase
  
  def setup
    @controller = Syndication::DealsController.new
    @publisher = Factory(:publisher, :self_serve => true)
    @user = Factory(:user, :company => @publisher, :allow_syndication_access => true)
    login_as @user
  end
  
  context "list" do
    
    setup do
      get :list
      assert_response :success
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
    
    should "render the appropriate view by links" do
      assert_select "#view_select" do
        assert_select "p", :text => "View:"
        assert_select "ul#view_buttons" do
          assert_select "li:nth-child(1)" do
            assert_select "a[href='#{grid_syndication_deals_path(:page => 1)}']", :text => "Grid"
          end
          assert_select "li.current:nth-child(2)" do
            assert_select "a[href='#{list_syndication_deals_path(:page => 1)}']", :text => "List"
          end
          assert_select "li:nth-child(3)" do
            assert_select "a[href='#{calendar_syndication_deals_path(:page => 1)}']", :text => "Calendar"
          end
          assert_select "li:nth-child(4)" do
            assert_select "a[href='#{map_syndication_deals_path(:page => 1)}']", :text => "Map"
          end
        end
      end
    end
    
    should "render status filters" do
      
      assert_select "ul#deal_key" do
        assert_select "li#all_deals" do
          assert_select "a[href='#{list_syndication_deals_path}']", :text => "All Deals"
        end
        assert_select "li#sourceable_by_publisher" do
          assert_select "a[href='#{list_syndication_deals_path(:status => 'sourceable_by_publisher')}']"
        end
        assert_select "li#sourced_by_publisher" do
          assert_select "a[href='#{list_syndication_deals_path(:status => 'sourced_by_publisher')}']"
        end
        assert_select "li#sourced_by_network" do
          assert_select "a[href='#{list_syndication_deals_path(:status => 'sourced_by_network')}']"
        end
        assert_select "li#distributed_by_publisher" do
          assert_select "a[href='#{list_syndication_deals_path(:status => 'distributed_by_publisher')}']"
        end
        assert_select "li#distributed_by_network" do
          assert_select "a[href='#{list_syndication_deals_path(:status => 'distributed_by_network')}']"
        end
      end
    end
    
  end
  
  context "grid" do
    
    setup do
      get :grid
      assert_response :success
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
    
    should "render the appropriate view by links" do
      assert_select "#view_select" do
        assert_select "p", :text => "View:"
        assert_select "ul#view_buttons" do
          assert_select "li.current:nth-child(1)" do
            assert_select "a[href='#{grid_syndication_deals_path(:page => 1)}']", :text => "Grid"
          end
          assert_select "li:nth-child(2)" do
            assert_select "a[href='#{list_syndication_deals_path(:page => 1)}']", :text => "List"
          end
          assert_select "li:nth-child(3)" do
            assert_select "a[href='#{calendar_syndication_deals_path(:page => 1)}']", :text => "Calendar"
          end
          assert_select "li:nth-child(4)" do
            assert_select "a[href='#{map_syndication_deals_path(:page => 1)}']", :text => "Map"
          end
        end
      end
    end
    
    should "render status filters" do
      
      assert_select "ul#deal_key" do
        assert_select "li#all_deals" do
          assert_select "a[href='#{grid_syndication_deals_path}']", :text => "All Deals"
        end
        assert_select "li#sourceable_by_publisher" do
          assert_select "a[href='#{grid_syndication_deals_path(:status => 'sourceable_by_publisher')}']"
        end
        assert_select "li#sourced_by_publisher" do
          assert_select "a[href='#{grid_syndication_deals_path(:status => 'sourced_by_publisher')}']"
        end
        assert_select "li#sourced_by_network" do
          assert_select "a[href='#{grid_syndication_deals_path(:status => 'sourced_by_network')}']"
        end
        assert_select "li#distributed_by_publisher" do
          assert_select "a[href='#{grid_syndication_deals_path(:status => 'distributed_by_publisher')}']"
        end
        assert_select "li#distributed_by_network" do
          assert_select "a[href='#{grid_syndication_deals_path(:status => 'distributed_by_network')}']"
        end
      end
    end
    
  end
  
  context "calendar" do
    
    setup do
      get :calendar
      assert_response :success
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
    
    should "render the appropriate view by links" do
      assert_select "#view_select" do
        assert_select "p", :text => "View:"
        assert_select "ul#view_buttons" do
          assert_select "li:nth-child(1)" do
            assert_select "a[href='#{grid_syndication_deals_path(:page => 1)}']", :text => "Grid"
          end
          assert_select "li:nth-child(2)" do
            assert_select "a[href='#{list_syndication_deals_path(:page => 1)}']", :text => "List"
          end
          assert_select "li.current:nth-child(3)" do
            assert_select "a[href='#{calendar_syndication_deals_path(:page => 1)}']", :text => "Calendar"
          end
          assert_select "li:nth-child(4)" do
            assert_select "a[href='#{map_syndication_deals_path(:page => 1)}']", :text => "Map"
          end
        end
      end
    end
    
    should "render status filters" do
      
      assert_select "ul#deal_key" do
        assert_select "li#all_deals" do
          assert_select "a[href='#{calendar_syndication_deals_path}']", :text => "All Deals"
        end
        assert_select "li#sourceable_by_publisher" do
          assert_select "a[href='#{calendar_syndication_deals_path(:status => 'sourceable_by_publisher')}']"
        end
        assert_select "li#sourced_by_publisher" do
          assert_select "a[href='#{calendar_syndication_deals_path(:status => 'sourced_by_publisher')}']"
        end
        assert_select "li#sourced_by_network" do
          assert_select "a[href='#{calendar_syndication_deals_path(:status => 'sourced_by_network')}']"
        end
        assert_select "li#distributed_by_publisher" do
          assert_select "a[href='#{calendar_syndication_deals_path(:status => 'distributed_by_publisher')}']"
        end
        assert_select "li#distributed_by_network" do
          assert_select "a[href='#{calendar_syndication_deals_path(:status => 'distributed_by_network')}']"
        end
      end
    end
    
  end
  
  context "map" do
    
    setup do
      get :map
      assert_response :success
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
    
    should "render the appropriate view by links" do
      assert_select "#view_select" do
        assert_select "p", :text => "View:"
        assert_select "ul#view_buttons" do
          assert_select "li:nth-child(1)" do
            assert_select "a[href='#{grid_syndication_deals_path(:page => 1)}']", :text => "Grid"
          end
          assert_select "li:nth-child(2)" do
            assert_select "a[href='#{list_syndication_deals_path(:page => 1)}']", :text => "List"
          end
          assert_select "li:nth-child(3)" do
            assert_select "a[href='#{calendar_syndication_deals_path(:page => 1)}']", :text => "Calendar"
          end
          assert_select "li.current:nth-child(4)" do
            assert_select "a[href='#{map_syndication_deals_path(:page => 1)}']", :text => "Map"
          end
        end
      end
    end
    
    should "render status filters" do
      assert_select "ul#deal_key", :count => 1 do
        assert_select "li#all_deals" do
          assert_select "a[href='#{map_syndication_deals_path}']", :text => "All Deals"
        end
        assert_select "li#sourceable_by_publisher" do
          assert_select "a[href='#{map_syndication_deals_path(:status => 'sourceable_by_publisher')}']"
        end
        assert_select "li#sourced_by_publisher" do
          assert_select "a[href='#{map_syndication_deals_path(:status => 'sourced_by_publisher')}']"
        end
        assert_select "li#sourced_by_network" do
          assert_select "a[href='#{map_syndication_deals_path(:status => 'sourced_by_network')}']"
        end
        assert_select "li#distributed_by_publisher" do
          assert_select "a[href='#{map_syndication_deals_path(:status => 'distributed_by_publisher')}']"
        end
        assert_select "li#distributed_by_network" do
          assert_select "a[href='#{map_syndication_deals_path(:status => 'distributed_by_network')}']"
        end
      end
    end
    
  end
  
end