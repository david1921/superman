require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::OffPlatformTest < ActionController::TestCase
  tests DailyDealsController
  include DailyDealHelper
  
  context "new" do
    
    setup do
      @publisher = Factory(:publisher, :self_serve => true)
      @advertiser = Factory(:advertiser, :publisher => @publisher)      
    end
    
    context "with admin user" do
      
      setup do        
        login_as Factory(:admin)
        get :new, :advertiser_id => @advertiser.id
      end
      
      should "render off_platform checkbox" do        
        assert_select "input[type=checkbox][name='daily_deal[off_platform]']", true
      end
      
    end
    
    context "with self pubishing user" do
      
      setup do
        @authorized_user = Factory(:user, :company => @publisher)
        login_as @authorized_user
        get :new, :advertiser_id => @advertiser.id
      end
      
      should "not render off platform checkbox" do
        assert_select "input[type=checkbox][name='daily_deal[off_platform]']", false
      end
      
    end
    
  end
  
  context "edit" do
    
    context "with off platform daily deal" do
      
      setup do
        @deal = Factory(:off_platform_daily_deal)
      end
      
      context "with admin user" do
        
        setup do
          login_as Factory(:admin)
          get :edit, :id => @deal.id
        end
        
        should "render a checked off_platform checkbox" do
          assert_select "input[type=checkbox][name='daily_deal[off_platform]'][checked=checked]", true
        end
        
        should "render the off platform purchase summary" do
          assert_select "input[type=text][name='daily_deal[off_platform_purchase_summary_attributes][flat_fee]']", true          
          assert_select "input[type=text][name='daily_deal[off_platform_purchase_summary_attributes][number_of_purchases]']", true
          assert_select "input[type=text][name='daily_deal[off_platform_purchase_summary_attributes][number_of_refunds]']", true
          assert_select "input[type=text][name='daily_deal[off_platform_purchase_summary_attributes][analog_analytics_split_percentage]']", true
          assert_select "select[name='daily_deal[off_platform_purchase_summary_attributes][gross_or_net]']" do
            assert_select "option[value='']", :text => ''
            assert_select "option[value='gross']", :text => 'gross'
            assert_select "option[value='net']", :text => 'net'
          end
          assert_select "input[type=text][name='daily_deal[off_platform_purchase_summary_attributes][paid_to_analog_analytics]']", true          
        end
        
      end
      
      context "with self publishing user" do
        
        setup do
          @deal.publisher.update_attribute(:self_serve, true)
          @authorized_user = Factory(:user, :company => @deal.publisher)
          login_as @authorized_user
          get :edit, :id => @deal.id
        end
        
        should "not render off platform checkbox" do
          assert_select "input[type=checkbox][name='daily_deal[off_platform]']", false
        end    
        
        should "not render the off platform purchase summary" do
          assert_select "input[type=text][name='daily_deal[off_platform_purchase_summary][flat_fee]']", false                    
        end    
        
      end
      
    end
    
  end
  
end