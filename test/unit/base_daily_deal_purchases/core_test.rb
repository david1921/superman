require File.dirname(__FILE__) + "/../../test_helper"

class BaseDailyDealPurchases::CoreTest < ActiveSupport::TestCase
  context "#consumer_name and #consumer_email" do
    should "return nil when consumer is nil" do
      purchase = Factory(:off_platform_daily_deal_purchase)
      assert_nil purchase.consumer_name
      assert_nil purchase.consumer_email
    end

    should "return consumer's name when consumer is not nil" do
      deal = Factory(:daily_deal)
      consumer = Factory(:consumer, :publisher => deal.publisher)
      purchase = Factory(:daily_deal_purchase, :daily_deal => deal, :consumer => consumer)
      assert_equal consumer.name, purchase.consumer_name
      assert_equal consumer.email, purchase.consumer_email
    end
  end

  context "#origin_name" do
    should "return Analog Analytics" do
      deal = Factory(:daily_deal)
      consumer = Factory(:consumer, :publisher => deal.publisher)
      purchase = Factory(:daily_deal_purchase, :daily_deal => deal, :consumer => consumer)
      assert_equal "Analog Analytics", purchase.origin_name
    end
  end

  context "#send_purchase_confirmation!" do
    should "enqueue the SendCertificates job with own id" do
      purchase = Factory(:captured_daily_deal_purchase)
      Resque.expects(:enqueue).with(SendCertificates, purchase.id)
      purchase.send_purchase_confirmation!
    end
  end

end
