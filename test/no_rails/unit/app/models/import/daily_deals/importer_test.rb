require File.dirname(__FILE__) + "/importer_test_helper"

# hydra class Import::DailyDeals::ImporterTest
module Import
  module DailyDeals
    class ImporterTest < Test::Unit::TestCase
      should "require the class" do
        assert true
      end

      context "self.import_daily_deals_via_http_for_publisher!" do
        context "entertainment publishing group" do
          setup do
            setup_import_daily_deals_via_http_for_publisher!('entertainment')
          end

          should "email import result when POST response body not success" do
            response_file = 'response_file'
            Import::DailyDeals::DailyDealsImporter.stubs(:daily_deals_import).returns(response_file)
            Import::DailyDealImport::HTTP.stubs(:post_file => mock('Response', :body => <<XML)).returns(response_file)
<?xml version="1.0" encoding="UTF-8" ?><Response>Failure</Response>
XML

            Import::DailyDeals::Importer.expects(:deliver_file!).with("DDAcct_Mgmt@entertainment.com", "Deal Import - Response Failed", response_file, 'text/xml')
            Importer.import_daily_deals_via_http_for_publisher!(@publisher)
          end

          should "not send import result by email when successful POST" do
            Import::DailyDeals::DailyDealsImporter.stubs(:daily_deals_import).returns('GET response')
            Import::DailyDealImport::HTTP.stubs(:post_file => mock(:body => <<XML))
<?xml version="1.0" encoding="UTF-8" ?><Response>Success</Response>
XML

            Import::DailyDeals::Importer.expects(:deliver_file!).never
            Importer.import_daily_deals_via_http_for_publisher!(@publisher)
          end

          should "email GET response when not a valid import request" do
            local_file = 'GET response file'
            File.stubs(:expand_path).returns(local_file)
            Import::DailyDeals::DailyDealsImporter.stubs(:daily_deals_import).raises(Exception)
            Import::DailyDeals::Importer.expects(:deliver_file!).with("DDAcct_Mgmt@entertainment.com", "Deal Import - Request Failed", local_file, 'text/xml')
            Importer.import_daily_deals_via_http_for_publisher!(@publisher)
          end

          should "email GET response when response status not 200" do
            local_file = 'GET response file'
            File.stubs(:expand_path).returns(local_file)
            Import::DailyDealImport::HTTP.stubs(:download_to_file).returns(mock(:code => '404'))
            Import::DailyDeals::DailyDealsImporter.expects(:daily_deals_import).never
            Import::DailyDeals::Importer.expects(:deliver_file!).with("DDAcct_Mgmt@entertainment.com", "Deal Import - Request Failed", local_file, 'text/xml')
            Importer.import_daily_deals_via_http_for_publisher!(@publisher)
          end
        end

        context "another publishing group" do
          setup do
            setup_import_daily_deals_via_http_for_publisher!('not-entertainment')
            UploadConfig.stubs(:new).returns({'not-entertainment' => {}})
          end

        end
      end

      context "#validates_presence_of" do
        should "add 'is empty' error when blank" do
          importer = Importer.new()
          importer.validate_presence_of({:brand_name => nil}, :brand_name)
          assert_contains importer.errors, ImporterError.new(:brand_name, 'is empty')
        end

        should "add 'is missing' error when missing" do
          importer = Importer.new()
          importer.validate_presence_of({}, :brand_name)
          assert_contains importer.errors, ImporterError.new(:brand_name, 'is missing')
        end

        should "not add an error when not blank" do
          importer = Importer.new()
          importer.validate_presence_of({:brand_name => 'not blank'}, :brand_name)
          assert !importer.errors?
        end
      end
    end
  end
end
