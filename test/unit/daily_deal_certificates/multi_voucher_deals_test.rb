require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDealCertificates::MultiVoucherDealsTest

module DailyDealCertificates
  
  class MultiVoucherDealsTest < ActiveSupport::TestCase
    
    context "DailyDealCertificate#line_item_name" do
      
      should "display the deal value when DailyDeal#certificates_to_generate_per_unit_quantity is 1" do
        deal = Factory :daily_deal, :certificates_to_generate_per_unit_quantity => 1, :price => 10, :value => 20
        purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal, :quantity => 1
        assert_equal 1, purchase.daily_deal_certificates.size
        assert purchase.daily_deal_certificates.first.line_item_name.starts_with?("$20.00")
      end
      
      should "display the deal value divided by DailyDeal#certificates_to_generate_per_unit_quantity " +
             "when the latter is greater than 1" do
        deal = Factory :daily_deal, :certificates_to_generate_per_unit_quantity => 2, :price => 10, :value => 20
        purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal, :quantity => 1
        assert_equal 2, purchase.daily_deal_certificates.size
        assert purchase.daily_deal_certificates.first.line_item_name.starts_with?("$10.00")
      end
      
      should "display the custom voucher headline when present" do
        deal = Factory :daily_deal, :certificates_to_generate_per_unit_quantity => 2, :price => 10, :value => 20, :voucher_headline => "my custom headline"
        deal.publisher.update_attributes! :enable_daily_deal_voucher_headline => true
        purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal, :quantity => 1
        assert_equal 2, purchase.daily_deal_certificates.size
        assert_equal "my custom headline", purchase.daily_deal_certificates.first.line_item_name
      end
      
    end

    context "#value" do

      context "with no daily deal variations" do

        should "return the daily deal purchase value with a certificates_to_generate_per_unit_quantity of 1" do
          deal = Factory :daily_deal, :certificates_to_generate_per_unit_quantity => 1, :price => 10, :value => 20
          purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal, :quantity => 1
          assert_equal 1, purchase.daily_deal_certificates.size
          assert_equal 20.0, purchase.daily_deal_certificates.first.value.to_f
        end

        should "return the daily deal purchase value / 2 with a certificates_to_generate_per_unit_quanity of 2" do
          deal = Factory :daily_deal, :certificates_to_generate_per_unit_quantity => 2, :price => 10, :value => 20
          purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal, :quantity => 1
          assert_equal 2, purchase.daily_deal_certificates.size
          assert_equal 10.0, purchase.daily_deal_certificates.first.value.to_f
        end

      end

      context "with daily deal variations" do

        should "return the daily deal purchase value even if the certificates_to_generate_per_unit_quantity for the deal is 2" do
          deal = Factory :daily_deal, :certificates_to_generate_per_unit_quantity => 2, :price => 10, :value => 20
          deal.publisher.update_attribute(:enable_daily_deal_variations, true)
          variation = Factory(:daily_deal_variation, :daily_deal => deal, :value => 20, :price => 10)
          purchase  = Factory(:captured_daily_deal_purchase, :daily_deal => deal, :daily_deal_variation => variation, :quantity => 1)
          assert_equal 1, purchase.daily_deal_certificates.size
          assert_equal 20.0, purchase.daily_deal_certificates.first.value.to_f
        end
      end

    end
    
  end
  
end
