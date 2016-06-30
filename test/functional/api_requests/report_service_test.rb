require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ApiRequests::ReportServiceTest

module ApiRequests
  class ReportServiceTest < ActionController::TestCase
    include ApiRequestsTestHelper

    tests ApiRequestsController

    setup :clear_txt_offer_cache

    def clear_txt_offer_cache
      TxtOffer.clear_cache
    end

    def test_report_service_with_no_authentication
      for_each_api_version do |api_version|
        get :report_service, {
          :format => :xml,
          :publisher_label => "longislandpress",
          :dates_begin => "2008-12-15",
          :dates_end => "2008-12-16"
        }
        assert_response :unauthorized, api_version
        assert_nil @response.headers['API-Version'], api_version
      end
    end

    def test_report_service_with_bad_password
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:greg).login, :pass => "foobar")
        get :report_service, {
          :format => :xml,
          :publisher_label => "longislandpress",
          :dates_begin => "2008-12-15",
          :dates_end => "2008-12-16"
        }
        assert_response :unauthorized, api_version
        assert_nil @response.headers['API-Version'], api_version
      end
    end

    def test_report_service_with_missing_publisher
      for_each_api_version do |api_version|
        # this tests all api version before 1.2.0
        unless api_version == '1.2.0'
          set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
          get :report_service, {
            :format => :xml,
            :dates_begin => "2008-12-15",
            :dates_end => "2008-12-16"
          }
          assert_response :forbidden, api_version
          assert_equal api_version, @response.headers['API-Version']
        end
      end
    end

    def test_report_service_with_invalid_publisher
      for_each_api_version do |api_version|
        # this tests all api version before 1.2.0
        unless api_version == '1.2.0'
          set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
          get :report_service, {
            :format => :xml,
            :publisher_label => "xxxxxx",
            :dates_begin => "2008-12-15",
            :dates_end => "2008-12-16"
          }
          assert_response :forbidden, api_version
          assert_equal api_version, @response.headers['API-Version']
        end
      end
    end

    def test_report_service_with_user_publisher_mismatch
      for_each_api_version do |api_version|
        # this tests all api version before 1.2.0
        unless api_version = '1.2.0'
          set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
          get :report_service, {
            :format => :xml,
            :publisher_label => "myspace",
            :dates_begin => "2008-12-15",
            :dates_end => "2008-12-16"
          }
          assert_response :forbidden, api_version
          assert_equal api_version, @response.headers['API-Version']
        end
      end
    end

    def test_report_service_version_1_0_0
      create_txt_api_request = lambda do |n, i, t, s|
        api_request = publishers(:li_press).txt_api_requests.create!(:mobile_number => n + i.to_s, :message => "test message #{i}")
        Txt.find_by_source_type_and_source_id('ApiRequest', api_request.id).update_attributes!(:status => s, :created_at => t)
      end
      5.times { |i| create_txt_api_request.call("626674590", i, "2008-12-15 01:23:45", "sent" ) }
      2.times { |i| create_txt_api_request.call("626674591", i, "2008-12-16 01:23:45", "error") }

      create_call_api_request = lambda do |c, m, i, t, s|
        api_request = publishers(:li_press).call_api_requests.create!(
          :consumer_phone_number => c + i.to_s,
          :merchant_phone_number => m + i.to_s
        )
        VoiceMessage.find_by_api_request_id(api_request).update_attributes!(:status => s, :created_at => t)
      end
      7.times { |i| create_call_api_request.call("626674590", "800555120", i, "2008-12-15 04:56:08", "sent" ) }
      1.times { |i| create_call_api_request.call("626674591", "800555121", i, "2008-12-16 09:08:07", "error") }

      set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
      @request.env['API-Version'] = "1.0.0"
      get :report_service, {
        :format => :xml,
        :publisher_label => "longislandpress",
        :dates_begin => "2008-12-15",
        :dates_end => "2008-12-16"
      }
      assert_response :success
      assert_equal "application/xml", @response.content_type
      assert_equal "1.0.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "report", root.attributes["type"], "XML response service_response[type]"
      assert_equal "2008-12-15", root.attributes["dates_begin"], "XML response service_response[dates_begin]"
      assert_equal "2008-12-16", root.attributes["dates_end"], "XML response service_response[dates_end]"

      returned_counts = returning({}) do |hash|
        root.each_element do |elem|
          assert_equal "counts", elem.name
          type = elem.attributes["type"]
          hash[type] = { :success => elem.elements["success_count"].text.to_i, :failure => elem.elements["failure_count"].text.to_i }
        end
      end
      expected_counts = {
          "txt" => { :success => 5, :failure => 2 },
         "call" => { :success => 7, :failure => 1 },
        "email" => { :success => 0, :failure => 0 }
      }
      assert_equal expected_counts, returned_counts, "Report XML counts"
    end

    def test_report_service_version_1_1_0
      publisher = publishers(:li_press)
      create_txt_api_request = lambda do |n, i, t, s, g|
        api_request = publisher.txt_api_requests.create!(
          :mobile_number => n + i.to_s,
          :message => "test message #{i}",
          :created_at => t,
          :report_group => g
        )
        Txt.find_by_source_type_and_source_id('ApiRequest', api_request.id).update_attributes!(:status => s, :created_at => t)
      end
      5.times { |i| create_txt_api_request.call("626674590", i, "2008-12-15 01:23:45", "sent" , nil) }
      2.times { |i| create_txt_api_request.call("626674591", i, "2008-12-16 01:23:46", "error", nil) }
      3.times { |i| create_txt_api_request.call("626674590", i, "2008-12-15 01:23:47", "sent" , "group1") }
      7.times { |i| create_txt_api_request.call("626674591", i, "2008-12-16 01:23:48", "error", " group1 ") }

      create_call_api_request = lambda do |c, m, i, t, s, g|
        api_request = publisher.call_api_requests.create!(
          :consumer_phone_number => c + i.to_s,
          :merchant_phone_number => m + i.to_s,
          :created_at => t,
          :report_group => g
        )
        VoiceMessage.find_by_api_request_id(api_request).update_attributes!(:status => s, :created_at => t)
      end
      7.times { |i| create_call_api_request.call("626674590", "800555120", i, "2008-12-15 04:56:07", "sent" , nil) }
      1.times { |i| create_call_api_request.call("626674591", "800555121", i, "2008-12-16 09:08:08", "error", nil) }
      2.times { |i| create_call_api_request.call("626674590", "800555120", i, "2008-12-15 04:56:09", "sent" , "  group1 ") }
      5.times { |i| create_call_api_request.call("626674591", "800555121", i, "2008-12-16 09:08:10", "error", "group1") }

      set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
      @request.env['API-Version'] = "1.1.0"
      get :report_service, {
        :format => :xml,
        :publisher_label => "longislandpress",
        :dates_begin => "2008-12-15",
        :dates_end => "2008-12-16"
      }

      assert_response :success
      assert_equal "application/xml", @response.content_type
      assert_equal "1.1.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "report", root.attributes["type"], "XML response service_response[type]"
      assert_equal "2008-12-15", root.attributes["dates_begin"], "XML response service_response[dates_begin]"
      assert_equal "2008-12-16", root.attributes["dates_end"], "XML response service_response[dates_end]"

      returned_counts = returning({}) do |a|
        root.each_element do |group|
          assert_equal "group", group.name
          tag = group.attributes["tag"]
          a[tag] = returning({}) do |b|
            group.each_element do |counts|
              assert_equal "counts", counts.name
              type = counts.attributes["type"]
              b[type] = {
                :success => counts.elements["success_count"].text.to_i,
                :failure => counts.elements["failure_count"].text.to_i
              }
            end
          end
        end
      end
      expected_counts = {
        "" => {
          "txt"   => { :success => 5, :failure => 2 },
          "call"  => { :success => 7, :failure => 1 },
          "email" => { :success => 0, :failure => 0 }
        },
        "group1" => {
          "txt"   => { :success => 3, :failure => 7 },
          "call"  => { :success => 2, :failure => 5 },
          "email" => { :success => 0, :failure => 0 }
        }
      }
      assert_equal expected_counts, returned_counts, "Report XML counts"
    end

    def test_report_service_with_missing_dates_begin
      test_report_service_with_invalid_options({ :dates_begin => nil }, 6, "Invalid date")
    end

    def test_report_service_with_invalid_dates_begin
      test_report_service_with_invalid_options({ :dates_begin => "2009-09-0x" }, 6, "Invalid date")
    end

    def test_report_service_with_missing_dates_end
      test_report_service_with_invalid_options({ :dates_end => nil }, 6, "Invalid date")
    end

    def test_report_service_with_invalid_dates_end
      test_report_service_with_invalid_options({ :dates_end => "2009-09-0x" }, 6, "Invalid date")
    end

    def test_report_service_with_api_version_1_2_0_with_no_publisher_label
      api_version = "1.2.0"
      @request.env['API-Version'] = api_version
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")
      get :report_service, {
        :format => :xml,
        :dates_begin => "2008-12-15",
        :dates_end => "2008-12-16"
      }

      assert_response :forbidden, api_version
      assert_equal api_version, @response.headers['API-Version']
    end

    def test_report_service_with_api_version_1_2_0_with_publisher_mismatch
      api_version = "1.2.0"
      @request.env['API-Version'] = api_version
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")
      get :report_service, {
        :format => :xml,
        :publisher_label => "myspace",
        :dates_begin => "2008-12-15",
        :dates_end => "2008-12-16"
      }

      assert_response :forbidden, api_version
      assert_equal api_version, @response.headers['API-Version']
    end

    def test_report_service_with_api_version_1_2_0_with_no_authentication
      api_version = "1.2.0"
      @request.env['API-Version'] = api_version
      get :report_service, {
        :format => :xml,
        :publisher_label => "houstonpress",
        :dates_begin => "2008-12-15",
        :dates_end => "2008-12-16"
      }

      assert_response :unauthorized, api_version
      assert_nil @response.headers['API-Version'], api_version
    end

    def test_report_service_with_api_version_1_2_0_with_no_advertiser_data_for_publishers
      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      get :report_service, {
        :format => :xml,
        :publisher_label => "houstonpress",
        :dates_begin => "2008-12-15",
        :dates_end => "2008-12-16"
      }
      assert_response :success
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "report", root.attributes["type"], "XML response service_response[type]"
      assert_equal "2008-12-15", root.attributes["dates_begin"], "XML response service_response[dates_begin]"
      assert_equal "2008-12-16", root.attributes["dates_end"], "XML response service_response[dates_end]"

      assert_not_nil root.elements["publisher[@label='houstonpress']"]
      assert_nil root.elements["publisher[@label='houstonpress']/advertiser"]
    end

    def test_report_service_with_api_version_1_2_0_with_advertisers_but_no_offer_stats
      user = users(:robert)
      publisher = Publisher.find_by_label("houstonpress")
      advertiser = publisher.advertisers.create!( :listing => '123123-9' )

      assert_equal 1, Publisher.find(publisher.id).advertisers.size

      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      get :report_service, {
        :format => :xml,
        :publisher_label => "houstonpress",
        :dates_begin => "2008-12-15",
        :dates_end => "2008-12-16"
      }
      assert_response :success
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "report", root.attributes["type"], "XML response service_response[type]"
      assert_equal "2008-12-15", root.attributes["dates_begin"], "XML response service_response[dates_begin]"
      assert_equal "2008-12-16", root.attributes["dates_end"], "XML response service_response[dates_end]"

      assert_not_nil root.elements["publisher[@label='houstonpress']"]
      assert_nil root.elements["publisher[@label='houstonpress']/advertiser[@client_id='123123'][@location_id='9']"]
    end

    def test_report_service_with_api_version_1_2_0_with_advertisers_with_offer_stats_with_no_click_data
      user = users(:robert)
      publisher = Publisher.find_by_label("houstonpress")
      advertiser = publisher.advertisers.create!( :listing => '123123-9' )
      offer = advertiser.offers.create!( :message => "my message" )

      assert_equal 1, Publisher.find(publisher.id).advertisers.size

      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      get :report_service, {
        :format => :xml,
        :publisher_label => "houstonpress",
        :dates_begin => "2008-12-15",
        :dates_end => "2008-12-16"
      }
      assert_response :success
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "report", root.attributes["type"], "XML response service_response[type]"
      assert_equal "2008-12-15", root.attributes["dates_begin"], "XML response service_response[dates_begin]"
      assert_equal "2008-12-16", root.attributes["dates_end"], "XML response service_response[dates_end]"

      assert_not_nil root.elements["publisher[@label='houstonpress']"]
      assert_not_nil root.elements["publisher[@label='houstonpress']/advertiser[@client_id='123123'][@location_id='9']"]

      assert_nil root.elements["publisher[@label='houstonpress']/advertiser[@client_id='123123'][@location_id='9']/web_coupon[@id='#{offer.id}']"]
    end

    def test_report_service_with_api_version_1_2_0_with_advertisers_with_offer_stats_with_no_click_data_with_offer_id_not_in_web_coupon_ids
      user = users(:robert)
      publisher = Publisher.find_by_label("houstonpress")
      advertiser = publisher.advertisers.create!( :listing => '123123-9' )
      offer = advertiser.offers.create!( :message => "my message" )

      assert_equal 1, Publisher.find(publisher.id).advertisers.size

      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      get :report_service, {
        :format => :xml,
        :publisher_label => "houstonpress",
        :dates_begin => "2008-12-15",
        :dates_end => "2008-12-16",
        :web_coupon_ids => "#{offer.id+1}, #{offer.id+2}"
      }
      assert_response :success
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "report", root.attributes["type"], "XML response service_response[type]"
      assert_equal "2008-12-15", root.attributes["dates_begin"], "XML response service_response[dates_begin]"
      assert_equal "2008-12-16", root.attributes["dates_end"], "XML response service_response[dates_end]"

      assert_not_nil root.elements["publisher[@label='houstonpress']"]
      assert_nil root.elements["publisher[@label='houstonpress']/advertiser[@client_id='123123'][@location_id='9']"]
    end

    def test_report_service_with_api_version_1_2_0_with_advertisers_with_txt_offer_stats_with_no_click_data
      user = users(:robert)
      publisher = Publisher.find_by_label("houstonpress")
      advertiser = publisher.advertisers.create!( :listing => '123123-9' )
      txt_offer  = advertiser.txt_offers.create!( :keyword => "houtaco", :message => "My message" )

      assert_equal 1, Publisher.find(publisher.id).advertisers.size

      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")



      get :report_service, {
        :format => :xml,
        :publisher_label => "houstonpress",
        :dates_begin => "2008-12-15",
        :dates_end => "2008-12-16"
      }

      assert_response :success
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "report", root.attributes["type"], "XML response service_response[type]"
      assert_equal "2008-12-15", root.attributes["dates_begin"], "XML response service_response[dates_begin]"
      assert_equal "2008-12-16", root.attributes["dates_end"], "XML response service_response[dates_end]"

      assert_not_nil root.elements["publisher[@label='houstonpress']"]
      assert_not_nil root.elements["publisher[@label='houstonpress']/advertiser[@client_id='123123'][@location_id='9']"]

      assert_nil root.elements["publisher[@label='houstonpress']/advertiser[@client_id='123123'][@location_id='9']/txt_coupon[@id='#{txt_offer.id}']"]
    end

    def test_report_service_with_api_version_1_2_0_with_advertisers_with_txt_offer_stats_with_no_click_data_with_txt_offer_id_not_in_txt_coupon_ids
      user = users(:robert)

      publisher = Publisher.find_by_label("houstonpress")
      advertiser = publisher.advertisers.create!( :listing => '123123-9' )
      txt_offer  = advertiser.txt_offers.create!( :keyword => "houtaco", :message => "My message" )

      assert_equal 1, Publisher.find(publisher.id).advertisers.size

      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      get :report_service, {
        :format => :xml,
        :publisher_label => "houstonpress",
        :dates_begin => "2008-12-15",
        :dates_end => "2008-12-16",
        :txt_coupon_ids => "#{txt_offer.id+1}, #{txt_offer.id+2}"
      }

      assert_response :success
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "XML response should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "report", root.attributes["type"], "XML response service_response[type]"
      assert_equal "2008-12-15", root.attributes["dates_begin"], "XML response service_response[dates_begin]"
      assert_equal "2008-12-16", root.attributes["dates_end"], "XML response service_response[dates_end]"

      assert_not_nil root.elements["publisher[@label='houstonpress']"]
      assert_nil root.elements["publisher[@label='houstonpress']/advertiser[@client_id='123123'][@location_id='9']"]
    end

    def test_report_service_version_1_2_0_with_selected_web_coupons_and_selected_txt_coupons
      publisher = publishers(:houston_press)

      advertiser_1 = create_advertiser(publisher,
        :listing => "A1-1",
        :offers => [{
          :label => "A1O1", :dates => Date.new(2008, 11, 15) .. Date.new(2008, 11, 30),
          :impressions => 100, :clicks => 2, :prints => 3, :txts => 4, :emails => 5
        }, {
          :label => "A1O2", :dates => Date.new(2008, 11, 15) .. Date.new(2008, 12, 15),
          :impressions => 200, :clicks => 6, :prints => 7, :txts => 8, :emails => 9
        }],
        :txt_offers => [{
          :label => "A1T1", :dates => Date.new(2008, 11, 30) .. Date.new(2008, 12, 15), :inbound_txts => 30
        }, {
          :label => "A1T2", :dates => Date.new(2008, 11, 15) .. Date.new(2008, 12, 30), :inbound_txts => 40
        }]
      )
      advertiser_2 = create_advertiser(publisher,
        :listing => "A2-2",
        :offers => [{
          :label => "A2O1", :dates => Date.new(2008, 10, 15) .. Date.new(2008, 10, 30),
          :impressions => 500, :clicks => 9, :prints => 8, :txts => 7, :emails => 6
        }, {
          :label => "A2O2", :dates => Date.new(2008, 10, 15) .. Date.new(2008, 10, 30),
          :impressions => 600, :clicks => 5, :prints => 4, :txts => 3, :emails => 2
        }],
        :txt_offers => [{
          :label => "A2T1", :dates => Date.new(2008, 10, 15) .. Date.new(2008, 11, 30), :inbound_txts => 70
        }, {
          :label => "A2T2", :dates => Date.new(2008, 10, 30) .. Date.new(2008, 11, 15), :inbound_txts => 80
        }]
      )
      offer_1_1 = Offer.find_by_label!("A1O1")
      offer_2_1 = Offer.find_by_label!("A2O1")
      txt_offer_1_1 = TxtOffer.find_by_label!("A1T1")
      filter = {
        :web_coupon_ids => "#{offer_1_1.id},#{offer_2_1.id}",
        :txt_coupon_ids => "#{txt_offer_1_1.id}"
      }
      assert_report_1_2_0_results publisher, "2008-10-15", "2008-12-30", filter, "advertiser" => [
        { "client_id" => "A1", "location_id" => "1",
          "web_coupon" => {
            "web_coupon_id" => offer_1_1.id.to_s, "fb_shares" => "0",
            "impressions" => "100", "twitter_shares" => "0", "clicks" => "2", "prints" => "3", "txts" => "4", "emails" => "5"
          },
          "txt_coupon" => {
            "txt_coupon_id" => txt_offer_1_1.id.to_s,
            "inbound_txts" => "30"
          }
        },
        { "client_id" => "A2", "location_id" => "2",
          "web_coupon" => {
            "web_coupon_id" => offer_2_1.id.to_s, "fb_shares" => "0",
            "impressions" => "500", "twitter_shares"=>"0", "clicks" => "9", "prints" => "8", "txts" => "7", "emails" => "6"
          }
        }
      ]
    end

    def test_report_service_version_1_2_0_with_selected_web_coupon_and_no_txt_coupons
      publisher = publishers(:houston_press)
      publisher.advertisers.destroy_all

      advertiser_1 = create_advertiser(publisher,
        :listing => "A1-1",
        :offers => [{
          :label => "A1O1", :dates => Date.new(2008, 11, 15) .. Date.new(2008, 11, 30),
          :impressions => 100, :clicks => 2, :prints => 3, :txts => 4, :emails => 5
        }, {
          :label => "A1O2", :dates => Date.new(2008, 11, 15) .. Date.new(2008, 12, 15),
          :impressions => 200, :clicks => 6, :prints => 7, :txts => 8, :emails => 9
        }],
        :txt_offers => [{
          :label => "A1T1", :dates => Date.new(2008, 11, 30) .. Date.new(2008, 12, 15), :inbound_txts => 30
        }, {
          :label => "A1T2", :dates => Date.new(2008, 11, 15) .. Date.new(2008, 12, 30), :inbound_txts => 40
        }]
      )
      advertiser_2 = create_advertiser(publisher,
        :listing => "A2-2",
        :offers => [{
          :label => "A2O1", :dates => Date.new(2008, 10, 15) .. Date.new(2008, 10, 30),
          :impressions => 500, :clicks => 9, :prints => 8, :txts => 7, :emails => 6
        }, {
          :label => "A2O2", :dates => Date.new(2008, 10, 15) .. Date.new(2008, 10, 30),
          :impressions => 600, :clicks => 5, :prints => 4, :txts => 3, :emails => 2
        }],
        :txt_offers => [{
          :label => "A2T1", :dates => Date.new(2008, 10, 15) .. Date.new(2008, 11, 30), :inbound_txts => 70
        }, {
          :label => "A2T2", :dates => Date.new(2008, 10, 30) .. Date.new(2008, 11, 15), :inbound_txts => 80
        }]
      )
      offer_1_1 = Offer.find_by_label!("A1O1")
      filter = {
        :web_coupon_ids => "#{offer_1_1.id}",
        :txt_coupon_ids => "0"
      }
      assert_report_1_2_0_results publisher, "2008-10-15", "2008-12-30", filter, "advertiser" => {
        "client_id" => "A1", "location_id" => "1",
        "web_coupon" => {
          "web_coupon_id" => offer_1_1.id.to_s, "fb_shares" => "0",
          "impressions" => "100", "twitter_shares"=>"0", "clicks" => "2", "prints" => "3", "txts" => "4", "emails" => "5"
        }
      }
    end

    def test_report_service_version_1_2_0_with_selected_web_coupon_and_all_txt_coupons
      publisher = publishers(:houston_press)
      publisher.advertisers.destroy_all

      advertiser_1 = create_advertiser(publisher,
        :listing => "A1-1",
        :offers => [{
          :label => "A1O1", :dates => Date.new(2008, 11, 15) .. Date.new(2008, 11, 30),
          :impressions => 100, :clicks => 2, :prints => 3, :txts => 4, :emails => 5
        }, {
          :label => "A1O2", :dates => Date.new(2008, 11, 15) .. Date.new(2008, 12, 15),
          :impressions => 200, :clicks => 6, :prints => 7, :txts => 8, :emails => 9
        }],
        :txt_offers => [{
          :label => "A1T1", :dates => Date.new(2008, 11, 30) .. Date.new(2008, 12, 15), :inbound_txts => 30
        }, {
          :label => "A1T2", :dates => Date.new(2008, 11, 15) .. Date.new(2008, 12, 30), :inbound_txts => 40
        }]
      )
      advertiser_2 = create_advertiser(publisher,
        :listing => "A2-2",
        :offers => [{
          :label => "A2O1", :dates => Date.new(2008, 10, 15) .. Date.new(2008, 10, 30),
          :impressions => 500, :clicks => 9, :prints => 8, :txts => 7, :emails => 6
        }, {
          :label => "A2O2", :dates => Date.new(2008, 10, 15) .. Date.new(2008, 10, 30),
          :impressions => 600, :clicks => 5, :prints => 4, :txts => 3, :emails => 2
        }],
        :txt_offers => [{
          :label => "A2T1", :dates => Date.new(2008, 10, 15) .. Date.new(2008, 11, 30), :inbound_txts => 70
        }, {
          :label => "A2T2", :dates => Date.new(2008, 10, 30) .. Date.new(2008, 11, 15), :inbound_txts => 80
        }]
      )
      offer_1_1 = Offer.find_by_label!("A1O1")
      txt_offer_1_1 = TxtOffer.find_by_label!("A1T1")
      txt_offer_1_2 = TxtOffer.find_by_label!("A1T2")
      txt_offer_2_1 = TxtOffer.find_by_label!("A2T1")
      txt_offer_2_2 = TxtOffer.find_by_label!("A2T2")

      filter = {
        :web_coupon_ids => "#{offer_1_1.id}"
      }
      assert_report_1_2_0_results publisher, "2008-10-15", "2008-12-30", filter, "advertiser" => [
        { "client_id" => "A1", "location_id" => "1",
          "web_coupon" => {
            "web_coupon_id" => offer_1_1.id.to_s, "fb_shares" => "0",
            "impressions" => "100", "twitter_shares"=>"0", "clicks" => "2", "prints" => "3", "txts" => "4", "emails" => "5"
          },
          "txt_coupon" => [
            { "txt_coupon_id" => txt_offer_1_1.id.to_s,
              "inbound_txts" => "30"
            },
            { "txt_coupon_id" => txt_offer_1_2.id.to_s,
              "inbound_txts" => "40"
            },
          ]
        },
        { "client_id" => "A2", "location_id" => "2",
          "txt_coupon" => [
            { "txt_coupon_id" => txt_offer_2_1.id.to_s,
              "inbound_txts" => "70"
            },
            { "txt_coupon_id" => txt_offer_2_2.id.to_s,
              "inbound_txts" => "80"
            },
          ]
        }
      ]
    end

    private

    def test_report_service_with_invalid_options(options, error_code, error_text)
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:greg).login, :pass => "monkey")
        options.reverse_merge!({
          :format => :xml,
          :publisher_label => "longislandpress",
          :dates_begin => "2009-08-01",
          :dates_end => "2008-08-31"
        })
        assert_no_difference 'ReportApiRequest.count' do
          get :report_service, options
        end
        assert_response :bad_request
        assert_equal "application/xml", @response.content_type
        assert_equal api_version, @response.headers['API-Version']

        root = REXML::Document.new(@response.body).root
        assert_not_nil root, "XML response should have a root element"
        assert_equal "service_response", root.name, "XML response root element name"
        assert_equal "report", root.attributes["type"], "XML response service_response[type]"

        error = root.elements["error"]
        assert_not_nil error, "XML response root should have an error child"
        assert_not_nil error.elements["param_name"], "XML response error should have an param_name child"
        assert_nil error.elements["param_name"].text, "XML response param_name"
        assert_not_nil error.elements["error_code"], "XML response error should have an error_code child"
        assert_equal error_code.to_s, error.elements["error_code"].text, "XML response error_code"
        assert_not_nil error.elements["error_string"], "XML response error should have an error_string child"
        assert_equal error_text, error.elements["error_string"].text, "XML response error_string"
      end
    end

    def assert_report_1_2_0_results(publisher, dates_begin, dates_end, filter, advertiser_stats)
      @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      get :report_service, {
        :format => :xml,
        :publisher_label => publisher.label,
        :dates_begin => dates_begin,
        :dates_end => dates_end
      }.merge(filter)

      assert_response :success
      assert_equal "application/xml", @response.content_type
      assert_equal "1.2.0", @response.headers['API-Version']

      expected_result = {
        "service_response" => {
          "type" => "report",
          "dates_begin" => dates_begin,
          "dates_end" => dates_end,
          "publisher" => { "label" => publisher.label }.merge(advertiser_stats)
        }
      }
      assert_equal expected_result, Hash.from_xml(@response.body)
    end

    def create_advertiser(publisher, options)
      assert((listing = options[:listing].to_s).present?, "Must have an advertiser listing")
      returning publisher.advertisers.create!(:name => "Advertiser #{listing}", :listing => listing) do |advertiser|
        options[:offers].try(:each) do |offer_options|
          assert((label = offer_options[:label].to_s).present?, "Must have an offer label")
          offer = advertiser.offers.create!(:label => label, :message => "Offer #{label}")

          assert((dates = offer_options[:dates]).is_a?(Range), "Must have offer dates range")
          dates = dates.to_a
          if count = offer_options[:impressions]
            offer.impression_counts.create! :publisher => offer.publisher, :count => count, :created_at => random_time(dates)
          end
          if count = offer_options[:clicks]
            offer.click_counts.create! :publisher => offer.publisher, :count => count, :created_at => random_time(dates)
          end
          offer_options[:prints].try(:times) do |i|
            offer.leads.create! :publisher => offer.publisher, :print_me => true, :created_at => random_time(dates)
          end
          offer_options[:emails].try(:times) do |i|
            offer.leads.create! :publisher => offer.publisher, :email_me => true, :created_at => random_time(dates), :email => "joe@gmail.com"
          end
          offer_options[:txts].try(:times) do |i|
            lead = offer.leads.create!(
              :publisher => offer.publisher,
              :txt_me => true,
              :created_at => random_time(dates),
              :mobile_number => "626-674-5901"
            )
            lead.txts.first.update_attributes! :created_at => random_time(dates), :status => "sent"
          end
        end
        options[:txt_offers].try(:each) do |txt_offer_options|
          assert((label = txt_offer_options[:label].to_s).present?, "Must have an TXT offer label")
          keyword = advertiser.txt_keyword_prefixes.first + label
          txt_offer = advertiser.txt_offers.create!(:label => label, :short_code => "898411", :keyword => keyword, :message => "TXT Offer #{label}")

          assert((dates = txt_offer_options[:dates]).is_a?(Range), "Must have offer dates range")
          dates = dates.to_a
          txt_offer_options[:inbound_txts].try(:times) do |i|
            txt_offer.inbound_txts.create!(
              :message => keyword, :keyword => keyword, :subkeyword => "",
              :server_address => "898411",
              :originator_address => "16266745902",
              :accepted_time => random_time(dates)
            )
          end
        end
      end
    end

    def random_time(dates)
      Time.zone.parse(dates.sample.to_s).beginning_of_day + rand(24).hours + rand(60).minutes
    end
  end
end