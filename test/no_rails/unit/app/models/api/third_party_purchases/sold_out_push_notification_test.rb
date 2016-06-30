require File.dirname(__FILE__) + "/../../../models_helper"

# hydra class Api::ThirdPartyPurchases::SoldOutPushNotificationTest

module Api::ThirdPartyPurchases
  class SoldOutPushNotificationTest < Test::Unit::TestCase
    def setup
      @deal = stub('deal', :listing => 'listing')
      @obj = SoldOutPushNotification.new(@deal)
    end

    context "#perform" do
      should "post the forced closure xml to each complete api config" do
        xml = mock('xml')
        @obj.stubs(:forced_closure_xml).returns(xml)
        configs = (1..2).map do |i|
          config = stub("config #{i}", :callback_url => mock("url #{i}"), :callback_username => mock("username #{i}"), :callback_password => mock("password #{i}"))
          SoldOutPushNotification.expects(:post_xml).with(xml, config.callback_url, config.callback_username, config.callback_password)
          config
        end
        @obj.stubs(:complete_api_configs).returns(configs)
        @obj.perform
      end
    end

    context "#forced_closure_xml(deal)" do
      should "return the forced closure xml for the deal" do
        expected = <<"EOF"
<?xml version="1.0"?>
<forced_closure>
  <daily_deal_listing>#{@deal.listing}</daily_deal_listing>
</forced_closure>
EOF
        assert_equal expected, @obj.forced_closure_xml
      end
    end

    context "#post_sold_out_xml(xml, url, username, password)" do
      should "POST the xml to the url with basic auth and https" do
        xml = "xml content"
        url = "https://host.com:1234/path?query=anything"
        username = 'user'
        password = 'password'
        request = mock('request')
        http = mock('http')

        Net::HTTP.expects(:new).with('host.com', 1234).returns(http)
        Net::HTTP::Post.expects(:new).with("/path?query=anything", { "Content-Type" => "application/xml"}).returns(request)
        request.expects(:body=).with(xml)
        request.expects(:basic_auth).with(username, password)
        http.expects(:use_ssl=).with(true)
        http.expects(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
        http.expects(:request).with(request)

        Api::ThirdPartyPurchases::SoldOutPushNotification.post_xml(xml, url, username, password)
      end
    end
  end
end