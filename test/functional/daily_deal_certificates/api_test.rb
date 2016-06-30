require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealCertificatesController::ApiTest < ActionController::TestCase
  tests DailyDealCertificatesController
  include DailyDealCertificatesTestHelper
  include Api::Consumers
  
  test "successful find of an active certificate for JSON format by the advertiser user" do
    daily_deal_certificate = create_daily_deal_certificate
    user = Factory(:user, :company => daily_deal_certificate.advertiser)
    @request.env['API-Version'] = "2.0.0"    
    get :find, :format => "json", :session => api_session_for_user(user), :serial_number => daily_deal_certificate.serial_number
    assert_response :success
    assert_active_json_find_response
  end

  test "successful find of an active certificate for JSON format by the advertiser user - example with non-nil active_session_token" do
    daily_deal_certificate = create_daily_deal_certificate
    user = Factory(:user, :company => daily_deal_certificate.advertiser)
    user.reset_active_session_token!
    assert user.active_session_token.present?
    @request.env['API-Version'] = "2.0.0"    
    get :find, :format => "json", :session => api_session_for_user(user), :serial_number => daily_deal_certificate.serial_number
    assert_response :success
    assert_active_json_find_response
  end

  test "successful find of an active certificate for JSON format by the publisher user" do
    daily_deal_certificate = create_daily_deal_certificate
    user = Factory(:user, :company => daily_deal_certificate.advertiser.publisher)
    @request.env['API-Version'] = "2.0.0"    
    get :find, :format => "json", :session => api_session_for_user(user), :serial_number => daily_deal_certificate.serial_number
    assert_response :success
    assert_active_json_find_response
  end

  test "successful find of an active certificate for JSON format by an admin user" do
    daily_deal_certificate = create_daily_deal_certificate
    user = Factory(:admin)
    @request.env['API-Version'] = "2.0.0"    
    get :find, :format => "json", :session => api_session_for_user(user), :serial_number => daily_deal_certificate.serial_number
    assert_response :success
    assert_active_json_find_response
  end

  test "successful find of a redeemed certificate for JSON format by the advertiser user" do
    daily_deal_certificate = create_daily_deal_certificate
    daily_deal_certificate.update_attributes!(:status => "redeemed", :redeemed_at => Time.parse("Oct 30, 2011 12:34:56 UTC"))
    user = Factory(:user, :company => daily_deal_certificate.advertiser)
    @request.env['API-Version'] = "2.0.0"    
    get :find, :format => "json", :session => api_session_for_user(user), :serial_number => daily_deal_certificate.serial_number
    assert_response :success
    assert_redeemed_json_find_response
  end

  test "successful find of a redeemed certificate for JSON format by the publisher user" do
    daily_deal_certificate = create_daily_deal_certificate
    daily_deal_certificate.update_attributes!(:status => "redeemed", :redeemed_at => Time.parse("Oct 30, 2011 12:34:56 UTC"))
    user = Factory(:user, :company => daily_deal_certificate.advertiser.publisher)
    @request.env['API-Version'] = "2.0.0"    
    get :find, :format => "json", :session => api_session_for_user(user), :serial_number => daily_deal_certificate.serial_number
    assert_response :success
    assert_redeemed_json_find_response
  end

  test "successful find of a redeemed certificate for JSON format by an admin user" do
    daily_deal_certificate = create_daily_deal_certificate
    daily_deal_certificate.update_attributes!(:status => "redeemed", :redeemed_at => Time.parse("Oct 30, 2011 12:34:56 UTC"))
    user = Factory(:admin)
    @request.env['API-Version'] = "2.0.0"    
    get :find, :format => "json", :session => api_session_for_user(user), :serial_number => daily_deal_certificate.serial_number
    assert_response :success
    assert_redeemed_json_find_response
  end
  
  test "find should fail for JSON without API version header" do
    daily_deal_certificate = create_daily_deal_certificate
    user = Factory(:user, :company => daily_deal_certificate.advertiser)
    get :find, :format => "json", :session => api_session_for_user(user), :serial_number => daily_deal_certificate.serial_number
    assert_response :not_acceptable
    assert_match /api-version/i, @response.body
  end
  
  test "find should fail for JSON without user session" do
    daily_deal_certificate = create_daily_deal_certificate
    @request.env['API-Version'] = "2.0.0"    
    get :find, :format => "json", :serial_number => daily_deal_certificate.serial_number
    assert_response :forbidden
    assert @response.body.blank?, "Should not have response body content"
  end

  test "find should fail for JSON with a user session when the active session token does not match the one in the database" do
    daily_deal_certificate = create_daily_deal_certificate
    user = Factory(:user, :company => daily_deal_certificate.advertiser)
    @request.env['API-Version'] = "2.0.0"    
    assert_nil user.active_session_token
    user_session_before_active_session_token_change = api_session_for_user(user)
    user.reset_active_session_token!
    assert user.active_session_token.present?
    get :find, :format => "json", :session => user_session_before_active_session_token_change, :serial_number => daily_deal_certificate.serial_number
    assert_response :forbidden
    assert @response.body.blank?, "Should not have response body content"
  end

  test "find should return status invalid for JSON with bad serial number" do
    daily_deal_certificate = create_daily_deal_certificate
    user = Factory(:user, :company => daily_deal_certificate.advertiser)
    @request.env['API-Version'] = "2.0.0"    
    get :find, :format => "json", :session => api_session_for_user(user), :serial_number => "XXXX-XXXX"

    json = JSON.parse(@response.body)
    assert_equal "invalid", json["status"]
    assert_nil json["methods"]
  end

  test "find should return status invalid for JSON with user belonging to a different advertiser" do
    daily_deal_certificate = create_daily_deal_certificate
    user = Factory(:user, :company => Factory(:advertiser))
    @request.env['API-Version'] = "2.0.0"    
    get :find, :format => "json", :session => api_session_for_user(user), :serial_number => daily_deal_certificate.serial_number

    json = JSON.parse(@response.body)
    assert_equal "invalid", json["status"]
    assert_nil json["methods"]
  end

  test "find should return status invalid for JSON with user belonging to a different publisher" do
    daily_deal_certificate = create_daily_deal_certificate
    user = Factory(:user, :company => Factory(:publisher))
    @request.env['API-Version'] = "2.0.0"    
    get :find, :format => "json", :session => api_session_for_user(user), :serial_number => daily_deal_certificate.serial_number

    json = JSON.parse(@response.body)
    assert_equal "invalid", json["status"]
    assert_nil json["methods"]
  end

  test "successful api_redeem of an active certificate for JSON format by the advertiser user" do
    daily_deal_certificate = create_daily_deal_certificate
    user = Factory(:user, :company => daily_deal_certificate.advertiser)
    @request.env['API-Version'] = "2.0.0"    
    put :api_redeem, :format => "json", :session => api_session_for_user(user), :id => daily_deal_certificate.to_param
    assert_response :success
    
    assert_equal "redeemed", daily_deal_certificate.reload.status
    assert_not_nil daily_deal_certificate.redeemed_at

    assert_equal({}, JSON.parse(@response.body))
  end

  test "successful api_redeem of an active certificate for JSON format by the publisher user" do
    daily_deal_certificate = create_daily_deal_certificate
    user = Factory(:user, :company => daily_deal_certificate.advertiser.publisher)
    @request.env['API-Version'] = "2.0.0"    
    put :api_redeem, :format => "json", :session => api_session_for_user(user), :id => daily_deal_certificate.to_param
    assert_response :success
    
    assert_equal "redeemed", daily_deal_certificate.reload.status
    assert_not_nil daily_deal_certificate.redeemed_at

    assert_equal({}, JSON.parse(@response.body))
  end

  test "successful api_redeem of an active certificate for JSON format by an admin user" do
    daily_deal_certificate = create_daily_deal_certificate
    user = Factory(:admin)
    @request.env['API-Version'] = "2.0.0"    
    put :api_redeem, :format => "json", :session => api_session_for_user(user), :id => daily_deal_certificate.to_param
    assert_response :success
    
    assert_equal "redeemed", daily_deal_certificate.reload.status
    assert_not_nil daily_deal_certificate.redeemed_at

    assert_equal({}, JSON.parse(@response.body))
  end

  test "api_redeem should fail for JSON without API version header" do
    daily_deal_certificate = create_daily_deal_certificate
    user = Factory(:user, :company => daily_deal_certificate.advertiser)
    put :api_redeem, :format => "json", :session => api_session_for_user(user), :id => daily_deal_certificate.to_param
    assert_response :not_acceptable
    assert_match /api-version/i, @response.body

    assert_equal "active", daily_deal_certificate.reload.status
  end

  test "api_redeem should fail for JSON without user session" do
    daily_deal_certificate = create_daily_deal_certificate
    @request.env['API-Version'] = "2.0.0"    
    put :api_redeem, :format => "json", :id => daily_deal_certificate.to_param
    assert_response :forbidden
    assert @response.body.blank?, "Should not have response body content"
    
    assert_equal "active", daily_deal_certificate.reload.status
  end

  test "api_redeem should fail for JSON with user belonging to a different advertiser" do
    daily_deal_certificate = create_daily_deal_certificate
    @request.env['API-Version'] = "2.0.0"    
    user = Factory(:user, :company => Factory(:advertiser))
    put :api_redeem, :format => "json", :session => api_session_for_user(user), :id => daily_deal_certificate.to_param
    assert_response :not_found
    assert @response.body.blank?, "Should not have response body content"
    
    assert_equal "active", daily_deal_certificate.reload.status
  end

  test "api_redeem should fail for JSON with user belonging to a different publisher" do
    daily_deal_certificate = create_daily_deal_certificate
    @request.env['API-Version'] = "2.0.0"    
    user = Factory(:user, :company => Factory(:publisher))
    put :api_redeem, :format => "json", :session => api_session_for_user(user), :id => daily_deal_certificate.to_param
    assert_response :not_found
    assert @response.body.blank?, "Should not have response body content"
    
    assert_equal "active", daily_deal_certificate.reload.status
  end

  test "api_redeem should not verify authenticity token" do
    daily_deal_certificate = create_daily_deal_certificate
    user = Factory(:user, :company => daily_deal_certificate.advertiser)
    @request.env['API-Version'] = "2.0.0"
    @controller.expects(:verified_request?).never
    put :api_redeem, :format => "json", :session => api_session_for_user(user), :id => daily_deal_certificate.to_param
    assert_response :success
  end

  private

  def assert_active_json_find_response
    json = JSON.parse(@response.body)

    assert_equal "active", json["status"]
    assert_equal 20.00, json["price"]
    assert_equal 50.00, json["value"]
    assert_equal "Changos", json["advertiser_name"]
    assert_equal "$50 of Tacos for $20", json["value_proposition"]
    assert_match /\A\d{4}-\d{2}-\d{2}\z/, json["expires_on"]
    
    location = json["location"]
    assert_equal "3005 South Lamar", location["address_line_1"]
    assert_equal "Austin", location["city"]
    assert_equal "TX", location["state"]
    assert_equal "78704", location["zip"]
    assert_equal "US", location["country"]
    
    assert_match /https/, json["methods"]["redeem"]
  end
  
  def assert_redeemed_json_find_response
    json = JSON.parse(@response.body)
    assert_equal "redeemed", json["status"]
    assert_equal "2011-10-30T12:34:56Z", json["redeemed_at"]
    assert_nil json["location"]
    assert_nil json["methods"]
  end
  
end
