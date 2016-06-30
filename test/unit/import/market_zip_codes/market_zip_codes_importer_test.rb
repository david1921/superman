require File.dirname(__FILE__) + "/../../../test_helper"
require Rails.root.join("lib/tasks/import/daily_deal_import")

# hydra class Import::MarketZipCodes::MarketZipCodesImporterTest

module Import
  module MarketZipCodes
    class MarketZipCodesImporterTest < ActiveSupport::TestCase

      def importer_for_testing(publisher, csv_import_file_path)
        importer = MarketZipCodesImporter.new(publisher, csv_import_file_path)
        importer.stubs(:create_response_file).returns(nil)
        importer
      end

      context "market zip code import" do
        setup do
          @publisher = Factory(:publisher, :name => "Kowabunga", :label => "kowabunga")
          @valid_import_csv_file_path = "#{data_file_path}/kowabunga_market_zip_codes-08-26-2011.csv"
        end

        context "when successful" do
          should "generate a response file with no errors" do
            importer = importer_for_testing(@publisher, @valid_import_csv_file_path)
            importer.import
            response_xml = Hash.from_xml(importer.xml_response)
            assert_equal "success", response_xml["market_zip_code_import_response"]["status"]
            assert_nil response_xml["market_zip_code_import_response"]["errors"]
          end

          should "expose the response file name" do
            importer = importer_for_testing(@publisher, @valid_import_csv_file_path)
            importer.import
            assert_equal "test/unit/import/data/kowabunga_market_zip_codes-08-26-2011-response.xml", importer.response_file_name
          end

          should "associate a job with the publisher" do
            importer = importer_for_testing(@publisher, @valid_import_csv_file_path)
            importer.import
            assert_not_nil @publisher.jobs.find_by_file_name("kowabunga_market_zip_codes-08-26-2011.csv")
          end
        end

        context "when unsuccessful" do
          should "generate a response file with an error if the CSV is not valid" do
            csv_file_path_not_parseable = "#{data_file_path}/notparseable_market_zip_codes-08-26-2011.csv"
            importer = importer_for_testing(@publisher, csv_file_path_not_parseable)
            importer.import
            response_xml = Hash.from_xml(importer.xml_response)
            assert_equal "errors", response_xml["market_zip_code_import_response"]["status"]
            assert_equal "Row 2 is not valid. No changes have been applied.", response_xml["market_zip_code_import_response"]["errors"]["error"]
          end

          should "generate a response file with an error if a state code is not valid" do
            import_csv_file_path = "#{data_file_path}/invalidstatecode_market_zip_codes-08-26-2011.csv"
            importer = importer_for_testing(@publisher, import_csv_file_path)
            importer.import
            response_xml = Hash.from_xml(importer.xml_response)
            assert_equal "errors", response_xml["market_zip_code_import_response"]["status"]
            assert_equal "State code is invalid", response_xml["market_zip_code_import_response"]["errors"]["error"]
          end
        end

        context "when market already exists" do
          setup do
            @ny_market = Factory(:market, :name => 'New York', :publisher_id => @publisher.id)
            @valid_import_csv_file_path = "#{data_file_path}/kowabunga_market_zip_codes-08-26-2011.csv"
          end

          should "create new market zip codes when they do not already exist" do
            assert_nil MarketZipCode.find_by_market_id_and_zip_code(@ny_market.id, "10001")
            importer = importer_for_testing(@publisher, @valid_import_csv_file_path)
            importer.import
            assert MarketZipCode.find_by_market_id_and_zip_code(@ny_market.id, "10001")
          end

          should "leave existing market zip codes that already exist and are in the import file" do
            Factory(:market_zip_code, :market_id => @ny_market.id, :zip_code => "10001")
            assert MarketZipCode.find_by_market_id_and_zip_code(@ny_market.id, "10001")
            importer = importer_for_testing(@publisher, @valid_import_csv_file_path)
            importer.import
            assert MarketZipCode.find_by_market_id_and_zip_code(@ny_market.id, "10001")
          end

          should "change an existing market zip code to point at a different market" do
            chinatown = Factory(:market, :publisher_id => @publisher.id)
            Factory(:market_zip_code, :market_id => chinatown.id, :zip_code => "10001")
            assert MarketZipCode.find_by_market_id_and_zip_code(chinatown.id, "10001")

            importer = importer_for_testing(@publisher, @valid_import_csv_file_path)
            importer.import

            assert MarketZipCode.find_by_market_id_and_zip_code(@ny_market.id, "10001")
            assert_nil MarketZipCode.find_by_market_id_and_zip_code(chinatown.id, "10001")
          end

          should "change an existing market zip code's state code if it has changed'" do
            chinatown = Factory(:market, :publisher_id => @publisher.id)
            Factory(:market_zip_code, :market_id => @ny_market.id, :zip_code => "10001", :state_code => "VT")
            assert MarketZipCode.find_by_market_id_and_zip_code_and_state_code(@ny_market.id, "10001", "VT")

            importer = importer_for_testing(@publisher, @valid_import_csv_file_path)
            importer.import

            assert MarketZipCode.find_by_market_id_and_zip_code_and_state_code(@ny_market.id, "10001", "NY")
          end
          
          should "add info about missing zip codes if they already exist and are not in the import file" do
            Factory(:market_zip_code, :market_id => @ny_market.id, :zip_code => "12345")
            assert MarketZipCode.find_by_market_id_and_zip_code(@ny_market.id, "12345")
            importer = importer_for_testing(@publisher, @valid_import_csv_file_path)
            importer.import
            response_xml = Hash.from_xml(importer.xml_response)
            assert MarketZipCode.find_by_market_id_and_zip_code(@ny_market.id, "12345")
            assert_equal "12345 - New York", response_xml["market_zip_code_import_response"]["existing_zip_codes_not_in_import"]["zip_code_and_market"]
          end
        end

        context "when market does not already exist" do
          should "create a new market" do
            assert_nil Market.find_by_publisher_id_and_name(@publisher.id, "Boston")
            importer = importer_for_testing(@publisher, @valid_import_csv_file_path)
            importer.import
            assert Market.find_by_publisher_id_and_name(@publisher.id, "Boston")
          end

          should "add new market zip codes for the market" do
            assert MarketZipCode.all.empty?
            importer = importer_for_testing(@publisher, @valid_import_csv_file_path)
            importer.import
            boston_market = Market.find_by_publisher_id_and_name(@publisher, "Boston")
            boston_market_zips = MarketZipCode.find_all_by_market_id(boston_market.id)
            assert_equal false, boston_market_zips.empty?

            boston_market_zips.each do |mzc|
              assert_equal boston_market.id, mzc.market_id
              assert mzc.zip_code
              assert_equal "MA", mzc.state_code
            end
          end
        end

        context "when an error occurs" do
          setup do
            @import_csv_file_path = "#{data_file_path}/onebadline_market_zip_codes-08-26-2011.csv"
          end

          should "not create any markets" do
            assert_difference('Market.count', 0) do
              importer = importer_for_testing(@publisher, @import_csv_file_path)
              importer.import
            end
          end

          should "not create any market zip codes" do
            assert_difference('MarketZipCode.count', 0) do
              importer = importer_for_testing(@publisher, @import_csv_file_path)
              importer.import
            end
          end

          should "not update any market zip codes" do
            boston_market = Factory(:market, :name => "Boston", :publisher_id => @publisher.id)
            boston_market_zip = Factory(:market_zip_code, :market_id => boston_market.id, :zip_code => "10001")

            importer = importer_for_testing(@publisher, @import_csv_file_path)
            importer.import

            boston_market_zip.reload
            assert_equal boston_market.id, boston_market_zip.market_id
          end

        end
      end
    end
  end
end