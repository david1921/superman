require File.join(File.dirname(__FILE__), "..", "..", "test_helper")
require File.join(File.dirname(__FILE__), "..", "..", "..", "lib", "analog", "qa_data")

# hydra class Analog::QaDataTest
module Analog
  class QaDataTest < ActiveSupport::TestCase

    context "generate_advertiser" do
      setup do
        @publisher = Factory(:publisher)
        @advertiser = Analog::QaData.generate_advertiser(@publisher)
      end

      should "create a new advertiser associated with the publisher" do
        assert @advertiser.valid?
        assert_equal Advertiser, @advertiser.class
        assert_equal 1, @publisher.advertisers.length
        assert_equal @advertiser, @publisher.advertisers.first
      end

      should "create an advertiser with important fields" do
        assert @advertiser.name
        assert @advertiser.tagline
        assert @advertiser.website_url
        assert @advertiser.email_address
        assert @advertiser.logo_file_name
      end
    end

    context "generate_store" do
      setup do
        @advertiser = Factory(:advertiser, :stores => [])
        @store = Analog::QaData.generate_store(@advertiser)
      end

      should "create a new store associated with the advertiser" do
        assert @store.valid?
        assert_equal Store, @store.class
        assert @advertiser.stores.include?(@store)
      end
    end

    context "generate_daily_deal" do
      setup do
        @advertiser = Factory(:advertiser)
      end

      should "create a new daily deal associated with the advertiser" do
        daily_deal = Analog::QaData.generate_daily_deal(@advertiser)
        assert daily_deal.valid?
        assert_equal DailyDeal, daily_deal.class
        assert_equal 1, @advertiser.daily_deals.length
        assert_equal daily_deal, @advertiser.daily_deals.first
      end

      should "create a daily deal with important fields" do
        daily_deal = Analog::QaData.generate_daily_deal(@advertiser)
        assert daily_deal.value_proposition
        assert daily_deal.price
        assert daily_deal.quantity
        assert daily_deal.min_quantity
        assert daily_deal.max_quantity
        assert daily_deal.description
        assert daily_deal.start_at
        assert daily_deal.hide_at
        assert daily_deal.photo_file_name
      end

      should "create a deal starting at the end of the last existing deal" do
        Timecop.freeze(Time.now) do
          last_deal = Factory(:daily_deal, :start_at => 2.days.ago, :hide_at => 1.day.ago)
          @advertiser.daily_deals << last_deal

          daily_deal = Analog::QaData.generate_daily_deal(@advertiser)
          assert_equal last_deal.hide_at.to_s, daily_deal.start_at.to_s
        end
      end
    end

  end
end
