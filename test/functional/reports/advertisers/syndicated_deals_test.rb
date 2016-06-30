require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Reports::Advertisers::SyndicatedDealsTest

module Reports
  module Advertisers
    class SyndicatedDealsTest < ActionController::TestCase
      tests Reports::AdvertisersController

      context "syndicated deals" do

        setup do
          @query_start_date = 3.weeks.ago
          @query_end_date = @query_start_date + 2.weeks

          @source_deal = Factory(:daily_deal_for_syndication, :quantity => 3)

          @syndicated_deal_publisher_1 = Factory(:publisher)
          @syndicated_deal_1 = syndicate(@source_deal, @syndicated_deal_publisher_1)

          @syndicated_deal_publisher_2 = Factory(:publisher)
          @syndicated_deal_2 = syndicate(@source_deal, @syndicated_deal_publisher_2)

          @source_deal_consumer = Factory(:consumer, :first_name => "John", :last_name => "Smith", :publisher => @source_deal.publisher )
          @syndicated_deal_consumer_1 = Factory(:consumer, :first_name => "Jill", :last_name => "Smith", :publisher => @syndicated_deal_1.publisher )
          @syndicated_deal_consumer_2 = Factory(:consumer, :first_name => "Jane", :last_name => "Doe", :publisher => @syndicated_deal_2.publisher )

          @source_deal_purchase = Factory(:captured_daily_deal_purchase_no_certs, :daily_deal => @source_deal, :consumer => @source_deal_consumer, :quantity => 2, :executed_at => @query_start_date + 1.minute)
          @syndicated_deal_purchase_1 = Factory(:captured_daily_deal_purchase_no_certs, :daily_deal => @syndicated_deal_1, :consumer => @syndicated_deal_consumer_1, :executed_at => @query_start_date + 5.minutes)
          @syndicated_deal_purchase_2 = Factory(:captured_daily_deal_purchase_no_certs, :daily_deal => @syndicated_deal_2, :consumer => @syndicated_deal_consumer_2, :executed_at => @query_start_date + 1.day)
          @syndicated_deal_purchase_3 = Factory(:captured_daily_deal_purchase_no_certs, :daily_deal => @syndicated_deal_2, :consumer => @syndicated_deal_consumer_2, :executed_at => @query_start_date - 1.day)

          @source_deal_certificate = Factory :daily_deal_certificate, :serial_number => "serial0", :daily_deal_purchase => @source_deal_purchase
          @syndicated_deal_certificate_1 = Factory :daily_deal_certificate, :serial_number => "serial1", :daily_deal_purchase => @syndicated_deal_purchase_1
          @syndicated_deal_certificate_2 = Factory :daily_deal_certificate, :serial_number => "serial2", :daily_deal_purchase => @syndicated_deal_purchase_2
          @syndicated_deal_certificate_3 = Factory :daily_deal_certificate, :serial_number => "serial3", :daily_deal_purchase => @syndicated_deal_purchase_3
        end

        should "display xml for purchased source and all syndicated deals to user belonging to publisher" do
          user = Factory(:user, :company => @source_deal.publisher)
          login_as user

          get :purchased_daily_deals, {
            :id => @source_deal.advertiser.to_param,
            :dates_begin => @query_start_date.to_s, :dates_end => @query_end_date.to_s,
            :format => "xml"
          }
          assert_success_for_all_source_and_syndicated_daily_deal_purchases_as_xml
        end

        should "display csv for purchased source and all syndicated deals to user belonging to publisher" do
          login_as Factory(:user, :company => @source_deal.publisher)
          get :purchased_daily_deals, {
            :id => @source_deal.advertiser.to_param,
            :dates_begin => @query_start_date.to_s, :dates_end => @query_end_date.to_s,
            :format => "csv"
          }
          assert_success_for_all_source_and_syndicated_daily_deal_purchases_as_csv
        end

        should "display xml for purchased source and all syndicated deals to user belonging to advertiser" do
          login_as Factory(:user, :company => @source_deal.advertiser)
          get :purchased_daily_deals, {
            :id => @source_deal.advertiser.to_param,
            :dates_begin => @query_start_date.to_s, :dates_end => @query_end_date.to_s,
            :format => "xml"
          }
          assert_success_for_all_source_and_syndicated_daily_deal_purchases_as_xml
        end

        should "display csv for purchased source and all syndicated deals to user belonging to advertiser" do
          login_as Factory(:user, :company => @source_deal.advertiser)
          get :purchased_daily_deals, {
            :id => @source_deal.advertiser.to_param,
            :dates_begin => @query_start_date.to_s, :dates_end => @query_end_date.to_s,
            :format => "csv"
          }
          assert_success_for_all_source_and_syndicated_daily_deal_purchases_as_csv
        end

        should "display xml for purchased source and all syndicated deals to admin user when advertiser belongs publisher" do
          login_as Factory(:admin)
          get :purchased_daily_deals, {
            :id => @source_deal.advertiser.to_param,
            :dates_begin => @query_start_date.to_s, :dates_end => @query_end_date.to_s,
            :format => "xml"
          }
          assert_success_for_all_source_and_syndicated_daily_deal_purchases_as_xml
        end

        should "display csv for purchased source and all syndicated deals to admin user when advertiser belongs publisher" do
          login_as Factory(:admin)
          get :purchased_daily_deals, {
            :id => @source_deal.advertiser.to_param,
            :dates_begin => @query_start_date.to_s, :dates_end => @query_end_date.to_s,
            :format => "csv"
          }
          assert_success_for_all_source_and_syndicated_daily_deal_purchases_as_csv
        end

        should "ONLY display xml for purchased deal that has the same publisher as user" do
          login_as Factory(:user, :company => @syndicated_deal_2.publisher)
          get :purchased_daily_deals, {
            :publisher_id => @source_deal.advertiser.publisher.to_param, :id => @source_deal.advertiser.to_param,
            :dates_begin => @query_start_date.to_s, :dates_end => @query_end_date.to_s,
            :format => "xml"
          }
          assert_success_for_syndicated_daily_deal_purchase_as_xml
        end

        should "ONLY display csv for purchased deal that has the same publisher as user" do
          login_as Factory(:user, :company => @syndicated_deal_2.publisher)
          get :purchased_daily_deals, {
            :publisher_id => @source_deal.advertiser.publisher.to_param, :id => @source_deal.advertiser.to_param,
            :dates_begin => @query_start_date.to_s, :dates_end => @query_end_date.to_s,
            :format => "csv"
          }
          assert_success_for_syndicated_daily_deal_purchase_as_csv
        end

      end

      private

      def assert_success_for_syndicated_daily_deal_purchase_as_xml
        assert_response :success
        records = Hash.from_xml(@response.body).try(:fetch, "daily_deal_certificates")
        assert_not_nil records, "Should have a list of purchased deal certificates"
        assert_equal 1, records.size
      end

      def assert_success_for_syndicated_daily_deal_purchase_as_csv
        assert_response :success
        rows = FasterCSV.parse(@response.binary_content)
        assert_not_nil rows, "Should have a list of purchased deal certificates"
        assert_equal ["Purchaser Name",
                      #"Purchaser Email",
                      "Recipient Name",
                      "Redeemed On",
                      "Redeemed At",
                      "Serial Number",
                      "Deal",
                      "Value",
                      "Price",
                      "Purchase Price",
                      "Purchase Date"], rows[0]
        assert_equal 2, rows.size #4 with header row
      end

      def syndicate(daily_deal, syndicated_publisher)
        daily_deal.syndicated_deals.build(:publisher_id => syndicated_publisher.id)
        daily_deal.save!
        daily_deal.syndicated_deals.last
      end

      def assert_success_for_all_source_and_syndicated_daily_deal_purchases_as_xml
        assert_response :success
        records = Hash.from_xml(@response.body).try(:fetch, "daily_deal_certificates").try(:fetch, "daily_deal_certificate")
        assert_not_nil records, "Should have a list of purchased deal certificates"
        assert_equal 3, records.size
      end

      def assert_success_for_all_source_and_syndicated_daily_deal_purchases_as_csv
        assert_response :success
        rows = FasterCSV.parse(@response.binary_content)
        assert_not_nil rows, "Should have a list of purchased deal certificates"
        assert_equal ["Purchaser Name",
                      #"Purchaser Email",
                      "Recipient Name",
                      "Redeemed On",
                      "Redeemed At",
                      "Serial Number",
                      "Deal",
                      "Value",
                      "Price",
                      "Purchase Price",
                      "Purchase Date"], rows[0]
        assert_equal 4, rows.size
      end

    end
  end
end
