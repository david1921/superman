require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Reports::Publishers::NavigationTest

module Reports
  module Publishers
    class NavigationTest < ActionController::TestCase
      tests Reports::PublishersController

      test "link to advertiser purchased daily deals by market when markets present" do
        date_begin = (Time.zone.now - 2.days).to_formatted_s(:db_date)
        date_end = (Time.zone.now + 2.days).to_formatted_s(:db_date)
        daily_deal = Factory(:daily_deal)
        market = Factory(:market, :publisher => daily_deal.publisher)
        daily_deal.markets << market
        daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :market => market)

        login_as Factory(:admin)
        get(:purchased_daily_deals,
            :format => "xml",
            :id => daily_deal.publisher.to_param,
            :market_id => market.to_param,
            :dates_begin => date_begin,
            :dates_end => date_end
        )
        assert_response :success
        assert_select "daily_deals daily_deal##{daily_deal.listing}" do
          assert_select "advertiser_href", "/reports/advertisers/#{daily_deal.advertiser.id}/markets/#{market.id}/purchased_daily_deals?dates_begin=#{date_begin}&amp;amp;dates_end=#{date_end}"
        end
      end

      test "link to all advertiser purchased daily deals when no markets present" do
        date_begin = (Time.zone.now - 2.days).to_formatted_s(:db_date)
        date_end = (Time.zone.now + 2.days).to_formatted_s(:db_date)
        daily_deal = Factory(:daily_deal)
        market = Factory(:market, :publisher => daily_deal.publisher)

        daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal)
        login_as Factory(:admin)
        get(:purchased_daily_deals,
            :format => "xml",
            :id => daily_deal.publisher.to_param,
            :dates_begin => date_begin,
            :dates_end => date_end
        )
        assert_response :success
        assert_select "daily_deals daily_deal##{daily_deal.listing}" do
          assert_select "advertiser_href", "/reports/advertisers/#{daily_deal.advertiser.id}/purchased_daily_deals?dates_begin=#{date_begin}&amp;amp;dates_end=#{date_end}"
        end
      end

      context "reports navigation" do
        setup do
          @publisher = Factory(:publisher, :allow_daily_deals => true)
          @advertiser = Factory(:advertiser, :publisher_id => @publisher.id)
          @store = Factory(:store, :advertiser_id => @advertiser.id)
          @market = Factory(:market, :publisher_id => @publisher.id)
        end

        context "with market in the params" do
          should "maintain the market param all active links to reports" do
            login_as :aaron
            get  :purchased_daily_deals, :id => @publisher.to_param, :market_id => @market.to_param, :dates_begin => 1.week.ago, :dates_end => 1.week.from_now
            assert_select "#summary_links" do
              assert_select "a" do |elements|
                elements.each do |element|
                  assert element.attributes['href'].include?("market_id=#{@market.id}")
                end
              end
            end
            get  :refunded_daily_deals, :id => @publisher.to_param, :market_id => @market.to_param, :dates_begin => 1.week.ago, :dates_end => 1.week.from_now
            assert_select "#summary_links" do
              assert_select "a" do |elements|
                elements.each do |element|
                  assert element.attributes['href'].include?("market_id=#{@market.id}")
                end
              end
            end
          end
        end
      end

    end
  end
end

