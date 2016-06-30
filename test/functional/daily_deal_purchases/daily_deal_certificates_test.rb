require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::DailyDealCertificatesTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  context "GET to :daily_deal_certificates" do

    setup do
      @publisher = Factory :publisher
      @consumer = Factory :consumer, :publisher => @publisher
      @advertiser_1 = Factory :advertiser, :publisher => @publisher
      @advertiser_2 = Factory :advertiser, :publisher => @publisher, :name => "Bob's Games Shop"
      @store_1 = Factory :store, :advertiser => @advertiser_2, :address_line_1 => "100 Test Road",
                         :address_line_2 => "", :city => "Testville", :state => "CA", :zip => "90210",
                         :phone_number => "18005551234"
      @advertiser_2.stores.reload
      @daily_deal_1 = Factory :daily_deal, :terms => "* the first term\n* the second term",
                              :advertiser => @advertiser_1
      @daily_deal_2 = Factory :side_daily_deal, :advertiser => @advertiser_2, :location_required => true
      @daily_deal_3 = Factory :side_daily_deal, :advertiser => @advertiser_2, :certificates_to_generate_per_unit_quantity => 2

      @purchase_with_no_location = Factory :captured_daily_deal_purchase, :uuid => "purchase-with-no-loc",
                                           :daily_deal => @daily_deal_1, :consumer => @consumer
      @purchase_with_no_location.daily_deal_certificates.first.update_attribute :bar_code, "123456"
      @purchase_with_location = Factory :captured_daily_deal_purchase, :uuid => "purchase-with-loc", :daily_deal => @daily_deal_2,
                                        :consumer => @consumer, :store => @store_1, :quantity => 2
      @purchase_with_multi_voucher_deal = Factory :captured_daily_deal_purchase, :uuid => "purchase-with-multi-voucer",
                                                  :daily_deal => @daily_deal_3, :consumer => @consumer, :quantity => 2
    end
    
    context "invalid requests" do

      should "return a 406 Not Acceptable when missing the API-Version header" do
        get :daily_deal_certificates, :id => @purchase_with_location.to_param, :format => "json"
        assert_response :not_acceptable
      end

      should "return a 406 Not Acceptable when using an API version that doesn't exist" do
        @request.env["API-Version"] = "9.9.9"
        get :daily_deal_certificates, :id => @purchase_with_location.to_param, :format => "json"
        assert_response :not_acceptable
      end

      should "return a 406 Not Acceptable with API-Version 1.0.0" do
        @request.env["API-Version"] = "1.0.0"
        get :daily_deal_certificates, :id => @purchase_with_location.to_param, :format => "json"
        assert_response :not_acceptable
      end

      should "return a 403 Forbidden with API-Version 2.0.0, but missing session info" do
        @request.env["API-Version"] = "2.0.0"
        get :daily_deal_certificates, :id => @purchase_with_location.to_param, :format => "json"
        assert_response 403
      end

      should "return a 403 Forbidden with API-Version 2.0.0, but incorrect session info" do
        @request.env["API-Version"] = "2.0.0"
        get :daily_deal_certificates, :id => @purchase_with_location.to_param, :consumer => { :session => "invalidsession" }, :format => "json"
        assert_response 403
      end
      
    end

    context "with api version 2.0.0" do
        
      setup do
        @request.env["API-Version"] = "2.0.0"
      end

      should "return a 200 Ok with API-Version 2.0.0 and correct session info" do
        get :daily_deal_certificates, :id => @purchase_with_location.to_param,
            :consumer => { :session => @controller.send(:verifier).generate(:user_id => @consumer.id) },
            :format => "json"
        assert_response :success
      end

      should "return this purchase's vouchers in JSON format with API-Version 2.0.0 and correct " +
             "session info (example without a location, with a bar code)" do
        get :daily_deal_certificates, :id => @purchase_with_no_location.to_param,
            :consumer => { :session => @controller.send(:verifier).generate(:user_id => @consumer.id) },
            :format => "json"
        assert_response :success

        first_voucher = @purchase_with_no_location.daily_deal_certificates.first
        expected_voucher_hash = {
          "serial_number" => first_voucher.serial_number,
          "status" => "active",
          "connections" => {
            "bar_code" => "http://test.host/daily_deal_purchases/purchase-with-no-loc/bar_codes/#{first_voucher.serial_number}.jpg"
          }
        }

        assert_equal [expected_voucher_hash], JSON.parse(@response.body)
      end

      should "return all a purchase's vouchers in JSON format with API-Version 2.0.0 and a multi-voucher deal" do
        get :daily_deal_certificates, :id => @purchase_with_multi_voucher_deal.to_param,
            :consumer => { :session => @controller.send(:verifier).generate(:user_id => @consumer.id) },
            :format => "json"
        assert_response :success
        assert_equal 4, JSON.parse(@response.body).size
      end
        
      should "return this purchase's vouchers in JSON format with API-Version 2.0.0 and correct " +
             "session info (example with a location, without bar codes)" do
        Store.any_instance.stubs(:latitude).returns("42.42")
        Store.any_instance.stubs(:longitude).returns("3.14")

        get :daily_deal_certificates, :id => @purchase_with_location.to_param,
            :consumer => { :session => @controller.send(:verifier).generate(:user_id => @consumer.id) },
            :format => "json"
        assert_response :success

        first_voucher = @purchase_with_location.daily_deal_certificates.first
        second_voucher = @purchase_with_location.daily_deal_certificates.second

        expected_voucher_array = [
          {
            "serial_number" => first_voucher.serial_number,
            "status" => "active",
            "location" => {
              "name" => "Bob's Games Shop",
              "address_line_1" => "100 Test Road",
              "address_line_2" => "",
              "city" => "Testville",
              "state" => "CA",
              "zip" => "90210",
              "country" => "US",
              "phone_number" => "18005551234",
              "latitude" => "42.42",
              "longitude" => "3.14"
            },
            "connections" => { "bar_code" => "http://test.host/daily_deal_purchases/purchase-with-loc/bar_codes/#{first_voucher.serial_number}.jpg" }
          },
          {
            "serial_number" => second_voucher.serial_number,
            "status" => "active",
            "location" => {
              "name" => "Bob's Games Shop",
              "address_line_1" => "100 Test Road",
              "address_line_2" => "",
              "city" => "Testville",
              "state" => "CA",
              "zip" => "90210",
              "country" => "US",
              "phone_number" => "18005551234",
              "latitude" => "42.42",
              "longitude" => "3.14"
            },
            "connections" => { "bar_code" => "http://test.host/daily_deal_purchases/purchase-with-loc/bar_codes/#{second_voucher.serial_number}.jpg" }
          }
        ]

        assert_equal expected_voucher_array, JSON.parse(@response.body)
      end

      should "blank out serial_number when hide_serial_number_if_bar_code_is_present flag is set" do
        @daily_deal_2.hide_serial_number_if_bar_code_is_present = true
        @daily_deal_2.save!
        first_voucher = @purchase_with_location.daily_deal_certificates.first
        second_voucher = @purchase_with_location.daily_deal_certificates.second
        first_voucher.bar_code = "I exist"
        second_voucher.bar_code = "I exist"
        first_voucher.save!
        second_voucher.save!

        get :daily_deal_certificates, :id => @purchase_with_location.to_param,
            :consumer => { :session => @controller.send(:verifier).generate(:user_id => @consumer.id) },
            :format => "json"

        assert_response :success
        actual = JSON.parse(@response.body)

        assert_equal "", actual[0]["serial_number"]
        assert_equal "", actual[1]["serial_number"]
      end

      should "include redeemed vouchers in the response" do
        @purchase_with_no_location.daily_deal_certificates.first.redeem!
        get :daily_deal_certificates, :id => @purchase_with_no_location.to_param,
            :consumer => { :session => @controller.send(:verifier).generate(:user_id => @consumer.id) },
            :format => "json"
        assert_response :success

        first_voucher = @purchase_with_no_location.daily_deal_certificates.first
        expected_voucher_hash = {
          "serial_number" => first_voucher.serial_number,
          "status" => "redeemed",
          "redeemed_at" => first_voucher.redeemed_at.to_s(:iso8601),
          "connections" => {
            "bar_code" => "http://test.host/daily_deal_purchases/purchase-with-no-loc/bar_codes/#{first_voucher.serial_number}.jpg"
          }
        }

        assert_equal [expected_voucher_hash], JSON.parse(@response.body)
      end
                
    end

    context "with api version 3.0.0" do
      
      setup do
        @request.env["API-Version"] = "3.0.0"        
      end
      
      should "return a 200 Ok with correct session info" do
        get :daily_deal_certificates, :id => @purchase_with_location.to_param,
            :consumer => { :session => @controller.send(:verifier).generate(:user_id => @consumer.id) },
            :format => "json"
        assert_response :success
      end
      
      should "return this purchase's vouchers in JSON format with API-Version 2.0.0 and correct " +
             "session info (example without a location, with a bar code)" do
        get :daily_deal_certificates, :id => @purchase_with_no_location.to_param,
            :consumer => { :session => @controller.send(:verifier).generate(:user_id => @consumer.id) },
            :format => "json"
        assert_response :success

        first_voucher = @purchase_with_no_location.daily_deal_certificates.first
        expected_voucher_hash = {
          "serial_number" => first_voucher.serial_number,
          "status" => "active",
          "connections" => {
            "bar_code" => "http://test.host/daily_deal_purchases/purchase-with-no-loc/bar_codes/#{first_voucher.serial_number}.jpg"
          }
        }
        assert_equal [expected_voucher_hash], JSON.parse(@response.body)
      end

      should "return all a purchase's vouchers in JSON format with API-Version 2.0.0 and a multi-voucher deal" do
        get :daily_deal_certificates, :id => @purchase_with_multi_voucher_deal.to_param,
            :consumer => { :session => @controller.send(:verifier).generate(:user_id => @consumer.id) },
            :format => "json"
        assert_response :success
        assert_equal 4, JSON.parse(@response.body).size
      end
        
      should "return this purchase's vouchers in JSON format with API-Version 2.0.0 and correct " +
             "session info (example with a location, without bar codes)" do
        Store.any_instance.stubs(:latitude).returns("42.42")
        Store.any_instance.stubs(:longitude).returns("3.14")

        get :daily_deal_certificates, :id => @purchase_with_location.to_param,
            :consumer => { :session => @controller.send(:verifier).generate(:user_id => @consumer.id) },
            :format => "json"
        assert_response :success

        first_voucher = @purchase_with_location.daily_deal_certificates.first
        second_voucher = @purchase_with_location.daily_deal_certificates.second

        expected_voucher_array = [
          {
            "serial_number" => first_voucher.serial_number,
            "status" => "active",
            "location" => {
              "name" => "Bob's Games Shop",
              "address_line_1" => "100 Test Road",
              "address_line_2" => "",
              "city" => "Testville",
              "state" => "CA",
              "zip" => "90210",
              "country" => "US",
              "phone_number" => "18005551234",
              "latitude" => "42.42",
              "longitude" => "3.14"
            },
            "connections" => { "bar_code" => "http://test.host/daily_deal_purchases/purchase-with-loc/bar_codes/#{first_voucher.serial_number}.jpg" }
          },
          {
            "serial_number" => second_voucher.serial_number,
            "status" => "active",
            "location" => {
              "name" => "Bob's Games Shop",
              "address_line_1" => "100 Test Road",
              "address_line_2" => "",
              "city" => "Testville",
              "state" => "CA",
              "zip" => "90210",
              "country" => "US",
              "phone_number" => "18005551234",
              "latitude" => "42.42",
              "longitude" => "3.14"
            },
            "connections" => { "bar_code" => "http://test.host/daily_deal_purchases/purchase-with-loc/bar_codes/#{second_voucher.serial_number}.jpg" }
          }
        ]

        assert_equal expected_voucher_array, JSON.parse(@response.body)
      end

      should "blank out serial_number when hide_serial_number_if_bar_code_is_present flag is set" do
        @daily_deal_2.hide_serial_number_if_bar_code_is_present = true
        @daily_deal_2.save!
        first_voucher = @purchase_with_location.daily_deal_certificates.first
        second_voucher = @purchase_with_location.daily_deal_certificates.second
        first_voucher.bar_code = "I exist"
        second_voucher.bar_code = "I exist"
        first_voucher.save!
        second_voucher.save!

        get :daily_deal_certificates, :id => @purchase_with_location.to_param,
            :consumer => { :session => @controller.send(:verifier).generate(:user_id => @consumer.id) },
            :format => "json"

        assert_response :success
        actual = JSON.parse(@response.body)

        assert_equal "", actual[0]["serial_number"]
        assert_equal "", actual[1]["serial_number"]
      end

      should "include redeemed vouchers in the response" do
        @purchase_with_no_location.daily_deal_certificates.first.redeem!
        get :daily_deal_certificates, :id => @purchase_with_no_location.to_param,
            :consumer => { :session => @controller.send(:verifier).generate(:user_id => @consumer.id) },
            :format => "json"
        assert_response :success

        first_voucher = @purchase_with_no_location.daily_deal_certificates.first
        expected_voucher_hash = {
          "serial_number" => first_voucher.serial_number,
          "status" => "redeemed",
          "redeemed_at" => first_voucher.redeemed_at.to_s(:iso8601),
          "connections" => {
            "bar_code" => "http://test.host/daily_deal_purchases/purchase-with-no-loc/bar_codes/#{first_voucher.serial_number}.jpg"
          }
        }

        assert_equal [expected_voucher_hash], JSON.parse(@response.body)
      end
      
    end

  end
end
