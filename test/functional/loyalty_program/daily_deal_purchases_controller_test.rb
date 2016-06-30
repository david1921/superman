require File.dirname(__FILE__) + "/../../test_helper"

# hydra class LoyaltyProgram::DailyDealPurchasesControllerTest

module LoyaltyProgram
  
  class DailyDealPurchasesControllerTest < ActionController::TestCase
    
    include DailyDealHelper
    tests DailyDealPurchasesController
        
    context "Creating a purchase when a loyalty program referral code is present" do
      
      setup do
        @daily_deal = Factory :daily_deal
        @consumer = Factory :consumer, :referrer_code => "OMGBBQ", :publisher => @daily_deal.publisher
        login_as @consumer
        @request.cookies["loyalty_referral_code_#{@daily_deal.id}"] = @consumer.referrer_code
      end

      context "when DailyDeal#enable_loyalty_program? is true" do
        
        setup do
          @daily_deal.update_attribute :enable_loyalty_program, true
          assert_difference "DailyDealPurchase.count", 1 do
            post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_purchase => { :quantity => "1" }
            @purchase = assigns(:daily_deal_purchase)
            assert_redirected_to confirm_daily_deal_purchase_url(@purchase)
          end
        end
        
        should "store the loyalty program referral code on the purchase" do
          assert_equal "OMGBBQ", @purchase.loyalty_program_referral_code
        end
      
      end
      
      context "when DailyDeal#enable_loyalty_program? is false" do
        
        setup do
          @daily_deal.update_attribute :enable_loyalty_program, false
          assert_difference "DailyDealPurchase.count", 1 do
            post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_purchase => { :quantity => "1" }
            @purchase = assigns(:daily_deal_purchase)
            assert_redirected_to confirm_daily_deal_purchase_url(@purchase)
          end
        end
        
        should "NOT store the loyalty program referral code on the purchase" do
          assert_nil @purchase.loyalty_program_referral_code
        end
        
      end
    
    end
    
    context "GET to :consumers_admin_edit as an admin" do
      
      setup do
        @admin = Factory :admin
        login_as(@admin)
        @publisher = Factory :publisher, :enable_loyalty_program_for_new_deals => true, :referrals_required_for_loyalty_credit_for_new_deals => 3
        @deal_1 = deal_with_loyalty_program_enabled(@publisher, :price => 30)
        @consumer = Factory :consumer, :publisher => @publisher
        @p1 = purchase_that_earned_loyalty_credit(@deal_1, @consumer)
        @p2 = Factory :daily_deal_purchase
      end
      
      context "when the purchase is not eligible for a loyalty refund" do
        
        setup do
          get :consumers_admin_edit, :id => @p2.id
          assert_response :success
        end
        
        should "not show the loyalty refund related button or form field" do
          assert_select "div.loyalty-refund", false
        end
        
      end
      
      context "when the purchase is eligible for a loyalty refund" do
        
        context "when the transaction settled in braintree" do
          
          setup do
            Braintree::Transaction.expects(:find).returns(stub(:status => Braintree::Transaction::Status::Settled))
            get :consumers_admin_edit, :id => @p1.id
            assert_response :success            
          end
        
          should "show the form to do a loyalty refund" do
            assert_select "form#frm-loyalty-refund[method=POST]"
            assert_select "form#frm-loyalty-refund[action=#{loyalty_refund_daily_deal_purchase_path(:id => @p1.id)}]"
            assert_select "form#frm-loyalty-refund input[name=authenticity_token]"
            assert_select "input[type=submit][value='Submit $30.00 Loyalty Refund']"
          end
          
        end
        
        context "when the transaction is not yet settled in braintree" do
          
          setup do
            Braintree::Transaction.expects(:find).returns(stub(:status => Braintree::Transaction::Status::Authorized))
            get :consumers_admin_edit, :id => @p1.id
            assert_response :success            
          end
          
          should "show a notice that the purchase is eligible for a loyalty refund, but must first be settled" do
            assert_select "form#frm-loyalty-refund", false
            assert_select "p#eligible-for-refund-but-must-wait-for-settlement"
          end
          
        end
        
      end
      
      context "when the purchase has already received a loyalty refund" do
        
        setup do
          expect_braintree_full_refund(@p1)
          @p1.loyalty_refund!(@admin)
          get :consumers_admin_edit, :id => @p1.id
          assert_response :success
        end
        
        should "not show the loyalty refund button" do
          assert_select "input[type=submit][value='Submit $30.00 Loyalty Refund']", false
        end
        
        should "show the amount of the loyalty refund" do
          assert_select "input[name='daily_deal_purchase[loyalty_refund_amount]'][value='30.00']"
        end
        
      end
      
    end
    
    context "POST to :loyalty_refund as an admin" do
      
      setup do
        @admin = Factory :admin
        login_as(@admin)
      end
      
      context "with a purchase that is eligible for a loyalty refund" do
        
        setup do
          @publisher = publisher_with_loyalty_program_enabled
          @consumer = Factory :consumer, :publisher => @publisher
          @deal = deal_with_loyalty_program_enabled(@publisher, :price => 25)
          @purchase = purchase_that_earned_loyalty_credit(@deal, @consumer)
        end
      
        should "execute a braintree refund and mark the purchase as refunded" do
          expect_braintree_full_refund(@purchase)
          post :loyalty_refund, :id => @purchase.id
          @purchase.reload
          assert @purchase.refunded?
          assert_equal 25, @purchase.loyalty_refund_amount
          assert_equal 25, @purchase.refund_amount
        end
      
        should "redirect back to consumers_admin_edit with a flash[:notice]" do
          expect_braintree_full_refund(@purchase)
          post :loyalty_refund, :id => @purchase.id
          assert_redirected_to daily_deal_purchases_consumers_admin_edit_path(@purchase.id)
          assert_equal "Loyalty refund for $25.00 was successful", flash[:notice]
        end
        
      end
      
      context "with a purchase that is not eligible for a loyalty refund" do
        
        setup do
          publisher = Factory :publisher
          deal = deal_with_loyalty_program_enabled(publisher)
          @purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal
          assert !@purchase.eligible_for_loyalty_refund?
        end
        
        should "not execute a braintree refund and raise an exception" do
          Braintree::Transaction.expects(:refund).never
          assert_raises(LoyaltyProgram::NotEligibleForRefundError) { post :loyalty_refund, :id => @purchase.id }
        end
        
      end

      context "with daily deal variations" do

        setup do
          @publisher    = Factory(:publisher, :enable_daily_deal_variations => true)
          @deal         = deal_with_loyalty_program_enabled(@publisher, :price => 25)
          @deal.update_attribute(:referrals_required_for_loyalty_credit, 2)
          
          @variation_1  = Factory(:daily_deal_variation, :daily_deal => @deal, :price => 25)
          @variation_2  = Factory(:daily_deal_variation, :daily_deal => @deal, :price => 30)

          @consumer     = Factory(:consumer, :publisher => @publisher)
          @friend_1     = Factory(:consumer, :publisher => @publisher)
          @friend_2     = Factory(:consumer, :publisher => @publisher)

        end   

        context "with a purchase that is eligible for a loyalty refund" do

          setup do
            @consumer_purchase  = Factory(:captured_daily_deal_purchase, :daily_deal => @deal, :daily_deal_variation => @variation_1, :consumer => @consumer)
            @friend_1_purchase  = Factory(:captured_daily_deal_purchase, :daily_deal => @deal, :daily_deal_variation => @variation_1, :consumer => @friend_1, :loyalty_program_referral_code => @consumer.referrer_code)
            @friend_2_purchase  = Factory(:captured_daily_deal_purchase, :daily_deal => @deal, :daily_deal_variation => @variation_1, :consumer => @friend_2, :loyalty_program_referral_code => @consumer.referrer_code)
          end

          should "execute a braintree refund and mark the purchase as refunded" do
            expect_braintree_full_refund(@consumer_purchase)
            post :loyalty_refund, :id => @consumer_purchase.id
            @consumer_purchase.reload
            assert @consumer_purchase.refunded?
            assert_equal 25, @consumer_purchase.loyalty_refund_amount
            assert_equal 25, @consumer_purchase.refund_amount
          end

        end

        context "with a purchase that is NOT eligible for a loyalty refund" do

          setup do
            @consumer_purchase  = Factory(:captured_daily_deal_purchase, :daily_deal => @deal, :daily_deal_variation => @variation_1, :consumer => @consumer)
            @friend_1_purchase  = Factory(:captured_daily_deal_purchase, :daily_deal => @deal, :daily_deal_variation => @variation_1, :consumer => @friend_1, :loyalty_program_referral_code => @consumer.referrer_code)
            @friend_2_purchase  = Factory(:captured_daily_deal_purchase, :daily_deal => @deal, :daily_deal_variation => @variation_2, :consumer => @friend_2, :loyalty_program_referral_code => @consumer.referrer_code)
          end

          should "raise LoyaltyProgram::NotEligibleForRefundError" do
            Braintree::Transaction.expects(:refund).never
            assert_raises(LoyaltyProgram::NotEligibleForRefundError) { post :loyalty_refund, :id => @consumer_purchase.id }
          end

        end

      end
      
    end
    
    context "POST to :loyalty_refund as a non-admin" do
      
      setup do
        @user = Factory :consumer
        login_as(@user)
        @publisher = publisher_with_loyalty_program_enabled
        @consumer = Factory :consumer, :publisher => @publisher
        @deal = deal_with_loyalty_program_enabled(@publisher, :price => 25)
        @purchase = purchase_that_earned_loyalty_credit(@deal, @consumer)
      end
      
      should "not execute a braintree refund" do
        Braintree::Transaction.expects(:refund).never
        post :loyalty_refund, :id => @purchase.id
      end
      
      should "redirect to the login page" do
        post :loyalty_refund, :id => @purchase.id
        assert_redirected_to new_session_url
      end
      
    end
    
    context "GET to :thank_you" do
      
      setup do
        @purchase = Factory :daily_deal_purchase
      end
    
      context "when the deal has the loyalty program enabled" do
        
        should "show the loyalty program affiliate link for this deal" do
          @purchase.daily_deal.update_attributes :enable_loyalty_program => true,
                                                 :referrals_required_for_loyalty_credit => 2
          set_purchase_session @purchase
          get :thank_you, :id => @purchase.to_param
          assert_response :success
          assert_match %r{#{Regexp.escape(loyalty_program_url(@purchase.daily_deal, @purchase.consumer))}},
                       @response.body
        end
        
      end
      
      context "when the deal does not have the loyalty program enabled" do
        
        should "not show the loyalty program affiliate link for this deal" do
          @purchase.daily_deal.update_attribute :enable_loyalty_program, false
          set_purchase_session @purchase
          get :thank_you, :id => @purchase.to_param
          assert_response :success
          assert_no_match %r{#{Regexp.escape(loyalty_program_url(@purchase.daily_deal, @purchase.consumer))}},
                          @response.body        
        end
        
      end
      
    end
    
    
    
  end
  
end
