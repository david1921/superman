require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeals::ReadyMadeThemeTest < ActionController::TestCase
  
  TEST_PUBLISHER = "test-uses-ready-made-theme"
  TEST_PUBLISHER_WITH_READY_MADE_THEME_CUSTOM_ACTION = "test-uses-ready-made-theme-with-custom-action"
  TEST_PUBLISHER_WITH_READY_MADE_THEME_CUSTOM_LAYOUT = "test-uses-ready-made-theme-with-custom-layout"
  TEST_PUB_GROUP_WITH_READY_MADE_THEME_CUSTOMIZED = "test-pg-with-customized-ready-made-theme"
  TEST_THEME = "cleverbetta"
  
  tests DailyDealsController
  
  context "when the publisher uses their own custom theme" do
    
    setup do
      @publisher = Factory :publisher, :label => "nydailynews"
      @advertiser = Factory :advertiser, :publisher => @publisher
      @daily_deal = Factory :daily_deal, :advertiser => @advertiser
    end
    
    should "render using the layout and template of the publisher's custom theme" do
      get :show, :id => @daily_deal.to_param
      assert_response :success
      assert_equal "themes/nydailynews/layouts/daily_deals", @response.layout
      assert_template "themes/nydailynews/daily_deals/show"
    end

  end
  
  context "when the publisher uses a ready-made theme" do
    
    setup do
      @publisher = Factory :publisher, :label => TEST_PUBLISHER, :parent_theme => TEST_THEME
      @advertiser = Factory :advertiser, :publisher => @publisher
      @daily_deal = Factory :daily_deal, :advertiser => @advertiser
      
      assert @publisher.uses_a_ready_made_theme?
    end
    
    should "render using the layout and template of the standard theme" do
      get :show, :id => @daily_deal.to_param
      assert_response :success
      assert_equal "themes/#{TEST_THEME}/layouts/daily_deals", @response.layout
      assert_template "themes/#{TEST_THEME}/daily_deals/show"
    end
    
    should "render the standard show.js.erb for js request" do
      get :show, :id => @daily_deal.to_param, :format => 'js'
      assert_response :success
      assert_nil @response.layout
      assert_template "daily_deals/show.js.erb"
    end
    
  end
  
  context "when the publisher uses a ready-made theme, but has customized the action template" do
    
    setup do
      @publisher = Factory :publisher, :label => TEST_PUBLISHER_WITH_READY_MADE_THEME_CUSTOM_ACTION, :parent_theme => TEST_THEME
      @advertiser = Factory :advertiser, :publisher => @publisher
      @daily_deal = Factory :daily_deal, :advertiser => @advertiser
      
      assert @publisher.uses_a_ready_made_theme?
    end
    
    should "render using the layout from the ready-made theme, and the publisher's customized action template" do
      get :show, :id => @daily_deal.to_param
      assert_response :success
      assert_equal "themes/#{TEST_THEME}/layouts/daily_deals", @response.layout
      assert_template "themes/#{TEST_PUBLISHER_WITH_READY_MADE_THEME_CUSTOM_ACTION}/daily_deals/show"
    end
    
    should "render the standard show.js.erb for js request with no customized show.js.erb" do
      get :show, :id => @daily_deal.to_param, :format => 'js'
      assert_response :success
      assert_nil @response.layout
      assert_template "daily_deals/show.js.erb"
    end
    
  end
  
  context "when the publisher uses a ready-made theme, but has customized the layout" do

    setup do
      @publisher = Factory :publisher, :label => TEST_PUBLISHER_WITH_READY_MADE_THEME_CUSTOM_LAYOUT, :parent_theme => TEST_THEME
      @advertiser = Factory :advertiser, :publisher => @publisher
      @daily_deal = Factory :daily_deal, :advertiser => @advertiser
      
      assert @publisher.uses_a_ready_made_theme?
    end
    
    should "render using the template from the ready-made theme, and the layout from the publisher's customized theme" do
      get :show, :id => @daily_deal.to_param
      assert_response :success
      assert_equal "themes/#{TEST_PUBLISHER_WITH_READY_MADE_THEME_CUSTOM_LAYOUT}/layouts/daily_deals", @response.layout
      assert_template "themes/#{TEST_THEME}/daily_deals/show"            
    end
    
    
    
  end  
  
  context "when the publishing group uses a ready-made theme, with no customizations" do
    
    setup do
      @publishing_group = Factory :publishing_group, :parent_theme => "howlingwolf"
      @publisher = Factory :publisher, :publishing_group => @publishing_group
      @advertiser = Factory :advertiser, :publisher => @publisher
      @daily_deal = Factory :daily_deal, :advertiser => @advertiser
    end
    
    should "render templates from the ready made theme" do
      get :show, :id => @daily_deal.to_param
      assert_response :success
      assert_equal "themes/howlingwolf/layouts/daily_deals", @response.layout
      assert_template "themes/howlingwolf/daily_deals/show"            
    end
    
    should "render the standard show.js.erb for js request" do
      get :show, :id => @daily_deal.to_param, :format => 'js'
      assert_response :success
      assert_nil @response.layout
      assert_template "daily_deals/show.js.erb"
    end
    
  end
  
  context "when the publishing group uses a ready-made theme with a custom action" do
    
    setup do
      @publishing_group = Factory :publishing_group, :label => TEST_PUB_GROUP_WITH_READY_MADE_THEME_CUSTOMIZED,
                                  :parent_theme => "howlingwolf"
      @publisher = Factory :publisher, :publishing_group => @publishing_group
      @advertiser = Factory :advertiser, :publisher => @publisher
      @daily_deal = Factory :daily_deal, :advertiser => @advertiser
    end
    
    should "render the template from the publishing group" do
      get :show, :id => @daily_deal.to_param
      assert_response :success
      assert_equal "themes/howlingwolf/layouts/daily_deals", @response.layout
      assert_template "themes/#{@publishing_group.label}/daily_deals/show"
    end
    
    should "render the standard show.js.erb for js request with no customized show.js.erb" do
      get :show, :id => @daily_deal.to_param, :format => 'js'
      assert_response :success
      assert_nil @response.layout
      assert_template "daily_deals/show.js.erb"
    end
    
  end
  
  context "when the publishing group uses a ready-theme and the publisher has a custom action" do
    
    setup do
      @publishing_group = Factory :publishing_group, :parent_theme => "howlingwolf"
      @publisher = Factory :publisher, :publishing_group => @publishing_group,
                           :label => TEST_PUBLISHER_WITH_READY_MADE_THEME_CUSTOM_ACTION
      @advertiser = Factory :advertiser, :publisher => @publisher
      @daily_deal = Factory :daily_deal, :advertiser => @advertiser
    end
    
    should "render the template from the publisher" do
      get :show, :id => @daily_deal.to_param
      assert_response :success
      assert_equal "themes/howlingwolf/layouts/daily_deals", @response.layout
      assert_template "themes/#{@publisher.label}/daily_deals/show"
    end
    
  end
  
      
end
  
