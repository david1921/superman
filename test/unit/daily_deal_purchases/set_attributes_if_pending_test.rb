# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchase::SetAttributesIfPendingTest < ActiveSupport::TestCase
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

  context "#set_attributes_if_pending" do
    should "set quantity, gift and recipient names" do
      daily_deal_purchase = build_with_attributes(@valid_attributes)
      assert_equal "pending", daily_deal_purchase.payment_status, "Default payment status"

      updated_attributes_1 = {:quantity => 3, :gift => true, :recipient_names => ["Joe Blow"] * 3}
      updated_attributes_1.each { |key, val| assert val != daily_deal_purchase.send(key), key }

      daily_deal_purchase.set_attributes_if_pending(updated_attributes_1)
      updated_attributes_1.each { |key, val| assert val == daily_deal_purchase.send(key), key }

      updated_attributes_2 = {:quantity => 10, :gift => false, :recipient_names => ["Bill Jump"] * 10}
      updated_attributes_2.each { |key, val| assert val != daily_deal_purchase.send(key), key }

      daily_deal_purchase.payment_status = "captured"
      daily_deal_purchase.set_attributes_if_pending(updated_attributes_2)
      updated_attributes_1.each { |key, val| assert val == daily_deal_purchase.send(key), key }
    end

    should "set donation attributes" do
      ddp = Factory(:pending_daily_deal_purchase)
      attrs = {
          :donation_name => 'Some School',
          :donation_city => 'Portland',
          :donation_state => 'OR'
      }
      ddp.set_attributes_if_pending(attrs)
      attrs.each do |k,v|
        assert_equal v, ddp.send(k)
      end
    end

    should "set mailing address attributes" do
      address = Factory.build(:address)
      purchase = Factory.build(:daily_deal_purchase)
      assert_nil purchase.mailing_address
      purchase.set_attributes_if_pending(:mailing_address_attributes => address.attributes)
      assert_equal address.attributes, purchase.mailing_address.attributes
    end
  end

  context "daily deal variations" do

    setup do
      @daily_deal_purchase = Factory(:pending_daily_deal_purchase)
      @daily_deal_purchase.publisher.update_attribute(:enable_daily_deal_variations, true)
      @variation          = Factory(:daily_deal_variation, :daily_deal => @daily_deal_purchase.daily_deal)

      @daily_deal_purchase.reload
    end

    should "not set daily deal variation if publisher is not setup for daily deal variations" do
      @daily_deal_purchase.publisher.update_attribute(:enable_daily_deal_variations, false)
      @daily_deal_purchase.set_attributes_if_pending( @valid_attributes.merge(:daily_deal_variation_id => @variation.to_param) )
      assert_nil @daily_deal_purchase.daily_deal_variation_id
    end

    should "set daily deal variation if publisher is setup for daily deal variations" do
      @daily_deal_purchase.publisher.update_attribute(:enable_daily_deal_variations, true)
      @daily_deal_purchase.set_attributes_if_pending( @valid_attributes.merge(:daily_deal_variation_id => @variation.to_param) )
      assert_equal @variation.id, @daily_deal_purchase.daily_deal_variation_id
    end

    should "not set daily deal variation if variation does not belong to daily deal associated with the purchase" do
      another_publisher = Factory(:publisher, :enable_daily_deal_variations => true)
      another_deal      = Factory(:daily_deal, :publisher => another_publisher)      
      another_variation = Factory(:daily_deal_variation, :daily_deal => another_deal)      

      @daily_deal_purchase.publisher.update_attribute(:enable_daily_deal_variations, true)
      @daily_deal_purchase.set_attributes_if_pending( @valid_attributes.merge(:daily_deal_variation_id => another_variation.to_param) )
      assert_nil @daily_deal_purchase.daily_deal_variation_id      
    end

  end
end
