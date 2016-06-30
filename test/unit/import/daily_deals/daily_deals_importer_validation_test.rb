require File.dirname(__FILE__) + "/../../../test_helper"
require Rails.root.join("lib/tasks/import/daily_deal_import")

# hydra class Import::DailyDeals::DailyDealsImporterValidationTest

module Import
  module DailyDeals
    class DailyDealsImporterValidationTest < ActiveSupport::TestCase

      def setup
        Net::HTTP.stubs(:get).returns(nil)
        ::Import::DailyDealImport::HTTP.stubs(:download_to_file).returns("/fake/file/name")

        @successful_deal_xml = read_test_data_file("valid-deal.xml")
        @invalid_deal_xml = read_test_data_file("invalid-deal.xml")
      end

      context "Everything missing" do
        context "empty string" do
          setup do
            @importer = DailyDealsImporter.from_xml("")
          end
          should "detect and report error" do
            assert !@importer.valid?
            assert @importer.errors.include?(ImporterError.new(:import_request, "is missing")), @importer.errors.inspect
          end
        end
        context "nil string" do
          setup do
            @importer = DailyDealsImporter.from_xml(nil)
          end
          should "detect and report error" do
            assert !@importer.valid?
            assert @importer.errors.include?(ImporterError.new(:import_request, "is missing")), @importer.errors.inspect
          end
        end
        context "no import request" do
          setup do
            xml = <<-IMPORT
  <?xml version="1.0" encoding="UTF-8"?>
  <foobar xmlns="http://analoganalytics.com/api/daily_deals"></foobar>
            IMPORT
            @importer = DailyDealsImporter.from_xml(xml)
          end
          should "detect import_request missing" do
            assert !@importer.valid?
            assert @importer.errors.include?(ImporterError.new(:import_request, "is missing")), @importer.errors.inspect
          end
        end
        context "import request but nothing else" do
          setup do
            xml = <<-IMPORT
<?xml version="1.0" encoding="UTF-8"?>
<import_request xmlns="http://analoganalytics.com/api/daily_deals"></import_request>
            IMPORT
            @importer = DailyDealsImporter.from_xml(xml)
          end
          should "correct number of daily_deal_hashes" do
            assert_equal 0, @importer.daily_deal_hashes.size
          end
          should "detect publisher label missing" do
            assert !@importer.valid?
            assert @importer.errors.include?(ImporterError.new(:publisher_label, "is missing")), @importer.errors.inspect
          end
          should "detect timestamp label missing" do
            assert !@importer.valid?
            assert @importer.errors.include?(ImporterError.new(:timestamp, "is missing")), @importer.errors.inspect
          end
        end
        context "missing fields on daily_deal" do
          setup do
            xml = <<-IMPORT
<?xml version="1.0" encoding="UTF-8"?>
<import_request publisher_label="import-test-publisher" timestamp="20110413205005" xmlns="http://analoganalytics.com/api/daily_deals">
  <daily_deal>
  </daily_deal>
