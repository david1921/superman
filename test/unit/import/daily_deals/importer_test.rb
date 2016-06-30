require 'ostruct'
require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Import::DailyDeals::ImporterTest
module Import
  module DailyDeals
    class ImporterTest < ActiveSupport::TestCase
      
      def setup
        @doubletakedeals = Factory :publisher, :label => "doubletakedeals"
        Factory :third_party_deals_api_config, :publisher => @doubletakedeals, :api_username => "dt_user", :api_password => "dt_pass"
        @entertainment = Factory :publishing_group, :label => "entertainment"
        @entertainmentdetroiteast = Factory :publisher, :label => "entertainmentdetroiteast", :publishing_group => @entertainment
        @entertainmentdetroitwest = Factory :publisher, :label => "entertainmentdetroitwest", :publishing_group => @entertainment
        Factory :third_party_deals_api_config, :publisher => @entertainmentdetroiteast, :api_username => "edd_east_user", :api_password => "edd_east_pass"
        Factory :third_party_deals_api_config, :publisher => @entertainmentdetroitwest, :api_username => "edd_west_user", :api_password => "edd_west_pass"
      end
      
      context "chaining importers to report errors upward" do
        setup do
          @parent = Importer.new
          @child1 = Importer.new
          @child2 = Importer.new
          @child3 = Importer.new
          @parent.add_child(@child1)
          @parent.add_child(@child2)
        end
        should "not have any errors in default state" do
          assert !@parent.errors?
        end
        should "have children" do
          assert_equal 2, @parent.children.size
        end
        context "error in parent alone" do
          setup do
            @parent.add_error(:parental_error, "oops")
          end
          should "have an error in the parent" do
            assert @parent.errors?
          end
          should "not have errors in the children" do
            assert !@child1.errors?
            assert !@child2.errors?
            assert !@child3.errors?
          end
        end
        context "error in child" do
          setup do
            @child1.add_error(:child_error, "oops")
          end
          should "propagate to parent" do
            assert @parent.errors?
          end
          should "be in erroneous child" do
            assert @child1.errors?
          end
          should "but not in siblings" do
            assert !@child2.errors?
            assert !@child3.errors?
          end
        end
        context "creation with a parent" do
          setup do
            @parent = Importer.new
            @child = Importer.new(@parent)
          end
          should "have children" do
            assert_equal 1, @parent.children.size
          end
        end
        context "alternate attribute names" do
          setup do
            @importer = Importer.new(nil, {:foobar => :barfoo})
          end
          should "not map attributes without alternate names" do
            assert_equal :no_alternate_name, @importer.alternate_attribute_name(:no_alternate_name)
          end
          should "map attributes with alternate names" do
            assert_equal :barfoo, @importer.alternate_attribute_name(:foobar)
          end
        end
      end
      
      context ".import_daily_deals_via_http!" do

        setup do
          FakeWeb.allow_net_connect = false

          ENV['PUBLISHER_LABEL'] = nil
          ENV['PUBLISHING_GROUP_LABEL'] = nil

          UploadConfig.stubs(:new).returns(
            "doubletakedeals" => {
              :daily_deals_import_url => "http://test.url/doubletake", :daily_deals_import_response_url => "http://test.url/doubletake_response"
            }
          )
        end

        teardown do
          FakeWeb.allow_net_connect = true
        end

        should "be a method on Import::DailyDeals::Importer" do
          assert Import::DailyDeals::Importer.respond_to?(:import_daily_deals_via_http!)
        end

        should "raise an ArgumentError if neither PUBLISHER_LABEL nor PUBLISHING_GROUP_LABEL is provided" do
          assert ENV['PUBLISHER_LABEL'].blank?
          assert ENV['PUBLISHING_GROUP_LABEL'].blank?
          assert_raises(ArgumentError) { Import::DailyDeals::Importer.import_daily_deals_via_http! }
        end

        should "run the import for a publisher when ENV['PUBLISHER_LABEL'] is provided" do
          ENV['PUBLISHER_LABEL'] = "doubletakedeals"
          downloaded_filename = Rails.root.join("tmp/doubletakedeals-deals-20110914095959.xml").to_s
          expected_auth_options = { :basic_auth => { :username => "dt_user", :password => "dt_pass" } }
          Import::DailyDealImport::HTTP.expects(:download_to_file).with("http://test.url/doubletake", downloaded_filename, expected_auth_options)
          Import::DailyDeals::DailyDealsImporter.expects(:daily_deals_import).with(@doubletakedeals, downloaded_filename).returns("/some/test/response")
          Import::DailyDealImport::HTTP.expects(:post_file).with("http://test.url/doubletake_response", "/some/test/response", expected_auth_options)          
          Timecop.freeze(Time.zone.parse("2011-09-14 09:59:59")) do
            assert_nothing_raised { Import::DailyDeals::Importer.import_daily_deals_via_http! }
          end
        end

        should "run the import for each publisher in a publishing group when ENV['PUBLISHING_GROUP_LABEL'] is provided" do
          edd_response_url = "https://ws-api.qa.entertainment.com/bidas/?ws=157.2A&action=postDealResponses&vendor=analoganalytics"

          edd_east_downloaded_filename = Rails.root.join("tmp/entertainmentdetroiteast-deals-20110914095959.xml").to_s
          edd_east_auth_options = { :basic_auth => { :username => "edd_east_user", :password => "edd_east_pass" } }
          edd_east_import_url = "https://ws-api.qa.entertainment.com/bidas/?ws=157.2A&action=getDeals&vendor=analoganalytics&marketlabel=entertainmentdetroiteast"
          Import::DailyDealImport::HTTP.expects(:download_to_file).with(edd_east_import_url, edd_east_downloaded_filename, edd_east_auth_options).returns(mock('Response', :code => '200'))
          Import::DailyDeals::DailyDealsImporter.expects(:daily_deals_import).with(@entertainmentdetroiteast, edd_east_downloaded_filename).returns("/some/test/response/east")
          Import::DailyDealImport::HTTP.expects(:post_file).with(edd_response_url, "/some/test/response/east", edd_east_auth_options)          
          
          edd_west_downloaded_filename = Rails.root.join("tmp/entertainmentdetroitwest-deals-20110914095959.xml").to_s
          edd_west_auth_options = { :basic_auth => { :username => "edd_west_user", :password => "edd_west_pass" } }
          edd_west_import_url = "https://ws-api.qa.entertainment.com/bidas/?ws=157.2A&action=getDeals&vendor=analoganalytics&marketlabel=entertainmentdetroitwest"
          Import::DailyDealImport::HTTP.expects(:download_to_file).with(edd_west_import_url, edd_west_downloaded_filename, edd_west_auth_options).returns(mock('Response', :code => '200'))
          Import::DailyDeals::DailyDealsImporter.expects(:daily_deals_import).with(@entertainmentdetroitwest, edd_west_downloaded_filename).returns("/some/test/response/west")
          Import::DailyDealImport::HTTP.expects(:post_file).with(edd_response_url, "/some/test/response/west", edd_west_auth_options)          

          Timecop.freeze(Time.zone.parse("2011-09-14 09:59:59")) do
            ENV['PUBLISHING_GROUP_LABEL'] = "entertainment"
            assert_nothing_raised { Import::DailyDeals::Importer.import_daily_deals_via_http! }
          end
        end

      end

      context "exceptions" do
        setup do
          xml = <<-IMPORT
