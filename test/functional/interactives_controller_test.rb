require File.dirname(__FILE__) + "/../test_helper"

class InteractivesControllerTest < ActionController::TestCase

  context "offer" do
  
    context "with missing publishing_group_id" do
    
      setup do
        get :offer
      end
      
      should "render 404 page" do
        assert_template "#{Rails.root}/public/404.html"
      end
      
    end
    
    context "with invalid publishing_group_id" do
    
      setup do
        get :offer, :publishing_group_id => "blah"
      end
      
      should "render 404 page" do
        assert_template "#{Rails.root}/public/404.html"
      end
      
    end
    
    context "with rr publishing group id" do
    
      setup do
        @publishing_group = Factory(:publishing_group, :label => "rr", :name => "Road Runner")
        get :offer, :publishing_group_id => @publishing_group.label
      end
      
      should "not render layout" do
        assert_layout false
      end
      
      should render_template("themes/rr/interactives/offer")
      
    end
    
    
  end
  
  context "create_offer" do
    
    context "with missing publishing_group_id" do
    
      setup do
        post :create_offer, :code => "MYCODE"
      end
      
      should "render 404 page" do
        assert_template "#{Rails.root}/public/404.html"
      end
      
    end
    
    context "with invalid publishing_group_id" do
    
      setup do
        post :create_offer, :publishing_group_id => "blah", :code => "MYCODE"
      end
      
      should "render 404 page" do
        assert_template "#{Rails.root}/public/404.html"
      end
      
    end
    
    context "with rr publishing group id" do
      
      setup do
        @publishing_group = Factory(:publishing_group, :label => "rr", :name => "Road Runner")
        @publisher        = Factory(:publisher, :label => "timewarnercable-austin", :market_name => "Austin", :name => "Time Warner Cable - Austin", :publishing_group_id => @publishing_group.id)
        @advertiser       = Factory(:advertiser, :name => "My Advertiser", :publisher_id => @publisher.id)
        @offer            = Factory(:offer, :value_proposition => "My Offer", :advertiser_id => @advertiser.id, :coupon_code => "MYCODE")
      end
      
      should "have created publishing group" do
        assert PublishingGroup.find_by_label( @publishing_group.label )
      end
      
        
      context "with a valid code" do   
        
        setup do
          post :create_offer, :publishing_group_id => @publishing_group.label, :code => @offer.coupon_code
        end
      
        should assign_to( :offer ).with( @offer )
        should render_template("themes/rr/interactives/offer")
                
      end
      
      context "with an invalid code" do

        setup do
          post :create_offer, :publishing_group_id => @publishing_group.label, :code => @offer.coupon_code + "blah"
        end
        
        should redirect_to( "new_publishing_group_interactive_path" ) { offer_publishing_group_interactives_path(@publishing_group.label) }
        should "set error message to flash error" do
          assert_equal "Sorry, that is an invalid code.", flash[:error]
        end
        
      end
      
      context "with an empty code" do

        setup do
          @offer.update_attribute( :coupon_code, "" )
          post :create_offer, :publishing_group_id => @publishing_group.label, :code => ""
        end
        
        should redirect_to( "new_publishing_group_interactive_path" ) { offer_publishing_group_interactives_path(@publishing_group.label) }
        should "set error message to flash error" do
          assert_equal "Sorry, that is an invalid code.", flash[:error]
        end
        
      end
      
    end
    
  end
 
  context "sweepstake" do
  
    context "with missing publishing_group_id" do
    
      setup do
        get :sweepstake
      end
      
      should "render 404 page" do
        assert_template "#{Rails.root}/public/404.html"
      end
      
    end  
    
    context "with rr publishing group id" do
    
      setup do
        @publishing_group = Factory(:publishing_group, :label => "rr", :name => "Road Runner")
        get :sweepstake, :publishing_group_id => @publishing_group.label
      end
      
      should "not render layout" do
        assert_layout false
      end
      
      should render_template("themes/rr/interactives/sweepstake")
      should assign_to( :subscriber )
      should "render appropriate sweepstake view" do
        assert_select "body" do
          assert_select "#analog_analytics_content" do
            assert_select "#sweepstakes_container" do
              assert_select "h2", :text => "X.Com/bojangles"
              assert_select "form[action='#{create_sweepstake_publishing_group_interactives_path(@publishing_group.label)}'][method='post']" do
                assert_select "input[type=hidden][name='subscriber[email_required]'][value='true']"
                %w( name zip_code gender ).each do |required_field|
                  assert_select "input[type=hidden][name='subscriber[required_fields][]'][value='#{required_field}']"
                end
                assert_select "input[type=text][name='subscriber[name]']"
                assert_select "input[type=text][name='subscriber[email]']"
                assert_select "input[type=text][name='subscriber[other_options][date_of_birth]']"
                assert_select "input[type=text][name='subscriber[zip_code]']"
                assert_select "input[type=text][name='subscriber[gender]']"
                assert_select "input[type=text][name=code]"
              end
            end
          end
        end
      end
      
    end
    
  end
  
  context "create_sweepstake" do 
      
    context "with missing publishing_group_id" do
    
      setup do
        post :create_sweepstake, :code => "MYCODE"
      end
      
      should "render 404 page" do
        assert_template "#{Rails.root}/public/404.html"
      end
      
    end
    
    context "with invalid publishing_group_id" do
    
      setup do
        post :create_sweepstake, :publishing_group_id => "blah", :code => "MYCODE"
      end
      
      should "render 404 page" do
        assert_template "#{Rails.root}/public/404.html"
      end
      
    end

    context "with rr publishing group id" do
      
      setup do
        @publishing_group = Factory(:publishing_group, :label => "rr", :name => "Road Runner")
        @publisher        = Factory(:publisher, :label => "timewarnercable-austin", :market_name => "Austin", :name => "Time Warner Cable - Austin", :publishing_group_id => @publishing_group.id)
        @advertiser       = Factory(:advertiser, :name => "My Advertiser", :publisher_id => @publisher.id)
        @offer            = Factory(:offer, :value_proposition => "My Offer", :advertiser_id => @advertiser.id, :coupon_code => "MYCODE")
        @valid_attributes = {
          :name => "John Doe", 
          :email => "jon.doe@somewhere.com", 
          :other_options => {:date_of_birth => "12/01/1965"}, 
          :zip_code => "97206", 
          :gender => "Male",
          :email_required => true,
          :required_fields => [
            "name",
            "zip",
            "gender"
          ] }
      end
      
      should "have created publishing group" do
        assert PublishingGroup.find_by_label( @publishing_group.label )
      end
      
      context "with invalid code" do
        
        setup do
          @code = "BLAH"
        end
        
        context "with valid subscriber information" do
          
          setup do
            post :create_sweepstake, :publishing_group_id => @publishing_group.label, :code => @code, :subscriber => @valid_attributes
          end
          
          should render_template("themes/rr/interactives/sweepstake")
          should assign_to( :subscriber )
          should "have invalid code error message" do
            assert assigns(:errors).include?( "Sorry, that is an invalid code." )
          end          
          should "have a valid subscriber" do 
            assert assigns(:subscriber).valid?
          end 
          
          should "render warn element" do
            assert_select "body" do
              assert_select "form" do
                assert_select "p.warn"
              end
            end            
          end
          
        end
        
        context "with invalid subscriber information" do
        
          setup do
            post :create_sweepstake, :publishing_group_id => @publishing_group.label, :code => @code, :subscriber => @valid_attributes.except(:email)
          end
          
          should render_template("themes/rr/interactives/sweepstake")
          should assign_to( :subscriber )
          should "have invalid code error message" do
            assert assigns(:errors).include?( "Sorry, that is an invalid code." )
          end
          should "have errors on subscriber" do
            assert assigns(:subscriber).errors.present?
          end
          should "render warn element" do
            assert_select "body" do
              assert_select "form" do
                assert_select "p.warn"
              end
            end            
          end                   
                    
        end
        
      end
      
      context "with valid code" do
        
        setup do
          @code = @offer.coupon_code
        end
        
        context "with valid subscriber information" do
          
          setup do
            post :create_sweepstake, :publishing_group_id => @publishing_group.label, :code => @code, :subscriber => @valid_attributes
          end
          
          should render_template("themes/rr/interactives/sweepstake")
          should assign_to( :subscriber )
          should assign_to( :success )

          should "not have invalid code error message" do
            assert !assigns(:errors).include?( "Sorry, that is an invalid code." )
          end          
          
          should "not have errors on subscriber" do
            assert !assigns(:subscriber).errors.present?
          end
          
        end
        
        context "with invalid subscriber information" do
        
          setup do
            post :create_sweepstake, :publishing_group_id => @publishing_group.label, :code => @code, :subscriber => @valid_attributes.except(:email)
          end
          
          should render_template("themes/rr/interactives/sweepstake")
          should assign_to( :subscriber )
          should_not assign_to( :success )
          
          should "not have invalid code error message" do
            assert !assigns(:errors).include?( "Sorry, that is an invalid code." )
          end          
          
          should "have errors on subscriber" do
            assert assigns(:subscriber).errors.present?
          end          
          
          should "render warn element" do
            assert_select "body" do
              assert_select "form" do
                assert_select "p.warn"
              end
            end            
          end
          
        end
        
      end      
    end
    
  end

end