</import_request>
            IMPORT
            @publisher = Factory(:publisher, :label => "import-test-publisher")
            @importer = DailyDealsImporter.from_xml(xml)
            @importer.validate
            @daily_deal_importer = @importer.daily_deal_importers.first
            @daily_deal_importer.validate
          end
          should "have daily_deal_hashes" do
            assert_not_nil @importer.daily_deal_hashes
          end
          should "have one daily_deal hash" do
            assert_equal 1, @importer.daily_deal_hashes.size
          end
          should "have daily_deal_importers" do
            assert_not_nil @importer.daily_deal_importers
            assert_equal 1, @importer.daily_deal_importers.size
          end
          should "have an invalid importer even though errors are only on the daily deal handler" do
            assert @daily_deal_importer.errors?
            assert_equal 1, @importer.children.size
            assert @importer.errors?
          end
          should "detect listing label missing" do
            assert @daily_deal_importer.includes_error?(ImporterError.new(:listing, "is missing")), @daily_deal_importer.errors.inspect
          end
          should "detect value_proposition missing" do
            assert @daily_deal_importer.includes_error?(ImporterError.new(:value_proposition, "is missing")), @daily_deal_importer.errors.inspect
          end
          should "detect description missing" do
            assert @daily_deal_importer.includes_error?(ImporterError.new(:description, "is missing")), @daily_deal_importer.errors.inspect
          end
          should "detect terms missing" do
            assert @daily_deal_importer.includes_error?(ImporterError.new(:terms, "is missing")), @daily_deal_importer.errors.inspect
          end
          should "detect at least one term" do
            assert @daily_deal_importer.includes_error?(ImporterError.new(:term, "must be at least one")), @daily_deal_importer.errors.inspect
          end
          should "detect missing photo_url" do
            assert @daily_deal_importer.includes_error?(ImporterError.new(:photo_url, "is missing")), @daily_deal_importer.errors.inspect
          end
          should "detect missing value" do
            assert @daily_deal_importer.includes_error?(ImporterError.new(:value, "is missing")), @daily_deal_importer.errors.inspect
          end
          should "detect missing price" do
            assert @daily_deal_importer.includes_error?(ImporterError.new(:price, "is missing")), @daily_deal_importer.errors.inspect
          end
          should "detect missing starts_at" do
            assert @daily_deal_importer.includes_error?(ImporterError.new(:starts_at, "is missing")), @daily_deal_importer.errors.inspect
          end
          should "detect missing ends_at" do
            assert @daily_deal_importer.includes_error?(ImporterError.new(:ends_at, "is missing")), @daily_deal_importer.errors.inspect
          end
        end
        context "missing fields on advertiser" do
          setup do
            xml = <<-IMPORT
<?xml version="1.0" encoding="UTF-8"?>
<import_request publisher_label="import-test-publisher" timestamp="20110413205005" xmlns="http://analoganalytics.com/api/daily_deals">
  <daily_deal>
    <merchant>
    </merchant>
  </daily_deal>
</import_request>
            IMPORT
            @publisher = Factory(:publisher, :label => "import-test-publisher")
            @importer = DailyDealsImporter.from_xml(xml)
            @daily_deal_importer = @importer.daily_deal_importers.first
            @daily_deal_importer.validate
            @advertiser_importer = @daily_deal_importer.advertiser_importer
          end
          should "detect missing listing" do
            assert @advertiser_importer.includes_error?(ImporterError.new(:listing, "is missing")), @daily_deal_importer.errors.inspect
          end
          should "detect missing brand_name" do
            assert @advertiser_importer.includes_error?(ImporterError.new(:brand_name, "is missing")), @daily_deal_importer.errors.inspect
          end
          should "detect missing logo_url" do
            assert @advertiser_importer.includes_error?(ImporterError.new(:logo_url, "is missing")), @daily_deal_importer.errors.inspect
          end
          should "detect missing locations" do
            assert @advertiser_importer.includes_error?(ImporterError.new(:locations, "is missing")), @daily_deal_importer.errors.inspect
          end
        end
      end

      context "missing fields on location" do
        setup do
          xml = File.read(Rails.root.join("test/unit/import/data/invalid-deal-no-location-listing.xml"))
          @publisher = Factory(:publisher, :label => "import-test-publisher")
          @importer = DailyDealsImporter.from_xml(xml)
          @daily_deal_importer = @importer.daily_deal_importers.first
          @daily_deal_importer.validate
          @store_importer = @daily_deal_importer.advertiser_importer.store_importers.first
        end

        should "detect missing listing" do
          assert @store_importer.includes_error?(ImporterError.new(:listing, "is missing")), @store_importer.errors.inspect
        end
      end

      context "no term elements in terms" do
        setup do
          xml = <<-IMPORT
<?xml version="1.0" encoding="UTF-8"?>
<import_request publisher_label="import-test-publisher" timestamp="20110413205005" xmlns="http://analoganalytics.com/api/daily_deals">
<daily_deal>
  <terms>
  </terms>
