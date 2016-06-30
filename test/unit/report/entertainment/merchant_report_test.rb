require File.dirname(__FILE__) + "/../../../test_helper"
require File.dirname(__FILE__) + '/../entertainment_setup'

class MerchantReportTest < ActiveSupport::TestCase
  
  include Report::EntertainmentSetup
       
  setup :entertainment_setup
  
  test "MERCHANT_ID" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal "DET1", report.value("MERCHANT_ID", @detroit_deal)
  end
   
  test "MARKET" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal "Detroit", report.value("MARKET", @detroit_deal)
    assert_equal "Dallas", report.value("MARKET", @dallas_deal)
  end
  
  test "DBA_NAME" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal @detroit_advertiser.name, report.value("DBA_NAME", @detroit_deal)
  end

  test "CONTACT_NAME" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal "Det Contact", report.value("CONTACT_NAME", @detroit_deal)
  end

  test "CONTACT_PHONE" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal "", report.value("CONTACT_PHONE", @detroit_deal)
  end

  test "CONTACT_EMAIL" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal "", report.value("CONTACT_EMAIL", @detroit_deal)
  end
                                                
  test "REP_ID" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal "Det Rep", report.value("REP_ID", @detroit_deal)
  end
  
  test "BANK_ROUTING_NUMBER" do
    report = Report::Entertainment::MerchantReport.new
    # encrypted and blank for now
    assert_equal "", report.value("BANK_ROUTING_NUMBER", @detroit_deal)
  end

  test "BANK_ACCOUNT_NUMBER" do
    report = Report::Entertainment::MerchantReport.new
    # encrypted and blank for now
    assert_equal "", report.value("BANK_ACCOUNT_NUMBER", @detroit_deal)
  end

  test "BANK_NAME" do
    report = Report::Entertainment::MerchantReport.new
    @detroit_deal.advertiser.bank_name = "US Bank"
    assert_equal "US Bank", report.value("BANK_NAME", @detroit_deal)
  end

  test "BANK_ACCOUNT_OWNER_NAME" do
    report = Report::Entertainment::MerchantReport.new
    @detroit_deal.advertiser.name_on_bank_account = "Mr. T"
    assert_equal "Mr. T", report.value("BANK_ACCOUNT_OWNER_NAME", @detroit_deal)
  end 
  
  test "PREFERRED_PAYMENT_METHOD" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal "ACH", report.value("PREFERRED_PAYMENT_METHOD", @detroit_deal)
  end 
  
  test "FEDERAL_TAX_ID" do
    report = Report::Entertainment::MerchantReport.new
    # encrypted and blank for now
    assert_equal "", report.value("FEDERAL_TAX_ID", @detroit_deal)
  end 

  test "OFFER_ID" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal @detroit_deal.id, report.value("OFFER_ID", @detroit_deal)
  end 

  test "OFFER_DESCIPTION" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal @detroit_deal.value_proposition, report.value("OFFER_DESCIPTION", @detroit_deal)
  end 
  
  test "MERCHANT_REVENUE_SHARE" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal @detroit_advertiser.revenue_share_percentage, report.value("MERCHANT_REVENUE_SHARE", @detroit_deal)
  end 

  test "OFFER_PERCENT_OFF" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal @detroit_deal.savings_as_percentage, report.value("OFFER_PERCENT_OFF", @detroit_deal)
  end 

  test "OFFER_VALUE" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal @detroit_deal.value, report.value("OFFER_VALUE", @detroit_deal)
  end 

  test "OFFER_PRICE" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal @detroit_deal.price, report.value("OFFER_PRICE", @detroit_deal)
  end 

  test "OFFER_DISCOUNT" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal @detroit_deal.savings, report.value("OFFER_DISCOUNT", @detroit_deal)
  end 

  test "REDEMPTION_LOCATIONS" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal "", report.value("REDEMPTION_LOCATIONS", @detroit_deal)
  end 

  test "OFFER_COPY" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal @detroit_deal.description, report.value("OFFER_COPY", @detroit_deal)
  end 

  test "TERMS" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal @detroit_deal.terms, report.value("TERMS", @detroit_deal)
  end 

  test "MINIMUM_PURCHASE_LIMIT" do
    report = Report::Entertainment::MerchantReport.new
    @detroit_deal.min_quantity = 3
    assert_equal 3, report.value("MINIMUM_PURCHASE_LIMIT", @detroit_deal)
  end 
  
  test "MAXIMUM_PURCHASE_LIMIT" do
    report = Report::Entertainment::MerchantReport.new
    @detroit_deal.max_quantity = 75
    assert_equal 75, report.value("MAXIMUM_PURCHASE_LIMIT", @detroit_deal)
  end 

  test "GET_PURCHASE_LIMIT" do
    report = Report::Entertainment::MerchantReport.new
    @detroit_deal.max_quantity = 75
    assert_equal 75, report.value("GET_PURCHASE_LIMIT", @detroit_deal)
  end          
  
  test "TOTAL_DEALS_AVAILABLE" do
    report = Report::Entertainment::MerchantReport.new
    @detroit_deal.quantity = 400
    assert_equal 400, report.value("TOTAL_DEALS_AVAILABLE", @detroit_deal)
  end
   
  test "RUN_DATE" do
    report = Report::Entertainment::MerchantReport.new
    @detroit_deal.start_at = Time.utc(2010, 10, 22, 12)
    assert_equal "20101022", report.value("RUN_DATE", @detroit_deal)
  end
   
  test "LOGO_UPLOADED" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal @detroit_advertiser.logo.file?, report.value("LOGO_UPLOADED", @detroit_deal)
  end
   
  test "PHOTO_UPLOADED" do
    report = Report::Entertainment::MerchantReport.new
    assert_equal @detroit_deal.photo.file?, report.value("PHOTO_UPLOADED", @detroit_deal)
  end

  test "MERCHANT_NAME" do
    report = Report::Entertainment::MerchantReport.new
    @detroit_deal.advertiser.merchant_name = "Sam's Ho Hos"
    assert_equal "Sam's Ho Hos", report.value("MERCHANT_NAME", @detroit_deal)
  end

  test "CHECK_PAYABLE_TO" do
    report = Report::Entertainment::MerchantReport.new
    @detroit_deal.advertiser.check_payable_to = "Sam's Ho Hos, LLC"
    assert_equal "Sam's Ho Hos, LLC", report.value("CHECK_PAYABLE_TO", @detroit_deal)
  end

  test "check mailing address fields" do
    report = Report::Entertainment::MerchantReport.new
    @detroit_deal.advertiser.check_mailing_address_line_1 = "3440 SE Sherman St"
    @detroit_deal.advertiser.check_mailing_address_line_2 = "Suite 400"
    @detroit_deal.advertiser.check_mailing_address_city = "Portland"
    @detroit_deal.advertiser.check_mailing_address_state = "OR"
    @detroit_deal.advertiser.check_mailing_address_zip = "97214"
    assert_equal "3440 SE Sherman St", report.value("CHECK_MAILING_ADDRESS_LINE_1", @detroit_deal)
    assert_equal "Suite 400", report.value("CHECK_MAILING_ADDRESS_LINE_2", @detroit_deal)
    assert_equal "Portland", report.value("CHECK_MAILING_ADDRESS_CITY", @detroit_deal)
    assert_equal "OR", report.value("CHECK_MAILING_ADDRESS_STATE", @detroit_deal)
    assert_equal "97214", report.value("CHECK_MAILING_ADDRESS_ZIP", @detroit_deal)
  end
end
