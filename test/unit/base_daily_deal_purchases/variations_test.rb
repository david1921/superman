require File.dirname(__FILE__) + "/../../test_helper"

# hydra class BaseDailyDealPurchases::VariationsTest

module BaseDailyDealPurchases
  
  class VariationsTest < ActiveSupport::TestCase

    context "value_proposition, price, and value delegation" do

      setup do
        @daily_deal_purchase = Factory(:pending_daily_deal_purchase)
        @daily_deal          = @daily_deal_purchase.daily_deal
        @daily_deal.update_attributes(:value_proposition_subhead => "daily deal subhead", :voucher_headline => "daily deal voucher headline", :terms => "daily deal terms")
      end

      context "with no daily deal variation" do

        should "delegate to daily deal" do
          assert_equal @daily_deal.value_proposition, @daily_deal_purchase.value_proposition
          assert_equal @daily_deal.value_proposition_subhead, @daily_deal_purchase.value_proposition_subhead
          assert_equal @daily_deal.voucher_headline, @daily_deal_purchase.voucher_headline
          assert_equal @daily_deal.price, @daily_deal_purchase.price
          assert_equal @daily_deal.value, @daily_deal_purchase.value
          assert_equal @daily_deal.line_item_name, @daily_deal_purchase.line_item_name
          assert_equal @daily_deal.humanize_value, @daily_deal_purchase.humanize_value
          assert_equal @daily_deal.humanize_price, @daily_deal_purchase.humanize_price
          assert_equal @daily_deal.terms, @daily_deal_purchase.terms
        end

      end

      context "with a daily deal variation" do

        setup do
          @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)
          @variation = Factory(:daily_deal_variation, 
                                  :daily_deal => @daily_deal, 
                                  :value_proposition => "VARIATION Value Proposition", 
                                  :value_proposition_subhead => "VARIATION Value Proposition Subhead",
                                  :voucher_headline => "VARIATION voucher headline",
                                  :price => @daily_deal.price + 20.0, 
                                  :value => @daily_deal.value + 20.0,
                                  :terms => "VARIATION terms")
          @daily_deal_purchase.update_attribute(:daily_deal_variation, @variation)
        end

        should "delegate to variation" do
          assert_equal @variation.value_proposition, @daily_deal_purchase.value_proposition
          assert_equal @variation.price, @daily_deal_purchase.price
          assert_equal @variation.value, @daily_deal_purchase.value
          assert_equal @variation.line_item_name, @daily_deal_purchase.line_item_name
          assert_equal @variation.humanize_value, @daily_deal_purchase.humanize_value
          assert_equal @variation.humanize_price, @daily_deal_purchase.humanize_price
          assert_equal @variation.terms, @daily_deal_purchase.terms
        end

      end

    end    
    
  end
  
end
