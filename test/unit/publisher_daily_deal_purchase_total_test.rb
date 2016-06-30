require File.dirname(__FILE__) + "/../test_helper"

class PublisherDailyDealPurchaseTotalTest < ActiveSupport::TestCase
  context "#set_totals" do
    setup do
      @target_date = Time.zone.parse("20121221").to_date
    end

    should "add record for each publisher label" do
      PublisherDailyDealPurchaseTotal.set_totals(@target_date, {"pub1" => 2, "pub2" => 2})

      assert_equal 2, PublisherDailyDealPurchaseTotal.count
    end

    should "drop any records not in current hash" do
      existing = Factory(:publisher_daily_deal_purchase_total, :date => @target_date)
      other_name = "blah - #{existing.publisher_label}"

      PublisherDailyDealPurchaseTotal.set_totals(@target_date, {other_name => 2})

      assert_equal 1, PublisherDailyDealPurchaseTotal.count
    end

    should "update existing records for publisher labels" do
      existing = Factory(:publisher_daily_deal_purchase_total, :date => @target_date)
      existing_count = PublisherDailyDealPurchaseTotal.count

      PublisherDailyDealPurchaseTotal.set_totals(@target_date, {existing.publisher_label => existing.total + 1})

      assert_equal existing_count, PublisherDailyDealPurchaseTotal.count
      item = PublisherDailyDealPurchaseTotal.find(:first, :conditions => ["publisher_label = :label and date = :date", {:label => existing.publisher_label, :date => @target_date}])
      assert_equal existing.total + 1, item.total
    end

    should "wrap everything in a transaction"
  end

  context "#fetch_totals" do
    setup do
      @target_date = Time.zone.parse("20121221").to_date
      @totals = Factory(:publisher_daily_deal_purchase_total, :date => @target_date)
    end

    should "return an empty hash when no totals are available" do
      results = PublisherDailyDealPurchaseTotal.fetch_totals(@target_date - 1.days)

      assert_equal Hash.new, results
    end

    should "return hash with key = publisher label and value = total purchases" do
      expected_results = { @totals.publisher_label => @totals.total }

      results = PublisherDailyDealPurchaseTotal.fetch_totals(@target_date)

      assert_equal expected_results, results
    end
  end
end
