require File.dirname(__FILE__) + "/../../../../models_helper"

# hydra class Api::ThirdPartyPurchases::SerialNumberResponses::CoreTest

module Api::ThirdPartyPurchases::SerialNumberResponses
  class CoreTest < Test::Unit::TestCase
    def setup
      @response = Object.new.extend(Core)
    end

    context "#to_xml" do
      should "render success xml" do
        req = stub('request', :success? => true)
        @response.instance_variable_set(:@request, req)
        @response.expects(:success_xml)

        @response.to_xml
      end

      should "render error xml" do
        req = stub('request', :success? => false)
        @response.instance_variable_set(:@request, req)
        @response.expects(:error_xml)

        @response.to_xml
      end
    end
  end
end