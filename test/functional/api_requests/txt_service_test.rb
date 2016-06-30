require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ApiRequests::TxtServiceTest

module ApiRequests
  class TxtServiceTest < ActionController::TestCase
    include ApiRequestsTestHelper

    tests ApiRequestsController

    def test_txt_service_with_invalid_mobile_number
      test_txt_service_with_invalid_options({ :mobile_number => "626674590x" }, 2, "Invalid phone number")
    end

    def test_txt_service_with_message_too_long
      test_txt_service_with_invalid_options({ :message => "x"*111 }, 3, "Invalid content length")
    end

    def test_txt_service_with_message_too_short
      test_txt_service_with_invalid_options({ :message => "" }, 3, "Invalid content length")
    end

    def test_txt_service_with_no_authentication
      for_each_api_version do |api_version|
        assert_no_difference 'Txt.count' do
          post :txt_service, :format => :xml, :publisher_label => "longislandpress", :mobile_number => "6266745901", :message => "test"
        end
        assert_response :unauthorized
        assert_nil @response.headers['API-Version'], api_version
      end
    end

    def test_txt_service_with_bad_password
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:greg).login, :pass => "foobar")
        assert_no_difference 'Txt.count' do
          post :txt_service, :format => :xml, :publisher_label => "longislandpress", :mobile_number => "6266745901", :message => "test"
        end
        assert_response :unauthorized
        assert_nil @response.headers['API-Version'], api_version
      end
    end

    def test_txt_service_with_missing_publisher
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
        assert_no_difference 'Txt.count' do
          post :txt_service, :format => :xml, :mobile_number => "6266745901", :message => "test"
        end
        assert_response :forbidden, api_version
        assert_equal api_version, @response.headers['API-Version']
      end
    end

    def test_txt_service_with_invalid_publisher
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
        assert_no_difference 'Txt.count' do
          post :txt_service, :format => :xml, :publisher_label => "xxxxxx", :mobile_number => "6266745901", :message => "test"
        end
        assert_response :forbidden
        assert_equal api_version, @response.headers['API-Version']
      end
    end

    def test_txt_service_with_user_publisher_mismatch
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
        assert_no_difference 'Txt.count' do
          post :txt_service, :format => :xml, :publisher_label => "myspace", :mobile_number => "6266745901", :message => "test"
        end
        assert_response :forbidden
        assert_equal api_version, @response.headers['API-Version']
      end
    end

    def test_txt_service
      for_each_api_version do |api_version|
        [Txt, TxtApiRequest].each(&:destroy_all)

        set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
        assert_difference 'Txt.count' do
          post :txt_service, :format => :xml, :publisher_label => "longislandpress", :mobile_number => "6266745901", :message => "test"
        end
        assert_response :created
        assert_equal "application/xml", @response.content_type
        assert_equal api_version, @response.headers['API-Version']

        txt = Txt.find_by_message("TXT411: test. Std msg chrgs apply. T&Cs at txt411.com")
        assert_not_nil txt, "New TXT should have the given message"
        assert_equal "16266745901", txt.mobile_number, "New TXT should have the given mobile number"
        assert_equal "created", txt.status, "New TXT status"

        assert_equal 1, TxtApiRequest.count
        txt_api_request = TxtApiRequest.first
        assert_equal publishers(:li_press), txt_api_request.publisher, "API request should belong to originating publisher"

        root = REXML::Document.new(@response.body).root
        assert_not_nil root, "XML response should have a root element"
        assert_equal "service_response", root.name, "XML response root element name"
        assert_equal "txt", root.attributes["type"], "XML response service_response[type]"

        request_id = root.elements["request_id"]
        assert_not_nil request_id, "XML response root should have a request_id child"
        assert_equal "txt-#{txt_api_request.to_param}", request_id.text, "XML response request ID"
      end
    end

    def test_txt_service_with_invalid_api_version
      [Txt, TxtApiRequest].each(&:destroy_all)

      set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
      @request.env['API-Version'] = "1.0"
      assert_no_difference 'Txt.count' do
        post :txt_service, :format => :xml, :publisher_label => "longislandpress", :mobile_number => "6266745901", :message => "test"
      end
      assert_response :not_acceptable
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      assert_equal 0, TxtApiRequest.count
    end

    private

    def test_txt_service_with_invalid_options(options, error_code, error_text)
      options.reverse_merge!({
        :format => :xml,
        :publisher_label => "longislandpress",
        :mobile_number => "6266745901",
        :message => "test"
      })
      test_service_with_invalid_options(:txt, "Txt.count", options, error_code, error_text)
    end

  end
end
