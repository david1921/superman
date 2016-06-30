# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchase::PromotionTest < ActiveSupport::TestCase
  context "#create_promotion_discount" do
    setup do
      @purchase = Factory(:authorized_daily_deal_purchase)
    end

    context "with a promotion" do
      setup do
        @promotion = Factory(:promotion, :publishing_group => @purchase.publisher.publishing_group)
      end

      should "create a discount when status moves to captured" do
        @purchase.send(:set_payment_status!, "captured")
        discount = Discount.find_by_daily_deal_purchase_id_and_promotion_id(@purchase.id, @promotion.id)
        assert_not_nil discount
      end
    end

    context "with a non active promotion" do
      setup do
        @promotion = Factory(:promotion,
                             :publishing_group => @purchase.publisher.publishing_group,
                             :start_at => 3.days.from_now,
                             :end_at => 5.days.from_now)
      end

      should "not create a discount" do
        @purchase.send(:set_payment_status!, "captured")
        discount = Discount.find_by_daily_deal_purchase_id_and_promotion_id(@purchase.id, @promotion.id)
        assert_nil discount
      end
    end

    context "without a promotion" do
      should "not create a discount" do
        @purchase.send(:set_payment_status!, "captured")
        discount = Discount.find_by_daily_deal_purchase_id(@purchase.id)
        assert_nil discount
      end
    end

    context "with an already created discount for the promotion" do
      setup do
        @promotion = Factory(:promotion, :publishing_group => @purchase.publisher.publishing_group)
        @promotion.create_discount_for_purchase(@purchase)
      end

      should "not create a discount" do
        @purchase.send(:set_payment_status!, "captured")
        discount = Discount.find_by_daily_deal_purchase_id_and_promotion_id(@purchase.id, @promotion.id)
        assert_not_nil discount
      end
    end

    context "when an error happens" do
      setup do
        DailyDealPurchase.any_instance.stubs(:eligible_for_promotion_discount?).raises("an error")
      end

      should "send error to Exceptional and return false" do
        DailyDealPurchase.any_instance.stubs(:eligible_for_promotion_discount?).raises("an error")
        Exceptional.expects(:handle).once
        assert !@purchase.send(:create_promotion_discount)
      end

      should "not raise an error in #after_captured" do
        Consumer.any_instance.expects(:daily_deal_purchase_captured!).once
        @purchase.send(:after_captured)
      end
    end
  end

  context "purchase with a promotion discount" do
    setup do
      @purchase = Factory(:authorized_daily_deal_purchase)
      @promotion = Factory(:promotion, :publishing_group => @purchase.publisher.publishing_group)
      @deal = Factory(:side_daily_deal, :publisher => @purchase.publisher)
      @discount = @promotion.create_discount_for_purchase(@purchase)
    end

    should "apply discount to purchase and flag as used" do
      Timecop.freeze(Time.zone.now) do
        captured_purchase = Factory(:captured_daily_deal_purchase, :discount_code => @discount.code,
                                    :consumer => @purchase.consumer, :daily_deal => @deal)
        @discount.reload
        assert_equal Time.zone.now.to_i, @discount.used_at.to_i
      end
    end
  end
end
