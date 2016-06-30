# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchase::DiscountTest < ActiveSupport::TestCase

  test "total_price when discount exceeds price" do
    discount = Factory(:discount, :amount => 10.00)
    daily_deal = Factory(:daily_deal, :publisher => discount.publisher, :price => 5.00)
    daily_deal_purchase = Factory.build(:pending_daily_deal_purchase, :daily_deal => daily_deal, :discount => discount, :quantity => 2)
    assert daily_deal_purchase.valid?, "Should be valid when discount exceeds price"
    assert_equal 0.0, daily_deal_purchase.total_price
  end

  test "total price with discount" do
    discount = Factory(:discount, :amount => 5.00)
    daily_deal = Factory(:daily_deal, :publisher => discount.publisher, :price => 15.00)
    daily_deal_purchase = Factory.build(:pending_daily_deal_purchase, {
      :daily_deal => daily_deal,
      :quantity => 2,
      :discount => discount
    })
    assert_equal 25.00, daily_deal_purchase.total_price
  end
  
  test "usable_only_once discount gets flagged as used if captured purchased" do
    discount = Factory(:discount, :amount => 5.00, :usable_only_once => true )
    daily_deal = Factory(:daily_deal, :publisher => discount.publisher)
    assert !discount.used_at, "It should not be flagged used"
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :discount_code => discount.code, :daily_deal => daily_deal)
    assert daily_deal_purchase.captured?, "daily deal purchase should be captured"
    assert_equal discount.id, daily_deal_purchase.discount.id, "Daily Deal should be assigned the Discount"
    discount.reload
    assert discount.used_at, "It should flag the Discount as used"
    assert !daily_deal.publisher.discounts.usable.exists?(discount), "The Discount should not be in the usable scope"
  end
  
  test "usable_only_once discount gets flagged as used if authorized purchased" do
    discount = Factory(:discount, :amount => 5.00, :usable_only_once => true )
    daily_deal = Factory(:daily_deal, :publisher => discount.publisher)
    assert !discount.used_at, "It should not be flagged used"
    daily_deal_purchase = Factory(:authorized_daily_deal_purchase, :discount_code => discount.code, :daily_deal => daily_deal)
    assert daily_deal_purchase.authorized?, "daily deal purchase should be authorized"
    assert_equal discount.id, daily_deal_purchase.discount.id, "Daily Deal should be assigned the Discount"
    discount.reload
    assert discount.used_at, "It should flag the Discount as used"
    assert !daily_deal.publisher.discounts.usable.exists?(discount), "The Discount should not be in the usable scope"
  end  
  
  test "usable_only_once discount should not be flagged as used if pending purchase" do
    discount = Factory(:discount, :amount => 5.00, :usable_only_once => true )
    daily_deal = Factory(:daily_deal, :publisher => discount.publisher)
    assert !discount.used_at, "It should not be flagged used"
    daily_deal_purchase = Factory(:daily_deal_purchase, :discount_code => discount.code, :daily_deal => daily_deal)
    assert daily_deal_purchase.pending?, "should be a pending daily deal purchase"
    assert_equal discount.id, daily_deal_purchase.discount.id, "Daily Deal should be assigned the Discount"
    discount.reload
    assert !discount.used_at, "It should NOT flag the Discount as used"
    assert daily_deal.publisher.discounts.usable.exists?(discount), "The Discount should still be in the usable scope"    
  end
  
  test "usable_only_once discount should only be flagged as used once" do
    discount = Factory(:discount, :amount => 5.00, :usable_only_once => true)
    daily_deal = Factory(:daily_deal, :publisher => discount.publisher)    
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :discount_code => discount.code, :daily_deal => daily_deal, :executed_at => 2.days.ago)
    discount.reload
    discount.update_attribute(:used_at, 2.days.ago)
    
    assert discount.used?, "discount should be marked as used"
    original_used_at = discount.used_at
    
    daily_deal_purchase.reload
    assert daily_deal_purchase.update_attributes(:donation_name => "Someone special"), "daily deal purchase should be updated"

    discount.reload    
    assert_equal original_used_at.to_date, discount.used_at.to_date, "the discount used at date should not change"
  end
  
  test "assignment of discount by uuid" do
    discount = Factory.create(:discount)
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    daily_deal_purchase.set_attributes_if_pending :discount_uuid => discount.uuid
    assert_equal discount, daily_deal_purchase.discount
  end
  
  test "assignment of discount by code" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    discount = Factory.create(:discount, :publisher => daily_deal_purchase.publisher)
    daily_deal_purchase.set_attributes_if_pending :discount_code => discount.code
    daily_deal_purchase.save!
    assert_equal discount, daily_deal_purchase.discount
  end
  
  test "rejection of discount code assigned to another publisher" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    discount = Factory.create(:discount)
    daily_deal_purchase.set_attributes_if_pending :discount_code => discount.code
    assert !daily_deal_purchase.valid?, "Should not be valid another publisher's discount code"
    assert_match /discount code \w+ wasn\'t valid/i, daily_deal_purchase.errors.on(:base)
  end
  
  test "rejection of nonexistent discount code" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    daily_deal_purchase.set_attributes_if_pending :discount_code => "NOSUCH"
    assert !daily_deal_purchase.valid?, "Should not be valid with non-existent discount code"
    assert_match /discount code \w+ wasn\'t valid/i, daily_deal_purchase.errors.on(:base)
  end
  
  test "rejection of discount code not usable at checkout" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    discount = Factory.create(:discount, :publisher => daily_deal_purchase.publisher, :usable_at_checkout => false)
    daily_deal_purchase.set_attributes_if_pending :discount_code => discount.code
    assert !daily_deal_purchase.valid?, "Should not be valid with non-existent discount code"
    assert_match /discount code \w+ wasn\'t valid/i, daily_deal_purchase.errors.on(:base)
  end
  
  test "consumer cannot use discount code again after executing it" do
    daily_deal_purchase = Factory.create(:authorized_daily_deal_purchase)
    publisher, daily_deal, consumer = daily_deal_purchase.publisher, daily_deal_purchase.daily_deal, daily_deal_purchase.consumer
  
    discount = Factory.create(:discount, :publisher => publisher)
    daily_deal_purchase.discount = discount
    daily_deal_purchase.save!
  
    daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer)
    daily_deal_purchase.set_attributes_if_pending :discount_code => discount.code
    assert !daily_deal_purchase.valid?, "Should not be valid with repeat use of discount"
    assert_match /already used discount code/i, daily_deal_purchase.errors.on(:base)
  end
  
  test "consumer can use discount code twice without executing it" do
    daily_deal_purchase = Factory.create(:pending_daily_deal_purchase)
    publisher, daily_deal, consumer = daily_deal_purchase.publisher, daily_deal_purchase.daily_deal, daily_deal_purchase.consumer
  
    discount = Factory.create(:discount, :publisher => publisher)
    daily_deal_purchase.discount = discount
    daily_deal_purchase.save!
  
    daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer)
    daily_deal_purchase.set_attributes_if_pending :discount_code => discount.code
    assert daily_deal_purchase.valid?, "Should be valid with repeat use of unexecuted discount"
  end
  
end