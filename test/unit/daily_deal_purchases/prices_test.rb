# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchase::PricesTest < ActiveSupport::TestCase
  include DailyDealPurchasesTestHelper

  context "actual purchase price" do

    setup do
      @publisher = Factory :publisher
      @advertiser = Factory :advertiser, :publisher => @publisher
      @daily_deal = Factory :daily_deal, :advertiser => @advertiser, :price => 10, :value => 30
    end

    context "when daily deal purchase is saved" do

      should "update the actual purchase price when it is blank" do
        ddp = Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 5)
        assert_nil ddp.actual_purchase_price
        ddp.save!
        assert_equal 50, ddp.actual_purchase_price
      end

      should "update the actual purchase price if present, but the purchase is not executed" do
        ddp = Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 5)
        ddp.actual_purchase_price = 42
        assert !ddp.executed?
        ddp.save!
        assert_equal 50, ddp.actual_purchase_price
      end

      should "not update the actual purchase price if it is already present and the purchase is executed" do
        ddp = Factory :captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 5
        assert ddp.executed?
        ddp.actual_purchase_price = 42
        ddp.save!
        assert_equal 42, ddp.actual_purchase_price
      end

      context "with no discount or credit applied" do

        setup do
          @daily_deal_purchase = Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 3, :credit_used => 0, :discount_id => nil)
        end

        should "be automatically set to quantity * price" do
          assert_nil @daily_deal_purchase.actual_purchase_price
          @daily_deal_purchase.save!
          assert_equal 30, @daily_deal_purchase.actual_purchase_price
        end

      end

      context "with a discount" do

        setup do
          discount = Factory :discount, :publisher => @publisher, :amount => 3
          @daily_deal_purchase = Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 3, :credit_used => 0, :discount_id => discount.id)
        end

        should "be set to (quantity * price) - discount amount" do
          assert_nil @daily_deal_purchase.actual_purchase_price
          @daily_deal_purchase.save!
          assert_equal 27, @daily_deal_purchase.actual_purchase_price
        end

      end

      context "with a credit applied" do

        setup do
          @daily_deal_purchase = Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 3, :credit_used => 10, :discount_id => nil)
        end

        should "be set to (quantity * price) - credit applied" do
          assert_nil @daily_deal_purchase.actual_purchase_price
          @daily_deal_purchase.save!
          assert_equal 20, @daily_deal_purchase.actual_purchase_price
        end

      end

      context "with a discount and a credit" do

        setup do
          discount = Factory :discount, :publisher => @publisher, :amount => 3
          @daily_deal_purchase = Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 3, :credit_used => 10, :discount_id => discount.id)
        end

        should "be set to (quantity * price) - credit applied - discount amount" do
          assert_nil @daily_deal_purchase.actual_purchase_price
          @daily_deal_purchase.save!
          assert_equal 17, @daily_deal_purchase.actual_purchase_price
        end

      end

      context "with a discount that is more than the gross" do

        setup do
          discount = Factory :discount, :publisher => @publisher, :amount => 20
          @daily_deal_purchase = Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1, :discount_id => discount.id)
        end

        should "set the actual price to 0" do
          assert_nil @daily_deal_purchase.actual_purchase_price
          @daily_deal_purchase.save!
          assert_equal 0, @daily_deal_purchase.actual_purchase_price
        end

      end

      context "with a credit that is more than the gross" do

        setup do
          @daily_deal_purchase = Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1, :credit_used => 20)
        end

        should "set the actual price to 0" do
          assert_nil @daily_deal_purchase.actual_purchase_price
          @daily_deal_purchase.save!
          assert_equal 0, @daily_deal_purchase.actual_purchase_price
        end

      end

      context "with a discount + credit that is more than the gross" do

        setup do
          discount = Factory :discount, :publisher => @publisher, :amount => 5
          @daily_deal_purchase = Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1, :discount_id => discount.id, :credit_used => 10)
        end

        should "set the actual price to 0" do
          assert_nil @daily_deal_purchase.actual_purchase_price
          @daily_deal_purchase.save!
          assert_equal 0, @daily_deal_purchase.actual_purchase_price
        end

      end

      context "with a voucher shipping amount present" do
        should "add the voucher shipping amount to the actual purchase price" do
          ddp = Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 5, :voucher_shipping_amount => 3.0)
          assert_nil ddp.actual_purchase_price
          ddp.save!
          assert_equal 53, ddp.actual_purchase_price
        end
      end
    end

  end

  context "gross price" do

    setup do
      @publisher = Factory :publisher
      @advertiser = Factory :advertiser, :publisher => @publisher
      @daily_deal = Factory :daily_deal, :advertiser => @advertiser, :price => 10, :value => 30
    end

    context "when daily deal purchase is saved" do

      setup do
        @daily_deal_purchase = Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1)
      end

      should "be automatically set to daily deal price x quantity if the gross price was blank" do
        assert_nil @daily_deal_purchase.gross_price
        @daily_deal_purchase.save!
        assert_equal 10, @daily_deal_purchase.gross_price
      end

      should "be automatically set to daily deal price x quantity if a gross price was present, but the purchase was not yet executed" do
        @daily_deal_purchase.gross_price = 42
        @daily_deal_purchase.save!
        assert_equal 10, @daily_deal_purchase.gross_price
      end

      should "ignore discounts and credits (these are factored into actual purchase price, not gross)" do
        discount = Factory :discount, :publisher => @publisher, :amount => 2
        @daily_deal_purchase.credit_used = 3
        @daily_deal_purchase.quantity = 5
        assert_nil @daily_deal_purchase.gross_price
        @daily_deal_purchase.save!
        assert_equal 50, @daily_deal_purchase.gross_price
      end

      should "*not* be automatically set if the gross price was present and the purchase was executed" do
        captured_ddp = Factory.build :captured_daily_deal_purchase, :gross_price => 25
        @daily_deal_purchase.save!
        assert_equal 25, captured_ddp.gross_price
      end

    end

  end

  test "total_price_without_discount" do
    daily_deal = Factory(:daily_deal, :value => 20.00, :price => 10.00)
    daily_deal_purchase = Factory.build(:authorized_daily_deal_purchase, :daily_deal => daily_deal, :quantity => 3)
    assert_equal 30.0, daily_deal_purchase.total_price_without_discount

    discount = Factory(:discount, :publisher => daily_deal.publisher, :amount => 5.00)
    daily_deal_purchase = Factory.build(:authorized_daily_deal_purchase, :daily_deal => daily_deal, :quantity => 3, :discount => discount)
    assert_equal 25.0, daily_deal_purchase.total_price
    assert_equal 30.0, daily_deal_purchase.total_price_without_discount
  end

end
