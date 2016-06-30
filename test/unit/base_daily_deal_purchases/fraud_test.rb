require File.dirname(__FILE__) + "/../../test_helper"

# hydra class BaseDailyDealPurchases::FraudTest

class BaseDailyDealPurchases::FraudTest < ActiveSupport::TestCase
  context "with daily deal purchases for a publisher" do
    setup do
      @publisher = Factory(:publisher)
      @daily_deals = (1..3).map do |day|
        show_at = Time.zone.local(2012, 1, day,  0,  0, 0)
        hide_at = Time.zone.local(2012, 1, day, 23, 55, 0)
        Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => @publisher), :start_at => show_at, :hide_at => hide_at)
      end
      @consumers = (1..4).map { Factory(:consumer, :publisher => @publisher) }
      @daily_deal_purchases = [].tap do |array|
        Timecop.freeze Time.zone.local(2012, 1, 1, 12, 34, 00) do
          array << Factory(:pending_daily_deal_purchase, :daily_deal => @daily_deals[0], :consumer => @consumers[0])
        end
        Timecop.freeze Time.zone.local(2012, 1, 1, 12, 34, 01) do
          array << Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deals[0], :consumer => @consumers[1])
        end
        Timecop.freeze Time.zone.local(2012, 1, 1, 12, 34, 02) do
          array << Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deals[0], :consumer => @consumers[2])
        end
        Timecop.freeze Time.zone.local(2012, 1, 1, 12, 34, 03) do
          array << Factory(:pending_daily_deal_purchase, :daily_deal => @daily_deals[0], :consumer => @consumers[1])
        end
        Timecop.freeze Time.zone.local(2012, 1, 2, 12, 34, 04) do
          array << Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deals[1], :consumer => @consumers[2])
        end
        Timecop.freeze Time.zone.local(2012, 1, 2, 12, 34, 05) do
          array << Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deals[1], :consumer => @consumers[3])
        end
        Timecop.freeze Time.zone.local(2012, 1, 3, 12, 34, 06) do
          array << Factory(:refunded_daily_deal_purchase, :daily_deal => @daily_deals[2], :consumer => @consumers[3])
        end
      end
    end
    
    should "select only captured purchases in the for_fraud_check named scope" do
      purchase_ids = @publisher.daily_deal_purchases.for_fraud_check.map(&:id)
      assert_same_elements [1, 2, 4, 5].map { |i| @daily_deal_purchases[i].id }, purchase_ids
    end
    
    should "select only purchases created before the timestamp in the before_fraud_check_increment named scope" do
      last_timestamp = Time.zone.local(2012, 1, 1, 12, 34, 02)
      purchase_ids = @publisher.daily_deal_purchases.before_fraud_check_increment(last_timestamp).map(&:id)
      assert_same_elements [0, 1].map { |i| @daily_deal_purchases[i].id }, purchase_ids
    end

    should "select only purchases created between the timestamps in the within_fraud_check_increment named scope" do
      last_timestamp = Time.zone.local(2012, 1, 1, 12, 34, 02)
      this_timestamp = Time.zone.local(2012, 1, 2, 12, 34, 04)
      purchase_ids = @publisher.daily_deal_purchases.within_fraud_check_increment(last_timestamp, this_timestamp).map(&:id)
      assert_same_elements [2, 3].map { |i| @daily_deal_purchases[i].id }, purchase_ids
    end
    
    should "group captured purchases by consumer in the grouped_by_fraud_key scope" do
      purchase_ids = @publisher.daily_deal_purchases.grouped_by_fraud_key.all(:select => "MAX(daily_deal_purchases.id) AS id").map(&:id)
      assert_same_elements [1, 4, 5].map { |i| @daily_deal_purchases[i].id }, purchase_ids
    end
  end
end
