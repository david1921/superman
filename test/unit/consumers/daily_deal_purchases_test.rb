require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Consumers::DailyDealPurchasesTest
class Consumers::DailyDealPurchasesTest < ActiveSupport::TestCase
  test "purchase_executed with purchase having zero credit_used does not change credit_available" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :credit_used => 0.00)
    consumer = daily_deal_purchase.consumer
    assert_no_difference 'consumer.reload.credit_available' do
      consumer.daily_deal_purchase_executed! daily_deal_purchase
    end
  end

  test "purchase_executed with purchase having positive credit_used decrements credit_available" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :credit_used => 10.00)
    consumer = daily_deal_purchase.consumer
    consumer.credits.create!(:amount => 20.00)
    assert_difference 'consumer.reload.credit_available', -10.00 do
      consumer.daily_deal_purchase_executed! daily_deal_purchase
    end
  end

  test "purchase_executed with purchase having credit_used greater than credit_available raises an exception" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :credit_used => 20.00)
    consumer = daily_deal_purchase.consumer
    consumer.credits.create!(:amount => 10.00)
    assert_raise ActiveRecord::RecordInvalid do
      consumer.daily_deal_purchase_executed! daily_deal_purchase
    end
  end

  test "my_daily_deal_purchases no purchases" do
    consumer = Factory(:consumer)
    assert consumer.my_daily_deal_purchases.empty?, "my_daily_deal_purchases"
  end

  test "my_daily_deal_purchases purchases" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase)
    assert_equal [ daily_deal_purchase ], daily_deal_purchase.consumer.my_daily_deal_purchases, "my_daily_deal_purchases"
  end

  test "my_daily_deal_purchases purchases should include off platform certificates" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase)
    off_platform_daily_deal_certificate = Factory(:off_platform_daily_deal_certificate, :consumer => daily_deal_purchase.consumer, :executed_at => 3.years.ago)
    assert_equal [ daily_deal_purchase, off_platform_daily_deal_certificate ], daily_deal_purchase.consumer.my_daily_deal_purchases, "my_daily_deal_purchases"
  end

  test "my_daily_deal_purchases should sort with nil expires_on" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase)
    off_platform_daily_deal_certificate = Factory(:off_platform_daily_deal_certificate, :consumer => daily_deal_purchase.consumer, :executed_at => 3.years.ago, :expires_on => nil)
    assert_equal [ daily_deal_purchase, off_platform_daily_deal_certificate ], daily_deal_purchase.consumer.my_daily_deal_purchases, "my_daily_deal_purchases"
  end
end