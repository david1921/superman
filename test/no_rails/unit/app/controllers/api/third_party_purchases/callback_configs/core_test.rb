require File.dirname(__FILE__) + '/../../../../controllers_helper'

# hydra class Api::ThirdPartyPurchases::CallbackConfigs::CoreTest

module Api::ThirdPartyPurchases::CallbackConfigs
  class CoreTest < Test::Unit::TestCase

    def setup
      @obj = Object.new.extend(Api::ThirdPartyPurchases::CallbackConfigs::Core)
    end

    context "#attributes_from_callback_xml" do
      should "return a hash with data from the xml" do
        xml = File.read(Rails.root + "/test/data/api/third_party_purchases/callback_config.xml")
        data = Hash.from_xml(xml)['callback_config']
        expected = {
            :callback_url => data['url'],
            :callback_username => data['username'],
            :callback_password => data['password']
        }

        assert_equal expected, @obj.attributes_from_callback_xml(xml)
      end
    end
  end
end