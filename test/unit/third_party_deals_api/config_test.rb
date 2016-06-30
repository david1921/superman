require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ThirdPartyDealsApi::ConfigTest

module ThirdPartyDealsApi
  
  class ConfigTest < ActiveSupport::TestCase
    
    context "validation" do

      setup do
        @publisher = Factory :publisher
      end
    
      should "require an api username and password, and a publisher id" do
        config = Factory.build :third_party_deals_api_config,
                               :api_username => "bob",
                               :api_password => "foobar",
                               :publisher_id => @publisher.id
        assert config.valid?
      
        config.api_username = ""
        assert config.invalid?
        config.api_username = "bob"
        assert config.valid?
      
        config.api_password = ""
        assert config.invalid?
        config.api_password = "foobar"
        assert config.valid?
      
        config.publisher_id = nil
        assert config.invalid?
        config.publisher_id = @publisher.id
        assert config.valid?
      end
      
      should "require the voucher serial numbers url to be https, if present" do
        config = Factory :third_party_deals_api_config, :voucher_serial_numbers_url => nil
        
        assert config.voucher_serial_numbers_url.blank?
        assert config.valid?
        
        config.voucher_serial_numbers_url = "http://example.com"
        assert config.invalid?
        assert_equal "Voucher serial numbers url must be https", config.errors.on(:voucher_serial_numbers_url)
        
        config.voucher_serial_numbers_url = "https://example.com"
        assert config.valid?
      end
  
    end
    
  end
  
end
