require File.dirname(__FILE__) + "/../../../test_helper"

class Syndication::DealsHelperTest < ActionView::TestCase
  
  context "syndication_grid_view_path" do
    should "return grid_syndication_deals_path" do
      assert_equal grid_syndication_deals_path, syndication_grid_view_path
    end
  end
  
  context "syndication_list_view_path" do
    should "return list_syndication_deals_path" do
      assert_equal list_syndication_deals_path, syndication_list_view_path
    end
  end

  context "syndication_map_view_path" do
    should "return list_syndication_deals_path" do
      assert_equal list_syndication_deals_path, syndication_list_view_path
    end
  end
  
  context "syndication_calendar_view_path" do
    should "return calendar_syndication_deals_path" do
      assert_equal calendar_syndication_deals_path, syndication_calendar_view_path
    end
  end
  
  context "current_page_for_site_navigation?" do
    
    should "return true if in context" do
      expects(:action_name).returns('grid')
      assert_equal true, current_page_for_site_navigation?(:browse_deals)
      expects(:action_name).returns('list')
      assert_equal true, current_page_for_site_navigation?(:browse_deals)
      expects(:action_name).returns('calendar')
      assert_equal true, current_page_for_site_navigation?(:browse_deals)
      expects(:action_name).returns('map')
      assert_equal true, current_page_for_site_navigation?(:browse_deals)
    end
    
    should "return false if not in context" do
      expects(:action_name).returns('grid')
      assert_equal false, current_page_for_site_navigation?(:my_account)
      expects(:action_name).returns('list')
      assert_equal false, current_page_for_site_navigation?(:my_account)
      expects(:action_name).returns('calendar')
      assert_equal false, current_page_for_site_navigation?(:my_account)
      expects(:action_name).returns('map')
      assert_equal false, current_page_for_site_navigation?(:my_account)
    end
    
  end
  
  context "syndication_show_deal_path" do
    
    setup do
      @deal = Factory(:daily_deal)
      @parms = HashWithIndifferentAccess.new
      @parms[:sort] = 'start_at desc'
    end
    
    should "return list_syndication_deal_path" do
      expects(:collect_request_parameters).returns({:sort => 'start_at desc'}).at_least_once
      expects(:action_name).returns('list')
      assert_equal syndication_deal_path(@deal, {:from_view => 'list', :sort => 'start_at desc'}), 
                   syndication_show_deal_path(@deal)
    end
    
  end
  
  context "url_for_syndication_status_label_search" do
    
    setup do
      @publisher = Factory(:publisher)
      @user = Factory(:user, :company => @publisher)
      @parms = HashWithIndifferentAccess.new
      @parms[:status] = 'distributed_by_publisher'
    end
    
    should "return list_syndication_deals_path when view unknown" do
      expects(:collect_request_parameters).returns({}).at_least_once
      expects(:page_parameter).returns(nil)
      expects(:action_name).returns('foo').at_least_once
      assert_equal list_syndication_deals_path({:status => 'distributed_by_publisher'}), 
                   url_for_syndication_status_label_search(:distributed_by_publisher)
    end
    
    should "return list_syndication_deals_path with status" do
      expects(:collect_request_parameters).returns({}).at_least_once
      expects(:page_parameter).returns(nil)
      expects(:action_name).returns('list').at_least_once
      assert_equal list_syndication_deals_path({:status => 'distributed_by_publisher'}), 
                   url_for_syndication_status_label_search(:distributed_by_publisher)
    end
    
    should "return grid_syndication_deals_path" do
      expects(:collect_request_parameters).returns({}).at_least_once
      expects(:page_parameter).returns(nil)
      expects(:action_name).returns('grid').at_least_once
      assert_equal grid_syndication_deals_path({:status => 'distributed_by_publisher'}), 
                   url_for_syndication_status_label_search(:distributed_by_publisher)
    end
    
    should "return calendar_syndication_deals_path" do
      expects(:collect_request_parameters).returns({}).at_least_once
      expects(:page_parameter).returns(nil)
      expects(:action_name).returns('calendar').at_least_once
      assert_equal calendar_syndication_deals_path({:status => 'distributed_by_publisher'}), 
                   url_for_syndication_status_label_search(:distributed_by_publisher)
    end
    
    should "return map_syndication_deals_path" do
      expects(:collect_request_parameters).returns({}).at_least_once
      expects(:page_parameter).returns(nil)
      expects(:action_name).returns('map').at_least_once
      assert_equal map_syndication_deals_path({:status => 'distributed_by_publisher'}), 
                   url_for_syndication_status_label_search(:distributed_by_publisher)
    end
    
    should "reset page" do
      expects(:collect_request_parameters).returns({}).at_least_once
      expects(:page_parameter).returns(3)
      expects(:action_name).returns('foo').at_least_once
      assert_equal list_syndication_deals_path({:status => 'distributed_by_publisher', :page => 1}), 
                   url_for_syndication_status_label_search(:distributed_by_publisher)
    end
  
    should "add params to url" do
      expects(:collect_request_parameters).returns({:sort => 'start_at desc'}).at_least_once
      expects(:page_parameter).returns(nil).at_least_once
      expects(:action_name).returns('list').at_least_once
      assert_equal list_syndication_deals_path({:sort => 'start_at desc', :status => 'distributed_by_publisher'}), 
                   url_for_syndication_status_label_search(:distributed_by_publisher)
      assert_equal list_syndication_deals_path({:sort => 'start_at desc', :status => 'distributed_by_publisher'}), 
                   url_for_syndication_status_label_search(:distributed_by_publisher)
      assert_equal list_syndication_deals_path({:sort => 'start_at desc', :status => 'distributed_by_publisher'}), 
                   url_for_syndication_status_label_search(:distributed_by_publisher)
    end
  
  end
  
  context "url_for_site_navigation_context" do
    
    setup do
      @publisher = Factory(:publisher)
      @user = Factory(:user, :company => @publisher)
      @parms = HashWithIndifferentAccess.new
    end
    
    context "in browse deals" do
      should "return list_syndication_deals_path when no from_view parameter" do
        expects(:collect_request_parameters).returns({}).at_least_once
        assert_equal list_syndication_deals_path, url_for_site_navigation_context("browse_deals")
      end
    
      should "return list_syndication_deals_path" do
        expects(:collect_request_parameters).returns({:from_view => 'list'}).at_least_once
        assert_equal list_syndication_deals_path({:from_view => 'list'}), 
                     url_for_site_navigation_context("browse_deals", {:include_params => true})
      end
      
      should "return grid_syndication_deals_path" do
        expects(:collect_request_parameters).returns({:from_view => 'grid'}).at_least_once
        assert_equal grid_syndication_deals_path({:from_view => 'grid'}), 
                     url_for_site_navigation_context("browse_deals", {:include_params => true})
      end
      
      should "return calendar_syndication_deals_path" do
        expects(:collect_request_parameters).returns({:from_view => 'calendar'}).at_least_once
        assert_equal calendar_syndication_deals_path({:from_view => 'calendar'}), 
                     url_for_site_navigation_context("browse_deals", {:include_params => true})
      end
      
      should "return map_syndication_deals_path" do
        expects(:collect_request_parameters).returns({:from_view => 'map'}).at_least_once
        assert_equal map_syndication_deals_path({:from_view => 'map'}), 
                     url_for_site_navigation_context("browse_deals", {:include_params => true})
      end
      
      should "return list_syndication_deals_path without params" do
        expects(:collect_request_parameters).returns({:from_view => 'list'}).at_least_once
        assert_equal list_syndication_deals_path, 
                     url_for_site_navigation_context("browse_deals")
      end
      
      should "return grid_syndication_deals_path without params" do
        expects(:collect_request_parameters).returns({:from_view => 'grid'}).at_least_once
        assert_equal grid_syndication_deals_path, 
                     url_for_site_navigation_context("browse_deals")
      end
      
      should "return calendar_syndication_deals_path without params" do
        expects(:collect_request_parameters).returns({:from_view => 'calendar'}).at_least_once
        assert_equal calendar_syndication_deals_path, 
                     url_for_site_navigation_context("browse_deals")
      end
      
      should "return map_syndication_deals_path without params" do
        expects(:collect_request_parameters).returns({:from_view => 'map'}).at_least_once
        assert_equal map_syndication_deals_path, 
                     url_for_site_navigation_context("browse_deals")
      end
    end
    
    context "in account context" do
      should "return empty" do
        expects(:collect_request_parameters).returns({}).at_least_once
        expects(:current_user).returns(@user)
        assert_equal edit_syndication_user_path(@user.id), url_for_site_navigation_context("my_account")
      end
    end
    
    context "in logout context" do
      should "return url with params" do
        expects(:collect_request_parameters).returns({}).at_least_once
        assert_equal syndication_logout_path, url_for_site_navigation_context("logout")
      end
    end
    
    should "add params to url" do
      expects(:collect_request_parameters).returns({:sort => 'start_at desc'}).at_least_once
      assert_equal list_syndication_deals_path({:sort => 'start_at desc'}), 
                   url_for_site_navigation_context("browse_deals", {:include_params => true})
      assert_equal list_syndication_deals_path({:sort => 'start_at desc'}), 
                   url_for_site_navigation_context("browse_deals", {:include_params => true})
      assert_equal list_syndication_deals_path({:sort => 'start_at desc'}), 
                   url_for_site_navigation_context("browse_deals", {:include_params => true})
    end
  
  end
  
  context "show_key?" do
    should "show key in browse deals context" do
      expects(:controller_name).returns('deals').at_least_once
      expects(:action_name).returns('list').at_least_once
      assert show_key?
      
      expects(:controller_name).returns('deals').at_least_once
      expects(:action_name).returns('grid').at_least_once
      assert show_key?
      
      expects(:controller_name).returns('deals').at_least_once
      expects(:action_name).returns('calendar').at_least_once
      assert show_key?
      
      expects(:controller_name).returns('deals').at_least_once
      expects(:action_name).returns('map').at_least_once
      assert show_key?
      
      expects(:controller_name).returns('deals').at_least_once
      expects(:action_name).returns('show').at_least_once
      assert show_key?
      
      expects(:controller_name).returns('deals').at_least_once
      expects(:action_name).returns('distribute').at_least_once
      assert_equal false, show_key?
      
      expects(:controller_name).returns('deals').at_least_once
      expects(:action_name).returns('source').at_least_once
      assert_equal false, show_key?
      
      expects(:controller_name).returns('deals').at_least_once
      expects(:action_name).returns('unsource').at_least_once
      assert_equal false, show_key?
    end
  end
  
  def request
    mock(:params => @params)
  end
end
