# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchase::NamedScopesTest < ActiveSupport::TestCase
  context "for_company scope" do
    setup do
      @advertiser = Factory(:advertiser)
      @daily_deal = Factory(:daily_deal_for_syndication, :advertiser => @advertiser)
      @daily_deal_purchase_1 = Factory(:pending_daily_deal_purchase, :daily_deal => @daily_deal)
      @daily_deal_purchase_2 = Factory(:authorized_daily_deal_purchase, :daily_deal => @daily_deal)
      @daily_deal_purchase_3 = Factory(:captured_daily_deal_purchase)

      @syndicated_deal_publisher = Factory(:publisher)
      @syndicated_deal = syndicate(@daily_deal, @syndicated_deal_publisher)
      @syndicated_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @syndicated_deal)
    end

    should "return all purchases for advertiser if company is nil" do
      assert_equal [@daily_deal_purchase_1, @daily_deal_purchase_2, @syndicated_deal_purchase].map(&:id).sort,
                    @advertiser.daily_deal_purchases.for_company(nil).map(&:id).sort
    end

    should "return purchases where company is publisher" do
      assert_equal [@daily_deal_purchase_1, @daily_deal_purchase_2].map(&:id).sort,
                    @advertiser.daily_deal_purchases.for_company(@advertiser.publisher).map(&:id).sort
    end

    should "return purchases where company is publishing group" do
      assert_equal [@daily_deal_purchase_1, @daily_deal_purchase_2].map(&:id).sort,
                    @advertiser.daily_deal_purchases.for_company(@advertiser.publisher.publishing_group).map(&:id).sort
    end

    should "return purchases where company is advertiser" do
      assert_equal [@daily_deal_purchase_1, @daily_deal_purchase_2, @syndicated_deal_purchase].map(&:id).sort,
                    @advertiser.daily_deal_purchases.for_company(@advertiser).map(&:id).sort
    end

    should "NOT return purchases for company that is other publisher" do
      assert_equal true, @advertiser.daily_deal_purchases.for_company(Factory(:publisher)).empty?
    end

    should "NOT return purchases for company that is other advertiser" do
      assert_equal  true, @advertiser.daily_deal_purchases.for_company(Factory(:advertiser)).empty?
    end

    should "NOT return purchases for company that is other publishing group" do
      assert_equal true, @advertiser.daily_deal_purchases.for_company(Factory(:publishing_group)).empty?
    end

  end

  test "in_market_scope" do
    daily_deal = daily_deal = Factory(:daily_deal)
    market_1 = Factory(:market, :publisher => daily_deal.publisher)
    market_2 = Factory(:market, :publisher => daily_deal.publisher)
    daily_deal.markets << market_1
    daily_deal.markets << market_2

    ddp_1 = Factory(:daily_deal_purchase, :daily_deal => daily_deal, :market => market_1)
    ddp_2 = Factory(:daily_deal_purchase, :daily_deal => daily_deal, :market => market_1)
    ddp_3 = Factory(:daily_deal_purchase, :daily_deal => daily_deal, :market => market_2)
    assert_equal [ddp_1, ddp_2], DailyDealPurchase.in_market(market_1)
  end

  test "not_in_market_scope" do
    DailyDealPurchase.destroy_all
    daily_deal = daily_deal = Factory(:daily_deal)
    market_1 = Factory(:market, :publisher => daily_deal.publisher)
    market_2 = Factory(:market, :publisher => daily_deal.publisher)
    daily_deal.markets << market_1
    daily_deal.markets << market_2

    ddp_1 = Factory(:daily_deal_purchase, :daily_deal => daily_deal, :market => market_1)
    ddp_2 = Factory(:daily_deal_purchase, :daily_deal => daily_deal, :market => market_1)
    ddp_3 = Factory(:daily_deal_purchase, :daily_deal => daily_deal)
    assert_equal [ddp_3], DailyDealPurchase.not_in_market
  end
end
