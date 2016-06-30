require File.dirname(__FILE__) + "/../../test_helper"

class Publishers::SweepstakeEntriesControllerTest < ActionController::TestCase
  include Application::PasswordReset

  context "create" do

    context "with TWC publisher" do

      setup do
        @publishing_group           = Factory(:publishing_group, :label => "rr")
        @publisher                  = Factory(:publisher, :publishing_group => @publishing_group)
        @consumer                   = Factory(:consumer, :publisher => @publisher, :password => "password", :password_confirmation => "password")
        @sweepstake                 = Factory(:sweepstake, :publisher => @publisher, :start_at => 2.days.ago, :hide_at => 3.days.from_now )
        @valid_entry_attributes     = Factory.attributes_for(:sweepstake_entry).except(:consumer, :sweepstake)
        @valid_consumer_attributes  = Factory.attributes_for(:consumer).except(:publisher, :activated_at, :activation_code, :agree_to_terms ).merge(:email => "sara.doe@somwehere.com", :password => "password", :password_confirmation => "password")
      end

      context "with new consumer" do

        context "with invalid consumer information" do

          setup do
            post :create, :publisher_id => @publisher.label,
              :sweepstake_id => @sweepstake.to_param,
              :sweepstake_entry => @valid_entry_attributes,
              :consumer => @valid_consumer_attributes.except(:email)
          end

          should "render the rr publishers/sweepstakes/show template" do
            assert_template "themes/rr/publishers/sweepstakes/show"
          end

          should "render the rr layouts/daily_deals" do
            assert_theme_layout "rr/layouts/publishers/landing_page"
          end

          should "not login consumer" do
            assert_nil @controller.send(:current_consumer)
          end

        end

        context "with valid consumer information and entry information" do

          setup do
            post :create, :publisher_id => @publisher.label,
              :sweepstake_id => @sweepstake.to_param,
              :sweepstake_entry => @valid_entry_attributes,
              :consumer => @valid_consumer_attributes
          end

          should redirect_to( "the sweepstake thank you page" ) { thank_you_publisher_sweepstake_path(@publisher.label, @sweepstake) }

          should "create a new entry" do
            assert_equal 1, @sweepstake.entries.size
          end

          should "login consumer" do
            assert_not_nil @controller.send(:current_consumer)
          end

          should "mark consumer as active" do
            assert @controller.send(:current_consumer).active?
          end


        end

        context "with valid consumer information and invalid entry information" do

          setup do
            post :create, :publisher_id => @publisher.label,
              :sweepstake_id => @sweepstake.to_param,
              :sweepstake_entry => @valid_entry_attributes.except(:phone_number),
              :consumer => @valid_consumer_attributes
          end

          should "render the rr publishers/sweepstakes/show template" do
            assert_template "themes/rr/publishers/sweepstakes/show"
          end

          should "render the rr layouts/daily_deals" do
            assert_theme_layout "rr/layouts/publishers/landing_page"
          end

          should "login consumer" do
            assert_not_nil @controller.send(:current_consumer)
          end

          should "mark consumer as active" do
            assert @controller.send(:current_consumer).active?
          end

        end

      end

      context "with existing consumer" do

        context "with invalid consumer login" do

          setup do
            post :create, :publisher_id => @publisher.label,
              :sweepstake_id => @sweepstake.to_param,
              :sweepstake_entry => @valid_entry_attributes,
              :session => { :email => @consumer.email, :password => "wrongpassword" }
          end

          should "render the rr publishers/sweepstakes/show template" do
            assert_template "themes/rr/publishers/sweepstakes/show"
          end

          should "render the rr layouts/daily_deals" do
            assert_theme_layout "rr/layouts/publishers/landing_page"
          end

          should "not login consumer" do
            assert_nil @controller.send(:current_consumer)
          end

        end

        context "with valid consumer login and valid entry information" do

          setup do
            post :create, :publisher_id => @publisher.label,
              :sweepstake_id => @sweepstake.to_param,
              :sweepstake_entry => @valid_entry_attributes,
              :session => { :email => @consumer.email, :password => "password" }
          end

          should redirect_to( "the sweepstake thank you page" ) { thank_you_publisher_sweepstake_path(@publisher.label, @sweepstake) }

          should "create a new entry" do
            assert_equal 1, @sweepstake.entries.size
          end

          should "login consumer" do
            assert_not_nil @controller.send(:current_consumer)
          end

        end

        context "with valid consumer login and invalid entry information" do

          setup do
            post :create, :publisher_id => @publisher.label,
              :sweepstake_id => @sweepstake.to_param,
              :sweepstake_entry => @valid_entry_attributes.except(:phone_number),
              :session => { :email => @consumer.email, :password => "password" }
          end

          should "render the rr publishers/sweepstakes/show template" do
            assert_template "themes/rr/publishers/sweepstakes/show"
          end

          should "render the rr layouts/daily_deals" do
            assert_theme_layout "rr/layouts/publishers/landing_page"
          end

          should "login consumer" do
            assert_not_nil @controller.send(:current_consumer)
          end

        end

      end

      context "with an authorized consumer" do

        context "with valid entry information" do

          setup do
            login_as @consumer
            post :create, :publisher_id => @publisher.label, :sweepstake_id => @sweepstake.to_param, :sweepstake_entry => @valid_entry_attributes
          end

          should redirect_to( "the sweepstake thank you page" ) { thank_you_publisher_sweepstake_path(@publisher.label, @sweepstake) }

          should "create a new entry" do
            assert_equal 1, @sweepstake.entries.size
          end

        end
        
        context "receive_promotional_emails opt in checkbox" do
          
          setup do
            login_as @consumer
          end          
          
          should "be set to true on the sweepstake entry when checked" do
            assert @consumer.sweepstake_entries.blank?
            post :create, :publisher_id => @publisher.label, :sweepstake_id => @sweepstake.to_param, :sweepstake_entry => @valid_entry_attributes.merge(:receive_promotional_emails => true)
            entry = @consumer.reload.sweepstake_entries.last
            assert_equal entry.consumer, @consumer
            assert entry.receive_promotional_emails?
          end
          
          should "be set to false on the sweepstake entry when not checked" do
            assert @consumer.sweepstake_entries.blank?
            post :create, :publisher_id => @publisher.label, :sweepstake_id => @sweepstake.to_param, :sweepstake_entry => @valid_entry_attributes.merge(:receive_promotional_emails => nil)
            entry = @consumer.reload.sweepstake_entries.last
            assert_equal entry.consumer, @consumer
            assert !entry.receive_promotional_emails?            
          end
          
        end

        context "with invalid entry information" do

          setup do
            login_as @consumer
            post :create, :publisher_id => @publisher.label, :sweepstake_id => @sweepstake.to_param, :sweepstake_entry => @valid_entry_attributes.except(:phone_number)
          end

          should "render the rr publishers/sweepstakes/show template" do
            assert_template "themes/rr/publishers/sweepstakes/show"
          end

          should "render the rr layouts/daily_deals" do
            assert_theme_layout "rr/layouts/publishers/landing_page"
          end

        end

      end

      context "with an inactive sweepstake" do

        setup do
          login_as @consumer
          @sweepstake.update_attributes(:start_at => 2.days.from_now, :hide_at => 3.days.from_now )
          post :create, :publisher_id => @publisher.label, :sweepstake_id => @sweepstake.to_param, :sweepstake_entry => @valid_entry_attributes
        end

        should redirect_to( "publishers sweepstakes page" ) { publisher_sweepstakes_path(@publisher.label) }

      end

    end

  end

  context "admin_index" do

    setup do
      @publisher  = Factory(:publisher)
      @sweepstake = Factory(:sweepstake, :publisher => @publisher)
      (1..3).each do |index|
        consumer = Factory(:consumer, :publisher => @publisher)
        entry    = Factory(:sweepstake_entry, :sweepstake => @sweepstake, :consumer => consumer)
      end
    end

    should "have 3 entries on sweepstakes" do
      assert_equal 3, @sweepstake.entries.size
    end
    
    context "with no authenticated account" do

      setup do
        get :admin_index, :publisher_id => @publisher.to_param, :sweepstake_id => @sweepstake.to_param
      end

      should redirect_to( "new session path" ) { new_session_path }

    end

    context "with admin account" do

      setup do
        login_as Factory(:admin)
        get :admin_index, :publisher_id => @publisher.to_param, :sweepstake_id => @sweepstake.to_param
      end

      should "have a 'Third Party Opt-In?' header" do
        assert_select "th.receive_promotional_emails", :text => "Third Party Opt-In?"
      end

      should render_with_layout( :application )
      should render_template( :admin_index )
      should assign_to( :publisher ).with( @publisher )
      should assign_to( :sweepstake ).with( @sweepstake )
      should assign_to( :sweepstake_entries )

    end

  end

  context "create with force password reset" do
    should "redirect to new consumers when force redirect is encountered" do
      consumer = Factory(:consumer, :force_password_reset => true)
      sweepstake = Factory(:sweepstake, :publisher => consumer.publisher)
      entry_attrs = Factory.attributes_for(:sweepstake_entry).except(:consumer, :sweepstake)
      assert_not_nil consumer.publisher.sweepstakes.active.find(sweepstake.id)
      post :create,
           :publisher_id => consumer.publisher.label,
           :sweepstake_id => sweepstake.to_param,
           :sweepstake_entry => entry_attrs,
           :session => { :email => consumer.email, :password => consumer.password }
      assert_redirected_to consumer_password_reset_path_or_url consumer.publisher
    end
  end

end
