require File.dirname(__FILE__) + "/../../../../test_helper"

# hydra class ThirdPartyDealsApi::XML::VoucherStatusRequestTest

module ThirdPartyDealsApi
  module XML

    class VoucherStatusRequestTest < ActiveSupport::TestCase

      context "voucher change notification" do

        context "creating voucher change notification" do
          setup do
            @daily_deal = Factory(:daily_deal, :listing => "special_123")
            @daily_deal_purchase = Factory(:captured_daily_deal_purchase,
                                           :daily_deal => @daily_deal,
                                           :quantity => 3)

            @actual_result = Nokogiri::XML(VoucherStatusChangeNotification.new(@daily_deal_purchase).create_voucher_status_change_notification)
            assert_equal "http://analoganalytics.com/api/third_party_deals/purchases", @actual_result.root.namespace.href
            @actual_result.remove_namespaces!
            @top_node = @actual_result.xpath("//voucher_status_change")
          end

          should "result in top level node with correct attributes" do
            assert_not_nil @top_node
            assert_equal "special_123", @top_node.attribute("listing").value
            assert_equal @daily_deal_purchase.uuid, @top_node.attribute("purchase_id").value
          end

          should "result in three status elements with the correct serial number and status" do
            assert_equal 3, @top_node.children.size
            @daily_deal_purchase.daily_deal_certificates.each do |cert|
              assert_equal cert.status, @top_node.css("status[@serial_number='#{cert.serial_number}']").text
            end
          end
        end

        context "only one certificate and no listing" do
          setup do
            @daily_deal = Factory(:daily_deal)
            @daily_deal.listing = nil
            @daily_deal.save!
            @daily_deal_purchase = Factory(:captured_daily_deal_purchase,
                                           :daily_deal => @daily_deal,
                                           :quantity => 1)
            @actual_result = Nokogiri::XML(VoucherStatusChangeNotification.new(@daily_deal_purchase).create_voucher_status_change_notification).remove_namespaces!
            @top_node = @actual_result.xpath("//voucher_status_change")
          end
          should "not have listing in top level element" do
            assert_not_nil @top_node
            assert_equal "", @top_node.attribute("listing").value
            assert_equal @daily_deal_purchase.uuid, @top_node.attribute("purchase_id").value
          end
          should "result in one status element element" do
            assert_equal 1, @top_node.children.size
            cert = @daily_deal_purchase.daily_deal_certificates.first
            assert_equal cert.status, @top_node.css("status[@serial_number='#{cert.serial_number}']").text
          end

        end

      end
      
      context "voided purchases" do
        
        setup do
          @voided_purchase = Factory :voided_daily_deal_purchase
          @voucher_status_change_xml = VoucherStatusChangeNotification.new(@voided_purchase).create_voucher_status_change_notification
          @parsed_change_notification = Nokogiri::XML(@voucher_status_change_xml)
        end
        
        should "translate the voided status to refunded, because Doubletake doesn't have a voided status" do
          assert_equal 1, @parsed_change_notification.css("status").length
          assert_equal "refunded", @parsed_change_notification.css("status").text
        end
        
      end

    end
  end
end
