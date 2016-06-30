require File.dirname(__FILE__) + "/../test_helper"

class LandingPagesControllerTest < ActionController::TestCase
  
  fast_context "show" do
    
    fast_context "with TWC publisher" do
      
      setup do
        @publishing_group = Factory(:publishing_group, :label => 'rr')
        @publisher        = Factory(:publisher, :label => "clickedin-austin", :publishing_group => @publishing_group)
        @zip_code         = "76511"
        @publisher.publisher_zip_codes.create!( :zip_code => @zip_code )
      end
      
      fast_context "with stick_consumer_to_publisher_based_on_zip_code to true" do
        
        setup do
          @publishing_group.update_attribute(:stick_consumer_to_publisher_based_on_zip_code, true)
        end
        
        fast_context "with no zip code set in the cookie" do
          
          setup do
            get :show, :publishing_group_id => @publishing_group.label
          end
          
          should "render with themes/rr/layouts/landing_pages" do
            assert_theme_layout( "rr/layouts/landing_pages")
          end
          should render_template( "themes/rr/landing_pages/show" )
          
        end
        
        fast_context "with invalid zip code set in cookie" do
                    
          setup do
            @request.cookies['zip_code'] = '99999'
            get :show, :publishing_group_id => @publishing_group.label
          end
          
          should "render with themes/rr/layouts/landing_pages" do
            assert_theme_layout( "rr/layouts/landing_pages")
          end
          should render_template( "themes/rr/landing_pages/show" )                    
                    
        end
        
        fast_context "with valid zip code set in cookie" do
          
          setup do
            @request.cookies['zip_code'] = @zip_code
            get :show, :publishing_group_id => @publishing_group.label
          end
          
          should redirect_to("public deal of the day page") { public_deal_of_day_url(:label => @publisher.label) }
          
        end
        
        
      end
      
      
      fast_context "with stick_consumer_to_publisher_based_on_zip_code to false" do
        
        setup do
          @publishing_group.update_attribute(:stick_consumer_to_publisher_based_on_zip_code, false)
          get :show, :publishing_group_id => @publishing_group.label
        end
        
        should "render with themes/rr/layouts/landing_pages" do
          assert_theme_layout( "rr/layouts/landing_pages")
        end
        should render_template( "themes/rr/landing_pages/show" )
        
        
        
      end
      
    end

    fast_context "publisher label cookie exists" do

      setup do
        @publishing_group = Factory(:publishing_group, :label => 'redplum')
        @publisher1 = Factory(:publisher, :publishing_group => @publishing_group)
        @publishing_group2 = Factory(:publishing_group, :label => 'bcbsa')
        @publisher2 = Factory(:publisher, :publishing_group => @publishing_group2)
      end

      fast_context "with valid publisher label" do
        setup do
          @request.cookies['publisher_label'] = @publisher1.label
        end

        should "redirect to the publisher deal page" do
          get :show, :publishing_group_id => @publishing_group.label
          assert_redirected_to public_deal_of_day_path(:label => @publisher1.label)
        end
      end

      fast_context "with invalid publisher label" do
        setup do
          @request.cookies['publisher_label'] = 'invalid_label'
        end

        should "not redirect" do
          get :show, :publishing_group_id => @publishing_group.label
          assert_response :success
        end
      end

      fast_context "with valid publisher label from a different publishing group" do
        setup do
          @request.cookies['publisher_label'] = @publisher2.label
        end

        should "not redirect" do
          get :show, :publishing_group_id => @publishing_group.label
          assert_response :success
        end
      end
    end

    context "redirect by membership code" do
      setup do
        @publishing_group = Factory(:publishing_group, :label => "bcbsa")
        @publisher = Factory(:publisher, :publishing_group => @publishing_group, :label => "bcbsma")
      end

      context "given a valid code" do
        setup do
          Factory(:publisher_membership_code, :code => "ABC", :publisher => @publisher)
        end

        should "redirect to publisher deal page given a valid membership code" do
          get :show, :publishing_group_id => @publishing_group.label, :membership_code => "ABC"
          assert_redirected_to public_deal_of_day_url(:label => @publisher.label)
        end

        should "store membership code, publisher label and zip in cookies" do
          get :show, :publishing_group_id => @publishing_group.label, :membership_code => "ABC", :zip_code => "98685"
          assert_equal "98685", cookies["zip_code"]
          assert_equal "bcbsma", cookies["publisher_label"]
          assert_equal "ABC", cookies["publisher_membership_code"]
        end
      end

      context "default bcbsa-national behavior" do
        should "redirect to the bcbsa-national public deal page" do
          get :show, :publishing_group_id => @publishing_group.label
          assert_redirected_to public_deal_of_day_url(:label => 'bcbsa-national')
        end
      end
    end
  end
end
