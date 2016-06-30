require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::DailyDealNationalOrWithinZipRadiusTest
module DailyDeals
  class DailyDealNationalOrWithinZipRadiusTest < ActiveSupport::TestCase

    context "national_or_within_zip_radius" do

      setup do
        @publisher = Factory(:publisher)

        advertiser1 = Factory(:advertiser, :publisher => @publisher)
        advertiser1.update_attributes(:stores => [])
        @daily_deal1 = Factory(:side_daily_deal, :advertiser => advertiser1, :national_deal => true)

        advertiser2 = Factory(:advertiser, :publisher => @publisher)
        advertiser2.store.update_attributes(:zip => "01033")
        @daily_deal2 = Factory(:side_daily_deal, :advertiser => advertiser2)

        ZipCode.stubs(:zips_near_zip_and_radius).returns(["98686"])
      end

      context "given a zip code and radius" do

        setup do
          advertiser3 = Factory(:advertiser, :publisher => @publisher)
          advertiser3.store.update_attributes(:zip => "98686")
          @daily_deal3 = Factory(:side_daily_deal, :advertiser => advertiser3)
        end

        should "return deals within radius as well as deals without a store" do
          daily_deals = @publisher.daily_deals.national_or_within_zip_radius("98685", 25)

          assert_equal [@daily_deal1.id, @daily_deal3.id], daily_deals.map(&:id).sort
        end

      end

      context "given only a radius" do

        should "return deals without a store" do
          daily_deals = @publisher.daily_deals.national_or_within_zip_radius("98685", 25)

          assert_equal [@daily_deal1.id], daily_deals.map(&:id).sort
        end

      end

    end

  end
end
