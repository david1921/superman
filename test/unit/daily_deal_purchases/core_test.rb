# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchase::CoreTest < ActiveSupport::TestCase
  context "#expected_number_of_recipients" do
    context "is a gifted purchase" do
      setup do
        @daily_deal = Factory(:daily_deal, :certificates_to_generate_per_unit_quantity => 1)
      end

      should "return the correct number of possible recipients with default values" do
        daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :gift => true, :quantity => 1, :recipient_names => ["Bob Barker"])
        assert_equal 1, daily_deal_purchase.expected_number_of_recipients
      end

      should "return the correct number of possible recipients when quantity is more than 1" do
        daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :gift => true, :quantity => 2, :recipient_names => ["Bob Barker", "Jon Stewart"])
        assert_equal 2, daily_deal_purchase.expected_number_of_recipients
      end

      should "return the correct number of possible recipients when certificates_to_generate_per_unit_quantity is more than 1" do
        daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :gift => true, :quantity => 1, :recipient_names => ["Bob Barker"])
        @daily_deal.certificates_to_generate_per_unit_quantity = 3
        @daily_deal.save
        assert_equal 3, daily_deal_purchase.expected_number_of_recipients
      end
    end

    context "is not a gifted purchase" do
   	  should "return 1 as the possible number of recipients" do
   	    daily_deal = Factory(:daily_deal, :certificates_to_generate_per_unit_quantity => 5)
		    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :gift => false, :quantity => 5)

		    assert_equal 1, daily_deal_purchase.expected_number_of_recipients
	    end
	  end
  end

  context "#gift_expected_number_of_recipients" do
  	setup do
      @daily_deal = Factory(:daily_deal, :certificates_to_generate_per_unit_quantity => 1)
    end

    should "return the correct number of possible recipients with default values" do
      daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1)
      assert_equal 1, daily_deal_purchase.gift_expected_number_of_recipients
    end

    should "return the correct number of possible recipients when quantity is more than 1" do
      daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :gift => true, :quantity => 2, :recipient_names => ["Bob Barker", "Jon Stewart"])
      assert_equal 2, daily_deal_purchase.gift_expected_number_of_recipients
    end

    should "return the correct number of possible recipients when certificates_to_generate_per_unit_quantity is more than 1" do
      daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1)
      @daily_deal.certificates_to_generate_per_unit_quantity = 3
      @daily_deal.save
      assert_equal 3, daily_deal_purchase.gift_expected_number_of_recipients
    end
  end
end