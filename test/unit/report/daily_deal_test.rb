require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealTest < ActiveSupport::TestCase
  test "with purchased daily deals" do
    publisher = publishers(:sdh_austin)
    advertiser = publisher.advertisers.first
    daily_deal = Factory(:daily_deal, :advertiser => advertiser, :start_at => Date.parse("Jan 22, 2010"))
    
    ConsumerMailer.stubs(:deliver_activation_request)
    valid_user_attributes = {
      :email => "joe@blow.com",
      :name => "Joe Blow",
      :password => "secret",
      :password_confirmation => "secret",
      :agree_to_terms => "1"
    }
    c_1 = publisher.consumers.create!( valid_user_attributes.merge(:email => "jon@hello.com", :name => "Jon Smith") )
    c_2 = publisher.consumers.create!( valid_user_attributes.merge(:email => "jill@hello.com", :name => "Jill Smith") )
    c_3 = publisher.consumers.create!( valid_user_attributes.merge(:email => "cheap@hello.com", :name => "Cheap Skate") )
    
    p_1 = daily_deal.daily_deal_purchases.build
    p_1.quantity = 1
    p_1.consumer = c_1
    p_1.payment_status = "captured"
    p_1.executed_at = "Jan 21, 2010 12:34:56 PST"
    p_1.daily_deal_payment = BraintreePayment.new
    p_1.daily_deal_payment.payment_gateway_id = "301181649"
    p_1.actual_purchase_price = p_1.daily_deal_payment.amount = 39
    p_1.daily_deal_payment.credit_card_last_4 = "5555"
    p_1.daily_deal_payment.payment_at = p_1.executed_at
    p_1.save!

    p_2 = daily_deal.daily_deal_purchases.build
    p_2.quantity = 3
    p_2.consumer = c_2
    p_2.payment_status = "captured"
    p_2.executed_at = "Jan 21, 2010 14:34:56 PST"
    p_2.daily_deal_payment = BraintreePayment.new
    p_2.daily_deal_payment.payment_gateway_id = "301181650"
    p_2.actual_purchase_price = p_2.daily_deal_payment.amount = 117
    p_2.daily_deal_payment.credit_card_last_4 = "5555"
    p_2.daily_deal_payment.payment_at = p_2.executed_at
    p_2.save!

    assert_equal 2, daily_deal.daily_deal_purchases.size
    
    dates = Date.parse("2010-01-20")..Date.parse("2010-01-30")
    
    assert_equal 4, daily_deal.purchases_count( dates )
    assert_equal 2, daily_deal.purchasers_count( dates ) 
    assert_equal 156.0, daily_deal.purchases_amount( dates )
  end
  
  test "duration in hours" do
    publisher = publishers(:sdh_austin)    
    advertiser = publisher.advertisers.first
    daily_deal = Factory(:daily_deal, :advertiser => advertiser, :start_at => Time.parse("Jan 22, 2010 12:00:00"), :hide_at => Time.parse("Jan 22, 2010 23:00:00"))
    assert_equal 11, daily_deal.duration_in_hours
  end
  
  test "advertiser_revenue_share_percentage default" do
    daily_deal = Factory(:daily_deal)
    assert_equal nil, daily_deal.advertiser_revenue_share_percentage, "advertiser_revenue_share_percentage"
  end
  
  test "advertiser_revenue_share_percentage" do
    daily_deal = Factory(:daily_deal, :advertiser_revenue_share_percentage => 50)
    assert_equal 50, daily_deal.advertiser_revenue_share_percentage, "advertiser_revenue_share_percentage"

    daily_deal = Factory(:daily_deal, :advertiser_revenue_share_percentage => 66.66666)
    assert_in_delta 66.666, daily_deal.advertiser_revenue_share_percentage, 0.001, "advertiser_revenue_share_percentage"

    daily_deal = Factory(:daily_deal, :advertiser_revenue_share_percentage => 98.50)
    assert_equal 98.50, daily_deal.advertiser_revenue_share_percentage, "advertiser_revenue_share_percentage"
  end
  
  test "advertiser_revenue_share_percentage should be between 0 and 100" do
    daily_deal = Factory.build(:daily_deal, :advertiser_revenue_share_percentage => -0.01)
    assert !daily_deal.valid?, "advertiser_revenue_share_percentage less than zero should not be valid"

    daily_deal = Factory.build(:daily_deal, :advertiser_revenue_share_percentage => 100)
    assert daily_deal.valid?, "advertiser_revenue_share_percentage of 100 should be valid"
  end

  context "the credit card fee percentage" do
    
    setup do
      @deal = Factory :daily_deal
    end
    
    should "be 4% for a deal that <= $10" do
      @deal.price = 0.01
      assert_equal 0.04, @deal.paychex_credit_card_percentage
      @deal.price = 10.00
      assert_equal 0.04, @deal.paychex_credit_card_percentage
    end
    
    should "be 3.8% for a deal that is > $10 and <= $15" do
      @deal.price = 10.01
      assert_equal 0.038, @deal.paychex_credit_card_percentage
      @deal.price = 15.00
      assert_equal 0.038, @deal.paychex_credit_card_percentage
    end
    
    should "be 3.5% for a deal that is > $15 and <= $20" do
      @deal.price = 15.01
      assert_equal 0.035, @deal.paychex_credit_card_percentage
      @deal.price = 20.00
      assert_equal 0.035, @deal.paychex_credit_card_percentage
    end
    
    should "be 3.3% for a deal that is > $20 and <= $30" do
      @deal.price = 20.01
      assert_equal 0.033, @deal.paychex_credit_card_percentage
      @deal.price = 30.00
      assert_equal 0.033, @deal.paychex_credit_card_percentage
    end
    
    should "be 2.8% for a deal that is > $30 and <= $40" do
      @deal.price = 30.01
      assert_equal 0.028, @deal.paychex_credit_card_percentage
      @deal.price = 40.00
      assert_equal 0.028, @deal.paychex_credit_card_percentage
    end
    
    should "be 2.7% for a deal that is > $40 and <= $60" do
      @deal.price = 40.01
      assert_equal 0.027, @deal.paychex_credit_card_percentage
      @deal.price = 60.00
      assert_equal 0.027, @deal.paychex_credit_card_percentage
    end
    
    should "be 2.6% for a deal that is > $60 and <= $80" do
      @deal.price = 60.01
      assert_equal 0.026, @deal.paychex_credit_card_percentage
      @deal.price = 80.00
      assert_equal 0.026, @deal.paychex_credit_card_percentage
    end
    
    should "be 2.5% for a deal that is > $80 and <= $100" do
      @deal.price = 80.01
      assert_equal 0.025, @deal.paychex_credit_card_percentage
      @deal.price = 100.00
      assert_equal 0.025, @deal.paychex_credit_card_percentage
    end
    
    should "be 2.4% for a deal that is > $100 and <= $120" do
      @deal.price = 100.01
      assert_equal 0.024, @deal.paychex_credit_card_percentage
      @deal.price = 120.00
      assert_equal 0.024, @deal.paychex_credit_card_percentage
    end
    
    should "be 2.3% for a deal that is > $120" do
      @deal.price = 120.01
      assert_equal 0.023, @deal.paychex_credit_card_percentage
      @deal.price = 240000.00
      assert_equal 0.023, @deal.paychex_credit_card_percentage
    end
    
  end

end
