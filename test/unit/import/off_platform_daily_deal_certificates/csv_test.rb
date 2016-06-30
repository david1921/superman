require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Import::OffPlatformDailyDealCertificates::CSVTest
module Import
  module OffPlatformDailyDealCertificates
    class CSVTest < ActiveSupport::TestCase
      test "should import certificates from orders and deals files" do
        publisher = Factory(:publisher, :label => "wcax-vermont")
        consumer = Factory(:consumer, :publisher => publisher, :email => "ahalloc@hotmail.com")
        
        ::OffPlatformDailyDealCertificate.from_csv_file(
          File.dirname(__FILE__) + "/../../../data/wcax-gift-card-purchased.csv", 
          "wcax-vermont"
        )
        
        assert_equal 0, publisher.advertisers.count, "should create no additional advertisers"
        assert_equal 0, publisher.daily_deals.count, "should create no additional deals"
        assert_equal 0, publisher.daily_deal_purchases.count, "should create no additional purchases"
        assert_equal 8, publisher.off_platform_daily_deal_certificates.count, "off_platform_daily_deal_certificates"

        assert_equal 8, publisher.consumers.count, "consumers"
        assert_equal 0, consumer.daily_deal_purchases.count, "daily_deal_purchases"
        assert_equal 1, consumer.off_platform_daily_deal_certificates.count, "off_platform_daily_deal_certificates"
      end

      test "create certificate from single CSV row" do
        row = { 
          "InventoryID" => "192960",
          "InventoryDateCreated" => "8/17/10 8:42",
          "Status" => "Active",
          "Code" => "eHKnhr",
          "MerchantCode" => "",
          "ContestID" => "17178",
          "CardName" => "Alex Martin",
          "PurchaserFirstName" => "Alex",
          "PurchaserLastName" => "Martin",
          "PurchaserEmail" => "amartin@wcax.com",
          "BillingPostalCode" => "5495",
          "OrderDateTime" => "Aug 17 2010 12:20PM",
          "MerchantName" => "Bourne's Service Center",
          "Offer" => "35.00 State Inspection for <b>17.00</b>",
          "OrderID" => "96754",
          "OrderLineID" => "15097",
          "Denomination" => "1",
          "OrderStatus" => "PAID",
          "Quantity" => "1",
          "ProductPriceWhenPurchased" => "17",
          "ItemTotal" => "17",
          "DateRedeemable" => "N/A",
          "DateExpires" => "N/A",
          "IsRedeemed" => "FALSE",
          "MethodRedeemed" => "",
          "DateRedeemed" => ""
        }
        
        publisher = Factory(:publisher)
        certificate = OffPlatformDailyDealCertificate.from_csv(row, publisher)

        assert_equal publisher, certificate.consumer.publisher, "publisher"
        assert_equal "amartin@wcax.com", certificate.consumer.email, "consumer email"
        assert_equal "http://wcax.upickem.net/engine/PrintDeal.aspx?code=eHKnhr&orderid=96754&OrderLineID=15097&contestid=17178", certificate.download_url, "download_url"
        Time.zone = 'Eastern Time (US & Canada)'
        assert_equal_dates Time.zone.local(2010, 8, 17, 12, 20, 0), certificate.executed_at, "executed_at"
        assert_equal nil, certificate.expires_on, "expires_on"
        assert_equal "35.00 State Inspection for 17.00", certificate.line_item_name, "line_item_name"
        assert_equal "Alex Martin", certificate.redeemer_names, "redeemer_names"
        assert_equal 1, certificate.quantity_excluding_refunds, "quantity_excluding_refunds"
      end

      test "mark redeemed certs as redeemed" do
        row = { 
          "InventoryID" => "192960",
          "InventoryDateCreated" => "8/17/10 8:42",
          "Status" => "Active",
          "Code" => "eHKnhr",
          "MerchantCode" => "",
          "ContestID" => "17178",
          "CardName" => "Alex Martin",
          "PurchaserFirstName" => "Alex",
          "PurchaserLastName" => "Martin",
          "PurchaserEmail" => "amartin@wcax.com",
          "BillingPostalCode" => "5495",
          "OrderDateTime" => "Aug 17 2010 12:20PM",
          "MerchantName" => "Bourne's Service Center",
          "Offer" => "35.00 State Inspection for <b>17.00</b>",
          "OrderID" => "96754",
          "OrderLineID" => "15097",
          "Denomination" => "1",
          "OrderStatus" => "PAID",
          "Quantity" => "1",
          "ProductPriceWhenPurchased" => "17",
          "ItemTotal" => "17",
          "DateRedeemable" => "N/A",
          "DateExpires" => "N/A",
          "IsRedeemed" => "True",
          "MethodRedeemed" => "on the My Deals Page",
          "DateRedeemed" => "Mar 16 2011 10:20AM"
        }
        
        publisher = Factory(:publisher)
        certificate = OffPlatformDailyDealCertificate.from_csv(row, publisher)

        Time.zone = 'Eastern Time (US & Canada)'
        assert_equal_dates Time.zone.local(2011, 3, 16, 10, 20, 0), certificate.redeemed_at, "redeemed_at"
        assert_equal true, certificate.redeemed?, "redeemed?"
      end
    end
  end
end
