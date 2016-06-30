require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ApiRequests::RootTest

module ApiRequests
  class RootTest < ActionController::TestCase
    include ApiRequestsTestHelper

    tests ApiRequestsController

    def test_api_root_with_no_authentication
      for_each_api_version do |api_version|
        get :root, :format => :xml
        assert_response :unauthorized, api_version
        assert_nil @response.headers['API-Version'], api_version
      end
    end

    def test_api_root_with_bad_password
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:greg).login, :pass => "foobar")
        get :root, :format => :xml
        assert_response :unauthorized, api_version
        assert_nil @response.headers['API-Version'], api_version
      end
    end

    def test_api_root
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
        get :root, :format => :xml
        assert_response :success, api_version
        assert_equal "application/xml", @response.content_type, api_version
        assert_equal api_version, @response.headers['API-Version']

        root = REXML::Document.new(@response.body).root
        assert_equal "services", root.name, api_version

        returned_services = returning({}) do |hash|
          root.each_element do |elem|
            assert_equal "service", elem.name, api_version
            name = elem.elements["name"].text
            href = elem.elements["href"].text
            hash[name] = href
          end
        end
        expected_services = returning({}) do |hash|
          %w{TXT Call Email Report WebCoupon TxtCoupon AdvertiserWebCoupons}.each do |name|
            hash[name] = eval("api_#{name.underscore}_service_url")
          end
        end
        assert_equal expected_services, returned_services, api_version
      end
    end

    def test_api_root_with_missing_version_header
      set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
      get :root, :format => :xml
      assert_response :not_acceptable
      assert_equal "1.2.0", @response.headers['API-Version']
      assert_api_error_response_xml 0, /missing or invalid API-Version/i
    end

    def test_api_root_with_invalid_version_header
      set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
      @request.env['API-Version'] = "1.0"
      get :root, :format => :xml
      assert_response :not_acceptable
      assert_equal "1.2.0", @response.headers['API-Version']
      assert_api_error_response_xml 0, /missing or invalid API-Version/i
    end
  end
end