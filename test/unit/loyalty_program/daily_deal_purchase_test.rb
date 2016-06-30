require File.dirname(__FILE__) + "/../../test_helper"

# hydra class LoyaltyProgram::DailyDealPurchaseTest

module LoyaltyProgram
  
  class DailyDealPurchaseTest < ActiveSupport::TestCase
    
    def setup
      @admin = Factory :admin
      @publishing_group = Factory :publishing_group, :allow_single_sign_on => true, :unique_email_across_publishing_group => true
      @publisher = Factory :publisher, :enable_loyalty_program_for_new_deals => true,
                           :referrals_required_for_loyalty_credit_for_new_deals => 3,
                           :publishing_group => @publishing_group
      @other_publisher = Factory :publisher, :enable_loyalty_program_for_new_deals => true, :referrals_required_for_loyalty_credit_for_new_deals => 4
      @consumer_1 = Factory :consumer, :publisher => @publisher
      @consumer_2 = Factory :consumer, :publisher => @publisher
      @consumer_3 = Factory :consumer, :publisher => @publisher
      @consumer_4 = Factory :consumer, :publisher => @publisher
      @consumer_5 = Factory :consumer, :publisher => @publisher
      @consumer_6 = Factory :consumer, :publisher => @publisher
      @consumer_7 = Factory :consumer, :publisher => @publisher
      @consumer_8 = Factory :consumer, :publisher => @other_publisher
      @consumer_9 = Factory :consumer, :publisher => @publisher
      @consumer_10 = Factory :consumer, :publisher => @publisher

      @deal_1 = deal_with_loyalty_program_enabled(@publisher)
      @deal_2 = deal_with_loyalty_program_enabled(@publisher)
      @deal_3 = deal_with_loyalty_program_enabled(@publisher)
      @deal_4 = deal_with_loyalty_program_disabled(@publisher)
      @deal_5 = deal_with_loyalty_program_enabled(@other_publisher)
      @deal_6 = deal_with_loyalty_program_enabled(@publisher)

      @referring_consumer = Factory :consumer, :publisher => @publisher
      assert @deal_1.enable_loyalty_program? && @deal_2.enable_loyalty_program?
      assert_equal 3, @deal_1.referrals_required_for_loyalty_credit
      assert_equal 3, @deal_2.referrals_required_for_loyalty_credit
      
      @p1 = purchase_that_earned_loyalty_credit(@deal_1, @consumer_1)
      @p2 = purchase_that_earned_loyalty_credit(@deal_1, @consumer_1)
      @p3 = purchase_that_earned_loyalty_credit(@deal_3, @consumer_2)
      @p4 = purchase_with_no_loyalty_referrals(@deal_3, @consumer_1)
      @p5 = purchase_with_num_loyalty_referrals_less_than_referrals_required(@deal_3, @consumer_2)
      @p6 = pending_purchase_with_loyalty_referrals_equal_to_referrals_required(@deal_1, @consumer_3)
      @p7 = captured_purchase_with_num_referrals_equal_to_referrals_required_but_not_all_captured(@deal_1, @consumer_4)
      @p8 = purchase_that_earned_loyalty_credit_and_has_received_the_credit(@deal_1, @consumer_5)
      @p9 = purchase_that_would_earn_loyalty_credit_but_deal_has_disabled_loyalty_program(@deal_4, @consumer_1)
      @p10 = refunded_purchase_with_loyalty_referrals_equal_to_referrals_required(@deal_1, @consumer_6)
      @p11 = purchase_that_earned_the_loyalty_credit_twice(@deal_1, @consumer_7)
      @p12 = purchase_that_earned_loyalty_credit(@deal_5, @consumer_8)
      @p13 = purchase_with_required_number_of_referrals_but_all_from_same_consumer(@deal_3, @consumer_9)
      @p14 = purchase_that_earned_loyalty_credit_from_purchases_made_by_single_sign_on_users(@deal_6, @consumer_10)
    end
    
    fast_context "DailyDealPurchase#eligible_for_loyalty_program_credit, when DailyDeal#referrals_required_for_loyalty_credit is 3" do
      
      should "return each purchase that belongs to a consumer who has referred 3 or more " +
             "other purchases of that deal, from different users" do
        assert_equal [@p1.id, @p2.id, @p3.id, @p11.id, @p12.id, @p14.id], DailyDealPurchase.eligible_for_loyalty_program_credit.map(&:id)
      end
      
    end
    
    fast_context "Publisher#purchases_eligible_for_loyalty_refund" do
      
      should "return the same thing as DailyDealPurchase#eligible_for_loyalty_program_credit, but only " +
             "for purchases belonging to this publisher" do
        assert_equal [@p1.id, @p2.id, @p3.id, @p11.id, @p14.id], @publisher.purchases_eligible_for_loyalty_refund.map(&:id)
      end
      
    end
    
    fast_context "DailyDealPurchase#loyalty_refund!" do
      
      should "raise an exception if the purchase is not in captured state" do
        begin
          @p10.loyalty_refund!(@admin)
        rescue ::LoyaltyProgram::NotEligibleForRefundError => e
          assert_equal "purchase must be in state 'captured' to apply loyalty refund, but is in state 'refunded'",
                       e.message
        else
          assert false, "should have raised an exception"
        end
      end
      
      should "raise an exception if DailyDeal#enable_loyalty_program? is disabled" do
        old_loyalty_program_value = @p1.daily_deal.enable_loyalty_program
        @p1.daily_deal.enable_loyalty_program = false
        begin
          @p1.loyalty_refund!(@admin)
        rescue ::LoyaltyProgram::NotEligibleForRefundError => e
          assert_equal "cannot apply loyalty refund to this purchase. the loyalty program is disabled for this deal",
                       e.message
        else
          assert false, "should have raised an exception"
        end
        @p1.daily_deal.enable_loyalty_program = old_loyalty_program_value
      end
      
      should "raise an exception if the actual_purchase_price is less than 1 x deal price" do
        @p1.stubs(:actual_purchase_price).returns(@p1.price - 1)
        begin
          @p1.loyalty_refund!(@admin)
        rescue ::LoyaltyProgram::NotEligibleForRefundError => e
          assert_equal "actual purchase price must be >= deal price in order to apply a loyalty refund to this purchase", e.message
        else
          assert false, "should have raised an exception"
        end
      end
      
      fast_context "a captured purchase with actual_purchase_price >= 1 x deal price" do
        
        setup do
          assert @p1.captured?
          assert @p1.actual_purchase_price >= @p1.price

          expect_braintree_full_refund(@p1)
          @p1.loyalty_refund!(@admin)
        end
      
        should "set the refund_amount to the amount of 1 x the deal price" do
          assert_equal @p1.price, @p1.refund_amount
        end
      
        should "set the loyalty_refund_amount to 1 x the deal price" do
          assert_equal @p1.price, @p1.loyalty_refund_amount
        end
      
        should "not change the status of the vouchers" do
          assert_equal %w(active), @p1.daily_deal_certificates.map(&:status)
        end
        
        should "set the payment status to refunded" do
          assert_equal "refunded", @p1.payment_status
        end
        
      end
      
    end
    
    fast_context "DailyDealPurchase#with_after_refunded_callback_disabled" do
      
      should "noop the after_refunded method inside the block passed to it" do
        purchase = Factory :captured_daily_deal_purchase
        class CalledMyAfterRefunded < Exception; end
        
        def purchase.after_refunded
          raise CalledMyAfterRefunded
        end

        assert purchase.respond_to?(:after_refunded)
        assert_nothing_raised do
          purchase.with_after_refunded_callback_disabled { purchase.after_refunded }
        end
        assert purchase.respond_to?(:after_refunded)
        
        assert_raises(CalledMyAfterRefunded) { purchase.after_refunded }
      end
            
    end
  
  end  
  
end