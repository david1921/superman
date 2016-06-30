require File.dirname(__FILE__) + "/../test_helper"

class OffPlatformDailyDealPurchaseTest < ActiveSupport::TestCase

  should "validate recipient names match quantity" do
    purchase = Factory.build(:off_platform_daily_deal_purchase)
    purchase.expects(:recipient_names_match_quantity)
    purchase.valid?
  end

  should "not allow a consumer" do
    consumer = Factory(:consumer)
    purchase = Factory.build(:off_platform_daily_deal_purchase, :consumer => consumer)
    assert !purchase.valid?
    assert_not_nil purchase.errors[:consumer]
  end

  should "not allow a consumer_id" do
    purchase = Factory.build(:off_platform_daily_deal_purchase, :consumer_id => 1)
    assert !purchase.valid?
    assert_not_nil purchase.errors[:consumer_id]
  end

  should "belong to an :api_user" do
    ddp = Factory(:off_platform_daily_deal_purchase)
    ddp.api_user = Factory(:user)
    ddp.save!
    ddp = OffPlatformDailyDealPurchase.find(ddp.id)
    assert ddp.api_user.kind_of?(User)
  end

  should "require an api_user" do
    ddp = Factory.build(:off_platform_daily_deal_purchase)
    ddp.api_user = nil
    assert !ddp.valid?
    assert_not_nil ddp.errors[:api_user]
  end
  
  should "be invalid when trying to create an OPP on a deal whose " +
         "certificates_to_generate_per_unit_quantity is > 1" do
    deal = Factory :daily_deal, :certificates_to_generate_per_unit_quantity => 3
    ddp = Factory.build(:off_platform_daily_deal_purchase, :daily_deal => deal)
    assert ddp.invalid?
    assert_equal "Daily deal must have a certificates_to_generate_per_unit_quantity of 1, but is 3", ddp.errors.on(:daily_deal)
    
    ddp.daily_deal.certificates_to_generate_per_unit_quantity = 1
    assert ddp.valid?
  end
  
end
