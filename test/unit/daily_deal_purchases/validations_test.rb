require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchase::ValidationsTest < ActiveSupport::TestCase
  include DailyDealPurchasesTestHelper

  fast_context "recipients names matching quantity" do
    should "validate recipient names match quantity" do
      purchase = Factory.build(:daily_deal_purchase, :gift => true, :recipient_names => ['', 'Adam', 'John'], :quantity => 3)
      assert !purchase.valid?
      assert_contains purchase.errors[:base], "There should be #{purchase.quantity} recipient names"
    end
  end

  fast_context "mailing address" do

    should "validate presence if mailing address is required" do
      purchase = Factory.build(:daily_deal_purchase, :fulfillment_method => "ship")
      assert !purchase.valid?
      assert purchase.errors.on(:mailing_address).grep(/blank/).present?
    end

    should "not validate presence if mailing address is not required" do
      purchase = Factory.build(:daily_deal_purchase, :fulfillment_method => "email")
      assert purchase.valid?
    end

    should "validate the mailing address if it should be validated" do
      invalid_address = Factory.build(:address, :city => nil)
      purchase = Factory.build(:daily_deal_purchase, :fulfillment_method => "ship", :mailing_address => invalid_address)
      assert !purchase.valid?
      assert purchase.mailing_address.errors.on(:city).present?
    end

    should "not validate the mailing address if it should not be validated" do
      invalid_address = Factory.build(:address, :city => nil)
      purchase = Factory.build(:daily_deal_purchase, :fulfillment_method => "email", :mailing_address => invalid_address)
      assert purchase.valid?, purchase.errors.full_messages
    end

  end

  context "#executed_via_payment_unless_free" do
    should "add an error when the purchase should create a payment" do
      purchase = Factory(:captured_daily_deal_purchase)
      assert purchase.creates_payment?
      purchase.daily_deal_payment.delete
      assert_nil purchase.reload.daily_deal_payment
      assert !purchase.valid?
      assert_equal "Daily deal payment must be present if executed", purchase.errors[:daily_deal_payment]
    end

    should "not add errors when purchase does not require a payment" do
      purchase = Factory(:captured_daily_deal_purchase)
      purchase.daily_deal_payment.delete
      assert_nil purchase.reload.daily_deal_payment
      purchase.daily_deal.publisher.payment_method = "travelsavers"
      purchase.daily_deal.publisher.save!
      assert !purchase.creates_payment?
      assert purchase.valid?
    end
  end

  fast_context "max_quantity with daily deal" do

    setup do
      @daily_deal = Factory(:daily_deal, :max_quantity => 3)
      @consumer   = Factory(:consumer, :publisher => @daily_deal.publisher)
    end

    fast_context "with no current purchases" do

      should "be able purchase 3 deals" do
        assert Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer, :quantity => 3).valid?, "should be able to purchase 3 deals"
      end

      should "NOT be able to purchase 4 deals" do
        assert Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer, :quantity => 4).invalid?, "should NOT be able to purchase 3 deals"
      end

    end

    fast_context "with 2 authorized purchases" do

      setup do
        2.times do
          Factory(:authorized_daily_deal_purchase, :consumer => @consumer, :daily_deal => @daily_deal)
        end
      end

      should "be able to purchase one more deal" do
        assert Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer, :quantity => 1).valid?, "should be able to purchase 1 more deal"
      end

      should "NOT be able to purchase more than one more deal" do
        assert Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer, :quantity => 2).invalid?, "should NOT be able to purchase 2 more deals"
      end

    end

    fast_context "with 2 captured purchases" do

      setup do
        2.times do
          Factory(:captured_daily_deal_purchase, :consumer => @consumer, :daily_deal => @daily_deal)
        end
      end

      should "be able to purchase one more deal" do
        assert Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer, :quantity => 1).valid?, "should be able to purchase 1 more deal"
      end

      should "NOT be able to purchase more than one more deal" do
        assert Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer, :quantity => 2).invalid?, "should NOT be able to purchase 2 more deals"
      end

    end    

  end

  fast_context "max_quantity with daily deal variation" do

    setup do       
      @daily_deal = Factory(:daily_deal, :quantity => 200, :min_quantity => 1, :max_quantity => 2)
      @consumer   = Factory(:consumer, :publisher => @daily_deal.publisher)
      @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)

      @variation_1 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :max_quantity => 2)
      @variation_2 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :max_quantity => 3)
    end

    fast_context "with no current purchases" do

      should "be able purchase 2 of variation 1" do
        assert Factory.build(:daily_deal_purchase, :daily_deal_variation => @variation_1, :daily_deal => @daily_deal, :consumer => @consumer, :quantity => 2).valid?, "should be able to purchase 2 deals with variation 1"
      end

      should "NOT be able to purchase 3 of variation 1" do
        assert Factory.build(:daily_deal_purchase, :daily_deal_variation => @variation_1, :daily_deal => @daily_deal, :consumer => @consumer, :quantity => 3).invalid?, "should NOT be able to purchase 3 deals with variation 1"
      end

      should "be able purchase 3 of variation 2" do
        assert Factory.build(:daily_deal_purchase, :daily_deal_variation => @variation_2, :daily_deal => @daily_deal, :consumer => @consumer, :quantity => 3).valid?, "should be able to purchase 3 deals with variation 2"
      end

      should "NOT be able to purchase 4 of variation 2" do
        assert Factory.build(:daily_deal_purchase, :daily_deal_variation => @variation_2, :daily_deal => @daily_deal, :consumer => @consumer, :quantity => 4).invalid?, "should NOT be able to purchase 4 deals with variation 2"
      end      

    end

    fast_context "with captured purchases across different variations" do

      setup do
        Factory(:captured_daily_deal_purchase, :consumer => @consumer, :daily_deal => @daily_deal, :daily_deal_variation => @variation_1)
        Factory(:captured_daily_deal_purchase, :consumer => @consumer, :daily_deal => @daily_deal, :daily_deal_variation => @variation_2)
      end

      should "be able to purchase 1 more deal with varation 1" do
        assert Factory.build(:daily_deal_purchase, :daily_deal_variation => @variation_1, :daily_deal => @daily_deal, :consumer => @consumer, :quantity => 1).valid?, "should be able to purchase 1 deal with variation 1"
      end

      should "not be able to purchase 2 more deals with variation 1" do
        assert Factory.build(:daily_deal_purchase, :daily_deal_variation => @variation_1, :daily_deal => @daily_deal, :consumer => @consumer, :quantity => 2).invalid?, "should NOT be able to purchase 2 deals with variation 1"
      end

      should "be able to purchase 2 more deals with variation 2" do
        assert Factory.build(:daily_deal_purchase, :daily_deal_variation => @variation_2, :daily_deal => @daily_deal, :consumer => @consumer, :quantity => 2).valid?, "should be able to purchase 2 deals with variation 2"
      end

      should "not be able to purchase 3 more deals with variation 2" do
        assert Factory.build(:daily_deal_purchase, :daily_deal_variation => @variation_2, :daily_deal => @daily_deal, :consumer => @consumer, :quantity => 3).invalid?, "should NOT be able to purchase 3 deals with variation 2"
      end

    end

  end

  should "require a quantity of 1 on Travelsavers purchases" do
    purchase = Factory.build(:travelsavers_daily_deal_purchase)
    assert_equal 1, purchase.quantity
    assert purchase.valid?
    purchase.quantity = 2
    assert purchase.invalid?
    assert_equal "Quantity must be 1 for Travelsavers purchases", purchase.errors.on(:quantity)
  end

  should "not allow Travelsavers purchases to be gifts" do
    purchase = Factory.build(:travelsavers_daily_deal_purchase)
    assert !purchase.gift?
    assert purchase.valid?
    purchase.gift = true
    purchase.recipient_names = ["Bob McAlice"]
    assert purchase.invalid?
    assert_equal "Travelsavers purchases cannot be gifted", purchase.errors.on(:gift)
  end

end
