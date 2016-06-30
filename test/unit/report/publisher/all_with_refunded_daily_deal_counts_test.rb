require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Report::Publisher::AllWithRefundedDailyDealCounts

module Report
  module Publisher

    class AllWithRefundedDailyDealCounts < ActiveSupport::TestCase
      
      def setup
        @pub1 = Factory(:publisher, :label => "pub1", :name => "Pub1")
        @pub2 = Factory(:publisher, :label => "pub2", :name => "Pub2")
        
        @pub1_advertiser1 = Factory(:advertiser, :publisher => @pub1, :name => "Pub1 Advertiser1")
        @pub1_advertiser2 = Factory(:advertiser, :publisher => @pub1, :name => "Pub1 Advertiser2")
        
        @pub2_advertiser1 = Factory(:advertiser, :publisher => @pub2, :name => "Pub2 Advertiser1")
      end
      
      context "with no daily_deals" do
        
        should "return no results" do
          assert ::Publisher.all_with_refunded_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2]).empty?, "should have empty results"
        end
        
      end
      
      context "with at least one daily deal, but no purchases" do
        
        setup do
          @daily_deal = Factory(:daily_deal, :start_at => 10.days.ago, :hide_at => 3.days.from_now, :advertiser => @pub1_advertiser1)
        end
        
        should "return no results" do
          assert ::Publisher.all_with_refunded_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2]).empty?, "should have empty results"
        end
        
      end      
      
      context "with daily deals and purchases" do
        
        context "with just one purchase on @pub1" do
          
          setup do
            @pub1_deal1     = Factory(:daily_deal, :advertiser => @pub1_advertiser1, :start_at => 20.days.ago, :hide_at => 5.days.ago)
            @pub1_consumer1 = Factory(:consumer, :activated_at => 2.years.ago, :publisher => @pub1, :name => "Pub1 Consumer1")
            
            @purchased_deal = Factory(:captured_daily_deal_purchase, :daily_deal => @pub1_deal1, :consumer => @pub1_consumer1, :executed_at => 10.days.ago)            
          end
          
          context "with no refunds" do
            
            should "return no results" do
              assert ::Publisher.all_with_refunded_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2]).empty?, "should have empty results"
            end
            
          end
          
          context "with a refund on the purchase" do
            
            setup do
              Factory(:refunded_daily_deal_purchase, :daily_deal => @purchased_deal.daily_deal, :refunded_at => @purchased_deal.executed_at + 1.day)
              @results = ::Publisher.all_with_refunded_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2])
            end
            
            should "have one result" do
              assert_equal 1, @results.size
            end
            
            should "display the correct information for @pub1" do
              assert_summary_refund_row_data(@results.first, {
                :name => @pub1.name,
                :deals_with_refunds => 1,
                :refunded_vouchers => 1,
                :purchasers => 1,              
                :currency => "$",
                :gross_refunded => @pub1_deal1.price,
                :discounts => 0.00,
                :total_refunded => @pub1_deal1.price
              })
            end
            
          end
          
          context "with a refund on the purchase, but deal price has been updated" do
            
            setup do
              @expected_refund = @purchased_deal.price.to_f
              Factory(:refunded_daily_deal_purchase, :daily_deal => @purchased_deal.daily_deal, :refunded_at => @purchased_deal.executed_at + 1.day)
              @purchased_deal.daily_deal.update_attribute(:price, @purchased_deal.price + 2.00)
              @results = ::Publisher.all_with_refunded_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2])
            end
            
            should "have one result" do
              assert_equal 1, @results.size
            end
            
            should "display the correct information for @pub1" do
              assert_summary_refund_row_data(@results.first, {
                :name => @pub1.name,
                :deals_with_refunds => 1,
                :refunded_vouchers => 1,
                :purchasers => 1,              
                :currency => "$",
                :gross_refunded => @expected_refund,
                :discounts => 0.00,
                :total_refunded => @expected_refund
              })
            end            
            
          end
          
        end
        
        context "with a multiple purchases on @pub1" do
          
          setup do
            @pub1_deal1     = Factory(:daily_deal, :advertiser => @pub1_advertiser1, :start_at => 20.days.ago, :hide_at => 5.days.ago)
            @pub1_consumer1 = Factory(:consumer, :activated_at => 2.years.ago, :publisher => @pub1, :name => "Pub1 Consumer1")            
            Factory(:captured_daily_deal_purchase, :daily_deal => @pub1_deal1, :consumer => @pub1_consumer1, :executed_at => 10.days.ago)
            
            @pub1_deal2     = Factory(:daily_deal, :advertiser => @pub1_advertiser2, :start_at => 15.days.ago, :hide_at => 5.days.ago)
            @pub1_consumer2 = Factory(:consumer, :activated_at => 2.years.ago, :publisher => @pub1, :name => "Pub1 Consumer1")            
            Factory(:captured_daily_deal_purchase, :daily_deal => @pub1_deal2, :consumer => @pub1_consumer2, :executed_at => 7.days.ago, :quantity => 2)
          end
          
          context "with no refunds" do
            
            should "have no results" do
              assert ::Publisher.all_with_refunded_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2]).empty?, "should have empty results"
            end
            
          end
          
          context "with a refund on just @deal 2" do
            
            setup do
              Factory(:refunded_daily_deal_purchase, :daily_deal => @pub1_deal2, :refunded_at => 6.days.ago)
              @results = ::Publisher.all_with_refunded_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2])
            end
            
            should "return only one result row" do
              assert_equal 1, @results.size
            end
            
            should "display the correct information for @pub1" do
              assert_summary_refund_row_data(@results.first, {
                :name => @pub1.name,
                :deals_with_refunds => 1,
                :refunded_vouchers => 1,
                :purchasers => 1,              
                :currency => "$",
                :gross_refunded => @pub1_deal2.price,
                :discounts => 0.00,
                :total_refunded => @pub1_deal2.price
              })
            end
                        
          end
          
          context "with a refund on @deal 1 and 2" do
            
            setup do
              Factory(:refunded_daily_deal_purchase, :daily_deal => @pub1_deal1, :refunded_at => 5.days.ago)
              Factory(:refunded_daily_deal_purchase, :daily_deal => @pub1_deal2, :refunded_at => 6.days.ago)
              @results = ::Publisher.all_with_refunded_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2])
            end
            
            should "return only one result row" do
              assert_equal 1, @results.size
            end
            
            should "display the correct information for @pub1" do
              assert_summary_refund_row_data(@results.first, {
                :name => @pub1.name,
                :deals_with_refunds => 2,
                :refunded_vouchers => 2,
                :purchasers => 2,              
                :currency => "$",
                :gross_refunded => @pub1_deal1.price + @pub1_deal2.price,
                :discounts => 0.00,
                :total_refunded => @pub1_deal1.price + @pub1_deal2.price
              })
            end            
            
          end
          
        end
        
      end
      
      private

      def assert_summary_refund_row_data(row, data = {})
        assert_equal data[:name], row.name, "expected publisher name"
        assert_equal data[:deals_with_refunds], row.daily_deals_count, "expected correct number for daily deal count"
        assert_equal data[:refunded_vouchers], row.daily_deal_refunded_vouchers_count, "expected correct number for refunded voucher count"
        assert_equal data[:purchasers], row.daily_deal_purchasers_count, "expected correct number for daily deal purchasers count"        
        assert_equal data[:currency], row.currency_symbol, "expected correct publisher currency"
        assert_equal data[:gross_refunded], row.daily_deal_refunded_vouchers_gross, "expected gross refunded"
        assert_equal data[:discounts], row.daily_deal_refunded_vouchers_gross - row.daily_deal_refunded_vouchers_amount, "expected discount"
        assert_equal data[:total_refunded], row.daily_deal_refunded_vouchers_amount, "expected total refunded"
      end
      
      
      
    end
  end
end
