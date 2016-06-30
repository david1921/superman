require File.dirname(__FILE__) + "/../../test_helper"

class PublishingGroups::MarketsControllerTest < ActionController::TestCase
  
  context "search" do
    
    setup do
      @publishing_group = Factory(:publishing_group, :label => "rr")
      @publisher        = Factory(:publisher, :label => "clickedin-austin", :publishing_group => @publishing_group)
      @zip_code         = "76511"
      @publisher.publisher_zip_codes.create!( :zip_code => @zip_code )
    end
    
    
    context "with a valid zip code" do
      
      setup do
        post :search, :publishing_group_id => @publishing_group.label, :zip_code => @zip_code
      end
      
      should redirect_to( "publisher landing page" ) { publisher_landing_page_path(@publisher.label) }
      should "set the cookies['zip_code'] to @zip_code" do
        assert_equal @zip_code, cookies['zip_code']
      end
      
    end
    
    context "with valid zip code and publishing group set to redirect to deal of the day path" do
      
      setup do
        @publishing_group.update_attribute(:redirect_to_deal_of_the_day_on_market_lookup, true)
        post :search, :publishing_group_id => @publishing_group.label, :zip_code => @zip_code
      end
      
      should redirect_to( "publisher deal of the day" ) { public_deal_of_day_path(@publisher.label) }
      should "set the cookies['zip_code'] to @zip_code" do
        assert_equal @zip_code, cookies['zip_code']
      end
      
    end
    
    context "with no zip code" do

      setup do
        @expected_redirect_to_url = publishing_group_landing_page_path(@publishing_group.label)
        post :search, :publishing_group_id => @publishing_group.label, :zip_code => ""
      end
      
      should redirect_to( "back to publishing group landing page" ) { @expected_redirect_to_url }
      should "assign flash warn" do
        assert_not_nil flash[:warn]
      end
      
    end
    
    context "with text for zip code" do

      setup do
        @expected_redirect_to_url = publishing_group_landing_page_path(@publishing_group.label)
        post :search, :publishing_group_id => @publishing_group.label, :zip_code => "Enter a zip code"
      end
      
      should redirect_to( "back to publishing group landing page" ) { @expected_redirect_to_url }
      should "assign flash warn" do
        assert_not_nil flash[:warn]
      end
      
    end    
    
    context "with invalid zip code" do
      
      setup do
        post :search, :publishing_group_id => @publishing_group.label, :zip_code => "99999"
      end
      
      should "render with themes/rr/layouts/landing_pages" do
        assert_theme_layout( "rr/layouts/landing_pages")
      end
      should render_template( "themes/rr/publishing_groups/markets/not_found" )
      
      should "not set the cookies['zip_code']" do
        assert_nil cookies['zip_code']
      end
      
      should "render form with publishing_group_subscribers_path as action and include zip code as hidden input" do
        assert_select "body" do
          assert_select "form[method=POST][action='#{publishing_group_subscribers_path(@publishing_group.label)}']" do
            assert_select "input[type=hidden][name='subscriber[zip_code]'][value='99999']"
            assert_select "input[type=hidden][name='redirect_to'][value='#{verifiable_url(publishing_group_landing_page_path(@publishing_group.label))}']"
          end
        end        
      end
      
    end
    
    context "with a publisher that is not launched but with valid zip code" do

      setup do
        @publisher.update_attribute(:launched, false)
        post :search, :publishing_group_id => @publishing_group.label, :zip_code => @zip_code
      end
      
      should "render with themes/rr/layouts/landing_pages" do
        assert_theme_layout( "rr/layouts/landing_pages")
      end
      should render_template( "themes/rr/publishing_groups/markets/not_found" )

      should "not set the cookies['zip_code']" do
        assert_nil cookies['zip_code']
      end
      
      should "render form with publishing_group_subscribers_path as action and include zip code as hidden input" do
        assert_select "body" do
          assert_select "form[method=POST][action='#{publishing_group_subscribers_path(@publishing_group.label)}']" do
            assert_select "input[type=hidden][name='subscriber[zip_code]'][value='#{@zip_code}']"
            assert_select "input[type=hidden][name='redirect_to'][value='#{verifiable_url(publishing_group_landing_page_path(@publishing_group.label))}']"
          end
        end        
      end
      
    end
    
    
  end

  context "not_found" do

    should "render template" do
      publishing_group = Factory(:publishing_group, :label => "rr")
      get :not_found, :publishing_group_id => publishing_group.label
      assert_template :not_found
    end

  end
  
end
