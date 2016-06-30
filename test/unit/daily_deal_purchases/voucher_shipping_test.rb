# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchase::VoucherShippingTest < ActiveSupport::TestCase
  include DailyDealPurchasesTestHelper

  context "for publishers that allow voucher shipping" do
    setup do
      @publisher = Factory(:publisher, :allow_voucher_shipping => true)
      @deal = Factory(:daily_deal, :publisher => @publisher)
      assert_equal @deal.publisher, @publisher
      @mailing_address = Factory(:address)
    end

    context "purchases having their attributes set with a fulfillment method of 'ship'" do
      setup do
        @ddp = Factory(:daily_deal_purchase,
                      :daily_deal => @deal,
                      :mailing_address => @mailing_address,
                      :voucher_shipping_amount => 3.0)
        @ddp.set_attributes_if_pending(:fulfillment_method => 'ship')
      end

      should "have a voucher shipping amount set" do
        assert_equal 3.0, @ddp.voucher_shipping_amount
      end

      should "have the voucher shipping amount unset when edited to have fulfillment method of 'email'" do
        @ddp.set_attributes_if_pending(:fulfillment_method => 'email')
        assert_equal nil, @ddp.voucher_shipping_amount
      end
    end

    context "daily deal certificates for purchases with fulfillment method of 'ship'" do
      setup do
        @ddp = Factory(:daily_deal_purchase,
                       :daily_deal => @deal,
                       :mailing_address => @mailing_address,
                       :quantity => 2,
                       :voucher_shipping_amount => 3.0)
        @ddp.set_attributes_if_pending(:fulfillment_method => 'ship')
      end

      should "NOT have adjusted actual_purchase_price on first certificate" do
        # We use to adjust the first certificate actual purchase price with the voucher shipping
        # amount before we rolled the voucher shipping amount into the daily deal purchase
        # actual purchase price.
        @ddp.create_certificates!
        assert_equal 2, @ddp.reload.daily_deal_certificates.count
        ddc1 = @ddp.daily_deal_certificates.first
        ddc2 = @ddp.daily_deal_certificates.last
        amount1 = @ddp.daily_deal.price
        amount2 = @ddp.daily_deal.price + @ddp.voucher_shipping_amount
        assert_equal amount1, ddc1.actual_purchase_price
        assert_equal amount2, ddc2.actual_purchase_price
        assert_equal @ddp.actual_purchase_price, ddc1.actual_purchase_price + ddc2.actual_purchase_price
      end
    end

    context "purchases created with a fulfillment method of 'email'" do
      setup do
        @ddp = Factory(:daily_deal_purchase,
                      :daily_deal => @deal,
                      :mailing_address => @mailing_address)
        @ddp.set_attributes_if_pending(:fulfillment_method => 'email')
      end

      should "have a voucher shipping amount unset" do
        assert_equal nil, @ddp.voucher_shipping_amount
      end

      should "have the voucher shipping amount set when edited to have fulfillment method of 'ship'" do
        @ddp.set_attributes_if_pending(:fulfillment_method => 'ship')
        assert_equal 3.0, @ddp.voucher_shipping_amount
      end
    end
  end

  context "for publishers that do not allow voucher shipping" do
    setup do
      @publisher = Factory(:publisher, :allow_voucher_shipping => false)
      @deal = Factory(:daily_deal, :publisher => @publisher)
      assert_equal @deal.publisher, @publisher
      @mailing_address = Factory(:address)
    end

    context "purchases created with a fulfillment method of 'ship'" do
      setup do
        @ddp = Factory(:daily_deal_purchase,
                      :daily_deal => @deal,
                      :mailing_address => @mailing_address)
        @ddp.set_attributes_if_pending(:fulfillment_method => 'ship')
      end
      
      should "not have a voucher shipping amount set" do
        assert_equal nil, @ddp.voucher_shipping_amount
      end
    end
  end

end
