module ApiRequestsTestHelper
  def for_each_api_version
    %w{ 1.0.0 1.1.0 1.2.0 }.each do |api_version|
      @controller = nil
      setup_controller_request_and_response
      @request.env['API-Version'] = api_version
      yield api_version
    end
  end

  def assert_api_error_response_xml(error_code, regex, param_name=nil)
    assert_equal "application/xml", @response.content_type

    root = REXML::Document.new(@response.body).root
    assert_not_nil root, "XML response should have a root element"
    assert_equal "service_response", root.name, "XML response root element name"
    assert_equal "api", root.attributes["type"], "XML response service_response[type]"

    error = root.elements["error"]
    assert_not_nil error, "XML response root should have an error child"
    assert_not_nil error.elements["param_name"], "XML response error should have an param_name child"
    assert_equal param_name, error.elements["param_name"].text, "XML response param_name"
    assert_not_nil error.elements["error_code"], "XML response error should have an error_code child"
    assert_equal error_code.to_s, error.elements["error_code"].text, "XML response error_code"
    assert_not_nil error.elements["error_string"], "XML response error should have an error_string child"
    assert_match regex, error.elements["error_string"].text, "XML response error_string"
  end

  def test_service_with_invalid_options(service, message_counter, options, error_code, error_text)
    for_each_api_version do |api_version|
      api_request_class = "#{service.to_s.camelize}ApiRequest".constantize
      action = "#{service}_service".to_sym

      api_request_class.destroy_all

      set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
      options.reverse_merge!({
        :format => :xml,
        :publisher_label => "longislandpress",
        :mobile_number => "6266745901",
        :message => "test"
      })
      assert_no_difference message_counter do
        post action, options
      end
      assert_response :bad_request
      assert_equal "application/xml", @response.content_type
      assert_equal api_version, @response.headers['API-Version']

      assert_equal 0, api_request_class.count

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "#{service}", root.attributes["type"], "XML response service_response[type]"

      error = root.elements["error"]
      assert_not_nil error, "XML response root should have an error child"
      assert_not_nil error.elements["param_name"], "XML response error should have an param_name child"
      assert_nil error.elements["param_name"].text, "XML response param_name"
      assert_not_nil error.elements["error_string"], "XML response error should have an error_string child"
      assert_equal error_code.to_s, error.elements["error_code"].text, "XML response error_code"
      assert_not_nil error.elements["error_string"], "XML response error should have an error_string child"
      assert_equal error_text, error.elements["error_string"].text, "XML response error_string"
    end
  end

end