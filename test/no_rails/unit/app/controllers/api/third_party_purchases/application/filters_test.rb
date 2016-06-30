require File.dirname(__FILE__) + '/../../../../controllers_helper'

# hydra class Api::ThirdPartyPurchases::Application::FiltersTest

module Api::ThirdPartyPurchases::Application
  class FiltersTest < Test::Unit::TestCase

    def setup
      @obj = Object.new.extend(Api::ThirdPartyPurchases::Application::Filters)
    end

    context "#set_xml_format" do
      should "set the request format to xml" do
        req = mock('request')
        req.expects(:format=).with(:xml)
        @obj.expects(:request).returns(req)
        @obj.set_xml_format
      end
    end
  end
end