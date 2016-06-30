require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::CoreTest

class DailyDeals::CoreTest < ActiveSupport::TestCase
  context "#bar_code_symbology" do
    should "respond" do
      assert DailyDeal.new.respond_to?(:bar_code_symbology)
    end
  end

  context "#featured_after" do
    setup do
      @publisher = Factory(:publisher)
      @advertiser = @publisher.advertisers.last || Factory(:advertiser, :publisher => @publisher)

      @now = Time.parse("2012-02-07T09:00:00-0800") # 1:00am PST
      Timecop.freeze(@now) do
        @featured_now = Factory(:daily_deal, :advertiser => @advertiser,
                                :start_at => Time.zone.now, :hide_at => Time.zone.now + 2.days,
                                :side_start_at => Time.zone.now + 20.hours, :side_end_at => Time.zone.now + 2.days)
        @featured_next = Factory(:featured_daily_deal, :advertiser => @advertiser,
                                 :start_at => @featured_now.side_start_at, :hide_at => @featured_now.hide_at + 2.days)
        @featured_after_next = Factory(:featured_daily_deal, :advertiser => @advertiser,
                                       :start_at => @featured_next.hide_at, :hide_at => @featured_next.hide_at + 1.day)
      end
      assert_equal 3, @publisher.daily_deals.size, "should be 3 daily deals for publisher"
    end

    should "return deals that become featured after specified time" do
      Timecop.freeze(@now) do
        deals = @publisher.daily_deals.featured_after(@publisher.now)
        assert_equal [@featured_next, @featured_after_next], deals, "Expected #{[@featured_next, @featured_after_next].map(&:id).inspect}, was #{deals.map(&:id).inspect}"
      end
    end
  end

  context "#accounting_id" do

    should "not have a column names accounting_id" do
      assert !DailyDeal.column_names.include?(:accounting_id), "should not have accounting id"
    end

    should "not be able to update accounting_id" do
      deal = Factory(:daily_deal)
      assert_raises NoMethodError do
        deal.update_attribute(:accounting_id, 2)
      end
    end

    should "return the daily deal id for the accounting id" do
      deal = Factory(:daily_deal)
      assert_equal deal.id.to_s, deal.accounting_id
    end

  end

  context "#accounting_id_for_variation" do

    should "raise MissingVariationException with nil variation" do
      deal = Factory(:daily_deal)
      assert_raises DailyDeals::MissingVariationException do
        deal.accounting_id_for_variation(nil)
      end
    end

    should "raise MissingDailyDealSequenceIDException with new variation" do
      deal      = Factory(:daily_deal)
      variation = Factory.build(:daily_deal_variation, :daily_deal => deal)
      assert_raises DailyDeals::MissingDailyDealSequenceIDException do
        deal.accounting_id_for_variation(variation)
      end      
    end

    should "return <daily_deal.id>-<variation.daily_deal_sequence_id>" do
      deal      = Factory(:daily_deal)
      deal.publisher.update_attribute(:enable_daily_deal_variations, true)
      variation = Factory(:daily_deal_variation, :daily_deal => deal)
      assert_equal "#{deal.id}-#{variation.daily_deal_sequence_id}", deal.accounting_id_for_variation(variation)  
    end

  end
end