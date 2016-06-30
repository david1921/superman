require File.dirname(__FILE__) + "/../test_helper"

class BraintreeRedirectResultTest < ActiveSupport::TestCase
  def test_latest_for_distinct_consumers
    ddp_1 = Factory.create(:captured_daily_deal_purchase)
    Time.stubs(:now).returns(Time.parse("Jun 15, 2010 12:00:01"))
    brr_1 = BraintreeRedirectResult.create!(:daily_deal_purchase => ddp_1, :error => true)
    Time.stubs(:now).returns(Time.parse("Jun 15, 2010 12:00:02"))
    brr_2 = BraintreeRedirectResult.create!(:daily_deal_purchase => ddp_1, :error => false)
    
    ddp_2 = Factory.create(:captured_daily_deal_purchase, :daily_deal => ddp_1.daily_deal, :consumer => ddp_1.consumer)
    Time.stubs(:now).returns(Time.parse("Jun 15, 2010 12:00:05"))
    brr_3 = BraintreeRedirectResult.create!(:daily_deal_purchase => ddp_2, :error => false)

    ddp_3 = Factory.create(:pending_daily_deal_purchase)
    Time.stubs(:now).returns(Time.parse("Jun 15, 2010 12:00:01"))
    brr_4 = BraintreeRedirectResult.create!(:daily_deal_purchase => ddp_3, :error => true)
    
    assert_equal [brr_3, brr_4].map(&:id).sort, BraintreeRedirectResult.latest_for_distinct_consumers.map(&:id).sort
  end
end
