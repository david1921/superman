require File.dirname(__FILE__) + "/../test_helper"

class FactorySanityCheckTest < ActiveSupport::TestCase
  test "daily deals" do
    deal = Factory(:daily_deal)
    assert_not_nil deal.advertiser
    assert_no_errors deal.advertiser
    
    assert_not_nil deal.publisher
    assert_no_errors deal.publisher
    
    assert_not_nil deal.publisher.publishing_group
    assert_no_errors deal.publisher.publishing_group
    
    assert_equal deal.advertiser.publisher, deal.publisher
  end

  test "daily deal purchase" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    deal = daily_deal_purchase.daily_deal
    
    assert_not_nil daily_deal_purchase.advertiser
    assert_no_errors daily_deal_purchase.advertiser
    assert_equal daily_deal_purchase.advertiser, deal.advertiser
    
    assert_not_nil deal.publisher
    assert_no_errors deal.publisher
    
    assert_not_nil deal.publisher.publishing_group
    assert_no_errors deal.publisher.publishing_group
    
    assert_equal daily_deal_purchase.advertiser.publisher, daily_deal_purchase.publisher
    assert_equal daily_deal_purchase.consumer.publisher, daily_deal_purchase.publisher
  end
end
