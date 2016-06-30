require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Import::DailyDeals::AdvertiserImporterTest
module Import
  module DailyDeals
    class AdvertiserImporterTest < ActiveSupport::TestCase

      context "importing advertisers" do

        setup do
          @advertiser_hash_without_listing = {
              :brand_name => "Coco Puffs",
              :logo_url => "not blank",
              :locations => {
                  :location => {
                      :listing => "DT-1244",
                      :address_line_1 => "3440 SE Sherman",
                      :city => "Portland",
                      :state => "OR",
                      :zip => "97214",
                      :phone_number => "503-757-5377"
                  }
              }
          }
          @advertiser_hash_with_listing = @advertiser_hash_without_listing.merge({:listing => "123-import-test"})
        end

        context "simple import new advertiser with listing" do

          setup do
            @publisher = Factory(:publisher, :advertiser_has_listing => true)
            @importer = AdvertiserImporter.new(nil, @publisher, @advertiser_hash_with_listing)
            @importer.stubs(:photo).returns(File.open(File.expand_path('advertiser_logo.png', Rails.root + 'test/fixtures/files')))
            @importer.import
          end

          should "have created an advertiser" do
            assert_not_nil @importer.advertiser
          end

          should "have valid importer" do
            assert @importer.valid?, @importer.errors.inspect
          end

          should "have made a valid advertiser" do
            assert @importer.advertiser.valid?, @importer.advertiser.errors.full_messages
          end

          should "have saved advertiser" do
            assert_not_nil ::Advertiser.find_by_listing("123-import-test")
          end

          should "advertiser should have correct publisher" do
            assert_equal @publisher, @importer.advertiser.publisher
          end

        end

        context "import new advertiser no listing" do

          setup do
            @publisher = Factory(:publisher)
            @importer = AdvertiserImporter.new(nil, @publisher, @advertiser_hash_without_listing)
            @importer.import
          end

          should "be invalid" do
            assert !@importer.valid?
          end

        end

        context "two publishers, two advertisers, one listing" do

          setup do
            @publisher1 = Factory(:publisher, :advertiser_has_listing => true)
            @publisher2 = Factory(:publisher, :advertiser_has_listing => true)
            @advertiser1 = Factory(:advertiser, :publisher => @publisher1, :listing => "123-import-test")
            @advertiser2 = Factory(:advertiser, :publisher => @publisher2, :listing => "123-import-test")
            @importer = AdvertiserImporter.new(nil, @publisher2, @advertiser_hash_with_listing)
            @importer.import
          end

          should "pick the correct advertiser" do
            assert_equal @advertiser2, @importer.advertiser
          end

        end


        context "#advertiser" do
          should "not find existing advertiser by name when listing is passed and doesn't exist'" do
            publisher = Factory(:publisher)
            name = 'existing advertiser'
            advertiser = Factory(:advertiser, :publisher => publisher, :name => name)
            assert_equal advertiser, ::Advertiser.find_by_publisher_id_and_name(publisher.id, name)
            importer = AdvertiserImporter.new(nil, publisher, @advertiser_hash_with_listing.merge(:brand_name => name))
            assert importer.advertiser.new_record?
          end
        end
      end
    end
  end
end
