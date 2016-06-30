require File.dirname(__FILE__) + "/../../../test_helper"
require Rails.root.join("lib/tasks/import/daily_deal_import")

# hydra class Import::DailyDeals::DailyDealsImporterTest

module Import
  module DailyDeals
    class DailyDealsImporterTest < ActiveSupport::TestCase

      def setup
        Net::HTTP.stubs(:get).returns(nil)
        ::Import::DailyDealImport::HTTP.stubs(:download_to_file).returns("/fake/file/name")

        @successful_deal_xml = read_test_data_file("valid-deal.xml")
        @invalid_deal_xml = read_test_data_file("invalid-deal.xml")
      end

      context "#daily_deals_import" do
        setup do
          @publisher = Factory.create(:publisher)
          DailyDealsImporter.stubs(:import_file).returns(DailyDealsImporter.new({}))
          DailyDealsImporter.stubs(:create_response_file).returns(nil)
        end

        should "associate a job with the publisher" do
          DailyDealsImporter.daily_deals_import(@publisher, "tmp/doit")
          assert_not_nil @publisher.jobs.find_by_file_name("doit")
        end
      end

      context "from_xml" do
        setup do
          xml = <<-IMPORT
  <?xml version="1.0" encoding="UTF-8"?>
  <sample>
    <nested_items>
      <nested></nested>
      <nested></nested>
      <nested></nested>
    </nested_items>
    <not_nested></not_nested>
    <not_nested></not_nested>
    <not_nested></not_nested>
    <not_nested></not_nested>
  </sample>
          IMPORT
          @hash = HashWithIndifferentAccess.new(Hash.from_xml(xml))
        end
        should "have nested_items with sub items" do
          assert_equal 3, @hash[:sample][:nested_items][:nested].size
        end
        should "have  not_nested items" do
          assert_equal 4, @hash[:sample][:not_nested].size
        end
      end

      context "construction with empty string" do
        setup do
          @importer = DailyDealsImporter.from_xml("")
        end
        should "should still be usable sort of" do
          assert_not_nil @importer
          assert @importer.root_hash.empty?
          assert_equal Hash.new, @importer.import_request
        end
      end

      context "construction with just an import_request" do
        setup do
          @importer = DailyDealsImporter.from_xml("<import_request></import_request>")
        end
        should "not be nil" do
          assert_not_nil @importer
          assert_not_nil @importer.root_hash
          assert_equal Hash.new, @importer.import_request
        end
      end

      context "multiple import requests" do
        setup do
          xml = <<-IMPORT
<?xml version="1.0" encoding="UTF-8"?>
<import_request publisher_label="import-test-publisher" timestamp="20110413205005" xmlns="http://analoganalytics.com/api/daily_deals">
</import_request>
<import_request publisher_label="import-test-publisher" timestamp="20110413205005" xmlns="http://analoganalytics.com/api/daily_deals">
</import_request>
          IMPORT
          @importer = DailyDealsImporter.from_xml(xml)
        end
        should "complain about multiple import requests" do
          assert !@importer.valid?
          assert_match /attempted adding second root element/, @importer.errors.first.message
        end
      end

      context "top level stuff" do
        setup do
          xml = <<-IMPORT
<?xml version="1.0" encoding="UTF-8"?>
<import_request publisher_label="import-test-publisher" timestamp="20110413205005" xmlns="http://analoganalytics.com/api/daily_deals">
  <daily_deal>
    <listing>123</listing>
    <expires_on>2011-07-31</expires_on>
  </daily_deal>
  <daily_deal>
    <listing>abc</listing>
    <expires_on>2011-07-31</expires_on>
  </daily_deal>
