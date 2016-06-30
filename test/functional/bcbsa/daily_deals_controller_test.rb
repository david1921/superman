require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Bcbsa::DailyDealsControllerTest

module Bcbsa
  
  class DailyDealsControllerTest < ActionController::TestCase
    
    tests DailyDealsController

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
      end

      context "a user with a publisher_membership_code cookie" do
        setup do
          @request.cookies["publisher_membership_code"] = "NXO"
        end

        should "not redirect to the bcbsa landing page on deal_of_the_day action" do
          get :show, :id => @daily_deal.to_param
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
          get :show, :id => @daily_deal.to_param
          assert_response :success          
        end
      end
      
    end
  
  end
    
end
