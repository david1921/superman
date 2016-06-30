require File.dirname(__FILE__) + "/../../test_helper"

# hydra class LoyaltyProgram::DailyDealsControllerTest

module LoyaltyProgram
  
  class DailyDealsControllerTest < ActionController::TestCase
    
    include ::DailyDealHelper    
    tests ::DailyDealsController
    
    context "GET to :loyalty_program with a logged in user" do
      
      setup do
        @daily_deal = Factory :daily_deal
        @consumer = Factory :consumer, :publisher => @daily_deal.publisher
        login_as(@consumer)
      end
      
      context "when the deal has the loyalty program enabled" do
        
        setup do
          @daily_deal.update_attributes :enable_loyalty_program => true,
                                        :referrals_required_for_loyalty_credit => 5
        end
        
        should "render successfully, and show the loyalty program url" do
          get :loyalty_program, :id => @daily_deal.to_param
          assert_response :success
          assert_match %r{#{Regexp.escape(loyalty_program_url(@daily_deal, @consumer))}}, @response.body
        end
        
      end
      
      context "when the deal has the loyalty program disabled" do
        
        setup do
          @daily_deal.update_attribute :enable_loyalty_program, false
        end
        
        should "render successfully, but with no link to the loyalty program" do
          get :loyalty_program, :id => @daily_deal.to_param
          assert_response :success
          assert_no_match %r{#{Regexp.escape(loyalty_program_url(@daily_deal, @consumer))}}, @response.body
        end
        
      end
      
    end
    
    context "GET to :loyalty_program when not logged in" do
      
      setup do
        @daily_deal = Factory :daily_deal, :enable_loyalty_program => true, :referrals_required_for_loyalty_credit => 2
      end
      
      should "render successfully, not show any loyalty program link, and tell the user " +
             "they need to log in to access their loyalty program url" do
        get :loyalty_program, :id => @daily_deal.to_param
        assert_response :success
        assert_no_match %r{referrer_code}, @response.body
        assert_select "p#login-to-access-loyalty-program-url"
      end
      
    end
    
    context "GET to :show when a referral_code is present in the URL" do
      
      setup do
        @daily_deal = Factory :daily_deal
      end
      
      should "store the referral_code in a loyalty_referral_code_{:deal_id} cookie when " +
             "DailyDeal#enable_loyalty_program is true" do
        @daily_deal.update_attribute :enable_loyalty_program, true
        get :show, :id => @daily_deal.to_param, :referral_code => "ABC-XYZ"
        assert_response :success
        assert_equal "ABC-XYZ", cookies["loyalty_referral_code_#{@daily_deal.id}"]
      end
             
      should "NOT store the referral_code in a loyalty_referral_code_{:deal_id} cookie when " +
             "DailyDeal#enable_loyalty_program is false" do
        @daily_deal.update_attribute :enable_loyalty_program, false
        get :show, :id => @daily_deal.to_param, :referral_code => "ABC-XYZ"
        assert_response :success
        assert cookies[:"loyalty_referral_code_#{@daily_deal.id}"].blank?
      end
      
      should "store the referral_code in a referral_code cookie when " +
             "Publisher#enable_daily_deal_referral is true" do
        @daily_deal.publisher.update_attribute :enable_daily_deal_referral, true
        get :show, :id => @daily_deal.to_param, :referral_code => "ABC-XYZ"
        assert_response :success
        assert_equal "ABC-XYZ", cookies["referral_code"]
      end
      
      should "NOT store the referral_code in a referral_code cookie when " +
             "Publisher#enable_daily_deal_referral is false" do
        @daily_deal.publisher.update_attribute :enable_daily_deal_referral, false
        get :show, :id => @daily_deal.to_param, :referral_code => "ABC-XYZ"
        assert_response :success
        assert cookies["referral_code"].blank?
      end
      
    end
    
    context "GET to :new as an admin, and publisher loyalty program defaults" do
      
      setup do
        @advertiser = Factory :advertiser
        login_as(Factory :admin)
      end
      
      should "check the enable loyalty program checkbox when Publisher#enable_loyalty_program_for_new_deals is true" do
        @advertiser.publisher.update_attribute :enable_loyalty_program_for_new_deals, true
        get :new, :advertiser_id => @advertiser.to_param
        assert_response :success
        assert_select "input[name='daily_deal[enable_loyalty_program]']"
        assert_select "input[name='daily_deal[enable_loyalty_program]'][checked=checked]"
      end
      
      should "NOT check the enable loyalty program checkbox when Publisher#enable_loyalty_program_for_new_deals is true" do
        @advertiser.publisher.update_attribute :enable_loyalty_program_for_new_deals, false
        get :new, :advertiser_id => @advertiser.to_param
        assert_response :success
        assert_select "input[name='daily_deal[enable_loyalty_program]']"
        assert_select "input[name='daily_deal[enable_loyalty_program]'][checked=checked]", false
      end
      
      should "set the referrals required to the value Publisher#referrals_required_for_loyalty_credit_for_new_deals, " +
             "when present" do
        @advertiser.publisher.update_attribute :referrals_required_for_loyalty_credit_for_new_deals, 42
        get :new, :advertiser_id => @advertiser.to_param
        assert_response :success
        assert_select "input[name='daily_deal[referrals_required_for_loyalty_credit]']"
        assert_select "input[name='daily_deal[referrals_required_for_loyalty_credit]'][value=42]"
      end
             
      should "set the referrals required to empty, when Publisher#referrals_required_for_loyalty_credit_for_new_deals " +
             "is empty" do
        @advertiser.publisher.update_attribute :referrals_required_for_loyalty_credit_for_new_deals, nil  
        get :new, :advertiser_id => @advertiser.to_param
        assert_response :success
        assert_select "input[name='daily_deal[referrals_required_for_loyalty_credit]']"
        assert_select "input[name='daily_deal[referrals_required_for_loyalty_credit]'][value='']", false
      end
      
    end
    
    context "GET to :edit as an admin" do
      
      setup do
        @advertiser = Factory :advertiser
        @deal = Factory :daily_deal, :advertiser => @advertiser
        login_as(Factory :admin)
      end
      
      should "set the value of the enable loyalty program field to the deal's value, not the publisher-wide default" do
        @advertiser.publisher.update_attribute :enable_loyalty_program_for_new_deals, true
        @deal.update_attribute :enable_loyalty_program, false
        get :edit, :id => @deal.to_param
        assert_response :success
        assert_select "input[name='daily_deal[enable_loyalty_program]']"
        assert_select "input[name='daily_deal[enable_loyalty_program]'][checked=checked]", false
      end
      
      should "set the referrals required to the deal's value not the publisher wide default" do
        @advertiser.publisher.update_attribute :referrals_required_for_loyalty_credit_for_new_deals, 42
        @deal.update_attribute :referrals_required_for_loyalty_credit, 10
        get :edit, :id => @deal.to_param
        assert_response :success
        assert_select "input[name='daily_deal[referrals_required_for_loyalty_credit]']"
        assert_select "input[name='daily_deal[referrals_required_for_loyalty_credit]'][value=10]"
      end
      
    end
    
  end
  
end