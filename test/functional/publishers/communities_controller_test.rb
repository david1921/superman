require File.dirname(__FILE__) + "/../../test_helper"

class Publishers::CommunitiesControllerTest < ActionController::TestCase
  
  context "index" do

    context "public" do
      
      context "for TWC" do
      
        setup do
          @publishing_group = Factory(:publishing_group, :label => "rr")
          @publisher        = Factory(:publisher, :label => "clickedin-austin", :publishing_group => @publishing_group)
          get :index, :publisher_id => @publisher.label
        end
        
        should "render the rr publishers/communities/index template" do
          assert_template "themes/rr/publishers/communities/index"
        end

        should "render the rr layouts/daily_deals" do
          assert_theme_layout "rr/layouts/publishers/landing_page"
        end
        
      end
      
    end
    
  end
  
  
end
