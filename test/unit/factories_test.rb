require File.dirname(__FILE__) + "/../test_helper"

class FactoriesTest < ActiveSupport::TestCase

  context "purchases with a payment" do
    factories = [:authorized_daily_deal_purchase, :authorized_daily_deal_paypal_purchase, :authorized_optimal_daily_deal_purchase, :captured_daily_deal_purchase_no_certs, :captured_daily_deal_purchase, :captured_optimal_daily_deal_purchase, :captured_daily_deal_purchase_with_discount, :refunded_daily_deal_purchase, :voided_braintree_daily_deal_purchase, :voided_optimal_payment_daily_deal_purchase, :voided_daily_deal_purchase, :refunded_daily_deal_purchase_no_certs, :refunded_optimal_payment_daily_deal_purchase]

    should "create only one consumer" do
      factories.each do |factory|
        assert_difference "Consumer.count" do
          Factory(factory)
        end
      end
    end

    should "create only one purchase" do
      factories.each do |factory|
        assert_difference "DailyDealPurchase.count" do
          Factory(factory)
        end
      end
    end

    should "create only one payment" do
      factories.each do |factory|
        assert_difference "DailyDealPayment.count" do
          Factory(factory)
        end
      end
    end

    should "have the correct status" do
      factories.each do |factory|
        purchase =  Factory(factory).reload
        assert_equal factory.to_s[0...factory.to_s.index('_')], purchase.payment_status, factory.inspect
        assert_not_nil purchase.executed_at, factory.inspect
      end
    end
  end

  context "purchases with certificates" do
    factories = [:captured_daily_deal_purchase, :captured_optimal_daily_deal_purchase, :captured_daily_deal_purchase_with_discount,
                 :refunded_daily_deal_purchase, :voided_daily_deal_purchase
    ]

    should "create some certificates" do
      factories.each do |factory|
        assert_difference "DailyDealCertificate.count", 1, factory.inspect do
          Factory(factory)
        end
      end
    end

    context ":pending_daily_deal_purchase" do
      should "be pending" do
        factories.each do |factory|
          purchase = Factory(:pending_daily_deal_purchase).reload
          assert purchase.pending?
        end
      end

      should "create only one customer" do
        factories.each do |factory|
          assert_difference "Consumer.count" do
            Factory(:pending_daily_deal_purchase)
          end
        end
      end

      should "not create a payment" do
        factories.each do |factory|
          assert_no_difference "DailyDealPayment.count" do
            Factory(:pending_daily_deal_purchase)
          end
        end
      end
    end
  end

end
