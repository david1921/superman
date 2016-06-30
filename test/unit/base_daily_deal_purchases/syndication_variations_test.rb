require File.dirname(__FILE__) + "/../../test_helper"

# hydra class BaseDailyDealPurchases::SyndicationVariationsTest

module BaseDailyDealPurchases
  
  class SyndicationVariationsTest < ActiveSupport::TestCase

    context "source deal with variations" do

      setup do
        @source_deal = Factory(:daily_deal_for_syndication, 
          :value_proposition => "daily deal value prop", 
          :value_proposition_subhead => "daily deal value prop subhead",
          :terms => "daily deal terms",
          :price => 100.00,
          :value => 200.00 )
        @source_deal.publisher.update_attribute(:enable_daily_deal_variations, true)
        @variation = Factory(:daily_deal_variation, 
          :daily_deal => @source_deal, 
          :price => 50.00, 
          :value => 100.00,
          :value_proposition => "daily deal variation value propostion")
      end

      should "have 1 daily deal variation" do
        assert_equal 1, @source_deal.daily_deal_variations.size
      end

      context "with a daily deal purchase with a distributed deal" do

        setup do
          @distributed_publisher = Factory(:publisher, :enable_daily_deal_variations => true)
          @distributed_publisher_consumer = Factory(:consumer, :publisher => @distributed_publisher)
          @distributed_deal = syndicate( @source_deal, @distributed_publisher )

          @daily_deal_purchase = Factory(:pending_daily_deal_purchase, 
            :daily_deal => @distributed_deal, 
            :daily_deal_variation => @variation, 
            :consumer => @distributed_publisher_consumer)
        end

        should "reference the @distributed_deal for the daily deal on purchase" do
          assert_equal @distributed_deal, @daily_deal_purchase.daily_deal
        end

        should "reference the @variations for the daily_deal_variation on the purchase" do
          assert_equal @variation, @daily_deal_purchase.daily_deal_variation
        end

        should "get price, value, etc from the daily deal variation and not the distributed_deal" do
          assert_equal @variation.price, @daily_deal_purchase.price
          assert_equal @variation.value, @daily_deal_purchase.value
          assert_equal @variation.value_proposition, @daily_deal_purchase.value_proposition
        end

      end

    end
    
  end
  
end
