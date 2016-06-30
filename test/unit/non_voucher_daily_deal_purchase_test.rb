require File.dirname(__FILE__) + "/../test_helper"

class NonVoucherDailyDealPurchaseTest < ActiveSupport::TestCase

  context "purchasing a non_voucher_deal DailyDeal" do
    setup do
      @daily_deal = Factory(:non_voucher_daily_deal)
      @daily_deal_purchase = Factory(:pending_non_voucher_daily_deal_purchase, :daily_deal => @daily_deal)
    end

    should "not send certificates when captured" do
      @daily_deal_purchase.expects(:send_certificates).never
      assert_equal "pending", @daily_deal_purchase.payment_status
      braintree_transaction = braintree_sale_transaction(@daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
      @daily_deal_purchase.handle_braintree_sale! braintree_transaction
      assert_equal "captured", @daily_deal_purchase.payment_status
    end

    should "not send certificates when authorized" do
      @daily_deal_purchase.expects(:send_certificates).never
      assert_equal "pending", @daily_deal_purchase.payment_status
      braintree_transaction = braintree_sale_transaction(@daily_deal_purchase, :status => Braintree::Transaction::Status::Authorized)
      @daily_deal_purchase.handle_braintree_sale! braintree_transaction
      assert_equal "authorized", @daily_deal_purchase.payment_status
    end

  end

end
