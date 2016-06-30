require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ApiRequests::WebCouponServiceTest

module ApiRequests
  class WebCouponServiceTest < ActionController::TestCase
    include ApiRequestsTestHelper

    tests ApiRequestsController

    def test_web_coupon_service
      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      assert_difference "Advertiser.count" do
        post :web_coupon_service, {
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
          :web_coupon_label => "1234",
          :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
          :web_coupon_terms => "Must finish pasta to get Cannoli",
          :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
          :web_coupon_image => nil,
          :web_coupon_show_on => "Jan 01,  2008",
          :web_coupon_expires_on => "Jan 31, 2008",
          :web_coupon_featured => "1"
        }
      end
      assert_response :created
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "web_coupon", root.attributes["type"], "XML response service_response[type]"

      elem = root.elements["web_coupon_id"]
      assert_not_nil elem, "XML response root should have a web_coupon_id child"

      offer = Offer.find(elem.text)
      assert_equal "Free Cannoli with Regular Pasta Dinner", offer.message
      assert_equal "Free Cannoli with Regular Pasta Dinner", offer.value_proposition
      assert_equal "Must finish pasta to get Cannoli", offer.terms
      assert_equal "Free Cannoli when you finish your pasta", offer.txt_message
      assert_equal Date.parse("Jan 01, 2008"), offer.show_on
      assert_equal Date.parse("Jan 31, 2008"), offer.expires_on
      assert_equal "1234", offer.label

      advertiser = offer.advertiser
      assert advertiser, "New offer should belong to an advertiser"
      assert_equal "Advertiser One", advertiser.name
      assert_equal "12345-1", advertiser.listing
      assert advertiser.allows_clipping_only_via?("txt", "email")
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

    def test_web_coupon_service_with_version_number_too_low
      @request.env['API-Version'] = "1.1.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      assert_no_difference "Advertiser.count" do
        post :web_coupon_service, {
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
          :web_coupon_label => "1234",
          :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
          :web_coupon_terms => "Must finish pasta to get Cannoli",
          :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
          :web_coupon_image => nil,
          :web_coupon_show_on => "Jan 01,  2008",
          :web_coupon_expires_on => "Jan 31, 2008",
          :web_coupon_featured => "1"
        }
      end
      assert_response :not_acceptable
      assert_equal "application/xml", @response.content_type
      assert_equal "1.1.0", @response.headers['API-Version']
      assert_api_error_response_xml 0, /missing or invalid API-Version/i
    end

    def test_web_coupon_service_with_no_authentication
      for_each_api_version do |api_version|
        assert_no_difference "Advertiser.count" do
          post :web_coupon_service, {
            :format => :xml,
            :publisher_label => "houston_press",
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
            :web_coupon_label => "1234",
            :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
            :web_coupon_terms => "Must finish pasta to get Cannoli",
            :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
            :web_coupon_image => nil,
            :web_coupon_show_on => "Jan 01,  2008",
            :web_coupon_expires_on => "Jan 31, 2008",
            :web_coupon_featured => "1"
          }
        end
        assert_response :unauthorized, api_version
        assert_nil @response.headers['API-Version'], api_version
      end
    end

    def test_web_coupon_service_with_bad_password
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:robert).login, :pass => "foobar")
        assert_no_difference "Advertiser.count" do
          post :web_coupon_service, {
            :format => :xml,
            :publisher_label => "houston_press",
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
            :web_coupon_label => "1234",
            :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
            :web_coupon_terms => "Must finish pasta to get Cannoli",
            :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
            :web_coupon_image => nil,
            :web_coupon_show_on => "Jan 01,  2008",
            :web_coupon_expires_on => "Jan 31, 2008",
            :web_coupon_featured => "1"
          }
        end
        assert_response :unauthorized, api_version
        assert_nil @response.headers['API-Version'], api_version
      end
    end

    def test_web_coupon_service_with_missing_publisher
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")
        assert_no_difference "Advertiser.count" do
          post :web_coupon_service, {
            :format => :xml,
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
            :web_coupon_label => "1234",
            :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
            :web_coupon_terms => "Must finish pasta to get Cannoli",
            :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
            :web_coupon_image => nil,
            :web_coupon_show_on => "Jan 01,  2008",
            :web_coupon_expires_on => "Jan 31, 2008",
            :web_coupon_featured => "1"
          }
        end
        assert_response :forbidden, api_version
        assert_equal api_version, @response.headers['API-Version']
      end
    end

    def test_web_coupon_service_with_invalid_publisher
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")
        assert_no_difference "Advertiser.count" do
          post :web_coupon_service, {
            :format => :xml,
            :publisher_label => "nosuchpublisher",
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
            :web_coupon_label => "1234",
            :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
            :web_coupon_terms => "Must finish pasta to get Cannoli",
            :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
            :web_coupon_image => nil,
            :web_coupon_show_on => "Jan 01,  2008",
            :web_coupon_expires_on => "Jan 31, 2008",
            :web_coupon_featured => "1"
          }
        end
        assert_response :forbidden, api_version
        assert_equal api_version, @response.headers['API-Version']
      end
    end

    def test_web_coupon_service_with_user_publisher_mismatch
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")
        assert_no_difference "Advertiser.count" do
          post :web_coupon_service, {
            :format => :xml,
            :publisher_label => "myspace",
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
            :web_coupon_label => "1234",
            :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
            :web_coupon_terms => "Must finish pasta to get Cannoli",
            :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
            :web_coupon_image => nil,
            :web_coupon_show_on => "Jan 01,  2008",
            :web_coupon_expires_on => "Jan 31, 2008",
            :web_coupon_featured => "1"
          }
        end
        assert_response :forbidden, api_version
        assert_equal api_version, @response.headers['API-Version']
      end
    end

    def test_web_coupon_service_with_invalid_option
      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      assert_no_difference "Advertiser.count" do
        post :web_coupon_service, {
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
          :advertiser_store_zip => "XXXXX",
          :advertiser_store_phone_number => "713-280-2400",
          :web_coupon_label => "1234",
          :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
          :web_coupon_terms => "Must finish pasta to get Cannoli",
          :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
          :web_coupon_image => nil,
          :web_coupon_show_on => "Jan 01,  2008",
          :web_coupon_expires_on => "Jan 31, 2008",
          :web_coupon_featured => "1"
        }
      end
      assert_response :bad_request
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "web_coupon", root.attributes["type"], "XML response service_response[type]"

      error = root.elements["error"]
      assert_not_nil error, "XML response root should have an error child"
      assert_not_nil error.elements["param_name"], "XML response error should have an param_name child"
      assert_equal "advertiser_store_zip", error.elements["param_name"].text, "XML response param_name"
      assert_not_nil error.elements["error_code"], "XML response error should have an error_code child"
      assert_equal "7", error.elements["error_code"].text, "XML response error_code"
      assert_not_nil error.elements["error_string"], "XML response error should have an error_string child"
      assert_equal "Validation errors: advertiser_store_zip is invalid", error.elements["error_string"].text, "XML response error_string"
    end

    def test_web_coupon_service_with_existing_web_coupon_label_and_updated_offer_message_and_expires_on
      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      assert_difference "Advertiser.count" do
        post :web_coupon_service, {
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
          :web_coupon_label => "1234",
          :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
          :web_coupon_terms => "Must finish pasta to get Cannoli",
          :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
          :web_coupon_image => nil,
          :web_coupon_show_on => "Jan 01,  2008",
          :web_coupon_expires_on => "Jan 31, 2008",
          :web_coupon_featured => "1"
        }
      end

      publisher = publishers(:houston_press)
      assert_equal 1, publisher.advertisers.size

      advertiser = publisher.advertisers.first
      assert_equal 1, advertiser.offers.size

      assert_no_difference "Advertiser.count" do
        post :web_coupon_service, {
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
          :web_coupon_label => "1234",
          :web_coupon_message => "Updated Message",
          :web_coupon_terms => "Must finish pasta to get Cannoli",
          :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
          :web_coupon_image => nil,
          :web_coupon_show_on => "Jan 01,  2008",
          :web_coupon_expires_on => "Mar 31, 2008",
          :web_coupon_featured => "1"
        }
      end

      assert_response :success
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "web_coupon", root.attributes["type"], "XML response service_response[type]"

      elem = root.elements["web_coupon_id"]
      assert_not_nil elem, "XML response root should have a web_coupon_id child"

      offer = Offer.find(elem.text)
      assert_equal "Updated Message", offer.message
      assert_equal "Updated Message", offer.value_proposition
      assert_equal "Must finish pasta to get Cannoli", offer.terms
      assert_equal "Free Cannoli when you finish your pasta", offer.txt_message
      assert_equal Date.parse("Jan 01, 2008"), offer.show_on
      assert_equal Date.parse("Mar 31, 2008"), offer.expires_on
      assert_equal "1234", offer.label
      assert !offer.deleted?

      advertiser = publisher.advertisers.first
      assert_equal 1, advertiser.offers.size
    end

    def test_web_coupon_service_with_existing_coupon_id_and_advertiser_id_with_advertiser_name_updated
      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      assert_difference "Advertiser.count" do
        post :web_coupon_service, {
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
          :web_coupon_label => "1234",
          :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
          :web_coupon_terms => "Must finish pasta to get Cannoli",
          :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
          :web_coupon_image => nil,
          :web_coupon_show_on => "Jan 01,  2008",
          :web_coupon_expires_on => "Jan 31, 2008",
          :web_coupon_featured => "1"
        }
      end

      publisher = publishers(:houston_press)
      assert_equal 1, publisher.advertisers.size

      advertiser = publisher.advertisers.first
      assert_equal 1, advertiser.offers.size

      assert_no_difference "Advertiser.count" do
        post :web_coupon_service, {
          :format => :xml,
          :publisher_label => "houstonpress",
          :advertiser_name => "Advertiser One (Updated)",
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
          :web_coupon_label => "1234",
          :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
          :web_coupon_terms => "Must finish pasta to get Cannoli",
          :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
          :web_coupon_image => nil,
          :web_coupon_show_on => "Jan 01,  2008",
          :web_coupon_expires_on => "Jan 31, 2008",
          :web_coupon_featured => "1"
        }
      end

      assert_response :success
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "web_coupon", root.attributes["type"], "XML response service_response[type]"

      elem = root.elements["web_coupon_id"]
      assert_not_nil elem, "XML response root should have a web_coupon_id child"

      offer = Offer.find(elem.text)
      assert_equal "Free Cannoli with Regular Pasta Dinner", offer.message
      assert_equal "Free Cannoli with Regular Pasta Dinner", offer.value_proposition
      assert_equal "Must finish pasta to get Cannoli", offer.terms
      assert_equal "Free Cannoli when you finish your pasta", offer.txt_message
      assert_equal Date.parse("Jan 01, 2008"), offer.show_on
      assert_equal Date.parse("Jan 31, 2008"), offer.expires_on
      assert_equal "1234", offer.label

      publisher = publishers(:houston_press)
      assert_equal 1, publisher.advertisers.size

      advertiser = publisher.advertisers.first
      assert_equal 1, advertiser.offers.size

      advertiser = offer.advertiser
      assert advertiser, "New offer should belong to an advertiser"
      assert_equal "Advertiser One (Updated)", advertiser.name
      assert_equal "12345-1", advertiser.listing
      assert advertiser.allows_clipping_only_via?("txt", "email")
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

    def test_web_coupon_service_with_existing_coupon_label_and_deleted
      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      assert_difference "Advertiser.count" do
        post :web_coupon_service, {
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
          :web_coupon_label => "1234",
          :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
          :web_coupon_terms => "Must finish pasta to get Cannoli",
          :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
          :web_coupon_image => nil,
          :web_coupon_show_on => "Jan 01,  2008",
          :web_coupon_expires_on => "Jan 31, 2008",
          :web_coupon_featured => "1"
        }
      end

      publisher = publishers(:houston_press)
      assert_equal 1, publisher.advertisers.size
      advertiser = publisher.advertisers.first
      assert_equal 1, advertiser.offers.size

      assert_no_difference "Advertiser.count" do
        post :web_coupon_service, {
          :format => :xml,
          :_method => "delete",
          :publisher_label => "houstonpress",
          :advertiser_client_id => "12345",
          :advertiser_location_id => "1",
          :web_coupon_label => "1234"
        }
      end
      assert_response :success
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "web_coupon", root.attributes["type"], "XML response service_response[type]"

      elem = root.elements["web_coupon_id"]
      assert_not_nil elem, "XML response root should have a web_coupon_id child"

      offer = Offer.find(elem.text)
      assert offer.deleted?
    end

    def test_web_coupon_service_with_unknown_coupon_label_and_deleted
      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      assert_difference "Advertiser.count" do
        post :web_coupon_service, {
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
          :web_coupon_label => "1234",
          :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
          :web_coupon_terms => "Must finish pasta to get Cannoli",
          :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
          :web_coupon_image => nil,
          :web_coupon_show_on => "Jan 01,  2008",
          :web_coupon_expires_on => "Jan 31, 2008",
          :web_coupon_featured => "1"
        }
      end

      publisher = publishers(:houston_press)
      assert_equal 1, publisher.advertisers.size
      advertiser = publisher.advertisers.first
      assert_equal 1, advertiser.offers.size

      assert_no_difference "Advertiser.count" do
        post :web_coupon_service, {
          :format => :xml,
          :_method => "delete",
          :publisher_label => "houstonpress",
          :advertiser_client_id => "12345",
          :advertiser_location_id => "1",
          :web_coupon_label => "9999"
        }
      end
      assert_response :bad_request
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "web_coupon", root.attributes["type"], "XML response service_response[type]"

      error = root.elements["error"]
      assert_not_nil error, "XML response root should have an error child"
      assert_not_nil error.elements["param_name"], "XML response error should have an param_name child"
      assert_equal "web_coupon_label", error.elements["param_name"].text, "XML response param_name"
      assert_not_nil error.elements["error_code"], "XML response error should have an error_code child"
      assert_equal "7", error.elements["error_code"].text, "XML response error_code"
      assert_not_nil error.elements["error_string"], "XML response error should have an error_string child"
      assert_equal "Validation errors: web_coupon_label doesn't exist", error.elements["error_string"].text, "XML response error_string"
    end

    def test_web_coupon_service_with_unknown_client_id_and_deleted
      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      assert_no_difference "Advertiser.count" do
        post :web_coupon_service, {
          :format => :xml,
          :_method => "delete",
          :publisher_label => "houstonpress",
          :advertiser_client_id => "12345",
          :advertiser_location_id => "1",
          :web_coupon_label => "9999"
        }
      end
      assert_response :bad_request
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "web_coupon", root.attributes["type"], "XML response service_response[type]"

      error = root.elements["error"]
      assert_not_nil error, "XML response root should have an error child"
      assert_not_nil error.elements["param_name"], "XML response error should have an param_name child"
      assert_equal "advertiser_client_id", error.elements["param_name"].text, "XML response param_name"
      assert_not_nil error.elements["error_code"], "XML response error should have an error_code child"
      assert_equal "7", error.elements["error_code"].text, "XML response error_code"
      assert_not_nil error.elements["error_string"], "XML response error should have an error_string child"
      assert_equal "Validation errors: advertiser_client_id doesn't exist", error.elements["error_string"].text, "XML response error_string"
    end
  end
end