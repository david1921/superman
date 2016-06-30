require File.dirname(__FILE__) + "/../../test_helper"

class PublishingGroups::DailyDealsControllerTest < ActionController::TestCase

  fast_context "GET active.xml" do
    
    fast_context "with publishing group requiring a login for active daily deal feed" do

        setup do
          @publishing_group = Factory(:publishing_group, :label => "dummy", :require_login_for_active_daily_deal_feed => true)
        end

        fast_context "as admin" do
          setup do
            admin = Factory(:admin)
            set_http_basic_authentication :name => admin.login, :pass => "monkey"
          end
        
          fast_context "with deals" do
            setup do
              @publisher1 = Factory(:publisher, :publishing_group => @publishing_group, :label => 'foo')
              @publisher2 = Factory(:publisher, :publishing_group => @publishing_group, :label => 'bar')
              @deal1 = Factory(:daily_deal, :publisher => @publisher1)
              @deal2 = Factory(:daily_deal, :publisher => @publisher2)
              @deal3 = Factory(:daily_deal, :publisher => @publisher2, :start_at => 10.days.from_now, :hide_at => 20.days.from_now)
            end
        
            should "render an XML structure of the publishing group's deals" do
              get :active, :format => "xml", :publishing_group_id => @publishing_group.to_param
              assert_response :success
        
              assert_select "daily_deals[publishing_group_label='#{@publishing_group.label}']" do
                assert_select 'daily_deal' do
                  assert_select 'value_proposition', @deal1.value_proposition
                  assert_select 'publisher_label', 'foo'
                end
        
                assert_select 'daily_deal' do
                  assert_select 'value_proposition', @deal2.value_proposition
                  assert_select 'publisher_label', 'bar'
                end
              end
            end
        
            should "not include inactive deals" do
              assert_select "daily_deals daily_deal id:content('#{@deal3.id}')", 0
            end
          end
        
        end

        fast_context "as publishing group admin user" do
          setup do
            @user = create_user_with_company :company => @publishing_group
            set_http_basic_authentication :name => @user.login, :pass => "test"
          end
        
          should "render successfully" do
            get :active, :format => "xml", :publishing_group_id => @publishing_group.to_param
            assert_response :success
          end
        end
        
        fast_context "as publishing group admin user whose account has been locked" do
          setup do
            @user = create_user_with_company :company => @publishing_group
            set_http_basic_authentication :name => @user.login, :pass => "test"
            @user.lock_access!
          end
        
          should "return a 401 Unauthorized" do
            get :active, :format => "xml", :publishing_group_id => @publishing_group.to_param
            assert_response :unauthorized
          end
        end

        fast_context "as publisher admin user" do
          setup do
            @publisher = Factory(:publisher, :publishing_group => @publishing_group)
            @user = create_user_with_company :company => @publisher
            set_http_basic_authentication :name => @user.login, :pass => "test"
          end
        
          should "respond with unauthorized" do
            get :active, :format => "xml", :publishing_group_id => @publishing_group.to_param
            assert_response :unauthorized
          end
        end

        fast_context "not logged in" do
           should "respond with unauthorized" do
             get :active, :format => "xml", :publishing_group_id => @publishing_group.to_param
             assert_response :unauthorized
           end
         end

      end
      
    end
    
    fast_context "with publishing group NOT requiring a login for active daily deal feed" do
      
      setup do
        @publishing_group = Factory(:publishing_group, :label => "dummy", :require_login_for_active_daily_deal_feed => false)
      end
      
      fast_context "with no login" do
        setup do
          @publisher1 = Factory(:publisher, :publishing_group => @publishing_group, :label => 'foo')
          @publisher2 = Factory(:publisher, :publishing_group => @publishing_group, :label => 'bar')
          @deal1 = Factory(:daily_deal, :publisher => @publisher1)
          @deal2 = Factory(:daily_deal, :publisher => @publisher2)
          @deal3 = Factory(:daily_deal, :publisher => @publisher2, :start_at => 10.days.from_now, :hide_at => 20.days.from_now)
        end
    
        should "render an XML structure of the publishing group's deals" do
          get :active, :format => "xml", :publishing_group_id => @publishing_group.to_param
          assert_response :success
    
          assert_select "daily_deals[publishing_group_label='#{@publishing_group.label}']" do
            assert_select 'daily_deal' do
              assert_select 'value_proposition', @deal1.value_proposition
              assert_select 'publisher_label', 'foo'
            end
    
            assert_select 'daily_deal' do
              assert_select 'value_proposition', @deal2.value_proposition
              assert_select 'publisher_label', 'bar'
            end
          end
        end
    
        should "not include inactive deals" do
          assert_select "daily_deals daily_deal id:content('#{@deal3.id}')", 0
        end
        
      end
      
    end

end
