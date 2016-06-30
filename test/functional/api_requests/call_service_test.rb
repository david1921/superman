require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ApiRequests::CallServiceTest

module ApiRequests
  class CallServiceTest < ActionController::TestCase
    include ApiRequestsTestHelper

    tests ApiRequestsController

    def test_call_service_with_no_authentication
      for_each_api_version do |api_version|
        assert_no_difference 'VoiceMessage.count' do
          post :call_service, {
            :format => :xml,
            :publisher_label => "longislandpress",
            :consumer_phone_number => "6266745901",
            :merchant_phone_number => "8005551212"
          }
        end
        assert_response :unauthorized
        assert_nil @response.headers['API-Version'], api_version
      end
    end

    def test_call_service_with_bad_password
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:greg).login, :pass => "foobar")
        assert_no_difference 'VoiceMessage.count' do
          post :call_service, {
            :format => :xml,
            :publisher_label => "longislandpress",
            :consumer_phone_number => "6266745901",
            :merchant_phone_number => "8005551212"
          }
        end
        assert_response :unauthorized
        assert_nil @response.headers['API-Version'], api_version
      end
    end

    def test_call_service_with_missing_publisher
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
        assert_no_difference 'VoiceMessage.count' do
          post :call_service, {
            :format => :xml,
            :consumer_phone_number => "6266745901",
            :merchant_phone_number => "8005551212"
          }
        end
        assert_response :forbidden
        assert_equal api_version, @response.headers['API-Version']
      end
    end

    def test_call_service_with_invalid_publisher
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
        assert_no_difference 'VoiceMessage.count' do
          post :call_service, {
            :format => :xml,
            :publisher_label => "xxxxxx",
            :consumer_phone_number => "6266745901",
            :merchant_phone_number => "8005551212"
          }
        end
        assert_response :forbidden
        assert_equal api_version, @response.headers['API-Version']
      end
    end

    def test_call_service_with_user_publisher_mismatch
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
        assert_no_difference 'VoiceMessage.count' do
          post :call_service, {
            :format => :xml,
            :publisher_label => "myspace",
            :consumer_phone_number => "6266745901",
            :merchant_phone_number => "8005551212"
          }
        end
        assert_response :forbidden
        assert_equal api_version, @response.headers['API-Version']
      end
    end

    def test_call_service
      for_each_api_version do |api_version|
        [VoiceMessage, CallApiRequest].each(&:destroy_all)
        set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
        assert_difference 'VoiceMessage.count' do
          post :call_service, {
            :format => :xml,
            :publisher_label => "longislandpress",
            :consumer_phone_number => "6266745901",
            :merchant_phone_number => "8005551212"
          }
        end
        assert_response :created
        assert_equal "application/xml", @response.content_type
        assert_equal api_version, @response.headers['API-Version']

        voice_message = VoiceMessage.find_by_mobile_number("16266745901")
        assert_not_nil voice_message, "New voice message should have the given consumer number"
        assert_equal "18005551212", voice_message.center_phone_number, "New voice message should have the given merchant number"
        assert_equal "4957", voice_message.voice_response_code, "New voice message response code"
        assert_equal "created", voice_message.status, "New voice message status"

        assert_equal 1, CallApiRequest.count
        call_api_request = CallApiRequest.first
        assert_equal publishers(:li_press), call_api_request.publisher, "API request should belong to originating publisher"

        root = REXML::Document.new(@response.body).root
        assert_not_nil root, "XML response should have a root element"
        assert_equal "service_response", root.name, "XML response root element name"
        assert_equal "call", root.attributes["type"], "XML response service_response[type]"

        request_id = root.elements["request_id"]
        assert_not_nil request_id, "XML response root should have a request_id child"
        assert_equal "call-#{call_api_request.to_param}", request_id.text, "XML response request ID"
      end
    end

    def test_call_service_with_invalid_consumer_phone_number
      test_call_service_with_invalid_options({ :consumer_phone_number => "626674590x" }, 2, "Invalid phone number")
    end

    def test_call_service_with_invalid_merchant_phone_number
      test_call_service_with_invalid_options({ :merchant_phone_number => "800555121x" }, 2, "Invalid phone number")
    end

    private

    def test_call_service_with_invalid_options(options, error_code, error_text)
      options.reverse_merge!({
        :format => :xml,
        :publisher_label => "longislandpress",
        :consumer_phone_number => "6266745901",
        :merchant_phone_number => "8005551212"
      })
      test_service_with_invalid_options(:call, "VoiceMessage.count", options, error_code, error_text)
    end

  end
end