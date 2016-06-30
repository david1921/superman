require File.dirname(__FILE__) + "/../../../../test_helper"

# hydra class ThirdPartyDealsApi::XML::SerialNumberRequestTest

module ThirdPartyDealsApi
  module XML

    class SerialNumberRequestTest < ActiveSupport::TestCase

      context "purchase has store" do
        setup do
          @store = Factory(:store, :listing => "store1_listing")
          @deal = Factory(:daily_deal, :listing => "my_listing")
          @purchase = Factory(:daily_deal_purchase, :daily_deal => @deal, :store => @store)
          @request = SerialNumberRequest.new(@purchase)
        end
        should "generate correct xml" do
          actual_result = Hash.from_xml(@request.create_serial_number_request_xml)['serial_number_request']
          assert_equal "my_listing", actual_result["listing"]
          assert_equal @purchase.uuid, actual_result["purchase_id"]
          assert_equal @purchase.consumer.name, actual_result["purchaser_name"]
          assert_equal @purchase.quantity.to_s, actual_result["quantity"]
          assert_equal 1, actual_result['recipient_names'].size
          assert_equal @purchase.consumer.name, actual_result['recipient_names']['recipient_name']
          assert_equal "store1_listing", actual_result['location']['listing']
        end
      end

      context "purchase has no store" do
        setup do
          @deal = Factory(:daily_deal, :listing => "my_listing")
          @purchase = Factory(:daily_deal_purchase, :daily_deal => @deal)
          @request = SerialNumberRequest.new(@purchase)
        end
        should "generate correct xml" do
          raw_xml = @request.create_serial_number_request_xml
          hashed_result = Hash.from_xml(raw_xml)['serial_number_request']
          assert_nil hashed_result['location']['listing']
        end
      end

    end
  end
end