<?xml version="1.0" encoding="UTF-8" ?><import_request publisher_label="entertainmentgrandrapids" timestamp="20120515032047" xmlns="http://analoganalytics.com/api/daily_deals"><daily_deal><category>O</category><currency/><description>Soak up super savings and get the Daily Deal that keeps your machine clean. For only $21, receive three Express Signature Car Washes from any of the five Southland Auto Wash locations in the Grand Rapids area. It&apos;s a $42 value that saves 50 percent of the cost to keep your car&apos;s shine alive.

Southland Auto Wash has been voted &quot;Best Car Wash&quot; by readers of Grand Rapids Magazine for 12 years in a row. Their Express Signature wash includes bumper-to-bumper cleaning and the full slate of Southland&apos;s exterior car-care services, including under sealant, polish, wax, clear coating, tire dressing and much more. Get three trips to any of the five Southland locations, including three right in GR, one in Wyoming, and one in Comstock Park.

Take your vehicle where more car owners rely on a professional car wash that doesn&apos;t miss an inch. For only $21, make it sparkle with a three-pack of Express Signature Washes from the car-care experts at Southland Auto Wash.</description><enable_email_blast>false</enable_email_blast><expires_on></expires_on><facebook_title_text>$21 for Three Express Signature Car Washes (a $42 Value)</facebook_title_text><featured>true</featured><highlights><highlight>Voted &quot;Best Car Wash&quot; by Grand Rapids Magazine readers for 12 years in a row.
 Environmentally friendly Advanced Water Reclaim systems.
 Valid at all five Grand Rapids-area Southland locations.</highlight></highlights><listing>EP-OPP-0065000000IqtqGAAR</listing><location_required>true</location_required><max_purchase_quantity>4</max_purchase_quantity><merchant><brand_name>Southland Auto Wash</brand_name><listing>EP-MER-0015000000Ps9FDAAZ</listing><locations><location><address_line_1>3755 Alpine NW</address_line_1><address_line_2/><city>Comstock Park</city><latitude/><listing>EP-LOC-a1i50000000LhQLAA0</listing><longitude/><phone_number>(616) 538-6520</phone_number><state>MI</state><zip>49321</zip></location><location><address_line_1>1259 28th Street SW</address_line_1><address_line_2/><city>Wyoming</city><latitude/><listing>EP-LOC-a1i50000000LhQMAA0</listing><longitude/><phone_number>(616) 538-6520</phone_number><state>MI</state><zip>49509</zip></location><location><address_line_1>1000 28th Street SE</address_line_1><address_line_2/><city>Grand Rapids</city><latitude/><listing>EP-LOC-a1i50000000LhQNAA0</listing><longitude/><phone_number>(616) 538-6520</phone_number><state>MI</state><zip>49508</zip></location><location><address_line_1>2730 28th Street SE</address_line_1><address_line_2/><city>Grand Rapids</city><latitude/><listing>EP-LOC-a1i50000000LhQOAA0</listing><longitude/><phone_number>(616) 538-6520</phone_number><state>MI</state><zip>49512</zip></location><location><address_line_1>1325 Leonard NW</address_line_1><address_line_2/><city>Grand Rapids</city><latitude/><listing>EP-LOC-a1i50000000LhQPAA0</listing><longitude/><phone_number>(616) 538-6520</phone_number><state>MI</state><zip>49509</zip></location></locations><logo_url>http://media.entertainment.com/media/DailyDeals/0065000000IqtqGAAR_logo.jpg</logo_url><website_url>southlandautowash.com</website_url></merchant><min_purchase_quantity>1</min_purchase_quantity><photo_url>http://media.entertainment.com/media/DailyDeals/0065000000IqtqGAAR_photo.jpg</photo_url><price>21.0</price><starts_at>2012-06-01 00:05:00</starts_at><ends_at>2012-06-03 23:55:00</ends_at><reviews/><short_description/><terms><term> Offer: Purchase a 3-Pack of Express Signature Washes for only $21 ($42 Value).
