require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Reports::LoyaltyProgramControllerTest

module Reports
  
  class LoyaltyProgramControllerTest < ActionController::TestCase
    
    tests Reports::LoyaltyProgramController
    
    fast_context "without daily deal variations" do

      setup do
        @now = Time.zone.local(2011, 4, 14, 12, 34, 56)
        Timecop.freeze(@now)
        @admin = Factory :admin
        @publishing_group = Factory(:publishing_group)
        @publisher_1 = Factory :publisher, :name => "Foo Publisher", :publishing_group => @publishing_group
        @publisher_2 = Factory :publisher, :name => "Bar Publisher"
        @publisher_3 = Factory :publisher, :name => "Baz Publisher"
        @publisher_4 = Factory :publisher, :name => "Fnorb Publisher"
        @other_publisher = Factory :publisher, :name => "Spam Publisher"
        
        @consumer_1 = Factory :consumer, :publisher => @publisher_1
        @consumer_2 = Factory :consumer, :publisher => @publisher_2
        @consumer_3 = Factory :consumer, :publisher => @publisher_4
        @consumer_4 = Factory :consumer, :publisher => @publisher_4
        @consumer_5 = Factory :consumer, :publisher => @publisher_4
        @consumer_6 = Factory :consumer, :publisher => @publisher_4
        @consumer_7 = Factory :consumer, :publisher => @publisher_4
        @consumer_8 = Factory :consumer, :publisher => @publisher_4
        
        @deal_1 = deal_with_loyalty_program_enabled(@publisher_1)
        @deal_2 = deal_with_loyalty_program_enabled(@publisher_2)
        @deal_3 = deal_with_loyalty_program_enabled(@publisher_3)
        @deal_4 = deal_with_loyalty_program_enabled(@publisher_4)
        @deal_5 = deal_with_loyalty_program_enabled(@publisher_4)
        
        @p1 = purchase_that_earned_loyalty_credit(@deal_1, @consumer_1)
        @p2 = purchase_that_earned_loyalty_credit(@deal_2, @consumer_2)
        @p3 = purchase_that_earned_loyalty_credit(@deal_4, @consumer_3)
        @p4 = purchase_with_no_loyalty_referrals(@deal_4, @consumer_7)
        @p5 = purchase_with_num_loyalty_referrals_less_than_referrals_required(@deal_5, @consumer_4)
        @p6 = purchase_with_num_loyalty_referrals_less_than_referrals_required(@deal_5, @consumer_5)
        @p7 = purchase_with_required_number_of_referrals_but_all_from_same_consumer(@deal_5, @consumer_6)
        @p8 = purchase_that_earned_the_loyalty_credit_twice(@deal_5, @consumer_6)
        @p9 = purchase_that_earned_loyalty_credit_and_has_received_the_credit(@deal_5, @consumer_8)
        
        @p3.update_attribute :executed_at, 100.minutes.ago
        @p4.update_attribute :executed_at, 50.minutes.ago
        @p5.update_attribute :executed_at, 1.minute.ago
        @p6.update_attribute :executed_at, 8.minutes.ago
        @p7.update_attribute :executed_at, 5.days.ago
        @p8.update_attribute :executed_at, 3.days.ago        
        @p9.update_attribute :executed_at, 2.days.ago
      end

      teardown do
        Timecop.return
      end

      context "restricted access" do
        setup do
          @user = Factory.create(:restricted_admin, :company => @publishing_group)
          login_as(@user)
        end

        should "restirct loyalty_eligible_index" do
          get :loyalty_eligible_index
          assert_select "table.publishers"
          assert_select "table.publishers tr", :count => 2
        end

        should "restrict loyalty_eligible_for_publisher to the users managed publishers" do
          get :loyalty_eligible_for_publisher, :id => @publisher_1.to_param
          assert_response :success
          assert_raises(ActiveRecord::RecordNotFound) do
            get :loyalty_eligible_for_publisher, :id => @publisher_2.to_param
          end
        end

        should "restrict loyalty_analytics_index to the users managed publishers" do
          get :loyalty_analytics_index
          assert_select "table.publishers"
          assert_select "table.publishers tr", :count => 2
        end

      end
      
      fast_context "GET to :loyalty_eligible_index as admin" do

        setup do
          login_as(@admin)
          get :loyalty_eligible_index
        end

        should "respond successfully" do
          assert_response :success
        end

        should "assign to @publishers only publishers that have purchases eligible for a loyalty refund" do
          assert_equal [@publisher_2.id, @publisher_4.id, @publisher_1.id], assigns(:publishers).map(&:id)
        end

        should "display a table listing the publishers with purchases eligible for a loyalty refund" do
          assert_select "table.publishers"
          assert_select "table.publishers tr", :count => 4
        end

        should "render links to each publisher's eligible purchase listing" do
          assert_select "a[href='#{loyalty_eligible_reports_publisher_path(:id => @publisher_1.to_param)}']"
          assert_select "a[href='#{loyalty_eligible_reports_publisher_path(:id => @publisher_2.to_param)}']"
        end

      end

      fast_context "GET to :loyalty_eligible_index, not authenticated" do

        setup do
          get :loyalty_eligible_index
        end

        should "redirect to the login page" do
          assert_redirected_to new_session_url
        end

      end

      fast_context "GET to :loyalty_eligible_for_publisher as admin" do

        setup do
          login_as(@admin)
          get :loyalty_eligible_for_publisher, :id => @publisher_1.to_param
        end

        should "respond successfully" do
          assert_response :success
        end

        should "assign the publisher to @publisher" do
          assert_equal @publisher_1, assigns(:publisher)
        end

        should "assign eligible purchases to @eligible_purchases" do
          assert_equal [@p1.id], assigns(:eligible_purchases).map(&:id)
        end

        should "render a row for each eligible purchase" do
          assert_select "tr#purchase-#{@p1.id}", :count => 1
        end

        should "render links to the purchase edit page" do
          assert_select "a[href='#{daily_deal_purchases_consumers_admin_edit_path(@p1.id)}']"
        end

      end

      fast_context "GET to :loyalty_eligible_for_publisher, not authenticated" do

        setup do
          get :loyalty_eligible_for_publisher, :id => @publisher_1.to_param
        end

        should "redirect to the login page" do
          assert_redirected_to new_session_url
        end

      end

      fast_context "GET to :loyalty_analytics_index as admin" do

        setup do
          login_as(@admin)
          get :loyalty_analytics_index
        end

        should "response successfully" do
          assert_response :success
        end

        should "assign to @publishers only publishers that have at least one deal " +
               "with the loyalty program enabled, ordered by name" do
          assert_equal [@publisher_2.id, @publisher_3.id, @publisher_4.id, @publisher_1.id], assigns(:publishers).map(&:id)
        end

        should "display a table listing the publishers" do
          assert_select "table.publishers"
          assert_select "table.publishers tr", :count => 5
        end

        should "render links to each publisher's loyalty analytics" do
          assert_select "a[href='#{loyalty_analytics_reports_publisher_path(:id => @publisher_1.to_param)}']"
        end

      end

      fast_context "GET to :loyalty_analytics_index, not authenticated" do

        setup do
          get :loyalty_analytics_index, :id => @publisher_1.to_param
        end

        should "redirect to the login page" do
          assert_redirected_to new_session_url
        end

      end

      fast_context "GET to :loyalty_analytics_for_publisher as an admin, in HTML format" do

        setup do
          login_as(@admin)
          get :loyalty_analytics_for_publisher, :id => @publisher_1.to_param
        end

        should "respond successfully" do
          assert_response :success
        end

        should "render the loyalty_analytics_for_publisher template" do
          assert_template "reports/loyalty_program/loyalty_analytics_for_publisher"
        end

        should "set the report title" do
          assert_match "Loyalty Referrals: Foo Publisher", @response.body
        end

        should "render the date widgets" do
          assert_select "div#dates"
        end

        should "render the results container" do
          assert_select "div#publishers_loyalty_referrals"
        end

        should "set the XML version of the report as the data source" do
          re_escaped_url = Regexp.escape(loyalty_analytics_reports_publisher_path(@publisher_1, :format => "xml"))
          assert_match %r{DataSource\('#{re_escaped_url}'\)}, @response.body
        end

      end

      fast_context "GET to :loyalty_analytics_for_publisher as an admin, in XML format" do

        setup do
          login_as(@admin)
          Timecop.freeze(@now) do
            get :loyalty_analytics_for_publisher, :id => @publisher_4.to_param, :format => "xml"
          end

          assert_response :success
          @xml = Nokogiri::XML(@response.body)
        end

        should "return a loyalty_purchase_analytics root node" do
          assert_equal "purchases", @xml.root.name
        end

        should "assign all purchases on this publisher in the last 30 days, with loyalty referrals " +
               "to @purchases_with_loyalty_referrals, in order of executed_at DESC" do
          assert_equal [@p5.id, @p6.id, @p3.id, @p9.id, @p8.id], assigns(:purchases_with_loyalty_referrals).map(&:id)
        end

        should "return an entry for each purchase on this publisher that has loyalty referrals" do
          assert_equal 5, @xml.css("purchase").size
        end

        should "include the loyalty_referrals_count for each purchase" do
          assert_equal [2, 2, 3, 3, 7], @xml.css("purchase loyalty_referrals_count").map { |lrc| lrc.text.to_i }
        end

        should "include other columns needed by the report" do
          %w(value_proposition quantity purchaser_name executed_at payment_status refunded_at).each do |column|
            assert_equal 5, @xml.css("purchase #{column}").size, "missing '#{column}' from loyalty analytics xml"
          end
        end

      end

      fast_context "GET to :loyalty_analytics_for_publisher as an admin, in XML format, with date parameters" do

        setup do
          login_as(@admin)
          get :loyalty_analytics_for_publisher, :id => @publisher_4.to_param, :format => "xml",
              :dates_begin => "2011-04-13", :dates_end => "2011-04-14"

          assert_response :success
          @xml = Nokogiri::XML(@response.body)
        end

        should "assign only purchases with loyalty referrals within the date range" do
          assert_equal [@p5.id, @p6.id, @p3.id], assigns(:purchases_with_loyalty_referrals).map(&:id)
        end

        should "include the loyalty_referrals_count for each purchase" do
          assert_equal [2, 2, 3], @xml.css("purchase loyalty_referrals_count").map { |lrc| lrc.text.to_i }
        end

      end


      fast_context "with daily deal variations" do

        setup do
          @publisher_5  = Factory(:publisher, :name => "Publisher Variations 1", :enable_daily_deal_variations => true)
          @consumer_8   = Factory(:consumer, :publisher => @publisher_5)
          @deal_6       = deal_with_loyalty_program_enabled(@publisher_5)

          @variation_1  = Factory(:daily_deal_variation, :daily_deal => @deal_6)
          @variation_2  = Factory(:daily_deal_variation, :daily_deal => @deal_6)

          # all the purchases are the same variations, so it should show up on report
          @p9 = purchase_that_earned_loyalty_credit_with_variation(@deal_6, @variation_2, @consumer_8)

          @publisher_6  = Factory(:publisher, :name => "Publisher Variations 2", :enable_daily_deal_variations => true)
          @consumer_9   = Factory(:consumer, :publisher => @publisher_6)
          @deal_7       = deal_with_loyalty_program_enabled(@publisher_6)

          @variation_3  = Factory(:daily_deal_variation, :daily_deal => @deal_7)
          @variation_4  = Factory(:daily_deal_variation, :daily_deal => @deal_7)

          # purchases are with difference variations, put the number of purchases match the daily deal referral quantity
          @p10 = purchase_that_match_referrals_required_for_loyalty_credit_with_different_variations(@deal_7, [@variation_3, @variation_4], @consumer_9)

          login_as(@admin)
          get :loyalty_eligible_index
        end

        fast_context "GET to :loyalty_eligible_index as admin with daily deal variation purchases" do

          should "respond successfully" do
            assert_response :success
          end

          should "assign to @publishers only publishers that have purchases eligible for a loyalty refund" do
            assert_equal [@publisher_2.id, @publisher_4.id, @publisher_1.id, @publisher_5.id], assigns(:publishers).map(&:id)
          end

          should "display a table listing the publishers with purchases eligible for a loyalty refund" do
            assert_select "table.publishers"
            assert_select "table.publishers tr", :count => 5
          end

          should "render links to each publisher's eligible purchase listing" do
            assert_select "a[href='#{loyalty_eligible_reports_publisher_path(:id => @publisher_1.to_param)}']"
            assert_select "a[href='#{loyalty_eligible_reports_publisher_path(:id => @publisher_2.to_param)}']"
            assert_select "a[href='#{loyalty_eligible_reports_publisher_path(:id => @publisher_5.to_param)}']"
            assert_select "a[href='#{loyalty_eligible_reports_publisher_path(:id => @publisher_6.to_param)}']", false
          end

        end

        fast_context "GET to :loyalty_eligible_for_publisher with valid purchases with daily deal variations as admin" do

          setup do
            login_as(@admin)
            get :loyalty_eligible_for_publisher, :id => @publisher_5.to_param
          end

          should "respond successfully" do
            assert_response :success
          end

          should "assign the publisher to @publisher" do
            assert_equal @publisher_5, assigns(:publisher)
          end

          should "assign eligible purchases to @eligible_purchases" do
            assert_equal [@p9.id], assigns(:eligible_purchases).map(&:id)
          end

          should "render a row for each eligible purchase" do
            assert_select "tr#purchase-#{@p9.id}", :count => 1
          end

          should "render links to the purchase edit page" do
            assert_select "a[href='#{daily_deal_purchases_consumers_admin_edit_path(@p9.id)}']"
          end

        end

        fast_context "GET to :loyalty_eligible_for_publisher with invalid purchases with daily deal variations as admin" do

          setup do
            login_as(@admin)
            get :loyalty_eligible_for_publisher, :id => @publisher_6.to_param
          end

          should "respond successfully" do
            assert_response :success
          end

          should "assign the publisher to @publisher" do
            assert_equal @publisher_6, assigns(:publisher)
          end

          should "have no eligible purchases" do
            assert assigns(:eligible_purchases).empty?
          end

        end

        fast_context "GET to :loyalty_analytics_for_publisher as an admin, with publisher who has purchases that match loyalty criteria in XML format" do

          setup do
            login_as(@admin)
            Timecop.freeze(@now) do
              get :loyalty_analytics_for_publisher, :id => @publisher_5.to_param, :format => "xml"
            end

            assert_response :success
            @xml = Nokogiri::XML(@response.body)
          end

          should "return a loyalty_purchase_analytics root node" do
            assert_equal "purchases", @xml.root.name
          end

          should "assign all purchases on this publisher in the last 30 days, with loyalty referrals " +
                 "to @purchases_with_loyalty_referrals, in order of executed_at DESC" do
            assert_equal [@p9.id], assigns(:purchases_with_loyalty_referrals).map(&:id)
          end

          should "return an entry for each purchase on this publisher that has loyalty referrals" do
            assert_equal 1, @xml.css("purchase").size
          end

          should "include the loyalty_referrals_count for each purchase" do
            assert_equal [3], @xml.css("purchase loyalty_referrals_count").map { |lrc| lrc.text.to_i }
          end


        end

        fast_context "GET to :loyalty_analytics_for_publisher as an admin, with publisher who has no purchases that match loyalty criteria in XML format" do

          setup do
            login_as(@admin)
            Timecop.freeze(@now) do
              get :loyalty_analytics_for_publisher, :id => @publisher_6.to_param, :format => "xml"
            end

            assert_response :success
            @xml = Nokogiri::XML(@response.body)
          end

          should "return a loyalty_purchase_analytics root node" do
            assert_equal "purchases", @xml.root.name
          end

          should "assign all purchases on this publisher in the last 30 days, with loyalty referrals " +
                 "to @purchases_with_loyalty_referrals, in order of executed_at DESC" do
            assert_equal [@p10.id], assigns(:purchases_with_loyalty_referrals).map(&:id)
          end

          should "return an entry for each purchase on this publisher that has loyalty referrals" do
            assert_equal 1, @xml.css("purchase").size
          end

        end

      end

    end

  end
  
end
