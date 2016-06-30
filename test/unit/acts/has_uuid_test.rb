require File.dirname(__FILE__) + "/../../test_helper"

class HasUuidTest < ActiveSupport::TestCase
  context "daily deal purchase with random UUID" do
    setup do
      DailyDealPurchase.send(:uuid_type, :random)
    end
    
    should "have UUID after save" do
      daily_deal_purchase = Factory.build(:daily_deal_purchase)
      assert_nil daily_deal_purchase.uuid, "Should not have a UUID assigned before save"
      daily_deal_purchase.save!
      assert_not_nil daily_deal_purchase.uuid, "Should have a UUID assigned after save"
    end

    should "have a UUID with the correct format" do
      daily_deal_purchase = Factory(:daily_deal_purchase)
      assert_match /\A[[:xdigit:]]{8}-([[:xdigit:]]{4}-){3}[[:xdigit:]]{12}\z/, daily_deal_purchase.uuid
    end

    should "have a unique UUID" do
      daily_deal_purchase_1 = Factory(:daily_deal_purchase)
      daily_deal_purchase_2 = Factory(:daily_deal_purchase)
      assert daily_deal_purchase_1.uuid != daily_deal_purchase_2.uuid, "UUIDs should not repeat"
    end
  end

  context "daily deal with timestamp UUID" do
    setup do
      DailyDealPurchase.send(:uuid_type, :timestamp)
    end
    
    should "have UUID after save" do
      daily_deal = Factory.build(:daily_deal)
      assert_nil daily_deal.uuid, "Should not have a UUID assigned before save"
      daily_deal.save!
      assert_not_nil daily_deal.uuid, "Should have a UUID assigned after save"
    end

    should "have a UUID with the correct format" do
      daily_deal = Factory(:daily_deal)
      assert_match /\A[[:xdigit:]]{8}-([[:xdigit:]]{4}-){3}[[:xdigit:]]{12}\z/, daily_deal.uuid
    end

    should "have a unique UUID" do
      daily_deal_1 = Factory(:daily_deal)
      daily_deal_2 = Factory(:daily_deal)
      assert daily_deal_1.uuid != daily_deal_2.uuid, "UUIDs should not repeat"
    end
  end
end
