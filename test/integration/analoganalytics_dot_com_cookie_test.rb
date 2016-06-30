require File.dirname(__FILE__) + "/../test_helper"

class AnalogAnalyticsDotComCookieTest < ActionController::IntegrationTest
  test "session cookie domain is the root domain (instead of full hostname) for all analoganalytics.com sites" do
    assert_not_nil cookie_name = ActionController::Base.session_options[:key]
    cookie_domain = '.analoganalytics.com'
    get_via_redirect '/', nil, :host => "anyhost#{cookie_domain}"
    assert_match /#{cookie_name}=#{cookies[cookie_name]}; domain=#{Regexp.escape(cookie_domain)}/, headers['Set-Cookie']
  end

  test "session cookie domain is not set for non-analoganalytics.com sites" do
    hostname = 'anything.notanaloganalytics.com'
    get_via_redirect "/", nil, :host => hostname
    assert_not_nil cookie_name = ActionController::Base.session_options[:key]
    assert_no_match /#{cookie_name}=#{cookies[cookie_name]}; domain/, headers['Set-Cookie']
  end
end
