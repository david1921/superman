require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ThirdPartyDealsApi::DailyDealTest

module ThirdPartyDealsApi

  class DailyDealTest < ActiveSupport::TestCase

    context "a daily deal that is also being sold via a third party" do

      setup do
        @daily_deal = Factory :daily_deal
      end

      should "set #sold_out_via_third_party to true" do
        @daily_deal.sold_out_via_third_party = true
        assert @daily_deal.sold_out_via_third_party?
      end

    end

    context "a syndicated daily deal that is also being sold via a third party" do

      setup do
        @source_deal = Factory :daily_deal_for_syndication
        @syndicated_publisher = Factory :publisher
        @syndicated_deal = syndicate @source_deal, @syndicated_publisher
      end

      should "require its #sold_out_via_third_party be nil" do
        assert @syndicated_deal.valid?
        @syndicated_deal.sold_out_via_third_party = true
        assert @syndicated_deal.invalid?
        assert_equal "Sold out via third party must be nil (this value can only be set on the syndication source deal)", @syndicated_deal.errors.on(:sold_out_via_third_party)
      end

      should "be able to set its source deal's #sold_out_via_third_party value to a boolean" do
        assert @syndicated_deal.source.valid?
        @syndicated_deal.source.sold_out_via_third_party = true
        assert @syndicated_deal.source.valid?
      end

      should "return the value of its syndication source's #sold_out_via_third_party flag" do
        assert !@source_deal.sold_out_via_third_party?
        assert !@syndicated_deal.sold_out_via_third_party?

        @source_deal.update_attributes :sold_out_via_third_party => true
        @syndicated_deal.reload
        assert @source_deal.sold_out_via_third_party?
        assert @syndicated_deal.sold_out_via_third_party?
      end

      context "when it sells out via that third party" do

        setup do
          @syndicated_deal.sold_out_via_third_party!
        end

        should "cause #sold_out? to return true" do
          assert @syndicated_deal.sold_out?
          assert @syndicated_deal.source.sold_out?
        end

      end

    end

    context "a syndicated daily deal that was imported from the third party deals api" do

      setup do
        @source_deal = Factory :daily_deal_for_syndication
        @source_publisher = @source_deal.publisher
        @syndicated_publisher = Factory :publisher
        @syndicated_deal = syndicate(@source_deal, @syndicated_publisher)
      end

      context "#using_third_party_serial_numbers?" do

        should "return true when the source deal publisher has a voucher_serial_numbers_url present" do
          assert !@syndicated_deal.using_third_party_serial_numbers?
          Factory :third_party_deals_api_config,
                  :voucher_serial_numbers_url => "https://test.url/serial_numbers",
                  :publisher => @source_publisher
          @syndicated_deal.reload
          assert @syndicated_deal.using_third_party_serial_numbers?
        end

        should "return false when the source deal publisher has a blank voucher_serial_numbers_url" do
          assert @source_publisher.voucher_serial_numbers_url.blank?
          assert !@syndicated_deal.using_third_party_serial_numbers?
        end

      end

      context "#voucher_status_request_url" do

        should "return the voucher status request url of the source publisher" do
          assert @syndicated_deal.voucher_status_request_url.blank?
          Factory :third_party_deals_api_config,
                  :voucher_status_request_url => "https://test.url/voucher_status",
                  :publisher => @source_publisher
          @syndicated_deal.reload
          assert_equal "https://test.url/voucher_status", @syndicated_deal.voucher_status_request_url
        end

      end

      context "#voucher_status_change_url" do

        should "return the voucher status change url of the source publisher" do
          assert @syndicated_deal.voucher_status_request_url.blank?
          Factory :third_party_deals_api_config,
                  :voucher_status_change_url => "https://test.url/voucher_status_change",
                  :publisher => @source_publisher
          @syndicated_deal.reload
          assert_equal "https://test.url/voucher_status_change", @syndicated_deal.voucher_status_change_url
        end

      end

    end

    context "#publisher_for_third_party_api_calls" do

      setup do
        @daily_deal = Factory :daily_deal_for_syndication
      end

      should "return the deal publisher for a regular deal" do
        assert_equal @daily_deal.publisher, @daily_deal.publisher_for_third_party_api_calls
      end

      should "return the source publisher for a syndicated deal" do
        syndicated_deal = syndicate(@daily_deal, Factory(:publisher))
        assert_equal syndicated_deal.source.publisher, @daily_deal.publisher_for_third_party_api_calls
      end

    end

  end

end
