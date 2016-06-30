require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ApiRequests::TxtCouponServiceTest

module ApiRequests
  class TxtCouponServiceTest < ActionController::TestCase
    include ApiRequestsTestHelper

    tests ApiRequestsController

    def test_txt_coupon_service
      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")
      listing = "12345"

      assert_difference "Advertiser.count" do
        post :txt_coupon_service, {
          :format => :xml,
          :publisher_label => "houstonpress",
          :advertiser_name => "Advertiser One",
          :advertiser_client_id => "12345",
          :advertiser_location_id => "1",
          :advertiser_coupon_clipping_modes => "txt,email",
          :advertiser_website_url => "http://www.advertiser-one.com/",
          :advertiser_logo => nil,
          :advertiser_industry_codes => "Restaurants: Italian",
          :advertiser_store_address_line_1 => "123 Main Street",
          :advertiser_store_address_line_2 => "Unit 4",
          :advertiser_store_city => "Houston",
          :advertiser_store_state => "TX",
          :advertiser_store_zip => "77002",
          :advertiser_store_phone_number => "713-280-2400",

          :txt_coupon_label => "My Label",
          :txt_coupon_keyword => "houtaco",
          :txt_coupon_message => "my message",
          :txt_coupon_appears_on => "Jan 01, 2009",
          :txt_coupon_expires_on => "Jan 30, 2009"
        }
      end
      assert_response :created
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "txt_coupon", root.attributes["type"], "XML response service_response[type]"

      elem = root.elements["txt_coupon_id"]
      assert_not_nil elem, "XML response root should have a txt_coupon_id child"

      txt_offer = TxtOffer.find(elem.text)
      assert_equal "My Label", txt_offer.label
      assert_equal "HOUTACO", txt_offer.keyword
      assert_equal "my message", txt_offer.message
      assert_equal Date.parse("Jan 01, 2009"), txt_offer.appears_on
      assert_equal Date.parse("Jan 30, 2009"), txt_offer.expires_on

      advertiser = txt_offer.advertiser
      assert advertiser, "New offer should belong to an advertiser"
      assert_equal "Advertiser One", advertiser.name
      assert_equal "12345-1", advertiser.listing
      assert_equal "http://www.advertiser-one.com/", advertiser.website_url

      store = advertiser.store
      assert store, "Advertiser should have a store"
      assert_equal "123 Main Street", store.address_line_1
      assert_equal "Unit 4", store.address_line_2
      assert_equal "Houston", store.city
      assert_equal "TX", store.state
      assert_equal "77002", store.zip
      assert_equal "17132802400", store.phone_number
    end

    def test_txt_coupon_service_with_version_number_too_low
      @request.env['API-Version'] = "1.1.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")
      listing = "12345"

      assert_no_difference "Advertiser.count" do
        post :txt_coupon_service, {
          :format => :xml,
          :publisher_label => "houstonpress",
          :advertiser_name => "Advertiser One",
          :advertiser_client_id => "12345",
          :advertiser_location_id => "1",
          :advertiser_website_url => "http://www.advertiser-one.com/",
          :advertiser_industry_codes => "Restaurants: Italian",
          :advertiser_store_address_line_1 => "123 Main Street",
          :advertiser_store_address_line_2 => "Unit 4",
          :advertiser_store_city => "Houston",
          :advertiser_store_state => "TX",
          :advertiser_store_zip => "77002",
          :advertiser_store_phone_number => "713-280-2400",

          :txt_coupon_label       => "My Label",
          :txt_coupon_keyword     => "taco",
          :txt_coupon_message     => "my message",
          :txt_coupon_appears_on  => "Jan 01, 2009",
          :txt_coupon_expires_on  => "Jan 30, 2009"
        }
      end
      assert_response :not_acceptable
      assert_equal "application/xml", @response.content_type
      assert_equal "1.1.0", @response.headers['API-Version']
      assert_api_error_response_xml 0, /missing or invalid API-Version/i
    end

    def test_txt_coupon_service_with_no_authentication
      for_each_api_version do |api_version|
        assert_no_difference "Advertiser.count" do
          post :txt_coupon_service, {
            :format => :xml,
            :publisher_label => "houstonpress",
            :advertiser_name => "Advertiser One",
            :advertiser_client_id => "12345",
            :advertiser_location_id => "1",
            :advertiser_website_url => "http://www.advertiser-one.com/",
            :advertiser_industry_codes => "Restaurants: Italian",
            :advertiser_store_address_line_1 => "123 Main Street",
            :advertiser_store_address_line_2 => "Unit 4",
            :advertiser_store_city => "Houston",
            :advertiser_store_state => "TX",
            :advertiser_store_zip => "77002",
            :advertiser_store_phone_number => "713-280-2400",

            :txt_coupon_label       => "My Label",
            :txt_coupon_keyword     => "taco",
            :txt_coupon_message     => "my message",
            :txt_coupon_appears_on  => "Jan 01, 2009",
            :txt_coupon_expires_on  => "Jan 30, 2009"
          }
        end
        assert_response :unauthorized, api_version
        assert_nil @response.headers['API-Version'], api_version
      end
    end

    def test_txt_coupon_service_with_invalid_option
      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      assert_no_difference "Advertiser.count" do
        post :txt_coupon_service, {
          :format => :xml,
          :publisher_label => "houstonpress",
          :advertiser_name => "Advertiser One",
          :advertiser_client_id => "12345",
          :advertiser_location_id => "1",
          :advertiser_website_url => "http://www.advertiser-one.com/",
          :advertiser_industry_codes => "Restaurants: Italian",
          :advertiser_store_address_line_1 => "123 Main Street",
          :advertiser_store_address_line_2 => "Unit 4",
          :advertiser_store_city => "Houston",
          :advertiser_store_state => "TX",
          :advertiser_store_zip => "XXXXX",
          :advertiser_store_phone_number => "713-280-2400",

          :txt_coupon_label       => "My Label",
          :txt_coupon_keyword     => "taco",
          :txt_coupon_message     => "my message",
          :txt_coupon_appears_on  => "Jan 01, 2009",
          :txt_coupon_expires_on  => "Jan 30, 2009"
        }
      end
      assert_response :bad_request
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "txt_coupon", root.attributes["type"], "XML response service_response[type]"

      error = root.elements["error"]
      assert_not_nil error, "XML response root should have an error child"
      assert_not_nil error.elements["param_name"], "XML response error should have an param_name child"
      assert_equal "advertiser_store_zip", error.elements["param_name"].text, "XML response param_name"
      assert_not_nil error.elements["error_code"], "XML response error should have an error_code child"
      assert_equal "7", error.elements["error_code"].text, "XML response error_code"
      assert_not_nil error.elements["error_string"], "XML response error should have an error_string child"
      assert_equal "Validation errors: advertiser_store_zip is invalid", error.elements["error_string"].text, "XML response error_string"
    end

    def test_txt_coupon_service_with_bad_password
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:robert).login, :pass => "foobar")
        assert_no_difference "Advertiser.count" do
          post :txt_coupon_service, {
            :format => :xml,
            :publisher_label => "houstonpress",
            :advertiser_name => "Advertiser One",
            :advertiser_client_id => "12345",
            :advertiser_location_id => "1",
            :advertiser_coupon_clipping_modes => "txt,email",
            :advertiser_website_url => "http://www.advertiser-one.com/",
            :advertiser_logo => nil,
            :advertiser_industry_codes => "Restaurants: Italian",
            :advertiser_store_address_line_1 => "123 Main Street",
            :advertiser_store_address_line_2 => "Unit 4",
            :advertiser_store_city => "Houston",
            :advertiser_store_state => "TX",
            :advertiser_store_zip => "77002",
            :advertiser_store_phone_number => "713-280-2400",

            :txt_coupon_label       => "My Label",
            :txt_coupon_keyword     => "taco",
            :txt_coupon_message     => "my message",
            :txt_coupon_appears_on  => "Jan 01, 2009",
            :txt_coupon_expires_on  => "Jan 30, 2009"
          }
        end
        assert_response :unauthorized, api_version
        assert_nil @response.headers['API-Version'], api_version
      end
    end

    def test_txt_coupon_service_with_missing_publisher
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")
        assert_no_difference "Advertiser.count" do
          post :txt_coupon_service, {
            :format => :xml,
            :advertiser_name => "Advertiser One",
            :advertiser_client_id => "12345",
            :advertiser_location_id => "1",
            :advertiser_website_url => "http://www.advertiser-one.com/",
            :advertiser_industry_codes => "Restaurants: Italian",
            :advertiser_store_address_line_1 => "123 Main Street",
            :advertiser_store_address_line_2 => "Unit 4",
            :advertiser_store_city => "Houston",
            :advertiser_store_state => "TX",
            :advertiser_store_zip => "77002",
            :advertiser_store_phone_number => "713-280-2400",

            :txt_coupon_label       => "My Label",
            :txt_coupon_keyword     => "taco",
            :txt_coupon_message     => "my message",
            :txt_coupon_appears_on  => "Jan 01, 2009",
            :txt_coupon_expires_on  => "Jan 30, 2009"
          }
        end
        assert_response :forbidden, api_version
        assert_equal api_version, @response.headers['API-Version']
      end
    end

    def test_txt_coupon_service_with_invalid_publisher
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")
        assert_no_difference "Advertiser.count" do
          post :txt_coupon_service, {
            :format => :xml,
            :publisher_label => "nosuchpublisher",
            :advertiser_name => "Advertiser One",
            :advertiser_client_id => "12345",
            :advertiser_location_id => "1",
            :advertiser_website_url => "http://www.advertiser-one.com/",
            :advertiser_industry_codes => "Restaurants: Italian",
            :advertiser_store_address_line_1 => "123 Main Street",
            :advertiser_store_address_line_2 => "Unit 4",
            :advertiser_store_city => "Houston",
            :advertiser_store_state => "TX",
            :advertiser_store_zip => "77002",
            :advertiser_store_phone_number => "713-280-2400",

            :txt_coupon_label => "My Label",
            :txt_coupon_keyword => "taco",
            :txt_coupon_message => "my message",
            :txt_coupon_appears_on => "Jan 01, 2009",
            :txt_coupon_expires_on => "Jan 30, 2009"
          }
        end
        assert_response :forbidden, api_version
        assert_equal api_version, @response.headers['API-Version']
      end
    end

    def test_txt_coupon_service_with_user_publisher_mismatch
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")
        assert_no_difference "Advertiser.count" do
          post :txt_coupon_service, {
            :format => :xml,
            :publisher_label => "myspace",
            :advertiser_name => "Advertiser One",
            :advertiser_client_id => "12345",
            :advertiser_location_id => "1",
            :advertiser_website_url => "http://www.advertiser-one.com/",
            :advertiser_industry_codes => "Restaurants: Italian",
            :advertiser_store_address_line_1 => "123 Main Street",
            :advertiser_store_address_line_2 => "Unit 4",
            :advertiser_store_city => "Houston",
            :advertiser_store_state => "TX",
            :advertiser_store_zip => "77002",
            :advertiser_store_phone_number => "713-280-2400",

            :txt_coupon_label => "My Label",
            :txt_coupon_keyword => "taco",
            :txt_coupon_message => "my message",
            :txt_coupon_appears_on => "Jan 01, 2009",
            :txt_coupon_expires_on => "Jan 30, 2009"
          }
        end
        assert_response :forbidden, api_version
        assert_equal api_version, @response.headers['API-Version']
      end
    end

    def test_txt_coupon_service_with_existing_txt_coupon_label
      advertiser = publishers(:houston_press).advertisers.create!(
        :name => "Advertiser One",
        :listing => "12345-1",
        :coupon_clipping_modes => %w{ txt email },
        :website_url => "http://www.advertiser-one.com/",
        :logo => nil
      )
      advertiser.stores.create!(
        :address_line_1 => "123 Main Street",
        :address_line_2 => "Unit 4",
        :city => "Houston",
        :state => "TX",
        :zip => "77002",
        :phone_number => "713-280-2400"
      )
      txt_offer = advertiser.txt_offers.create!(
        :label => "42",
        :keyword => "HOUONE",
        :message => "Message One",
        :appears_on => "Jan 01, 2008",
        :expires_on => "Jan 31, 2008"
      )
      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      assert_no_difference "Advertiser.count" do
        post :txt_coupon_service, {
          :format => :xml,
          :publisher_label => "houstonpress",
          :advertiser_name => "Advertiser Two",
          :advertiser_client_id => "12345",
          :advertiser_location_id => "1",
          :advertiser_website_url => "http://www.advertiser-two.com/",
          :advertiser_logo => nil,
          :advertiser_industry_codes => "Restaurants: Chinese",
          :advertiser_store_address_line_1 => "987 Main Street",
          :advertiser_store_address_line_2 => "Unit 6",
          :advertiser_store_city => "Ithaca",
          :advertiser_store_state => "NY",
          :advertiser_store_zip => "14850",
          :advertiser_store_phone_number => "607-123-4567",
          :txt_coupon_label => "42",
          :txt_coupon_message => "Message Two",
          :txt_coupon_appears_on => "Feb 01, 2008",
          :txt_coupon_expires_on => "Feb 28, 2008"
        }
      end
      assert_response :success
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "txt_coupon", root.attributes["type"], "XML response service_response[type]"

      elem = root.elements["txt_coupon_id"]
      assert_not_nil elem, "XML response root should have a txt_coupon_id child"

      advertiser.reload.store.reload
      assert_equal "12345-1", advertiser.listing
      assert_equal "http://www.advertiser-two.com/", advertiser.website_url
      assert_equal "987 Main Street", advertiser.store.address_line_1
      assert_equal "Unit 6", advertiser.store.address_line_2
      assert_equal "Ithaca", advertiser.store.city
      assert_equal "NY", advertiser.store.state
      assert_equal "14850", advertiser.store.zip
      assert_equal "16071234567", advertiser.store.phone_number
      assert advertiser.allows_clipping_only_via?(:txt, :email), "Coupon clipping modes should not change"

      txt_offer.reload
      assert_equal "42", txt_offer.label
      assert_equal "Message Two", txt_offer.message
      assert_equal Date.new(2008, 2,  1), txt_offer.appears_on
      assert_equal Date.new(2008, 2, 28), txt_offer.expires_on
      assert !txt_offer.deleted, "TXT offer should not be deleted"
    end

    def test_web_coupon_service_with_existing_coupon_label_and_deleted
      advertiser = publishers(:houston_press).advertisers.create!(
        :name => "Advertiser One",
        :listing => "12345-1",
        :coupon_clipping_modes => %w{ txt email },
        :website_url => "http://www.advertiser-one.com/",
        :logo => nil
      )
      advertiser.stores.create!(
        :address_line_1 => "123 Main Street",
        :address_line_2 => "Unit 4",
        :city => "Houston",
        :state => "TX",
        :zip => "77002",
        :phone_number => "713-280-2400"
      )
      txt_offer = advertiser.txt_offers.create!(
        :label => "42",
        :keyword => "HOUONE",
        :message => "Message One",
        :appears_on => "Jan 01, 2008",
        :expires_on => "Jan 31, 2008"
      )
      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      assert_no_difference "Advertiser.count" do
        post :txt_coupon_service, {
          :format => :xml,
          :_method => "delete",
          :publisher_label => "houstonpress",
          :advertiser_client_id => "12345",
          :advertiser_location_id => "1",
          :txt_coupon_label => "42"
        }
      end
      assert_response :success
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "txt_coupon", root.attributes["type"], "XML response service_response[type]"

      elem = root.elements["txt_coupon_id"]
      assert_not_nil elem, "XML response root should have a web_coupon_id child"

      assert_equal txt_offer.reload.id.to_s, elem.text
      assert txt_offer.deleted, "TXT offer should have deleted flag set"
    end

  end
end