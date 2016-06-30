require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ThirdPartyDealsApi::DailyDealCertificateTest

module ThirdPartyDealsApi
  
  class DailyDealCertificateTest < ActiveSupport::TestCase
    
    context "third party certificate serial numbers" do
      
      setup do
        @daily_deal_purchase = Factory :captured_daily_deal_purchase_no_certs
        @daily_deal = @daily_deal_purchase.daily_deal
      end
      
      should "require that serial_number_generated_by_third_party? is true " +
             "if publisher.voucher_serial_numbers_url is present" do
        Factory :third_party_deals_api_config,
                :voucher_serial_numbers_url => "https://example.com",
                :publisher => @daily_deal.publisher
        @daily_deal_purchase.publisher.reload
      
        certificate = Factory.build :daily_deal_certificate, :daily_deal_purchase => @daily_deal_purchase
        
        assert certificate.invalid?
        assert_equal "Serial number generated by third party must be true (this publisher uses third party serial numbers)", certificate.errors.on(:serial_number_generated_by_third_party)
        certificate.serial_number_generated_by_third_party = true
        assert certificate.valid?
      end
      
      should "not be required to be unique" do
        cert_using_internal_serials = Factory :daily_deal_certificate, :serial_number => "MY-SERIAL"
        
        cert_using_third_party_serials = nil
        assert_nothing_raised do
          cert_using_third_party_serials = Factory :daily_deal_certificate_using_third_party_serial,
                                                   :serial_number => cert_using_internal_serials.serial_number
        end
        
        assert cert_using_third_party_serials.valid?
        assert cert_using_internal_serials.valid?
        assert_equal "MY-SERIAL", cert_using_third_party_serials.serial_number
        assert_equal "MY-SERIAL", cert_using_internal_serials.serial_number
        
        cert_using_internal_serials_2 = Factory.build :daily_deal_certificate, :serial_number => "MY-SERIAL"
        assert cert_using_internal_serials_2.invalid?
        assert_equal "Serial number MY-SERIAL is not unique across all certificates", cert_using_internal_serials_2.errors.on(:serial_number)
      end
            
    end
    
  end
  
end