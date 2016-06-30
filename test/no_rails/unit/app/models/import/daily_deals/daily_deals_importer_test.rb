require File.dirname(__FILE__) + "/../../../models_helper"

# hydra class Import::DailyDeals::DailyDealsImporterTest
module Import
  module DailyDeals
    class DailyDealsImporterTest < Test::Unit::TestCase
      context "#xml_response" do
        setup do
          @builder = mock(:instruct! => nil)
          @builder.instance_eval do
            def import_response(*args, &block)
              block_given?
            end
          end
          Builder::XmlMarkup.stubs(:new).returns(@builder)
          @importer = DailyDealsImporter.new({})
        end

        context "with no deal importers" do
          should "call builder.import_response without a block" do
            @importer.stubs(:daily_deal_importers).returns([])
            @builder.expects(:import_response).returns(false)
            @importer.xml_response
          end
        end

        context "with some deal importers" do
          should "call builder.import_response with a block" do
            @importer.stubs(:daily_deal_importers).returns([mock, mock])
            @builder.expects(:import_response).returns(true)
            @importer.xml_response
          end
        end
      end
    end
  end
end