</import_request>
          IMPORT
          Factory(:publisher, :label => "import-test-publisher")
          @importer = DailyDealsImporter.from_xml(xml)
          @importer.import
        end
        should "correct number of daily_deal_hashes" do
          assert_equal 2, @importer.daily_deal_hashes.size
        end
        should "have an import request" do
          assert_not_nil @importer.import_request
        end
        should "have correct publisher_label" do
          assert_equal "import-test-publisher", @importer.publisher_label
        end
        should "have correct timestamp" do
          assert_equal "20110413205005", @importer.timestamp
        end
        should "make the right number of daily deal importers" do
          assert_not_nil @importer.daily_deal_importers
          assert_not_nil @importer.daily_deal_importers.first
          assert_not_nil @importer.daily_deal_importers.second
          assert_equal 2, @importer.daily_deal_importers.size
        end
        should "have the correct listing" do
          assert_equal "123", @importer.daily_deal_importers.first.listing
          assert_equal "abc", @importer.daily_deal_importers.second.listing
        end
        should "be able to access publisher" do
          assert_nothing_raised do
            assert_not_nil @importer.publisher
          end
        end
      end

      context "daily deal with side dates" do
        setup do
          setup_analytics_categories
          @publisher = Factory(:publisher, :label => "import-test-publisher", :advertiser_has_listing => true)
          @zone = ActiveSupport::TimeZone.new @publisher.time_zone
          @valid_deal_with_sides = read_test_data_file("valid-deal-with-side-dates.xml")
          @importer = DailyDealsImporter.from_xml(@valid_deal_with_sides)
          @importer.import
          actual = Hash.from_xml(@importer.xml_response)
          assert_equal "success", actual["import_response"]["result"]["status"], actual["import_response"]["result"]["error"]
          @deal = @importer.daily_deals.first
          
        end
        should "have correct main start_at" do
          assert_equal @zone.parse("2011-04-12T06:00:00Z"), @deal.start_at
        end
        should "have correct main ends_at" do
          assert_equal @zone.parse("2011-04-18T05:55:00Z"), @deal.hide_at
        end
        # should "have correct side start_at" do
        #   assert_equal @zone.parse("2011-04-13T07:00:00Z"), @deal.side_start_at
        # end
        # should "have correct side end_at" do
        #   assert_equal @zone.parse("2011-04-15T04:55:00Z"), @deal.side_end_at
        # end
        should "not be featured" do
          assert !@deal.featured
        end
      end
      context "daily deal everything roses" do
        setup do
          setup_analytics_categories
          @publisher = Factory(:publisher, :label => "import-test-publisher", :advertiser_has_listing => true)
          @ny = Factory(:market, :publisher => @publisher, :name => "New York")
          @la = Factory(:market, :publisher => @publisher, :name => "Los Angeles")
          @importer = DailyDealsImporter.from_xml(@successful_deal_xml)
          @importer.import
          actual = Hash.from_xml(@importer.xml_response)
          assert_equal "success", actual["import_response"]["result"]["status"], actual["import_response"]["result"]["error"]
          @deal = @importer.daily_deals.first

        end
        should "be valid" do
          assert @importer.valid?
        end
        should "create the deal in the database" do
          assert !@deal.new_record?
          assert_not_nil ::DailyDeal.find(@deal.id)
        end
        should "correct number of daily_deal_hashes" do
          assert_equal 1, @importer.daily_deal_hashes.size
        end
        should "correct number of daily_deals" do
          assert_equal 1, @importer.daily_deals.size
        end
        should "have correct listing" do
          assert_equal "123", @deal.listing
        end
        should "set the analytics_category" do
          assert_equal "D", @deal.analytics_category.abbreviation
        end
        should "not set the publishers_category" do
          assert @deal.publishers_category.blank?
        end
        should "have correct value proposition" do
          assert_equal "This is the value proposition", @deal.value_proposition
        end
        should "have the correct value proposition subhead" do
          assert_equal "This is the value proposition subhead", @deal.value_proposition_subhead
        end
        should "have the correct description" do
          assert_equal "This is the description", @deal.description(:plain)
        end
        should "have the correct short_description" do
          assert_equal "This is the short description", @deal.short_description
        end
        should "have the correct highlights" do
          expected = <<-EXPECTED
          <ul>
            <li>highlight1</li>
            <li>highlight2</li>
            <li>highlight3</li>
          </ul>
          EXPECTED
          assert_equal expected.gsub(/\s/, ""), @deal.highlights.gsub(/\s/, "")
        end
        should "have the correct reviews" do
          expected = <<-EXPECTED
          <ul>
            <li>review1</li>
            <li>review2</li>
            <li>review3</li>
          </ul>
          EXPECTED
          assert_equal expected.gsub(/\s/, ""), @deal.reviews.gsub(/\s/, "")
        end
        should "have the correct terms" do
          expected = <<-EXPECTED
          <ul>
            <li>term1</li>
            <li>term2</li>
            <li>term3</li>
          </ul>
          EXPECTED
          assert_equal expected.gsub(/\s/, ""), @deal.terms.gsub(/\s/, "")
        end
        should "have correct value" do
          assert_equal 100, @deal.value, "was: #{@deal.value.to_s}"
        end
        should "have correct price" do
          assert_equal 95.95, @deal.price, "was: #{@deal.price.to_s}"
        end
        should "have correct start_at" do
          assert_equal Time.utc(2011, 4, 12, 6, 0, 0), @deal.start_at
        end
        should "have correct hide_at" do
          assert_equal Time.utc(2011, 4, 18, 5, 55, 0), @deal.hide_at
        end
        should "have correct expires_on" do
          assert_equal Time.utc(2011, 07, 31).to_date, @deal.expires_on
        end
        should "have correct facebook title text" do
          assert_equal "$15 for $30 worth of food and drinks at Facebook", @deal.facebook_title_text
        end
        should "have correct twitter status text" do
          assert_equal "$15 for $30 worth of food and drinks at Twitter", @deal.twitter_status_text
        end
        should "be featured" do
          assert @deal.featured_during_lifespan?
        end
        should "not be upcoming" do
          assert !@deal.upcoming?
        end
        should "enable email blast" do
          assert @deal.enable_daily_email_blast?
        end
        should "have correct quantity" do
          assert_equal 1500, @deal.quantity
        end
        should "have correct min purchase quantity" do
          assert_equal 3, @deal.min_quantity
        end
        should "have correct max purchase quantity" do
          assert_equal 10, @deal.max_quantity
        end
        should "have correct location_required" do
          assert_equal false, @deal.location_required?
          end
        should "have correct custom fields" do
          assert_equal "custom value one", @deal.custom_1
          assert_equal "custom value two", @deal.custom_2
          assert_equal "custom value three", @deal.custom_3
        end

        should "have correct affiliate_url" do
          assert_equal "http://deals.nydailynews.com/publishers/nydailynews/daily_deals/6024", @deal.affiliate_url
        end

        should "not have side_* dates since they weren't given" do
          assert_nil @deal.side_start_at
          assert_nil @deal.side_end_at
        end

        context "advertiser aka merchant" do
          should "have correct advertiser" do
            assert_not_nil @deal.advertiser
          end
          should "have correct name" do
            assert_equal "Grotta Azura", @deal.advertiser.name
          end
          should "have correct website url" do
            assert_equal "http://bluegrotta.com", @deal.advertiser.website_url
          end
          should "have correct publisher" do
            assert_equal @publisher, @deal.advertiser.publisher
          end
          should "have stores" do
            assert_equal 1, @deal.advertiser.stores.size
          end
          context "advertisers stores aka locations" do
            setup do
              @store = @deal.advertiser.stores.first
            end
            should "have correct address_line_1" do
              assert_equal "177 Mulberry St.", @store.address_line_1
            end
            should "have correct address_line_2" do
              assert_equal "Unit 1", @store.address_line_2
            end
            should "have correct city" do
              assert_equal "New York", @store.city
            end
            should "have correct state" do
              assert_equal "NY", @store.state
            end
            should "have correct zip" do
              assert_equal "10013", @store.zip
            end
            should "have correct latitude" do
              assert_equal 40.7205, @store.latitude
            end
            should "have correct longitude" do
              assert_equal -73.9969, @store.longitude
            end
            should "have correct phone_number" do
              assert_equal "12125551212", @store.phone_number
            end
          end
        end
        context "markets" do
          should "have the correct markets" do
            assert_equal 2, @deal.markets.size
            assert @deal.markets.include?(@ny)
            assert @deal.markets.include?(@la)
          end
        end
      end

      context "valid daily deal with no min_purchase_quantity, featured,  enable_daily_email_blast, or upcoming specified" do
        setup do
          @publisher = Factory(:publisher, :label => "import-test-publisher", :advertiser_has_listing => true)
          @ny = Factory(:market, :publisher => @publisher, :name => "New York")
          @la = Factory(:market, :publisher => @publisher, :name => "Los Angeles")
          @importer = DailyDealsImporter.from_xml(read_test_data_file("valid-deal-missing-elements-that-have-defaults.xml"))
          @importer.import
          @deal = @importer.daily_deals.first
        end

        should "be valid" do
          assert @importer.valid?
        end

        should "create the deal in the database" do
          assert !@deal.new_record?
          assert_not_nil ::DailyDeal.find(@deal.id)
        end

        should "set the min_quantity to 1" do
          assert_equal 1, @deal.min_quantity
        end
        
        should "set featured to false" do
          assert !@deal.featured?
        end
        
        should "set enable_daily_email_blast to false" do
          assert !@deal.enable_daily_email_blast?
        end
        
        should "set upcoming to false" do
          assert !@deal.upcoming?
        end
      end

      context "generation of import_response" do
        setup do
          @publisher = Factory(:publisher, :label => "import-test-publisher", :advertiser_has_listing => true)
          @ny = Factory(:market, :publisher => @publisher, :name => "New York")
          @la = Factory(:market, :publisher => @publisher, :name => "Los Angeles")
        end
        context "successful response" do
          setup do
            @importer = DailyDealsImporter.from_xml(@successful_deal_xml)
            @importer.import
            @deal = @importer.daily_deals.first
          end
          should "be valid" do
            assert @importer.valid?, "Should be valid, but had #{@importer.errors.size} errors: #{@importer.errors.map(&:to_s).join(", ")}"
          end
          should "generate successful xml" do
            actual_hash = Hash.from_xml(@importer.xml_response)
            assert_equal "success", actual_hash["import_response"]["result"]["status"], actual_hash["import_response"]["result"].inspect
            assert_equal "123", actual_hash["import_response"]["result"]["listing"]
            assert_equal "#{@deal.id}", actual_hash["import_response"]["result"]["record_id"]
          end
        end

        context "response with errors" do
          setup do
            @invalid_xml = read_test_data_file("invalid-deal.xml")
            @importer = DailyDealsImporter.from_xml(@invalid_xml)
            @importer.import
          end

          should "generate correct response xml with errors" do
            actual = Hash.from_xml(@importer.xml_response)
            assert_equal "failure", actual["import_response"]["result"]["status"]
            errors = actual["import_response"]["result"]["error"]
            assert_equal 5, errors.size
            attributes = errors.map { |e| e["attribute"] }
            assert attributes.include?("price")
            assert attributes.include?("brand_name")
            assert attributes.include?("listing")
            assert attributes.include?("address_line_1")
          end
        end

        context "response with active record errors" do
          setup do
            @invalid_xml = read_test_data_file("invalid-deal-with-activerecord-errors.xml")
            @importer = DailyDealsImporter.from_xml(@invalid_xml)
            @importer.import
          end

          should "generate correct response xml with errors" do
            actual = Hash.from_xml(@importer.xml_response)
            assert_equal "import-test-publisher", actual["import_response"]["publisher_label"]
            assert_equal "20110413205005", actual["import_response"]["timestamp"]
            assert_equal "http://analoganalytics.com/api/daily_deals", actual["import_response"]["xmlns"]
            assert_equal "failure", actual["import_response"]["result"]["status"]
            errors = actual["import_response"]["result"]["error"]
            errors_as_tuples = errors.inject([]){|array, error| array << [error["attribute"], error["message"]]}
            [
                ["price", "Price is not a number"],
                ["expires_on", "Expires on must be after hide at"],
                ["expires_on", "Expires on must be after start at"]
            ].each do |attribute, message|
              assert_contains errors_as_tuples, [attribute, message]
            end
            assert_does_not_contain errors.map(&:first), 'advertiser' # invalid advertiser should not generate this response error
          end
        end

        context "errors mixed with no errors" do
          setup do
            @mixed_xml = read_test_data_file("errors-and-no-errors.xml")
            @original_deal_count = DailyDeal.count
            @importer = DailyDealsImporter.from_xml(@mixed_xml)
            @importer.import
            @deal = @importer.daily_deals.first
          end
          should "have the right number of deals" do
            assert_equal 2, @importer.daily_deals.size
          end
          should "have created one deal" do
            assert_equal 1, DailyDeal.count - @original_deal_count
          end
          should "have the right number of deal hashes" do
            assert_equal 2, @importer.daily_deal_hashes.size
          end
          should "have the right number of deal importers" do
            assert_equal 2, @importer.daily_deal_importers.size
          end
          context "response" do
            should "have a response that has both successes and failures" do
              actual = Hash.from_xml(@importer.xml_response)
              assert_equal "success", actual["import_response"]["result"][0]["status"], actual["import_response"]["result"][1]["error"].inspect
              assert_equal "123", actual["import_response"]["result"][0]["listing"]
              assert_equal "#{@deal.id}", actual["import_response"]["result"][0]["record_id"]
              assert_equal "failure", actual["import_response"]["result"][1]["status"]
              errors = actual["import_response"]["result"][1]["error"]
              assert_equal 4, errors.size
              assert_equal Set.new(["listing", "price", "brand_name", "address_line_1"]), Set.new(errors.map { |e| e["attribute"] })
              assert_equal Set.new(["is missing"]), Set.new(errors.map { |e| e["message"] })
            end
          end
        end
      end

      context "updates" do
        context "updating a deal" do
          setup do
            @publisher = Factory(:publisher, :label => "import-test-publisher", :advertiser_has_listing => true)
            @ny = Factory(:market, :publisher => @publisher, :name => "New York")
            @la = Factory(:market, :publisher => @publisher, :name => "Los Angeles")
            original_deal = Factory(:daily_deal, :publisher => @publisher, :listing => "123", :description => "original description", :max_quantity => 7, :start_at => 10.days.from_now, :hide_at => 20.days.from_now)
            original_deal.markets << @ny
            original_deal.markets << @la
            assert_equal 2, original_deal.markets.size

            @importer = DailyDealsImporter.from_xml(@successful_deal_xml)
            @importer.import
            @deal = ::DailyDeal.find(original_deal.id)
          end

          should "have the new description" do
            assert_equal "This is the description", @deal.description(:plain)
          end

          should "not duplicate markets on the deal" do
            assert_equal 2, @deal.markets.size
          end
        end

        context "updating an advertiser" do
          setup do
            @publisher = Factory(:publisher, :label => "import-test-publisher", :advertiser_has_listing => true)
            @ny = Factory(:market, :publisher => @publisher, :name => "New York")
            @la = Factory(:market, :publisher => @publisher, :name => "Los Angeles")
            original_advertiser = Factory(:advertiser, :publisher => @publisher, :listing => "abc-merch", :website_url => "http://somethingfishy.com")
            @importer = DailyDealsImporter.from_xml(@successful_deal_xml)
            @importer.import
            @advertiser = ::Advertiser.find(original_advertiser.id)
          end
          should "have updated the advertiser" do
            assert_equal "http://bluegrotta.com", @advertiser.website_url
          end
        end
        context "updating a store" do
          setup do
            @publisher = Factory(:publisher, :label => "import-test-publisher", :advertiser_has_listing => true)
            @ny = Factory(:market, :publisher => @publisher, :name => "New York")
            @la = Factory(:market, :publisher => @publisher, :name => "Los Angeles")
            @advertiser = Factory(:advertiser, :publisher => @publisher, :listing => "abc-merch")
            store = Factory(:store, :advertiser => @advertiser, :listing => "my-house", :address_line_1 => "3440 SE Sherman")
            @importer = DailyDealsImporter.from_xml(@successful_deal_xml)
            @importer.import
            @store = ::Store.find(store.id)
          end
          should "have imported with errors" do
            assert @importer.valid?
          end
          should "have updated address line 1" do
            assert_equal "177 Mulberry St.", @store.address_line_1
          end
        end
      end

      context "featured deal swapping" do
        setup do
          @deal_xml = read_test_data_file("valid-deal.xml")
          start_at_date = 1.day.ago
          end_at_date = 7.days.from_now
          expires_on_date = 8.days.from_now

          @deal_hash = HashWithIndifferentAccess.new(Hash.from_xml(@deal_xml))
          @deal_hash[:import_request][:daily_deal][:starts_at] = start_at_date.iso8601
          @deal_hash[:import_request][:daily_deal][:ends_at] = end_at_date.iso8601
          @deal_hash[:import_request][:daily_deal][:expires_on] = expires_on_date.iso8601

          @publisher = Factory(:publisher, :label => "import-test-publisher", :advertiser_has_listing => true)
          @ny = Factory(:market, :publisher => @publisher, :name => "New York")

          @original_deal = Factory(:daily_deal, :publisher => @publisher, :listing => "456", :start_at => start_at_date, :hide_at => end_at_date)
          @original_deal.markets << @ny
          assert_equal @ny, @original_deal.markets(true).first

          @original_deal.reload
        end

        should "result in failure if a featured deal already exists and you attempt to upload another during the same time range" do
          @importer = DailyDealsImporter.new(@deal_hash)
          @importer.import
          @original_deal.reload
          assert_equal true, @original_deal.featured
          response_hash = HashWithIndifferentAccess.new(Hash.from_xml(@importer.xml_response))
          assert_equal "failure", response_hash[:import_response][:result][:status]

        end

        should "not un-feature the existing deal if the incoming deal is not valid" do
          deal_hash = HashWithIndifferentAccess.new(Hash.from_xml(@deal_xml))
          deal_hash[:import_request][:daily_deal][:value_proposition] = ""
          @importer = DailyDealsImporter.new(deal_hash)
          assert_nil DailyDeal.find_by_listing("123")
          @importer.import
          imported_deal = DailyDeal.find_by_listing("123")
          assert_nil imported_deal
          assert_equal true, @original_deal.featured
        end

      end
      
      context "valid deal with a market specified that doesn't exist in the DB" do
        setup do
          @publisher = Factory(:publisher, :label => "import-test-publisher", :advertiser_has_listing => true)
          @importer = DailyDealsImporter.from_xml(read_test_data_file("valid-deal-with-new-market.xml"))
          @importer.import
          @deal = @importer.daily_deals.first
        end
        should "be valid" do
          assert @importer.valid?
        end
        should "create the new market in the database" do
          assert_equal ["Sydney"], @deal.publisher.markets.map(&:name)
        end        
        should "assign the market to the deal" do
          assert_equal ["Sydney"], @deal.markets.map(&:name)
        end
      end

      context "category specified which does not exist" do
        setup do
          @publisher = Factory(:publisher, :label => "import-test-publisher", :advertiser_has_listing => true)
          @ny = Factory(:market, :publisher => @publisher, :name => "New York")
          @la = Factory(:market, :publisher => @publisher, :name => "Los Angeles")
          @importer = DailyDealsImporter.from_xml(read_test_data_file("valid-deal-with-unrecognized-category.xml"))
          @importer.import
          @daily_deal_importer = @importer.daily_deal_importers.first
          @deal = @importer.daily_deals.first
        end
        should "be valid" do
          assert @importer.valid?
        end
        should "set the deal analytics category to blank" do
          assert @deal.analytics_category.blank?
        end
      end
      
      context "deals with the term 'gift certificates' in their terms" do
        
        setup do
          @publisher = Factory(:publisher, :label => "import-test-publisher", :advertiser_has_listing => true)
          @importer = DailyDealsImporter.from_xml(read_test_data_file("valid-deal-with-gift-certificate-in-terms.xml"))
          @importer.import
          @deal = @importer.daily_deals.first
        end
        
        should "translate all appearances of that term to 'promotional certificate' instead" do
          expected_terms = %r{\* this promotional certificate is awesome\.

no, seriously\. this promotional certificate will change your life\.
\* term2 promotional
certificate
\* term3 promotional certificate!}
          assert_match expected_terms, @deal.terms_source
        end
        
      end
      
      # context "importing new deals with doubletake branding in their description and urls" do

      #   setup do
      #     @publisher = Factory(:publisher, :label => "import-test-publisher", :advertiser_has_listing => true)
          
      #     @importer = DailyDealsImporter.from_xml(read_test_data_file("valid-deal-with-doubletake-branding.xml"))
      #     @importer.import
      #     @deal = @importer.daily_deals.first
      #     @deal.reload
      #   end
        
      #   should "remove the words 'Double Take' (and variations thereof) from its description, " +
      #          "short description, value proposition and value proposition subhead" do
      #     assert_equal "This is the value proposition from deals!", @deal.value_proposition
      #     assert_equal "deals are great", @deal.value_proposition_subhead
      #     assert_equal "This is the description [] and then some more [] and even more []", @deal.description(:plain)
      #     assert_equal "This is the short description. FTW.", @deal.short_description
      #   end
        
      #   should "blank out the url for advertisers that have the domain doubletakedeals.com" do
      #     assert @deal.advertiser.website_url.blank?
      #   end
        
      # end
      
      # context "updating existing deals with doubletake branding in their description and urls" do

      #   setup do
      #     @publisher = Factory :publisher, :label => "import-test-publisher", :advertiser_has_listing => true
      #     @advertiser = Factory :advertiser, :publisher => @publisher, :name => "Grotta Azura", :listing => "abc-merch"
      #     @deal_before_editing = Factory :daily_deal, :advertiser => @advertiser, :listing => "123", :start_at => 10.days.from_now, :hide_at => 20.days.from_now
          
      #     @importer = DailyDealsImporter.from_xml(read_test_data_file("valid-deal-with-doubletake-branding.xml"))
      #     @importer.import

      #     @deal = @importer.daily_deals.first
      #     @deal.reload
      #     @deal_before_editing.reload
      #   end
        
      #   should "remove the words 'Double Take' (and variations thereof) from its description, " +
      #          "short description, value proposition and value proposition subhead" do
      #     assert_equal "This is the value proposition from deals!", @deal_before_editing.value_proposition
      #     assert_equal "deals are great", @deal_before_editing.value_proposition_subhead
      #     assert_equal "This is the description [] and then some more [] and even more []", @deal_before_editing.description(:plain)
      #     assert_equal "This is the short description. FTW.", @deal_before_editing.short_description
      #   end
        
      #   should "blank out the url for advertisers that have the domain doubletakedeals.com" do
      #     assert @deal_before_editing.advertiser.website_url.blank?
      #   end
        
      # end
      
      context "when the listing specified is also used by another publisher" do
      
        setup do
          @import_publisher = Factory :publisher, :label => "import-test-publisher", :advertiser_has_listing => true
          @other_publisher = Factory :publisher, :label => "some-other-publisher", :advertiser_has_listing => true
          @other_advertiser = Factory :advertiser, :publisher => @other_publisher, :listing => "ADV1"
          @other_deal = Factory :daily_deal, :advertiser => @other_advertiser, :listing => "DUPE-LISTING",
                                :value_proposition => "This is an amazing deal"
          
          @importer = DailyDealsImporter.from_xml(read_test_data_file("valid-deal-with-listing-used-by-other-pub.xml"))
          @importer.import
          @imported_deal = @importer.daily_deals.first
          
          @other_deal.reload
        end
        
        should "be a valid import" do
          assert @importer.valid?
        end

        should "only update the deal of the import publisher, not the other publisher" do
          assert_equal "My awesome deal", @imported_deal.value_proposition
          assert_equal "This is an amazing deal", @other_deal.value_proposition
        end
        
      end
      
      context "input misc entity sanitizing" do
        setup do
          @publisher = Factory :publisher, :label => "import-test-publisher", :advertiser_has_listing => true
          @entity_xml = read_test_data_file("valid-deal-with-entities.xml")
          @importer = DailyDealsImporter.from_xml(@entity_xml)
          @importer.import
          @deal = @importer.daily_deals.first
        end

        should "apply to the description element" do
          assert_equal "Good ol' American home-style, homemade cooking is what you're in for at Moe's Cafe.", @deal.description(:plain)
        end

        should "apply to the short description element" do
          assert_equal "Good ol' short's description", @deal.short_description
        end

        should "apply to the terms element" do
          assert_equal "\n\tGood ol' American home-style, homemade terms is what! You're in for it at Moe's Cafe.\n\tterm2\n\tterm3\n", @deal.terms(:plain)
        end
      end
      
      context "a valid deal with no expires_on" do

        setup do
          @publisher = Factory :publisher, :label => "import-test-publisher", :advertiser_has_listing => true
          @import_xml = read_test_data_file("valid-deal-with-no-expires-on.xml")
          @importer = DailyDealsImporter.from_xml(@import_xml)
          @importer.import
          assert @importer.valid?, @importer.errors
          @deal = @importer.daily_deals.first
          assert @deal.valid?
          @sanitized = "<b>bold</b><i>italic</i>cell\ndiv"
        end

        should "be a valid import" do
          assert @importer.valid?
        end
        
        should "create a valid deal with an expires_on value of nil" do
          assert @deal.valid?
          assert_nil @deal.expires_on
        end
        
      end

      context "input html sanitizing" do
        setup do
          @publisher = Factory :publisher, :label => "import-test-publisher", :advertiser_has_listing => true
          @entity_xml = read_test_data_file("valid-deal-with-html-tags.xml")
          @importer = DailyDealsImporter.from_xml(@entity_xml)
          @importer.import
          @deal = @importer.daily_deals.first
          @deal.reload
        end

        should "apply to the description element" do
          assert_equal "Description with html tags table data", @deal.description(:source)
        end

        should "apply to the short description element" do
          assert_equal "Short description with html tags div content ", @deal.short_description
        end

        should "apply to the terms element" do
          assert_equal "* Term with html tags div content \n* Term with html tags table data\n* Term with html tags<b>bold text</b>\n", @deal.terms(:source)
        end
      end

      context "empty import_request" do
        should "return an empty import_response" do
          publisher = Factory(:publisher, :label => "import-test-publisher")
          importer = DailyDealsImporter.from_xml(<<XML)
<import_request publisher_label="#{publisher.label}" timestamp="20110413205005" xmlns="http://analoganalytics.com/api/daily_deals"/>
XML
          response = Hash.from_xml(importer.xml_response)
          assert_not_nil response['import_response']
          assert_equal publisher.label, response['import_response']['publisher_label']
          assert_nil response['import_response']['result']
        end
      end
    end
  end
end

