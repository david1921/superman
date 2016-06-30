module AnalogTestHelper
  module InstanceMethods
    def mock_paypal_ipn_verification(params, response)
      http = mock("http")
      Net::HTTP.expects(:new).with(AppConfig.paypal_host, 80).returns(http)
      http.expects(:post).with( AppConfig.paypal_path, params).returns(response)
    end
  end
end

ActiveSupport::TestCase.send :include, AnalogTestHelper::InstanceMethods
