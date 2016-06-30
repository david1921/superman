require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Consumers::AssimilationTest
class Consumers::AssimilationTest < ActiveSupport::TestCase

  context "Assimilation" do

    setup do
      @publishing_group = Factory(:publishing_group,
                                  :allow_single_sign_on => true,
                                  :unique_email_across_publishing_group => true)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @deal = Factory(:daily_deal, :publisher => @publisher)
      @deal2 = Factory(:side_daily_deal, :publisher => @publisher)
      @borg = Factory(:consumer, :publisher => @publisher)
      @consumer = Factory(:consumer, :publisher => @publisher)
    end

    context "assimilate_purchases" do

      should "work if there are no purchases" do
        assert_equal 0, @consumer.daily_deal_purchases.size
        assert_equal 0, @borg.daily_deal_purchases.size
        @borg.assimilate!(@consumer)
        assert_equal 0, @borg.daily_deal_purchases.size
      end

      should "assimilate one purchase if have none already" do
        purchase = Factory(:daily_deal_purchase, :daily_deal => @deal, :consumer => @consumer)
        @borg.assimilate!(@consumer)
        purchase.reload
        @borg.reload
        @consumer.reload
        assert_equal 0, @consumer.daily_deal_purchases.size
        assert_equal 1, @borg.daily_deal_purchases.size
        assert_equal @borg, purchase.consumer
      end

      should "add multiple purchases to existing purchases" do
        existing_borg_purchases = [
          Factory(:daily_deal_purchase, :daily_deal => @deal, :consumer => @borg),
          Factory(:daily_deal_purchase, :daily_deal => @deal, :consumer => @borg)
        ]
        consumer_purchases = [
          Factory(:daily_deal_purchase, :daily_deal => @deal, :consumer => @consumer),
          Factory(:daily_deal_purchase, :daily_deal => @deal, :consumer => @consumer),
          Factory(:daily_deal_purchase, :daily_deal => @deal, :consumer => @consumer)
        ]
        @borg.assimilate!(@consumer)
        @borg.reload
        @consumer.reload
        assert_equal 0, @consumer.daily_deal_purchases.size
        assert_equal 5, @borg.daily_deal_purchases.size
        (existing_borg_purchases + consumer_purchases).each do |purchase|
          assert @borg.daily_deal_purchases.include?(purchase)
          purchase.reload
          assert_equal @borg, purchase.consumer
        end
      end

      should "work if the payment has been executed" do
        purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @deal, :consumer => @consumer)
        @borg.assimilate!(@consumer)
        purchase.reload
        @borg.reload
        @consumer.reload
        assert_equal 0, @consumer.daily_deal_purchases.size
        assert_equal 1, @borg.daily_deal_purchases.size
        assert_equal @borg, purchase.consumer
      end
    end

    context "assimilate orders" do

      should "add multiple orders to existing orders" do
        existing_borg_order = Factory(:daily_deal_order, :consumer => @borg)
        existing_consumer_orders = [
          Factory(:daily_deal_order, :consumer => @consumer),
          Factory(:daily_deal_order, :consumer => @consumer)
        ]
        @borg.assimilate!(@consumer)
        @borg.reload
        @consumer.reload
        assert_equal 0, @consumer.daily_deal_orders.size
        assert_equal 3, @borg.daily_deal_orders.size
        ([existing_borg_order] + existing_consumer_orders).each do |order|
          assert @borg.daily_deal_orders.include?(order)
          order.reload
          assert_equal @borg, order.consumer
        end
      end

    end

    context "assimilate!.credits" do

      should "add multiple new credits to existing credits" do
        existing_borg_credit = Factory(:credit, :consumer => @borg)
        existing_consumer_credits = [
          Factory(:credit, :consumer => @consumer),
          Factory(:credit, :consumer => @consumer)
        ]
        @borg.assimilate!(@consumer)
        @borg.reload
        @consumer.reload
        assert_equal 0, @consumer.credits.size
        assert_equal 3, @borg.credits.size
        ([existing_borg_credit] + existing_consumer_credits).each do |credit|
          assert @borg.credits.include?(credit)
          credit.reload
          assert_equal @borg, credit.consumer
        end
      end
    end

    context "assimilate! sweepstake entries" do
      should "add sweepstake entries to consumer" do
        sweepstake = Factory(:sweepstake, :publisher => @publisher)
        sweepstake2 = Factory(:sweepstake, :publisher => @publisher)
        borg_entry = Factory(:sweepstake_entry, :sweepstake => sweepstake, :consumer => @borg)
        consumer_entries = [
          Factory(:sweepstake_entry,:sweepstake => sweepstake, :consumer => @consumer),
          Factory(:sweepstake_entry, :sweepstake => sweepstake2, :consumer => @consumer)
        ]
        @borg.assimilate!(@consumer)
        @borg.reload
        @consumer.reload
        assert_equal 0, @consumer.sweepstake_entries.size
        assert_equal 3, @borg.sweepstake_entries.size
        ([borg_entry] + consumer_entries).each do |entry|
          assert @borg.sweepstake_entries.include?(entry)
          entry.reload
          assert_equal @borg, entry.consumer
        end
      end
    end

    context "assimilate daily deal categories" do
      should "combine categories during assimilation" do
        cats = 5.times.map { Factory(:daily_deal_category) }
        @borg.daily_deal_categories << cats[0]
        @borg.daily_deal_categories << cats[1]
        @borg.daily_deal_categories << cats[2]
        @consumer.daily_deal_categories << cats[2]
        @consumer.daily_deal_categories << cats[3]
        @consumer.daily_deal_categories << cats[4]
        assert_equal 3, @borg.daily_deal_categories.size
        @borg.assimilate!(@consumer)
        assert_equal 5, @borg.daily_deal_categories.size
        cats.each do |cat|
          assert @borg.daily_deal_categories.include?(cat)
        end
      end
    end

  end
end
