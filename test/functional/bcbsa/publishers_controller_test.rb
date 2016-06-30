require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Bcbsa::PublishersControllerTest

module Bcbsa
  
  class PublishersControllerTest < ActionController::TestCase
    
    tests PublishersController
    
    context "A BCBSA publisher" do
      
      setup do
        @publishing_group = Factory(:publishing_group, :label => "bcbsa", :require_publisher_membership_codes => true)
        @publisher = Factory(:publisher, :label => "bcbsami", :publishing_group => @publishing_group)
        @advertiser = Factory(:advertiser, :publisher => @publisher)
        @daily_deal = Factory(:daily_deal, :advertiser => @advertiser)
      end

      context "a user without a publisher_membership_code cookie" do
        setup do
          @request.cookies["publisher_membership_code"] = nil
        end

        should "not redirect to the bcbsa landing page on seo_friendly_deal_of_the_day action" do
          get :seo_friendly_deal_of_the_day, :publisher_label => @publisher.label
          assert_response :success
        end
      end

      context "a user with a publisher_membership_code cookie" do
        setup do
          @request.cookies["publisher_membership_code"] = "NXO"
        end

        should "not redirect to the bcbsa landing page on deal_of_the_day action" do
          get :deal_of_the_day, :label => @publisher.label
          assert_response :success
        end

        should "not redirect to the bcbsa landing page on seo_friendly_deal_of_the_day action" do
          get :seo_friendly_deal_of_the_day, :publisher_label => @publisher.label
          assert_response :success
        end
      end

      context "a logged in user with no publisher_membership_code cookie" do
        setup do
          @request.cookies["publisher_membership_code"] = nil
          code = @publisher.publisher_membership_codes.create(:code => "NXO")
          @consumer = Factory(:consumer, :publisher => @publisher, :publisher_membership_code => code)
          login_as @consumer
        end

        should "not be redirected" do
          get :deal_of_the_day, :label => @publisher.label
          assert_response :success          
        end
      end

      context "publisher_label cookie" do                                 @response
        should 'set a publisher_label cookie when the user visits a vanity url' do
          assert_equal nil, cookies['publisher_label']
          get :seo_friendly_deal_of_the_day, :publisher_label => @publisher.label
          assert_response :success
          assert_equal @publisher.label, cookies['publisher_label']
        end
      end
      
    end

    context "filter deals by show_on_landing_page" do
      setup do
        @publishing_group = Factory(:publishing_group, :label => "bcbsa", :require_publisher_membership_codes => true)
        @publisher = Factory(:publisher, :label => "bcbsami", :publishing_group => @publishing_group)
        @daily_deal = Factory(:daily_deal, :publisher => @publisher, :show_on_landing_page => false)
        @daily_deal2 = Factory(:side_daily_deal, :show_on_landing_page => true, :publisher => @publisher)
      end

      should "filter deals with show_on_landing_page" do
        @publisher.update_attributes(:main_publisher => true)
        get :deal_of_the_day, :label => @publisher.label
        assert_response :success
        assert_equal @daily_deal2, assigns(:daily_deal)
      end

      should "not filter deals with show_on_landing_page for admins" do
        @publisher.update_attributes(:main_publisher => true)
        login_as Factory(:admin)
        get :deal_of_the_day, :label => @publisher.label
        assert_response :success
        assert_equal @daily_deal, assigns(:daily_deal)
      end

      should "not filter deals with show_on_landing_page for consumers with master_membership_code" do
        @publishing_group = Factory(:publishing_group, :require_publisher_membership_codes => true)
        @publisher.update_attributes(:main_publisher => true, :publishing_group => @publishing_group)
        master_publisher_membership_code = Factory(:publisher_membership_code, :publisher => @publisher, :master => true)
        @consumer = Factory(:consumer, :publisher => @publisher, :publisher_membership_code => master_publisher_membership_code, :email => "foobar@yahoo.com", :password => "password", :password_confirmation => "password")

        login_as @consumer
        get :deal_of_the_day, :label => @publisher.label
        assert_response :success
        assert_equal @daily_deal, assigns(:daily_deal)
      end
    end
    
  end
  
end
