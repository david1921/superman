require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::StatusTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  test "status with api 1.0.0 with missing api header" do
    daily_deal_purchase   = Factory(:captured_daily_deal_purchase)
    consumer              = daily_deal_purchase.consumer
    get :status,
      :id           => daily_deal_purchase.to_param,
      :session      => @controller.send(:verifier).generate({:user_id => consumer.id}),
      :format       => "json"

    assert_response :not_acceptable
  end

  test "status with api 1.0.0 with invalid api header" do
    @request.env['API-Version'] = "9.9.9"
    daily_deal_purchase   = Factory(:captured_daily_deal_purchase)
    consumer              = daily_deal_purchase.consumer
    get :status,
      :id           => daily_deal_purchase.to_param,
      :session      => @controller.send(:verifier).generate({:user_id => consumer.id}),
      :format       => "json"

    assert_response :not_acceptable
  end

  test "status with api 1.0.0 with invalid user_id in session" do
    @request.env['API-Version'] = "1.0.0"
    daily_deal_purchase   = Factory(:captured_daily_deal_purchase)
    consumer              = daily_deal_purchase.consumer
    get :status,
      :id           => daily_deal_purchase.to_param,
      :session      => @controller.send(:verifier).generate({:user_id => 9999}),
      :format       => "json"

    assert_response :forbidden
  end

  test "status with api 1.0.0 with missing session" do
    @request.env['API-Version'] = "1.0.0"
    daily_deal_purchase   = Factory(:captured_daily_deal_purchase)
    consumer              = daily_deal_purchase.consumer
    get :status,
      :id           => daily_deal_purchase.to_param,
      :format       => "json"

    assert_response :forbidden
  end

  test "status with api 1.0.0 with valid user_id in session" do
    @request.env['API-Version'] = "1.0.0"
    daily_deal_purchase     = Factory(:captured_daily_deal_purchase_no_certs)
    daily_deal_certificate  = Factory(:daily_deal_certificate, :daily_deal_purchase => daily_deal_purchase)
    consumer                = daily_deal_purchase.consumer
    get :status,
      :id           => daily_deal_purchase.to_param,
      :session      => @controller.send(:verifier).generate({:user_id => consumer.id}),
      :format       => "json"

    assert_response :success
    assert_equal daily_deal_purchase, assigns(:daily_deal_purchase)

    json = JSON.parse( @response.body )
    assert_equal "true", json["captured"]
    assert_equal 1, json["vouchers"].size
    assert_equal daily_deal_certificate.redeemer_name.to_s, json["vouchers"].first["name"]
    assert_equal daily_deal_certificate.serial_number.to_s, json["vouchers"].first["serial_number"]
  end

  test "status with api 1.0.0 with valid session but invalid purchase id" do
    @request.env['API-Version'] = "1.0.0"
    daily_deal_purchase     = Factory(:captured_daily_deal_purchase)
    daily_deal_certificate  = Factory(:daily_deal_certificate, :daily_deal_purchase => daily_deal_purchase)
    consumer                = daily_deal_purchase.consumer
    get :status,
      :id           => "blahblah",
      :session      => @controller.send(:verifier).generate({:user_id => consumer.id}),
      :format       => "json"

    assert_response :not_found
  end
  
  test "status with API 3.0.0 and valid session" do
    Timecop.freeze Time.parse("2011-12-01 00:00:00") do
      advertiser = Factory(:advertiser, :name => "Changos Austin")
      deal = Factory(:daily_deal, :advertiser => advertiser, :expires_on => "2020-01-01")
      purchase = Factory(:captured_daily_deal_purchase_no_certs, :daily_deal => deal, :executed_at => "2011-12-01 12:34:56")
      certificate = Factory(:daily_deal_certificate, :daily_deal_purchase => purchase, :serial_number => "6666", :bar_code => "1234")
      session = @controller.send(:verifier).generate(:user_id => purchase.consumer.id)

      @request.env['API-Version'] = "3.0.0"
      get :status, :id => purchase.to_param, :session => session, :format => "json"
      assert_response :success
      assert_equal purchase, assigns(:daily_deal_purchase)

      json = JSON.parse(@response.body)
      assert_equal "captured", json['status']
      assert_equal "$30.00 for only $15.00!", json['description']
      assert_equal "<p>these are my terms</p>", json['terms']
      assert_equal "$30.00 Deal to Changos Austin", json['synopsis']
      assert_equal "http://test.host/images/missing/daily_deals/photos/widget.png", json['photo']
      assert_equal 1, json['quantity']
      assert_equal 15.0, json['total_price']
      assert_equal 30.0, json['value']
      assert_equal 0.0, json['credit_used']
      assert_equal "2020-01-01", json['expires_on']
      assert_equal "2011-12-01T20:34:56Z", json['executed_at']

      assert_not_nil(location = json['location'])
      assert_equal "Changos Austin", location['name']
      assert_equal "3005 South Lamar", location['address_line_1']
      assert_equal "Apt 1", location['address_line_2']
      assert_equal "Austin", location['city']
      assert_equal "TX", location['state']
      assert_equal "78704", location['zip']
      assert_equal "US",location['country']
      assert_equal "15124161500", location['phone_number']
      assert_equal 45.5381, location['latitude']
      assert_equal -121.567,location['longitude']
      
      assert_equal 1, json['vouchers'].size
      voucher = json['vouchers'].last
      assert_equal "active", voucher['status']
      assert_equal "6666", voucher['serial_number']
      assert_equal "John Public", voucher['redeemer_name']
      assert_equal "http://test.host/daily_deal_purchases/#{purchase.uuid}/bar_codes/6666.jpg", voucher["bar_code"]
    end
  end
end
