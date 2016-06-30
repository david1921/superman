ENV["RAILS_ENV"] = "test"

# By default, do not benchmark tests
ENV['BENCHMARK'] ||= "false"

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
#require File.expand_path(File.dirname(__FILE__) + '/factories')
require File.expand_path('lib/tasks/upload_config', RAILS_ROOT)
require File.expand_path(File.dirname(__FILE__) + '/mocks/test/yelp/client')
require File.expand_path(File.dirname(__FILE__) + '/lib/html_assertions')

class ActiveSupport::TestCase
  include AuthenticatedTestHelper
  include AuthorizationTestHelper
  include BraintreeTestHelper
  include DailyDealCategoryTestHelper
  include DailyDealsTestHelper
  include OffersTestHelper
  include PdfToTextHelper
  include SyndicationTestHelper
  include ReportsTestHelper
  include LoyaltyProgramTestHelper
  include TravelsaversTestHelper
  include PurchaseSessionTestHelper
  include Testing::HTMLAssertions
  include UrlVerifierHelper

  # We want a transaction for each test method, even when we only use factories
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false

  fixtures :all
  setup    :stub_paperclip
  setup    :stub_s3
  setup    :stub_google_map_geocoding
  setup    :stub_publisher_with_logo
  setup    :reset_user_current
  setup    :reset_locale
  setup    :reset_time_zone
  setup    :capture_on_purchase
  
  teardown :assert_no_angle_brackets
  teardown :assert_no_bad_urls
  teardown :scrub_instance_variables
  teardown :reset_timecop

  @@no_angle_brackets_exceptions = nil
  @@stub_paperclip_exceptions = nil
  @@reserved_ivars = %w(@loaded_fixtures @test_passed @fixture_cache @method_name @_assertion_wrapped @_result @controller)

  class << self
    def assert_no_angle_brackets(*options)
      if options == [:none]
        write_inheritable_attribute :no_angle_brackets_exceptions, :none
      else
        options = options.extract_options!
        write_inheritable_attribute :no_angle_brackets_exceptions, Array.wrap(options[:except])
      end
    end

    def no_angle_brackets_exceptions
      if current_no_angle_brackets_exceptions = read_inheritable_attribute(:no_angle_brackets_exceptions)
        current_no_angle_brackets_exceptions
      else
        write_inheritable_attribute :no_angle_brackets_exceptions, []
      end
    end

    def stub_paperclip(*options)
      options = options.extract_options!
      write_inheritable_attribute :stub_paperclip_exceptions, Array.wrap(options[:except])
    end

    def stub_paperclip_exceptions
      if current_stub_paperclip_exceptions = read_inheritable_attribute(:stub_paperclip_exceptions)
        current_stub_paperclip_exceptions
      else
        write_inheritable_attribute :stub_paperclip_exceptions, []
      end
    end

  end
  
  def not_used_in_this_test
    "not used in this test"
  end

  # Detect HTML escaping screw-ups
  def assert_no_angle_brackets
    unless self.class.no_angle_brackets_exceptions == :none || self.class.no_angle_brackets_exceptions.include?(@method_name.to_sym)
      assert_not_in_response "&lt;", "escaped left angle bracket"
      assert_not_in_response "&rt;", "escaped right angle bracket"
    end
  end  
  
  # Detect production_host + absolute URL screw-ups
  def assert_no_bad_urls
    assert_not_in_response "http://localhost:3000http", "bad URL with double 'http'"
    assert_not_in_response "http://0.0.0.0:3000http", "bad URL with double 'http'"
    assert_not_in_response "http://test.hosthttp", "bad URL with double 'http'"
  end

  def assert_not_in_response(text, message)
    if @controller && @controller.response && @controller.response.body.present?
      body_string = @controller.response.body.to_s
      if body_string[text]
        add_failure "Found #{message} in #{body_string}"
      end
    end
  end

  def stub_paperclip
    unless self.class.stub_paperclip_exceptions.include?(@method_name.to_sym)
      Paperclip.stubs(:run).returns("130x110")
    end
  end

  def stub_s3
    AWS::S3::Base.stubs :establish_connection!
    AWS::S3::S3Object.stubs :store
    AWS::S3::S3Object.stubs :exists?
  end

  # stubbing out 3rd party call to Google Map Geocoding.
  def stub_google_map_geocoding(lat = 45.538069, lng = -121.56724)
    geocode = mock("geocode")
    geocode.stubs(:success?).returns(true)
    geocode.stubs(:lat).returns(lat)
    geocode.stubs(:lng).returns(lng)    
    Geokit::Geocoders::GoogleGeocoder.stubs(:geocode).returns(geocode)    
  end
  
  def stub_publisher_with_logo
    Publisher.any_instance.stubs(:with_logo).returns("")
  end
  
  def reset_user_current
    User.current = nil
  end
  
  def reset_locale
    I18n.locale = nil
  end
  
  def reset_time_zone
    Time.zone = nil
  end

  def capture_on_purchase
    AppConfig.capture_on_purchase = true
  end

  def scrub_instance_variables
    (instance_variables - @@reserved_ivars).each do |ivar|
      instance_variable_set(ivar, nil)
    end
  end
  
  # Turn off Timecop to ensure subsequent tests aren't affected by any Timecop freezing
  def reset_timecop
    Timecop.return    
  end
  
  # Automatically removes the "layout/" prefix.
  # Example: test for default layout: assert_layout("application")
  def assert_layout(expected)
    if expected
      assert_equal("layouts/#{expected}", @response.layout, "layout")
    else
      assert_nil(@response.layout, "no layout")
    end
  end
  
  # Automatically removes the "themes/" prefix.
  # Example: test for default layout: assert_layout("application")
  def assert_theme_layout(expected)
    if expected
      assert_equal("themes/#{expected}", @response.layout, "layout")
    else
      assert_nil(@response.layout, "no layout")
    end
  end

  def assert_equal_times(expected, actual, message = nil, format = "%H:%M")
    assert_equal_dates(expected, actual, message, format)
  end
  
  def assert_equal_date_times(expected, actual, message = nil, format = "%Y-%m-%d %H:%M:%S")
    assert_equal_dates(expected, actual, message, format)
  end
  
  def assert_equal_dates(expected, actual, message = nil, format = "%Y-%m-%d")
    if expected != nil && (expected.is_a?(Date) || expected.is_a?(DateTime) || expected.is_a?(Time))
      expected = expected.strftime(format)
    end
    formatted_actual = actual
    if !actual.nil? and (actual.is_a?(Date) || actual.is_a?(DateTime) || actual.is_a?(Time))
      formatted_actual = actual.strftime(format)
    end
    assert_block("#{message} \nExpected #{expected} \nbut was #{formatted_actual}") do 
      expected == formatted_actual
    end
  end
  
  # Not aliasing assert_equals to keep tests explicit and fast
  def assert_equal_arrays(expected, actual, message = nil)
    if actual.is_a?(Array) && expected.is_a?(Array)

      diffs = []
      extra = expected - actual
      if extra.any?
        diffs << "Extra: #{extra.join(", ")}."
      end

      missing = actual - expected
      if missing.any?
        diffs << "Missing: #{missing.join(", ")}."
      end
      
      if extra.any? || missing.any?
        if expected.any?
          expected_message = expected.join(", ")
        else
          expected_message = "[]"
        end
        
        if actual.any?
          actual_message = actual.join(", ")
        else
          actual_message = "[]"
        end
        
        flunk "#{message}\nExpected\n#{expected_message} but was\n#{actual_message}\n#{diffs.join("\n")}"
      end
    else
      assert_equal expected, actual, message
    end
  end
  
  def assert_equal_floats(expected, actual, message = nil)
    assert_equal BigDecimal.new(expected.to_s), BigDecimal.new(actual.to_s), message
  end
  
  def assert_application_page_title(text)
    assert_select "html head title", "Analog Analytics: #{text}", 1
  end
  
  # Simple model valid assert macro
  def assert_no_errors(record)
    assert_not_nil record, "Record"
    assert record.errors.empty?, record.errors.full_messages.join(", ")
  end

  def create_demo_user!
    publishers(:my_space).users.create!(
      :login => "demo@analoganalytics.com", 
      :password => "secret", 
      :password_confirmation => "secret"
    )
  end
  
  def quietly
    verbose, $VERBOSE = $VERBOSE, nil; yield; ensure $VERBOSE = verbose
  end
  
  def ssl_on
     @request    = ActionController::TestRequest.new if @request.nil?
     @request.env['HTTPS'] = 'on'
  end 
  
  def ssl_off
     @request.env['HTTPS'] = nil
  end

  def login_with_basic_auth(options = {})
    case options
      when Hash
        login, password = options[:login], options[:password]
        @request.env['HTTP_AUTHORIZATION'] = 'Basic ' + Base64::encode64("#{login}:#{password}")
      when User
        @request.env['HTTP_AUTHORIZATION'] = 'Basic ' + Base64::encode64("#{options.login}:test")
      else
        raise ArgumentError, "expected Hash or User object, got #{options}"
    end
  end

  def assert_cdata_text(node, text)
    assert_equal text, node.text
    assert_equal 1, node.children.length
    assert_equal Nokogiri::XML::CDATA, node.children[0].class
  end

  def data_file_path
    "test/unit/import/data"
  end
  
  def read_test_data_file(filename)
    File.read(Rails.root.join("#{data_file_path}/#{filename}"))
  end
  
  def create_user_with_company(options)
    company = options[:company]
    unless company.present?
      raise ArgumentError, "missing required argument :company"
    end
    
    user = Factory.build :user_without_company, options.except(:company)
    user.user_companies << UserCompany.new(:company => company)
    user.save!
    user
  end
  
  def init_cyber_source_credentials_for_tests(label)
    CyberSource::Credentials.init({
      :label => label,
      :merchant_id => "ep_cookie",
      :shared_secret => "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDBO132ymyS5KYvEfljr9Aefwf2gPI9Tw3uJ01Z4wbGdb4qMT9TnEHtfEwyow5viGkmJL4bNmiyDOfymJrFc/8dbnJtP0Jh/LW4OsH7F+4bTWFqRtOtMKjhsukEABgczQXR8Ek595VuQZ70+bWat9IuK3Swkx72dLYi8ji6w5mvJwIDAQAB",
      :serial_number => "3294982392010176056165",
      :soap_username => "ep_cookie",
      :soap_password => "cthvZtITBU5CAtSOfD5CmcNzN80F5YJzMmNzUsVnllNWTprOOLOcqT9aIU5qypZiN0WzCgWCFFayp5LvdZgag8SbqZl2UUme4vtmb5cF0OjxjAsi+kt3Rquu+XSGc7AyzvmcXMKGOs+Gq2eC+nvgDionrNY9ISQU3XF6UCVLZFxAIJyOuJggepuavDsI0WT2itLezQXlgnMyY3NSxWeWU1ZOms44s5ypP1ohTmrKlmI3RbMKBYIUVrKnku91mBqDxJupmXZRSZ7i+2ZvlwXQ6PGMCyL6S3dGq675dIZzsDLO+ZxcwoY6z4arZ4L6e+AOKies1j0hJBTdcXpQJUtkXA=="
    })
  end
end

class ActionController::TestCase
  def better_cookies
    cookies = {}
    Array(@response.headers['Set-Cookie']).each do |cookie|
      key = nil
      details = cookie.split(';').inject({}) do |fields, cookie_field|
        pair = cookie_field.split('=').map { |val| Rack::Utils.unescape(val.strip) }
        key = pair.first unless key
        fields.merge(pair.first => pair.last)
      end
      details['expires'] = Time.parse(details['expires']) if details['expires']
      cookies[key] = details
    end
    cookies
  end
end

class ActionMailer::TestCase

  private

  def parts(email)
    {
        :text => email.parts.detect { |p| p.content_type == "text/plain" },
        :html => email.parts.detect { |p| p.content_type == "text/html" }
    }
  end

  def html_body(email)
    @html_body ||= Nokogiri::HTML(parts(email)[:html].body)
  end

  def plain_body(email)
    @plain_body ||= parts(email)[:text].body
  end
end