</daily_deal>
</import_request>
          IMPORT
          @publisher = Factory(:publisher, :label => "import-test-publisher")
          @importer = DailyDealsImporter.from_xml(xml)
          @importer.validate
          @daily_deal_importer = @importer.daily_deal_importers.first
          @daily_deal_importer.validate
        end

        should "detect missing terms" do
          assert @daily_deal_importer.includes_error?(ImporterError.new(:term, "must be at least one")), @daily_deal_importer.errors.inspect
        end
      end

      context "publisher does not exist" do
        setup do
          @missing_publisher_xml = read_test_data_file("deal-with-invalid-publisher.xml")
          @publisher = Factory(:publisher, :label => "import-test-publisher", :advertiser_has_listing => true)
          @ny = Factory(:market, :publisher => @publisher, :name => "New York")
          @la = Factory(:market, :publisher => @publisher, :name => "Los Angeles")
          @importer = DailyDealsImporter.from_xml(@missing_publisher_xml)
          @importer.import
        end

        should "not be valid" do
          assert !@importer.valid?
        end

        should "have a related error in errors" do
          assert @importer.includes_error?(ImporterError.new(:publisher, "does not exist")), @importer.errors.inspect
        end
      end

      context "invalid store addresses" do
        setup do
          @bad_deal_xml = read_test_data_file("nil-advertiser-case-deal.xml")
          @publisher = Factory.create(:publisher, :label => "kowabunga")
          @importer = DailyDealsImporter.from_xml(@bad_deal_xml)
          AdvertiserImporter.any_instance.stubs(:photo).returns(File.open(File.expand_path('advertiser_logo.png', Rails.root + 'test/fixtures/files')))
          @importer.import
        end

        should "not result in a persisted daily deals" do
          deal = DailyDeal.find_by_publisher_id_and_listing(@publisher.id, "2451")
          assert_nil deal, "No deal should have been saved"
        end

        should "result in a failure message in the response XML" do
          response_hash = HashWithIndifferentAccess.new(Hash.from_xml(@importer.xml_response))
          assert_equal "failure", response_hash[:import_response][:result][:status]
          errors = {}

          response_hash[:import_response][:result][:error].each do |element|
            errors[:country] = element[:message] if element.has_value?("country")
            errors[:zip_code] = element[:message] if element.has_value?("zip_code")
          end

          assert_equal 2, errors.size, "Should be two errors"
          assert_equal "Country does not exist", errors[:country]
          assert_match /Zip code is invalid/, errors[:zip_code]
        end
      end

      context "too many values for fields" do
        setup do
          @bad_deal_xml = read_test_data_file("deal-with-too-many-values-for-fields.xml")
          @publisher = Factory.create(:publisher, :label => "import-test-publisher")
          @importer = DailyDealsImporter.from_xml(@bad_deal_xml)
          @importer.import
          @daily_deal_importer = @importer.daily_deal_importers.first
        end

        should "not result in a persisted daily deals" do
          deal = DailyDeal.find_by_publisher_id_and_listing(@publisher.id, "deal-listing")
          assert_nil deal, "No deal should have been saved"
          deal = DailyDeal.find_by_publisher_id_and_listing(@publisher.id, "deal-listing2")
          assert_nil deal, "No deal should have been saved"
        end

        should "result in a failure message in the response XML" do
          response_hash = HashWithIndifferentAccess.new(Hash.from_xml(@importer.xml_response))
          assert_equal "failure", response_hash[:import_response][:result][:status]
          errors = {}

          fields = %w(listing value_proposition photo_url value price starts_at ends_at
            value_proposition_subhead currency facebook_title_text
            twitter_status_text quantity_available max_purchase_quantity min_purchase_quantity)

          fields.each do |field|
            assert @daily_deal_importer.includes_error?(ImporterError.new(field.to_sym, "has too many values")),
              "#{field} should have too many values: #{@daily_deal_importer.errors.inspect}"
          end
        end
      end

      context "disallowed affiliate handling" do
        context "deals with 'tippr' in the affiliate URL" do

          setup do
            @publisher = Factory :publisher, :label => "import-test-publisher", :advertiser_has_listing => true
            @import_xml = read_test_data_file("valid-deal-with-tippr-as-affiliate.xml")
            @importer = DailyDealsImporter.from_xml(@import_xml)
            @importer.import
          end

          should "not result in a persisted daily deal" do
            deal = DailyDeal.find_by_publisher_id_and_listing(@publisher.id, "tippr-12345")
            assert_nil deal, "No deal should have been saved"
          end

          should "result in a failure message in the response XML" do
            response_hash = HashWithIndifferentAccess.new(Hash.from_xml(@importer.xml_response))
            assert_equal "failure", response_hash[:import_response][:result][:status]
            assert_equal "affiliate_url", response_hash[:import_response][:result][:error][:attribute]
            assert_equal "contains a disallowed affiliate", response_hash[:import_response][:result][:error][:message]
          end

        end
      end
    end
  end
end

