require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeal::NumberSoldDisplayThresholdTest < ActiveSupport::TestCase

  context "build_with_defaults" do

    context "number_sold_display_threshold" do

      should "use publishing_group setting if no publisher setting" do
        publishing_group = Factory(:publishing_group, :number_sold_display_threshold_default => 15)
        publisher = Factory(:publisher, :publishing_group => publishing_group, :number_sold_display_threshold_default => nil)
        advertiser = Factory(:advertiser, :publisher => publisher)
        deal = DailyDeal.build_with_defaults(advertiser)
        assert_equal(15, deal.number_sold_display_threshold)
      end

      should "use publisher setting if available" do
        publishing_group = Factory(:publishing_group, :number_sold_display_threshold_default => 15)
        publisher = Factory(:publisher, :publishing_group => publishing_group, :number_sold_display_threshold_default => 22)
        advertiser = Factory(:advertiser, :publisher => publisher)
        deal = DailyDeal.build_with_defaults(advertiser)
        assert_equal(22, deal.number_sold_display_threshold)
      end

      should "use a very high number if for some reason the defaults are unavailable" do
        publishing_group = Factory(:publishing_group, :number_sold_display_threshold_default => nil)
        publisher = Factory(:publisher, :publishing_group => publishing_group, :number_sold_display_threshold_default => nil)
        advertiser = Factory(:advertiser, :publisher => publisher)
        deal = DailyDeal.build_with_defaults(advertiser)
        assert_equal(5000, deal.number_sold_display_threshold)
      end

    end

  end

  context "number_sold_meets_or_exceeds_display_threshold?" do

    setup do
      @daily_deal = Factory.build(:daily_deal, :number_sold_display_threshold => 45)
    end

    should "not meet or exceed threshold when before threshold" do
      @daily_deal.stubs(:number_sold).returns(20)
      assert !@daily_deal.number_sold_meets_or_exceeds_display_threshold?
    end

    should "meet or exceed threshold when at limit" do
      @daily_deal.stubs(:number_sold).returns(45)
      assert @daily_deal.number_sold_meets_or_exceeds_display_threshold?
    end

    should "meet or exceed threshold when above limit" do
      @daily_deal.stubs(:number_sold).returns(50)
      assert @daily_deal.number_sold_meets_or_exceeds_display_threshold?
    end

    should "not meet or exceed threshold when threshold is nil" do
      @daily_deal.number_sold_display_threshold = nil
      @daily_deal.stubs(:number_sold).returns(50)
      assert !@daily_deal.number_sold_meets_or_exceeds_display_threshold?
    end

    should "not meet or exceed threshold when number_sold is nil" do
      @daily_deal.stubs(:number_sold).returns(nil)
      assert !@daily_deal.number_sold_meets_or_exceeds_display_threshold?
    end

  end

end