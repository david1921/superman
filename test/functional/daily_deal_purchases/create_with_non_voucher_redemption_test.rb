require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::CreateWithNonVoucherRedemptionTest < ActionController::TestCase
  tests DailyDealPurchasesController

  context "non-voucher deal purchase" do
    setup do
      @publisher = Factory(:publisher, :allow_registration_during_purchase => false)
      @daily_deal = Factory(:non_voucher_daily_deal, :publisher => @publisher)
    end

    context "given no consumer is logged in" do

      should "deny access" do
        post :create, :daily_deal_id => @daily_deal.to_param, :publisher_id => @publisher.to_param
        assert_redirected_to new_publisher_daily_deal_session_path(@publisher)
      end

    end

    context "given a consumer is logged in" do

      context "purchasing a deal for the first time" do
        setup do
          ActionMailer::Base.deliveries.clear
          @consumer = Factory(:consumer, :publisher => @publisher)
          login_as @consumer
          post :create, :daily_deal_id => @daily_deal.to_param, :publisher_id => @publisher.to_param
        end

        should "create a free purchase record" do
          assert_equal 1, @daily_deal.non_voucher_daily_deal_purchases.count
          daily_deal_purchase = @daily_deal.non_voucher_daily_deal_purchases.first
          assert_equal 0, daily_deal_purchase.actual_purchase_price
          assert_equal "captured", daily_deal_purchase.payment_status
        end

        should "set the deal_credit cookie" do
          assert_equal "applied", cookies["deal_credit"]
        end

        should "set the analytics_tag" do
          assert flash[:analytics_tag]
        end

        should "redirect to the deal redemption page" do
          daily_deal_purchase = @daily_deal.non_voucher_daily_deal_purchases.first
          assert_redirected_to non_voucher_redemption_daily_deal_purchase_url(daily_deal_purchase)
        end

        should "not send certificate email" do
          assert_equal 0, ActionMailer::Base.deliveries.size
        end
      end

      context "purchasing a deal for a second time" do
        setup do
          ActionMailer::Base.deliveries.clear
          @daily_deal_purchase = Factory(:captured_non_voucher_daily_deal_purchase, :daily_deal => @daily_deal)
          @consumer = @daily_deal_purchase.consumer
          login_as @consumer
        end

        should "not create a new purchase record" do
          assert_no_difference "@daily_deal.non_voucher_daily_deal_purchases.count" do
            post :create, :daily_deal_id => @daily_deal.to_param, :publisher_id => @publisher.to_param
          end
        end

        should "redirect to the deal redemption page for the existing page" do
          post :create, :daily_deal_id => @daily_deal.to_param, :publisher_id => @publisher.to_param
          assert_redirected_to non_voucher_redemption_daily_deal_purchase_url(@daily_deal_purchase)
        end

        should "not send certificate email" do
          post :create, :daily_deal_id => @daily_deal.to_param, :publisher_id => @publisher.to_param
          assert_equal 0, ActionMailer::Base.deliveries.size
        end
      end

    end

  end

end
 
