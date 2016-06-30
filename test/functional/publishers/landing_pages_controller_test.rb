require File.dirname(__FILE__) + "/../../test_helper"

class Publishers::LandingPagesControllerTest < ActionController::TestCase

  context "show" do
  
    context "with a publisher that uses the default page" do
    
      setup do
        @publisher    = Factory(:publisher, :label => "treehouse")
        @advertiser   = Factory(:advertiser, :publisher => @publisher)
        @daily_deal   = Factory(:daily_deal, :advertiser => @advertiser, :start_at => 2.days.ago, :hide_at => 3.day.from_now)
        get :show, :publisher_id => @publisher.label
      end
      
      should render_template( "publishers/landing_pages/show" )
      should render_with_layout( "landing_page" )
      should assign_to( :publisher ).with( @publisher )
      should  assign_to( :daily_deal ).with(@daily_deal)
      should assign_to( :offers ).with( [] )
    
    end
    
    context "with TWC (rr) that overrides the default behaviour" do
      
      setup do
        # TODO: do we want the layouts/publishers/landing_page layout to be at the publishing group level, 
        # i believe we do, and possible the template as well.
        @publishing_group     = Factory(:publishing_group, :label => "rr", :stick_consumer_to_publisher_based_on_zip_code => true)
        @publisher            = Factory(:publisher, :publishing_group => @publishing_group)        
        @advertiser           = Factory(:advertiser, :publisher => @publisher)
        @daily_deal           = Factory(:daily_deal, :advertiser => @advertiser, :start_at => 2.days.ago, :hide_at => 3.day.from_now)
        @featured_offer       = Factory(:offer, :advertiser => @advertiser, :featured => "both")
        @non_featured_offer   = Factory(:offer, :advertiser => @advertiser, :featured => "none")
        @past_featured_offer  = Factory(:offer, :advertiser => @advertiser, :featured => "both", :show_on => Time.zone.now - 10.days, :expires_on => Time.zone.now - 2.days)
        @expected_offers      = [@featured_offer]
        @zip_code         = "76511"
        @publisher.publisher_zip_codes.create!( :zip_code => @zip_code )
        @request.cookies['zip_code'] = "76511"
        get :show, :publisher_id => @publisher.label
      end
      
      should "redirect to the public deal of the day page" do
        assert_redirected_to public_deal_of_day_url(:label => @publisher.label)
      end
      
    end
    
    
  end


end
