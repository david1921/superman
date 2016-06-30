require File.dirname(__FILE__) + "/../../test_helper"

class Publishers::SearchControllerTest < ActionController::TestCase

  fast_context "show" do
    
    fast_context "with TWC publishing group" do

      setup do
        @publishing_group = Factory(:publishing_group, :label => 'rr')
        @publisher        = Factory(:publisher, :publishing_group => @publishing_group)
        @advertiser       = Factory(:advertiser, :name => "New Seasons", :publisher => @publisher)
        @offer            = Factory(:offer, :advertiser => @advertiser, :message => "12 Apples for Free")
        @daily_deal       = Factory(:daily_deal, :publisher => @publisher, :value_proposition => "Free Nutrition Consultation", :description => "Get yourself a free nutrition consultation.")
        @sweepstake       = Factory(:sweepstake, :publisher => @publisher, :value_proposition => "Free Ticket", :description => "Special Concert")
      end

      fast_context "with no search param" do

        setup do
          get :show, :publisher_id => @publisher.label
        end
        
        should "render the rr publishers/search/summary template" do
          assert_template "themes/rr/publishers/search/summary"
        end

        should "render the rr layouts/publishers/search" do
          assert_theme_layout "rr/layouts/publishers/search"
        end
        
        should_not assign_to(:daily_deals)
        should_not assign_to(:offers)
        should_not assign_to(:sweepstakes)

        should "render no search value message" do
          assert_select "p.notice", :text => "Please enter a search value."
        end

      end      
      
      fast_context "with search param that does not match offers or deals" do
      
        setup do
          get :show, :publisher_id => @publisher.label, :q => "blahblah"
        end
        
        should "render the rr publishers/search/summary template" do
          assert_template "themes/rr/publishers/search/summary"
        end

        should "render the rr layouts/publishers/search" do
          assert_theme_layout "rr/layouts/publishers/search"
        end
        
        should assign_to(:daily_deals).with([])
        should assign_to(:offers).with([])
        should assign_to(:sweepstakes).with([])
        
        should "render no results message" do
          assert_select "p.notice", :html => "Sorry, no results found for <strong>blahblah</strong>."
        end
                                
      end
      
      fast_context "with search param that matches just offers" do
        
        setup do
          @expected_offers = [@offer]
          get :show, :publisher_id => @publisher.label, :q => "apples"
        end
        
        should assign_to(:daily_deals).with([])
        should assign_to(:offers).with(@expected_offers)
        should assign_to(:sweepstakes).with([])
        
        should "render no results found in the daily deals section" do
          assert_select "div.daily_deals" do
            assert_select "p", :html => "Sorry, no daily deals were found for <strong>apples</strong>."
          end
        end
        
        should "render the offers found in the offers section" do
          assert_select "div.offers" do
            assert_select "div.offer" do

            end
          end
        end
        
      end
      
      fast_context "with search param that matches just daily deals" do
        
        setup do
          @expected_deals = [@daily_deal]
          get :show, :publisher_id => @publisher.label, :q => "nutrition"
        end
        
        should assign_to(:daily_deals).with(@expected_deals)
        should assign_to(:offers).with([])
        should assign_to(:sweepstakes).with([])
        
        should "render the daily deals found in the daily_deals section" do
          assert_select "div.daily_deals" do
            assert_select "div.daily_deal" do

            end
          end
        end
                
        should "render no results found in the offers section" do
          assert_select "div.offers" do
            assert_select "p", :html => "Sorry, no offers were found for <strong>nutrition</strong>."
          end
        end
        
      end      
      
      fast_context "with search param that matches just sweepstakes" do
        setup do
          @expected_sweepstakes = [@sweepstake]
          get :show, :publisher_id => @publisher.label, :q => "concert"
        end
        
        should assign_to(:daily_deals).with([])
        should assign_to(:offers).with([])
        should assign_to(:sweepstakes).with(@expected_sweepstakes)
        
        should "render no results found in the daily deals section" do
          assert_select "div.daily_deals" do
            assert_select "p", :html => "Sorry, no daily deals were found for <strong>concert</strong>."
          end
        end
        
        should "render no results found in the offers section" do
          assert_select "div.offers" do
            assert_select "p", :html => "Sorry, no offers were found for <strong>concert</strong>."
          end
        end
        
      end
      
      
      fast_context "with search param and context" do
      
        fast_context "with invalid context" do
              
          setup do
            get :show, :publisher_id => @publisher.label, :q => "some text", :c => "blahblah"
          end
      
          should "render the rr publishers/search/summary template" do
            assert_template "themes/rr/publishers/search/summary"
          end

          should "render the rr layouts/publishers/search" do
            assert_theme_layout "rr/layouts/publishers/search"
          end
      
          should assign_to(:daily_deals).with([])
          should assign_to(:offers).with([])
          should assign_to(:sweepstakes).with([])
      
          should "render no results message" do
            assert_select "p.notice", :html => "Sorry, no results found for <strong>some text</strong>."
          end          
          
        end
        
        fast_context "with valid dailydeals context" do
        
          fast_context "with no search results" do
          
            setup do
              get :show, :publisher_id => @publisher.label, :q => "blahblah", :c => "dailydeals"
            end
            
            should "render the rr publishers/search/daily_deals template" do
              assert_template "themes/rr/publishers/search/daily_deals"
            end

            should "render the rr layouts/publishers/search" do
              assert_theme_layout "rr/layouts/publishers/search"
            end

            should assign_to(:daily_deals).with([])
            should_not assign_to(:offers)
            should_not assign_to(:sweepstakes)
            
            should "render no results message" do
              assert_select "p", :html => "Sorry, no daily deals were found for <strong>blahblah</strong>."
            end            
            
          end
          
          fast_context "with valid results put no paging information" do
          
            setup do
              @query = "apples"
              (1..20).each do |index|
                Factory(:side_daily_deal, :value_proposition => "Deal #{index}", :description => "this deal has everything to do with #{@query}", :publisher => @publisher)
              end
              get :show, :publisher_id => @publisher.label, :q => @query, :c => "dailydeals"
            end

            should "render daily deals" do
              assert_select "div.daily_deals" do
                assert_select "div.daily_deal", :count => 20
              end
            end
            
          end
          
        end
        
        fast_context "with valid offers context" do
        
          fast_context "with no search results" do
          
            setup do
              get :show, :publisher_id => @publisher.label, :q => "blahblah", :c => "offers"
            end
            
            should "render the rr publishers/search/offers template" do
              assert_template "themes/rr/publishers/search/offers"
            end

            should "render the rr layouts/publishers/search" do
              assert_theme_layout "rr/layouts/publishers/search"
            end

            should_not assign_to(:daily_deals)
            should assign_to(:offers).with([])
            should_not assign_to(:sweepstakes)            
            
            should "render no results message" do
              assert_select "p", :html => "Sorry, no offers were found for <strong>blahblah</strong>."
            end            
            
          end
          
        end
        
        fast_context "with valid sweepstakes context" do
          
          fast_context "with no search resutls" do
            
            setup do
              get :show, :publisher_id => @publisher.label, :q => "blahblah", :c => "sweepstakes"
            end

            should "render the rr publishers/search/sweepstakes template" do
              assert_template "themes/rr/publishers/search/sweepstakes"
            end

            should "render the rr layouts/publishers/search" do
              assert_theme_layout "rr/layouts/publishers/search"
            end

            should_not assign_to(:daily_deals)
            should_not assign_to(:offers) 
            should     assign_to(:sweepstakes).with([])

            should "render no results message" do
              assert_select "p", :html => "Sorry, no sweepstakes were found for <strong>blahblah</strong>."
            end          
                        
          end
          
        end
        
      end
      
      
    end
    
  end
  

end
