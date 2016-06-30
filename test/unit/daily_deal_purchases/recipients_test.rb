# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchase::RecipientsTest < ActiveSupport::TestCase
  include DailyDealPurchasesTestHelper

  def setup
    @valid_attributes = { :daily_deal => daily_deals(:changos), :consumer => users(:john_public), :quantity => 2 }
    @valid_gift_attributes = @valid_attributes.merge({
      :quantity => 2,
      :gift => true,
      :recipient_names => ["Bess Rackham", "Harry Kidd"]
    })
    ActionMailer::Base.deliveries.clear
    super
  end

  test "recipient names on create" do
    attributes = @valid_attributes.merge({
      :quantity => 2,
      :gift => true,
      :recipient_names => [ "Bess Rackham ", "  Harry Kidd   " ]
    })
    (daily_deal_purchase = build_with_attributes(attributes)).save!
    daily_deal_purchase.reload
    assert_equal ["Bess Rackham", "Harry Kidd"], daily_deal_purchase.recipient_names
  end

  test "recipient names validation" do
    attributes = @valid_attributes.merge({
      :quantity => 2,
      :gift => true,
      :recipient_names => [ "Bess Rackham", "Harry Kidd" ]
    })
    daily_deal_purchase = build_with_attributes(attributes)
    assert daily_deal_purchase.valid?, "Should be valid as gift with appropriate number of recipient names"

    daily_deal_purchase.quantity = 3
    assert daily_deal_purchase.invalid?, "Should not be valid as gift with too few recipient names"

    daily_deal_purchase.quantity = 1
    assert daily_deal_purchase.invalid?, "Should not be valid as gift with too many recipient names"

    daily_deal_purchase.quantity = 2
    daily_deal_purchase.recipient_names = [ "Bess Rackham", " " ]
    assert daily_deal_purchase.invalid?, "Should not be valid as gift with blank recipient name"

    daily_deal_purchase.gift = false
    assert daily_deal_purchase.valid?, "Should be valid if not a gift"
  end

  test "recipients quantity validation for gift purchase" do
    ddp = Factory.build(:daily_deal_purchase, :gift => true, :quantity => qty = 3)
    ddp.daily_deal = Factory(:daily_deal, :requires_shipping_address => true)
    assert !ddp.valid?
    assert_match /#{qty} recipient/, ddp.errors.on(:recipients)
  end

  test "recipients quantity validation for non-gift purchase" do
    ddp = Factory.build(:daily_deal_purchase, :gift => false)
    ddp.daily_deal = Factory(:daily_deal, :requires_shipping_address => true)
    assert !ddp.valid?
    assert_match /one recipient/, ddp.errors.on(:recipients)
  end

  test "recipient names must be present for gift" do
    daily_deal_purchase = build_with_attributes(@valid_gift_attributes)
    assert daily_deal_purchase.valid?, "Should be valid with valid attributes"
    daily_deal_purchase.recipient_names = nil
    assert daily_deal_purchase.gift, "Should be a gift"
    assert daily_deal_purchase.invalid?, "Gift purchase should not be valid without recipient names"
  end

  test "has many recipients" do
    Timecop.freeze do
      ddp = Factory(:daily_deal_purchase)
      r1 = Factory(:daily_deal_purchase_recipient, :daily_deal_purchase => ddp)
      r2 = Factory(:daily_deal_purchase_recipient, :daily_deal_purchase => ddp)
      r3 = Factory(:daily_deal_purchase_recipient)
      assert_equal ddp.recipients.size, 2
      recipient = ddp.recipients.first(:order => "created_at DESC")
      assert_equal r1, recipient
    end
  end

  test "recipients set_attributes_if_pending" do
    daily_deal = Factory(:daily_deal)
    daily_deal_purchase = daily_deal.daily_deal_purchases.build
    daily_deal_purchase.set_attributes_if_pending(:quantity => 2)
    assert_equal 2, daily_deal_purchase.quantity, "quantity"
    assert_equal 0, daily_deal_purchase.recipients.size, "recipients"
  end

  test "recipients set_attributes_if_pending requires_shipping_address" do
    daily_deal = Factory(:daily_deal, :requires_shipping_address => true)
    daily_deal_purchase = daily_deal.daily_deal_purchases.build
    daily_deal_purchase.set_attributes_if_pending(
      :quantity => 1,
      :recipients_attributes => {
        "0" => {
          :name => "Jackal",
          :address_line_1 => "104 Main",
          :city => "Memphis",
          :state => "TN",
          :zip => "19191"
        }
      }
    )
    assert_equal 1, daily_deal_purchase.quantity, "quantity"
    assert_equal 1, daily_deal_purchase.recipients.size, "recipients"
    assert_equal ["Jackal"], daily_deal_purchase.recipient_names, "recipient_names"
  end

  test "recipients set_attributes_if_pending requires_shipping_address gift" do
    daily_deal = Factory(:daily_deal, :requires_shipping_address => true)
    daily_deal_purchase = daily_deal.daily_deal_purchases.build
    daily_deal_purchase.set_attributes_if_pending(
      :quantity => 1,
      :recipients_attributes => {
        "0" => {
          :name => "Jackal",
          :address_line_1 => "104 Main",
          :city => "Memphis",
          :state => "TN",
          :zip => "19191"
        }
      }
    )
    assert_equal 1, daily_deal_purchase.quantity, "quantity"
    assert_equal 1, daily_deal_purchase.recipients.size, "recipients"
    assert_equal ["Jackal"], daily_deal_purchase.recipient_names, "recipient_names"
  end

  test "recipients set_attributes_if_pending gift" do
    daily_deal = Factory(:daily_deal)
    daily_deal_purchase = daily_deal.daily_deal_purchases.build
    daily_deal_purchase.set_attributes_if_pending :quantity => 1, :gift => true, :recipient_names => ["Ian"]
    assert_equal 0, daily_deal_purchase.recipients.size, "recipients"
    assert_equal ["Ian"], daily_deal_purchase.recipient_names, "recipient_names"
  end

  test "recipients set_attributes_if_pending gift more than one" do
    daily_deal = Factory(:daily_deal)
    daily_deal_purchase = daily_deal.daily_deal_purchases.build
    daily_deal_purchase.set_attributes_if_pending :quantity => 2, :gift => true, :recipient_names => [ "Ian", "Russel" ]
    assert_equal 0, daily_deal_purchase.recipients.size, "recipients"
    assert_equal ["Ian", "Russel"], daily_deal_purchase.recipient_names, "recipient_names"
  end

  test "recipients assign_recipient_from_consumer_recipient with nil recipient" do
    daily_deal_purchase = Factory(:daily_deal_purchase)
    consumer = Factory(:consumer)
    daily_deal_purchase.assign_recipient_from_consumer_recipient(nil, consumer)
    assert_match /stored shipping address could not be used/, daily_deal_purchase.errors.on(:recipient)
  end

  test "recipients assign_recipient_from_consumer_recipient with nil consumer" do
    daily_deal_purchase = Factory(:daily_deal_purchase)
    recipient = Factory(:recipient)
    daily_deal_purchase.assign_recipient_from_consumer_recipient(recipient, nil)
    assert_match /stored shipping address could not be used/, daily_deal_purchase.errors.on(:recipient)
  end

  test "recipients assign_recipient_from_consumer_recipient with invalid consumer" do
    daily_deal_purchase = Factory(:daily_deal_purchase)
    consumer_1 = Factory(:consumer)
    consumer_2 = Factory(:consumer)
    consumer_recipient = Factory(:recipient, :addressable => consumer_2)
    daily_deal_purchase.assign_recipient_from_consumer_recipient(consumer_recipient, consumer_1)
    assert_match /stored shipping address could not be used/, daily_deal_purchase.errors.on(:recipient)
  end

  test "recipients assign_recipient_from_consumer_recipient with valid recipient" do
    daily_deal_purchase = Factory(:daily_deal_purchase)
    consumer = Factory(:consumer)
    consumer_recipient = Factory(:recipient, :addressable => consumer, :name => 'John Smith', :address_line_1 => '123 Main St',
                          :address_line_2 => '#2', :city => 'Seattle', :state => 'WA', :zip => '12345')
    daily_deal_purchase.assign_recipient_from_consumer_recipient(consumer_recipient, consumer)
    daily_deal_purchase_recipient = daily_deal_purchase.recipients.first
    assert_equal 'John Smith', daily_deal_purchase_recipient.name
    assert_equal '123 Main St', daily_deal_purchase_recipient.address_line_1
    assert_equal '#2', daily_deal_purchase_recipient.address_line_2
    assert_equal 'Seattle', daily_deal_purchase_recipient.city
    assert_equal 'WA', daily_deal_purchase_recipient.state
    assert_equal '12345', daily_deal_purchase_recipient.zip
  end

end
