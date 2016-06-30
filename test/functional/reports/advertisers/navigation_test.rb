require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Reports::Advertisers::NavigationTest

module Reports
  module Advertisers
    class NavigationTest < ActionController::TestCase
      tests Reports::AdvertisersController

      context "reports navigation" do
        setup do
          @publisher = Factory(:publisher, :allow_daily_deals => true)
          @advertiser = Factory(:advertiser, :publisher_id => @publisher.id)
          @store = Factory(:store, :advertiser_id => @advertiser.id)
          @market = Factory(:market, :publisher_id => @publisher.id, :name => "Baltimore")
          @market2 = Factory(:market, :publisher_id => @publisher.id, :name => "New Baltimore")
          login_as :aaron
        end

        context "market navigation" do
          should "display for advertisers with deals in markets" do
            dd = Factory(:side_daily_deal, :advertiser_id => @advertiser.id)
            dd2 = Factory(:side_daily_deal, :advertiser_id => @advertiser.id)
            dd.markets << @market
            dd2.markets << @market2
            get  :purchased_daily_deals, :id => @advertiser.to_param, :dates_begin => 1.week.ago, :dates_end => 1.week.from_now
            assert_select "#market_navigation", :count => 1 do
              assert_select "a", :count => 2
            end
          end

          should "not display for advertisers without deals in markets" do
            get  :purchased_daily_deals, :id => @advertiser.to_param, :dates_begin => 1.week.ago, :dates_end => 1.week.from_now
            assert_select "#market_navigation", :count => 0
          end
        end

        context "without market in the params" do
          should "not include the market param in the link to the refunded to the daily deal reports" do
            get  :purchased_daily_deals, :id => @advertiser.to_param, :dates_begin => 1.week.ago, :dates_end => 1.week.from_now
            assert_response :success
            assert_select "#summary_links" do
              assert_select "a[href*='#{refunded_daily_deals_reports_advertiser_path(:id => @advertiser.id)}']", :count => 1
            end
          end

          should "not include the market param in the link to the purchased daily deal reports" do
            get  :refunded_daily_deals, :id => @advertiser.to_param, :dates_begin => 1.week.ago, :dates_end => 1.week.from_now
            assert_response :success
            assert_select "#summary_links" do |element|
              assert_select "a[href*='#{purchased_daily_deals_reports_advertiser_path(:id => @advertiser.id)}']", :count => 1
            end
          end
        end

        context "with market in the params" do
          should "include the market param in the link to the refunded to the daily deal reports" do
            get  :purchased_daily_deals, :id => @advertiser.to_param, :market_id => @market.to_param, :dates_begin => 1.week.ago, :dates_end => 1.week.from_now
            assert_response :success
            assert_select "#summary_links" do |element|
              assert_select "a[href*='#{market_refunded_daily_deals_reports_advertiser_path(:id => @advertiser.id, :market_id => @market.id)}']", :count => 1
            end
          end

          should "include the market param in the link to the purchased daily deal reports" do
            get  :refunded_daily_deals, :id => @advertiser.to_param, :market_id => @market.to_param, :dates_begin => 1.week.ago, :dates_end => 1.week.from_now
            assert_response :success
            assert_select "#summary_links" do |element|
              assert_select "a[href*='#{market_purchased_daily_deals_reports_advertiser_path(:id => @advertiser.id, :market_id => @market.id)}']", :count => 1
            end
          end

          should "maintain the market param in links to non-market reports" do
            get  :refunded_daily_deals, :id => @advertiser.to_param, :market_id => @market.to_param, :dates_begin => 1.week.ago, :dates_end => 1.week.from_now
            assert_select "#summary_links" do |element|
              assert_select "a[href*='market_id=#{@market.id}']", :count => 3
            end
          end
        end
      end

    end
  end
end