* Limit 1 per person.
* 2 may  be purchased as gifts.
* Valid at all locations.
* Not valid until the day after purchase.
* Expires 12/30/12
* Offers may exclude tax, tip, and alcohol, where applicable.
* May not be combined in multiple visits or with any other discount or advertising promotion.
 * No Cash Value or Cash Back.</term></terms><twitter_status_text>$21 for Three Express Signature Car Washes (a $42 Value)</twitter_status_text><upcoming>false</upcoming><value>42.0</value><value_proposition>$21 for Three Express Signature Car Washes (a $42 Value)</value_proposition><value_proposition_subhead/></daily_deal></import_request>
          IMPORT
          Factory(:publisher, :label => "entertainmentgrandrapids")
          @importer = DailyDealsImporter.from_xml(xml)
          @exception = RuntimeError.new('test exception')
        end

        should "handle errors when building the DailyDeal" do
          @importer.daily_deal_importers.first.expects(:populate_model).raises(@exception)
          @importer.import
          @response = Hash.from_xml(@importer.xml_response)
          assert_equal "failure", @response["import_response"]["result"]["status"], @response["import_response"]["result"].inspect
          assert_equal "exception", @response["import_response"]["result"]["error"].first['attribute'], @response["import_response"]["result"].inspect
          assert_equal "test exception", @response["import_response"]["result"]["error"].first['message'], @response["import_response"]["result"].inspect
        end

        should "alert Exceptional when there is an exception" do
          @importer.daily_deal_importers.first.expects(:populate_model).raises(@exception)
          Exceptional.expects(:handle).with(@exception,"Import::DailyDeals::Importer.import: there was a problem populating the DailyDeal.")
          @importer.import
        end
      end
    end
    
    class DoNothingImporter < Importer

      def find_or_new_model()
        DoNothingModel.new
      end

      def populate_model(model)
        # do nothing
      end
    end

    class DoNothingModel
      def save
        # do nothing
      end
      def errors
        []
      end
    end

  end
end

