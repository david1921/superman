require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ApiRequests::EmailServiceTest

module ApiRequests
  class EmailServiceTest < ActionController::TestCase
    include ApiRequestsTestHelper

    tests ApiRequestsController

    def test_email_service_with_no_authentication
      for_each_api_version do |api_version|
        assert_no_difference 'ActionMailer::Base.deliveries.size' do
          post :email_service, {
            :format => :xml,
            :publisher_label => "longislandpress",
            :email_subject => "This is a test",
            :destination_email_address => "test@example.com",
            :text_plain_content => "This is a test message body"
          }
        end
        assert_response :unauthorized, api_version
        assert_nil @response.headers['API-Version'], api_version
      end
    end

    def test_email_service_with_bad_password
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:greg).login, :pass => "foobar")
        assert_no_difference 'ActionMailer::Base.deliveries.size' do
          post :email_service, {
            :format => :xml,
            :publisher_label => "longislandpress",
            :email_subject => "This is a test",
            :destination_email_address => "test@example.com",
            :text_plain_content => "This is a test message body"
          }
        end
        assert_response :unauthorized, api_version
        assert_nil @response.headers['API-Version'], api_version
      end
    end

    def test_email_service_with_missing_publisher
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
        assert_no_difference 'ActionMailer::Base.deliveries.size' do
          post :email_service, {
            :format => :xml,
            :email_subject => "This is a test",
            :destination_email_address => "test@example.com",
            :text_plain_content => "This is a test message body"
          }
        end
        assert_response :forbidden, api_version
        assert_equal api_version, @response.headers['API-Version']
      end
    end

    def test_email_service_with_invalid_publisher
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
        assert_no_difference 'ActionMailer::Base.deliveries.size' do
          post :email_service, {
            :format => :xml,
            :publisher_label => "xxxxxx",
            :email_subject => "This is a test",
            :destination_email_address => "test@example.com",
            :text_plain_content => "This is a test message body"
          }
        end
        assert_response :forbidden, api_version
        assert_equal api_version, @response.headers['API-Version']
      end
    end

    def test_email_service_with_user_publisher_mismatch
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
        assert_no_difference 'ActionMailer::Base.deliveries.size' do
          post :email_service, {
            :format => :xml,
            :publisher_label => "myspace",
            :email_subject => "This is a test",
            :destination_email_address => "test@example.com",
            :text_plain_content => "This is a test message body"
          }
        end
        assert_response :forbidden, api_version
        assert_equal api_version, @response.headers['API-Version']
      end
    end

    def test_email_service
      for_each_api_version do |api_version|
        ActionMailer::Base.deliveries.clear
        EmailApiRequest.destroy_all

        set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
        assert_difference 'ActionMailer::Base.deliveries.size' do
          post :email_service, {
            :format => :xml,
            :publisher_label => "longislandpress",
            :email_subject => "This is a test",
            :destination_email_address => "test@example.com",
            :text_plain_content => "This is a test plain message body",
            :text_html_content => "<table><tr><td>This is a test HTML message body</td></tr></table>"
          }
        end
        assert_response :created
        assert_equal "application/xml", @response.content_type
        assert_equal api_version, @response.headers['API-Version']

        email = ActionMailer::Base.deliveries.first
        assert_equal "This is a test", email.subject, "New email should have the specified subject"
        assert_match(/This is a test plain message body/, email.body, "New email body should contain specfied content")
        assert_match(/This is a test HTML message body/, email.body, "New email body should contain specfied content")

        assert_equal 1, EmailApiRequest.count
        email_api_request = EmailApiRequest.first
        assert_equal publishers(:li_press), email_api_request.publisher, "API request should belong to originating publisher"

        root = REXML::Document.new(@response.body).root
        assert_not_nil root, "XML response should have a root element"
        assert_equal "service_response", root.name, "XML response root element name"
        assert_equal "email", root.attributes["type"], "XML response service_response[type]"

        request_id = root.elements["request_id"]
        assert_not_nil request_id, "XML response root should have a request_id child"
        assert_equal "email-#{email_api_request.to_param}", request_id.text, "XML response request ID"
      end
    end

    def test_email_service_with_missing_email_subject
      test_email_service_with_invalid_options({ :email_subject => nil }, 4, "Missing email subject")
    end

    def test_email_service_with_missing_destination_email_address
      test_email_service_with_invalid_options({ :destination_email_address => nil }, 5, "Invalid email address")
    end

    def test_email_service_with_missing_text_plain_content
      test_email_service_with_invalid_options({ :text_plain_content => nil }, 3, "Invalid content length")
    end

    def test_email_service_with_invalid_destination_email_address
      test_email_service_with_invalid_options({ :destination_email_address => "x" }, 5, "Invalid email address")
    end

    def test_email_service_with_text_plain_content_too_long
      test_email_service_with_invalid_options({ :text_plain_content => "x" * 8193 }, 3, "Invalid content length")
    end

    private

    def test_email_service_with_invalid_options(options, error_code, error_text)
      options.reverse_merge!({
        :format => :xml,
        :publisher_label => "longislandpress",
        :email_subject => "This is a test",
        :destination_email_address => "test@example.com",
        :text_plain_content => "This is a test message body"
      })
      test_service_with_invalid_options(:email, "ActionMailer::Base.deliveries.size", options, error_code, error_text)
    end
  end
end