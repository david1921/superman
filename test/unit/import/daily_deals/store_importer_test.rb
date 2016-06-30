require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Import::DailyDeals::StoreImporterTest

module Import
  module DailyDeals
    class StoreImporterTest < ActiveSupport::TestCase
      def setup
        @store_hash_no_listing = {
                :address_line_1 => "3440 SE Sherman",
                :city => "Portland",
                :state => "OR",
                :zip => "97214",
                :phone_number => "503-757-5377"
        }
        @store_with_listing = @store_hash_no_listing.merge({
          :listing => "abc123"
        })
      end

      context "make a simple store" do
        setup do
          @advertiser = Factory(:advertiser)
          @importer = StoreImporter.new(nil, @advertiser, @store_hash_no_listing)
          @importer.import
        end
        should "importer should be invalid" do
          assert !@importer.valid?, @importer.errors.inspect
        end
      end

      context "find an existing store" do
        setup do
          @advertiser = Factory(:advertiser)
          @store = Factory(:store, :advertiser => @advertiser, :listing => @store_with_listing[:listing])
          @importer = StoreImporter.new(nil, @advertiser, @store_with_listing)
          @importer.import
        end
        should "setup correct" do
          assert_equal "3440 SE Sherman", @store_with_listing[:address_line_1]
        end
        should "use existing store" do
          assert_equal @store, @importer.store
        end
      end

      context "two stores, two advertisers, one listing" do
        setup do
          @advertiser1 = Factory(:advertiser)
          @advertiser2 = Factory(:advertiser)
          @store1 = Factory(:store, :advertiser => @advertiser1, :listing => @store_with_listing[:listing])
          @store2 = Factory(:store, :advertiser => @advertiser2, :listing => @store_with_listing[:listing])
          @importer = StoreImporter.new(nil, @advertiser2, @store_with_listing)
          @importer.import
        end
        should "use the correct store" do
          assert_equal @store2, @importer.store
        end
      end

      context "Canadian store" do
        should "be valid if country specified in store data" do
          advertiser = Factory(:advertiser)
          @importer = StoreImporter.new(nil, advertiser, @store_with_listing.merge(:country => "CA", :state => "ON", :zip => "K2H 7K9"))
          @importer.import
          canada = Country.find_by_code("CA")
          assert_equal canada, @importer.store.reload.country
          assert @importer.store.valid?, "Store was invalid: #{@importer.store.errors.full_messages.inspect}"
        end
      end
    end
  end
end