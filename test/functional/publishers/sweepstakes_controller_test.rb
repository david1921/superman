require File.dirname(__FILE__) + "/../../test_helper"

class Publishers::SweepstakesControllerTest < ActionController::TestCase

  fast_context "index" do

    fast_context "for TWC" do

      setup do
        @publishing_group = Factory(:publishing_group, :label => "rr")
        @publisher        = Factory(:publisher, :label => "clickedin-austin", :publishing_group => @publishing_group)        
      end

      context "with no sweepstakes" do

        setup do
          get :index, :publisher_id => @publisher.label
        end

        should "be a successful request" do
          assert_response :success
        end

        should "render the rr publishers/sweepstakes/index template" do
          assert_template "themes/rr/publishers/sweepstakes/index"
        end

        should "render the rr layouts/daily_deals" do
          assert_theme_layout "rr/layouts/publishers/landing_page"
        end

        should "have 0 sweepstakes" do
          assert_equal [], assigns(:sweepstakes)
        end

      end
      
      context "with no active or featured sweepstakes" do

        setup do
          @sweepstake = Factory(:sweepstake, :publisher => @publisher, :start_at => 3.hours.from_now, :hide_at => 10.days.from_now)
          get :index, :publisher_id => @publisher.label
        end

        should "render the rr publishers/sweepstakes/index template" do
          assert_template "themes/rr/publishers/sweepstakes/index"
        end

        should "render the rr layouts/daily_deals" do
          assert_theme_layout "rr/layouts/publishers/landing_page"
        end

        should "have 0 sweepstakes" do
          assert_equal [], assigns(:sweepstakes)
        end

        
        should_not assign_to(:featured)
        
      end
      
      context "with active sweepstakes and no featured sweepstake" do

        setup do
          @sweepstake = Factory(:sweepstake, :publisher => @publisher, :start_at => 3.hours.ago, :hide_at => 10.days.from_now)
          get :index, :publisher_id => @publisher.label
        end

        should "render the rr publishers/sweepstakes/index template" do
          assert_template "themes/rr/publishers/sweepstakes/index"
        end

        should "render the rr layouts/daily_deals" do
          assert_theme_layout "rr/layouts/publishers/landing_page"
        end

        should "have 1 sweepstakes" do
          assert_equal [@sweepstake], assigns(:sweepstakes)
        end
        
        should_not assign_to(:featured)
        
      end
      
      context "with active sweepstakes and a featured sweepstake" do

        setup do
          @featured   = Factory(:sweepstake, :publisher => @publisher, :start_at => 1.day.ago, :hide_at => 3.days.from_now, :featured => true)
          @sweepstake = Factory(:sweepstake, :publisher => @publisher, :start_at => 3.hours.ago, :hide_at => 10.days.from_now, :featured => false)          
          get :index, :publisher_id => @publisher.label
        end

        should "render the rr publishers/sweepstakes/index template" do
          assert_template "themes/rr/publishers/sweepstakes/index"
        end

        should "render the rr layouts/daily_deals" do
          assert_theme_layout "rr/layouts/publishers/landing_page"
        end
        
        should "have 1 sweepstakes" do
          assert_equal [@sweepstake], assigns(:sweepstakes)
        end
        
        should assign_to(:featured).with(@featured)        
        
      end
      
    end

    fast_context "for entertainment" do

      setup do
        @publishing_group = Factory(:publishing_group, :label => "entercomnew")
        @publisher        = Factory(:publisher, :label => "entercom-greenville", :publishing_group => @publishing_group)
      end

      context "with no sweepstakes" do

        setup do
          get :index, :publisher_id => @publisher.label
        end

        should "have no sweepstakes" do
          assert @publisher.sweepstakes.size == 0
        end

        should "be a successful response" do
          assert_response :success
        end

      end

    end


  end

  fast_context "show" do

    fast_context "for TWC" do

      setup do
        @publishing_group = Factory(:publishing_group, :label => "rr")
        @publisher        = Factory(:publisher, :label => "clickedin-austin", :publishing_group => @publishing_group)
        @sweepstake       = Factory(:sweepstake, :publisher => @publisher)
      end

      fast_context "with inactive sweepstake" do

        setup do
          @sweepstake.update_attributes(:start_at => 3.days.from_now, :hide_at => 10.days.from_now)
        end

        should "should raise ActiveRecord::RecordNotFound error" do
          assert_raise ActiveRecord::RecordNotFound do
            get :show, :publisher_id => @publisher.label, :id => @sweepstake.to_param
          end
        end

      end

      fast_context "with active sweepstake" do

        setup do
          @sweepstake.update_attributes(:start_at => 2.days.ago, :hide_at => 10.days.from_now)
          get :show, :publisher_id => @publisher.label, :id => @sweepstake.to_param
        end

        should "render the rr publishers/sweepstakes/show template" do
          assert_template "themes/rr/publishers/sweepstakes/show"
        end

        should "render the rr layouts/publishers/landing_page" do
          assert_theme_layout "rr/layouts/publishers/landing_page"
        end
        
        should assign_to( :sweepstake )
        
      end
      
    end
    
  end
  
  fast_context "thank_you" do
    
    fast_context "for TWC" do
      
      setup do
        @publishing_group     = Factory(:publishing_group, :label => "rr")
        @publisher            = Factory(:publisher, :label => "clickedin-austin", :publishing_group => @publishing_group)
        @sweepstake_1         = Factory(:sweepstake, :publisher => @publisher, :start_at => 2.days.ago, :hide_at => 1.day.from_now)        
        @sweepstake_2         = Factory(:sweepstake, :publisher => @publisher, :start_at => 3.days.ago, :hide_at => 3.days.from_now)
        @sweepstake_3         = Factory(:sweepstake, :publisher => @publisher, :start_at => 1.day.ago,  :hide_at => 3.days.from_now)        
        @sweepstake_4         = Factory(:sweepstake, :publisher => @publisher, :start_at => 4.days.ago, :hide_at => 1.day.ago)
        @expected_sweepstakes = @publisher.sweepstakes.active.except(@sweepstake_1)
      end
      
      fast_context "with @sweepstake_1" do
        
        setup do
          get :thank_you, :publisher_id => @publisher.label, :id => @sweepstake_1.to_param
        end

        should "render the rr publishers/sweepstakes/thank_you template" do
          assert_template "themes/rr/publishers/sweepstakes/thank_you"
        end

        should "render the rr layouts/publishers/landing_page" do
          assert_theme_layout "rr/layouts/publishers/landing_page"
        end

        should assign_to( :sweepstake )
        should assign_to( :sweepstakes ).with( @expected_sweepstakes )
        
      end

    end

  end

  fast_context "new" do

    setup do
      @publishing_group = Factory(:publishing_group, :label => "rr")
      @publisher = Factory(:publisher, :label => "clickedin-austin", :publishing_group => @publishing_group)
    end

    fast_context "with no authenticated account" do

      setup do
        get :new, :publisher_id => @publisher.to_param
      end

      should redirect_to("syndication login path") { new_session_path }

    end

    fast_context "with admin account" do

      setup do
        login_as Factory(:admin)
        get :new, :publisher_id => @publisher.to_param
      end

      should render_with_layout(:application)
      should render_template(:edit)
      should assign_to(:sweepstake)
      should "render the new sweepstake form" do
        assert_select "body" do
          assert_select "form[method='post'][action='#{ publisher_sweepstakes_path(@publisher)}']" do
            assert_fields_for_sweepstakes_edit
          end
        end
      end
      
    end
    
    fast_context "with publisher account" do
      
      setup do
        login_as Factory(:user, :company => @publisher)
        get :new, :publisher_id => @publisher.to_param
      end
      
      should render_with_layout(:application)
      should render_template(:edit)
      should assign_to(:sweepstake)
      should "render the new sweepstake form" do
        assert_select "body" do
          assert_select "form[method='post'][action='#{ publisher_sweepstakes_path(@publisher)}']" do
            assert_fields_for_sweepstakes_edit
          end
        end
      end
      
    end
    
    fast_context "with publishing group account" do
      
      setup do
        login_as Factory(:user, :company => @publishing_group)
        get :new, :publisher_id => @publisher.to_param
      end
      
      should render_with_layout(:application)
      should render_template(:edit)
      should assign_to(:sweepstake)
      should "render the new sweepstake form" do
        assert_select "body" do
          assert_select "form[method='post'][action='#{ publisher_sweepstakes_path(@publisher)}']" do
            assert_fields_for_sweepstakes_edit
          end
        end
      end

    end

  end

  fast_context "create" do

    setup do
      @publishing_group = Factory(:publishing_group, :label => "rr")
      @publisher = Factory(:publisher, :label => "clickedin-austin", :publishing_group => @publishing_group)
    end

    fast_context "with no authenticated account" do

      setup do
        post :create, :publisher_id => @publisher.to_param, :sweepstake => Factory.attributes_for(:sweepstake)
      end

      should redirect_to("syndication login path") { new_session_path }

    end

    fast_context "with admin acccount" do

      setup do
        login_as Factory(:admin)
        post :create, :publisher_id => @publisher.to_param, :sweepstake => Factory.attributes_for(:sweepstake)
      end

      should redirect_to("admin publisher sweepstakes") { admin_index_publisher_sweepstakes_path(@publisher.to_param) }
      should "assign flash notice" do
        assert_equal "Sweepstake was succesfully created.", flash[:notice]
      end

      should "create a new sweepstake on publisher" do
        assert_equal 1, @publisher.sweepstakes.size
      end

    end

    
    fast_context "with publisher acccount" do
    
      setup do
        login_as Factory(:user, :company => @publisher)
        post :create, :publisher_id => @publisher.to_param, :sweepstake => Factory.attributes_for(:sweepstake)
      end
      
      should redirect_to("admin publisher sweepstakes") { admin_index_publisher_sweepstakes_path(@publisher.to_param) }
      should "assign flash notice" do
        assert_equal "Sweepstake was succesfully created.", flash[:notice]
      end
      
      should "create a new sweepstake on publisher" do
        assert_equal 1, @publisher.sweepstakes.size
      end
      
    end
    
    fast_context "with publishing group acccount" do
    
      setup do
        login_as Factory(:user, :company => @publishing_group)
        post :create, :publisher_id => @publisher.to_param, :sweepstake => Factory.attributes_for(:sweepstake)
      end
      
      should redirect_to("admin publisher sweepstakes") { admin_index_publisher_sweepstakes_path(@publisher.to_param) }
      should "assign flash notice" do
        assert_equal "Sweepstake was succesfully created.", flash[:notice]
      end
      
      should "create a new sweepstake on publisher" do
        assert_equal 1, @publisher.sweepstakes.size
      end
      
    end
    
  end

  fast_context "edit" do

    setup do 
      @publishing_group = Factory(:publishing_group, :label => "rr")
      @publisher = Factory(:publisher, :label => "clickedin-austin", :publishing_group => @publishing_group)
      @sweepstake = Factory(:sweepstake, :publisher => @publisher)
    end

    fast_context "with no authenticated account" do

      setup do
        get :edit, :publisher_id => @publisher.to_param, :id => @sweepstake.to_param
      end

      should redirect_to("syndication login path") { new_session_path }

    end

    fast_context "with admin account" do

      setup do
        login_as Factory(:admin)
        get :edit, :publisher_id => @publisher.to_param, :id => @sweepstake.to_param
      end

      should render_with_layout( :application )
      should render_template(:edit)
      should assign_to(:sweepstake).with( @sweepstake )
      
      should "render the edit sweepstake form" do
        assert_select "body" do
          assert_select "form[method='post'][action='#{ publisher_sweepstake_path(@publisher, @sweepstake)}']" do
            assert_fields_for_sweepstakes_edit
          end
        end
      end
      
    end
    
    fast_context "with publisher account" do
    
      setup do
        login_as Factory(:user, :company => @publisher)
        get :edit, :publisher_id => @publisher.to_param, :id => @sweepstake.to_param
      end
      
      should render_with_layout( :application )
      should render_template(:edit)
      should assign_to(:sweepstake).with( @sweepstake )
      
      should "render the edit sweepstake form" do
        assert_select "body" do
          assert_select "form[method='post'][action='#{ publisher_sweepstake_path(@publisher, @sweepstake)}']" do
            assert_fields_for_sweepstakes_edit
          end
        end
      end
      
    end
    
    fast_context "with publishing group account" do
    
      setup do
        login_as Factory(:user, :company => @publishing_group)
        get :edit, :publisher_id => @publisher.to_param, :id => @sweepstake.to_param
      end
      
      should render_with_layout( :application )
      should render_template(:edit)
      should assign_to(:sweepstake).with( @sweepstake )
      
      should "render the edit sweepstake form" do
        assert_select "body" do
          assert_select "form[method='post'][action='#{ publisher_sweepstake_path(@publisher, @sweepstake)}']" do
            assert_fields_for_sweepstakes_edit
          end
        end
      end

    end

  end

  fast_context "update" do
    
    setup do 
      @publishing_group = Factory(:publishing_group, :label => "rr")
      @publisher = Factory(:publisher, :label => "clickedin-austin", :publishing_group => @publishing_group)
      @sweepstake = Factory(:sweepstake, :publisher => @publisher)
    end    
    
    fast_context "with no authenticated account" do

      setup do
        put :update, :publisher_id => @publisher.to_param, :id => @sweepstake.to_param
      end

      should redirect_to("syndication login path") { new_session_path }

    end

    fast_context "with admin account" do

      setup do
        login_as Factory(:admin)
      end

      fast_context "with valid attributes" do
        setup do
          put :update, :publisher_id => @publisher, :id => @sweepstake, :sweepstake => {:value_proposition => "My new value prop"}
        end

        should redirect_to( "admin index publisher sweepstake path" ) { admin_index_publisher_sweepstakes_path(@publisher) }
        should "assign flash notice" do
          assert_equal "Sweepstake was successfully updated.", flash[:notice]
        end
      end

      fast_context "with invalid attributes" do
        setup do
          put :update, :publisher_id => @publisher, :id => @sweepstake, :sweepstake => {:value_proposition => ""}
        end

        should "render the edit template in the admin layout" do
          assert_response :ok
          assert_template 'edit'
          assert_layout 'application'
        end
        should "assign flash notice" do
          assert_equal "Sweepstake could not be updated.", flash[:error]
        end
      end
    end
    
    fast_context "with publisher account" do
      
      setup do
        login_as Factory(:user, :company => @publisher)
        put :update, :publisher_id => @publisher.to_param, :id => @sweepstake.to_param, :sweepstake => {:value_proposition => "My new value prop"}
      end
      
      should redirect_to( "admin index publisher sweepstake path" ) { admin_index_publisher_sweepstakes_path(@publisher) }
      should "assign flash notice" do
        assert_equal "Sweepstake was successfully updated.", flash[:notice]
      end
      
    end
    
    fast_context "with publishing group account" do
      
      setup do
        login_as Factory(:user, :company => @publishing_group)
        put :update, :publisher_id => @publisher.to_param, :id => @sweepstake.to_param, :sweepstake => {:value_proposition => "My new value prop"}
      end
      
      should redirect_to( "admin index publisher sweepstake path" ) { admin_index_publisher_sweepstakes_path(@publisher) }
      should "assign flash notice" do
        assert_equal "Sweepstake was successfully updated.", flash[:notice]
      end
      
    end
    
  end

  fast_context "admin_index" do

    setup do
      @publisher    = Factory(:publisher)
      @sweepstake_1 = Factory(:sweepstake, :publisher => @publisher, :value_proposition => "Sweepstake 1")
      @sweepstake_1 = Factory(:sweepstake, :publisher => @publisher, :value_proposition => "Sweepstake 2")
    end

    fast_context "with no authenticated account" do

      setup do
        get :admin_index, :publisher_id => @publisher.to_param
      end

      should redirect_to("syndication login path") { new_session_path }

    end

    fast_context "with admin account" do

      setup do
        login_as Factory(:admin)
        get :admin_index, :publisher_id => @publisher.to_param
      end

      should render_with_layout( :application )
      should render_template( :admin_index )
      should assign_to( :sweepstakes )

    end

  end

  fast_context "preview" do

    fast_context "with TWC theme" do

      setup do
        @publishing_group = Factory(:publishing_group, :label => "rr")
        @publisher        = Factory(:publisher, :label => "clickedin-austin", :publishing_group => @publishing_group)
        @sweepstake       = Factory(:sweepstake, :publisher => @publisher, :start_at => 2.days.from_now, :hide_at => 3.days.from_now)
      end

      fast_context "with no authenticated account" do

        setup do
          get :preview, :publisher_id => @publisher.label, :id => @sweepstake.to_param
        end

        should redirect_to("syndication login path") { new_session_path }

      end

      fast_context "with an authenticated account that does not belong to current publisher" do

        setup do
          @another_publisher = Factory(:publisher)
          @consumer          = Factory(:consumer, :publisher => @another_publisher)
          login_as @consumer
          get :preview, :publisher_id => @publisher.label, :id => @sweepstake.to_param
        end

        should redirect_to("syndication login path") { new_session_path }

      end
      
      fast_context "with an authenticated account that belongs to current publisher" do

        setup do
          login_as Factory(:admin)
          get :preview, :publisher_id => @publisher.label, :id => @sweepstake.to_param
        end

        should "render the rr publishers/sweepstakes/show template" do
          assert_template "themes/rr/publishers/sweepstakes/show"
        end

        should "render the rr layouts/daily_deals" do
          assert_theme_layout "rr/layouts/publishers/landing_page"
        end
        
        should assign_to( :sweepstake )

      end
      
      fast_context "when Sweepstake#show_promotional_opt_in_checkbox is false" do
        
        setup do
          @sweepstake = Factory :sweepstake, :publisher => @publisher, :show_promotional_opt_in_checkbox => false
          @user = Factory :user, :company => @publisher
          login_as @user
          get :preview, :publisher_id => @publisher.label, :id => @sweepstake.to_param
          assert_response :success
        end
        
        should "not show the receive_promotional_emails checkbox" do
          assert_select "input[type=checkbox][name='sweepstake_entry[receive_promotional_emails]']", false
        end
        
      end

      fast_context "when Sweepstake#show_promotional_opt_in_checkbox is true" do
        
        setup do
          @sweepstake = Factory :sweepstake, :publisher => @publisher, :show_promotional_opt_in_checkbox => true
          @user = Factory :user, :company => @publisher
          login_as @user
          get :preview, :publisher_id => @publisher.label, :id => @sweepstake.to_param
          assert_response :success
        end
        
        should "show the receive_promotional_emails checkbox" do
          assert_select "input[type=checkbox][name='sweepstake_entry[receive_promotional_emails]']"
        end
        
      end

    end

  end

  fast_context "clear_logo" do

    setup do
      @sweepstake = Factory.build(:sweepstake)
      @sweepstake.logo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
      @sweepstake.save

      post :clear_logo, :publisher_id => @sweepstake.publisher.to_param, :id => @sweepstake.to_param
    end

    should "clear the logo" do
      assert !Sweepstake.find_by_id(@sweepstake.id).logo.file?
    end

  end

  fast_context "clear_logo_alternate" do

    setup do
      @sweepstake = Factory.build(:sweepstake)
      @sweepstake.logo_alternate = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
      @sweepstake.save

      post :clear_logo_alternate, :publisher_id => @sweepstake.publisher.to_param, :id => @sweepstake.to_param
    end

    should "clear the alternate logo" do
      assert !Sweepstake.find_by_id(@sweepstake.id).logo_alternate.file?
    end

  end

  fast_context "clear_photo" do

    setup do
      @sweepstake = Factory.build(:sweepstake)
      @sweepstake.photo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
      @sweepstake.save

      post :clear_photo, :publisher_id => @sweepstake.publisher.to_param, :id => @sweepstake.to_param
    end

    should "clear the photo" do
      assert !Sweepstake.find_by_id(@sweepstake.id).photo.file?
    end

  end
  
  fast_context "official rules" do
    
    fast_context "with twc publishing group" do

      setup do
        @publishing_group = Factory(:publishing_group, :label => "rr")
        @publisher        = Factory(:publisher, :label => "clickedin-austin", :publishing_group => @publishing_group)
        @sweepstake       = Factory(:sweepstake, :publisher => @publisher, :start_at => 2.days.ago, :hide_at => 3.days.from_now)
        get :official_rules, :publisher_id => @publisher.label, :id => @sweepstake.to_param
      end
      
      should "not render layout" do
        assert_layout nil
      end
      
      should "render the publishers/sweepstakes/official_rules template" do
        assert_template "publishers/sweepstakes/official_rules"
      end
      
      
    end

    
    
  end
  
  private 
  
  def assert_fields_for_sweepstakes_edit
    assert_select "input[type='text'][name='sweepstake[value_proposition]']", true, "should have value proposition field"
    assert_select "input[type='text'][name='sweepstake[value_proposition_subhead]']", true, "shoule have value proposition subhead field"
    assert_select "textarea[name='sweepstake[description]']", true, "should have description textarea"
    assert_select "textarea[name='sweepstake[terms]']", true, "should have terms textarea"
    assert_select "textarea[name='sweepstake[official_rules]']", true, "should have official rules textarea"
    assert_select "textarea[name='sweepstake[short_description]']", true, "should have short_description textarea"
    assert_select "input[type='text'][name='sweepstake[start_at]']", true, "should have start_at input"
    assert_select "input[type='text'][name='sweepstake[hide_at]']", true, "should have hide_at input"
    assert_select "input[type='file'][name='sweepstake[photo]']", true, "should have photo file input"
    assert_select "input[type='file'][name='sweepstake[logo]']", true, "should have logo file input"
    assert_select "input[type='file'][name='sweepstake[logo_alternate]']", true, "should have logo_alternate file input"
    assert_select "select[name='sweepstake[unlimited_entries]']", true, "should have unlimited_entries input"
    assert_select "input[type='text'][name='sweepstake[max_entries_per_period]']", true, "should have max_entries_per_period input"
    assert_select "select[name='sweepstake[max_entries_period]']", true, "should have max_entries_period input"
    assert_select "input[type='checkbox'][name='sweepstake[featured]']", true, "should have featured checkbox"
    assert_select "input[type='text'][name='sweepstake[promotional_opt_in_text]']", true, "should have promotional opt in text input"
    assert_select "input[type='checkbox'][name='sweepstake[show_promotional_opt_in_checkbox]']", true, "should show promotional opt-in checkbox"
  end
  
end
