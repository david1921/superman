require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Report::Publisher::AllWithPurchasedDailyDealCountsTest
module Report
  module Publisher

    class AllWithPurchasedDailyDealCountsTest < ActiveSupport::TestCase
      
      def setup
        @pub1 = Factory(:publisher, :label => "pub1", :name => "Pub1")
        @pub2 = Factory(:publisher, :label => "pub2", :name => "Pub2")
        
        @pub1_advertiser1 = Factory(:advertiser, :publisher => @pub1, :name => "Pub1 Advertiser1")
        @pub1_advertiser2 = Factory(:advertiser, :publisher => @pub1, :name => "Pub1 Advertiser2")
        
        @pub2_advertiser1 = Factory(:advertiser, :publisher => @pub2, :name => "Pub2 Advertiser1")
      end
      
      context "with no daily_deals" do
        
        should "return no results" do
          assert ::Publisher.all_with_purchased_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2]).empty?, "should have empty results"
        end
        
      end
      
      context "with at least one daily deal, but no purchases" do
        
        setup do
          @daily_deal = Factory(:daily_deal, :start_at => 10.days.ago, :hide_at => 3.days.from_now, :advertiser => @pub1_advertiser1)
        end
        
        should "return no results" do
          # NOTE: Currently, the way the report stands... if there's no purchases then it doesn't pull in daily deal counts.
          # TODO: ask accounting if this is what they really want.
          assert ::Publisher.all_with_purchased_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2]).empty?, "should have empty results"
        end
        
      end
      
      context "with daily deals and purchases" do
        
        context "with just one purchase on @pub1" do
          
          setup do
            @pub1_deal1     = Factory(:daily_deal, :advertiser => @pub1_advertiser1, :start_at => 20.days.ago, :hide_at => 5.days.ago)
            @pub1_consumer1 = Factory(:consumer, :activated_at => 2.years.ago, :publisher => @pub1, :name => "Pub1 Consumer1")
            
            Factory(:captured_daily_deal_purchase, :daily_deal => @pub1_deal1, :consumer => @pub1_consumer1, :executed_at => 10.days.ago)            
            @results = ::Publisher.all_with_purchased_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2])
          end
          
          should "have 1 result" do
            assert_equal 1, @results.size
          end
          
          should "display the correct information for @pub1" do
            assert_summary_daily_deal_row_data(@results.first, {
              :name => @pub1.name,
              :purchasers => 1,              
              :purchases => 1,
              :gross => @pub1_deal1.price,
              :net => @pub1_deal1.price,
              :refunds => 0.00,
              :discounts => 0.00
            })
          end
          
        end
        
        context "with just one purchase on @pub1, but deal price and purchased price differ" do
          
          setup do
            @pub1_deal1     = Factory(:daily_deal, :advertiser => @pub1_advertiser1, :start_at => 20.days.ago, :hide_at => 5.days.ago)
            @pub1_consumer1 = Factory(:consumer, :activated_at => 2.years.ago, :publisher => @pub1, :name => "Pub1 Consumer1")
          end

          context "with a purchase quantity of 1" do

            setup do
              @purchased_deal = Factory(:captured_daily_deal_purchase, :daily_deal => @pub1_deal1, :consumer => @pub1_consumer1, :executed_at => 10.days.ago, :quantity => 1)            
              @expected_price = (@pub1_deal1.price * @purchased_deal.quantity).to_f
              assert @pub1_deal1.update_attribute(:price, @pub1_deal1.price + 2.00), "should allow simulating a price change after purchases"
              @results = ::Publisher.all_with_purchased_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2])            
            end

            should "have 1 result" do
              assert_equal 1, @results.size
            end

            should "display the correct information for @pub1 and the purchased deal" do
              assert_summary_daily_deal_row_data(@results.first, {
                :name => @pub1.name,
                :purchasers => 1,
                :purchases => 1,
                :gross => @expected_price,
                :net => @expected_price,
                :refunds => 0.00,
                :discounts => 0.00
              })
            end
            
          end
          
          context "with a purchase quantity of 2" do

            setup do
              @purchased_deal = Factory(:captured_daily_deal_purchase, :daily_deal => @pub1_deal1, :consumer => @pub1_consumer1, :executed_at => 10.days.ago, :quantity => 2)            
              @expected_price = (@pub1_deal1.price * @purchased_deal.quantity).to_f
              assert @pub1_deal1.update_attribute(:price, @pub1_deal1.price + 2.00), "should allow simulating a price change after purchases"
              @results = ::Publisher.all_with_purchased_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2])            
            end

            should "have 1 result" do
              assert_equal 1, @results.size
            end

            should "display the correct information for @pub1 and the purchased deal" do
              assert_summary_daily_deal_row_data(@results.first, {
                :name => @pub1.name,
                :purchasers => 1,
                :purchases => 2,
                :gross => @expected_price,
                :net => @expected_price,
                :refunds => 0.00,
                :discounts => 0.00
              })
            end            
            
          end
          
        end        
        
        context "with purchases on @pub1 and @pub2" do
          
          setup do
            @pub1_deal1     = Factory(:daily_deal, :advertiser => @pub1_advertiser1, :start_at => 20.days.ago, :hide_at => 5.days.ago)
            @pub1_consumer1 = Factory(:consumer, :activated_at => 2.years.ago, :publisher => @pub1, :name => "Pub1 Consumer1")            
            Factory(:captured_daily_deal_purchase, :daily_deal => @pub1_deal1, :consumer => @pub1_consumer1, :executed_at => 10.days.ago)
            
            @pub1_deal2     = Factory(:daily_deal, :advertiser => @pub1_advertiser2, :start_at => 15.days.ago, :hide_at => 5.days.ago)
            @pub1_consumer2 = Factory(:consumer, :activated_at => 2.years.ago, :publisher => @pub1, :name => "Pub1 Consumer1")            
            Factory(:captured_daily_deal_purchase, :daily_deal => @pub1_deal2, :consumer => @pub1_consumer2, :executed_at => 7.days.ago)
            
            @pub2_deal1     = Factory(:daily_deal, :advertiser => @pub2_advertiser1, :start_at => 20.days.ago, :hide_at => 5.days.ago)
            @pub2_consumer1 = Factory(:consumer, :activated_at => 2.years.ago, :publisher => @pub2, :name => "Pub2 Consumer1")            
            Factory(:captured_daily_deal_purchase, :daily_deal => @pub2_deal1, :consumer => @pub2_consumer1, :executed_at => 10.days.ago)
            
            @results = ::Publisher.all_with_purchased_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2])
          end
          
          should "have 2 results" do
            assert_equal 2, @results.size
          end
          
          should "display the correct information for @pub1" do
            assert_summary_daily_deal_row_data(@results.first, {
              :name => @pub1.name,
              :purchasers => 2,
              :purchases => 2,
              :gross => @pub1_deal1.price + @pub1_deal2.price,
              :net => @pub1_deal1.price + @pub1_deal2.price,
              :refunds => 0.00,
              :discounts => 0.00
            })
          end
          
          should "display the correct information for @pub2" do
            assert_summary_daily_deal_row_data(@results.second, {
              :name => @pub2.name,
              :purchasers => 1,
              :purchases => 1,
              :gross => @pub2_deal1.price,
              :net => @pub2_deal1.price,
              :refunds => 0.00,
              :discounts => 0.00
            })
            
          end
          
        end
        
        context "with refunds" do
          
          context "with a refund in the same period as the daily deal purchases" do
            
            setup do
              @pub1_deal1     = Factory(:daily_deal, :advertiser => @pub1_advertiser1, :start_at => 20.days.ago, :hide_at => 5.days.ago)
              @pub1_consumer1 = Factory(:consumer, :activated_at => 2.years.ago, :publisher => @pub1, :name => "Pub1 Consumer1")            
              @purchase1      = Factory(:captured_daily_deal_purchase, :daily_deal => @pub1_deal1, :consumer => @pub1_consumer1, :executed_at => 10.days.ago)

              @pub1_deal2     = Factory(:daily_deal, :advertiser => @pub1_advertiser2, :start_at => 15.days.ago, :hide_at => 5.days.ago)
              @pub1_consumer2 = Factory(:consumer, :activated_at => 2.years.ago, :publisher => @pub1, :name => "Pub1 Consumer1")            
              @purchase2      = Factory(:refunded_daily_deal_purchase, :daily_deal => @pub1_deal2, :consumer => @pub1_consumer2, :executed_at => 9.days.ago, :refunded_at => 7.days.ago)

              @results = ::Publisher.all_with_purchased_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2])              
            end

            should "just return 1 result" do
              assert_equal 1, @results.size
            end

            should "display the correct information for @pub1" do
              assert_summary_daily_deal_row_data(@results.first, {
                :name => @pub1.name,
                :purchasers => 2,
                :purchases => 2,
                :gross =>  @pub1_deal1.price + @pub1_deal2.price,
                :net => @pub1_deal1.price.to_f, # substracting deal2 since it's been refunded.
                :refunds => @pub1_deal2.price.to_f,
                :discounts => 0.00
              })
            end

            
          end          
          
          context "with a refund for a daily deal purchase before the range given" do
            
            setup do
              @pub1_deal1     = Factory(:daily_deal, :advertiser => @pub1_advertiser1, :start_at => 20.days.ago, :hide_at => 5.days.ago)
              @pub1_consumer1 = Factory(:consumer, :activated_at => 2.years.ago, :publisher => @pub1, :name => "Pub1 Consumer1")            
              @purchase1      = Factory(:captured_daily_deal_purchase, :daily_deal => @pub1_deal1, :consumer => @pub1_consumer1, :executed_at => 10.days.ago)

              @pub1_deal2     = Factory(:daily_deal, :advertiser => @pub1_advertiser2, :start_at => 40.days.ago, :hide_at => 30.days.ago)
              @pub1_consumer2 = Factory(:consumer, :activated_at => 2.years.ago, :publisher => @pub1, :name => "Pub1 Consumer1")            
              @purchase2      = Factory(:refunded_daily_deal_purchase, :daily_deal => @pub1_deal2, :consumer => @pub1_consumer2, :executed_at => 35.days.ago, :refunded_at => 7.days.ago)

              @results = ::Publisher.all_with_purchased_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2])              
            end
            
            should "just return 1 result" do
              assert_equal 1, @results.size
            end
            
            should "display the correct information for @pub1" do
              assert_summary_daily_deal_row_data(@results.first, {
                :name => @pub1.name,
                :purchasers => 1,
                :purchases => 1,
                :gross => @pub1_deal1.price,
                :net => @pub1_deal1.price - @pub1_deal2.price,
                :refunds => @pub1_deal2.price,
                :discounts => 0.00
              })              
            end
            
          end
          
          context "with a refund on a syndicated deal where the purchased happened before the range given" do
            
            setup do
              @pub1_deal1     = Factory(:daily_deal, :advertiser => @pub1_advertiser1, :start_at => 20.days.ago, :hide_at => 5.days.ago)
              @pub1_consumer1 = Factory(:consumer, :activated_at => 2.years.ago, :publisher => @pub1, :name => "Pub1 Consumer1")            
              @purchase1      = Factory(:captured_daily_deal_purchase, :daily_deal => @pub1_deal1, :consumer => @pub1_consumer1, :executed_at => 10.days.ago)
              
              @pub2_deal1     = Factory(:daily_deal, :advertiser => @pub2_advertiser1, :start_at => 40.days.ago, :hide_at => 30.days.ago, :available_for_syndication => true)              
              
              @pub1_deal2     = Factory(:distributed_daily_deal, :source => @pub2_deal1, :publisher => @pub1)
              @pub1_consumer2 = Factory(:consumer, :activated_at => 2.years.ago, :publisher => @pub1, :name => "Pub1 Consumer1")            
              @purchase2      = Factory(:refunded_daily_deal_purchase, :daily_deal => @pub1_deal2, :consumer => @pub1_consumer2, :executed_at => 35.days.ago, :refunded_at => 7.days.ago)
              
              @results = ::Publisher.all_with_purchased_daily_deal_counts(22.days.ago..1.day.ago, [@pub1, @pub2])              
            end
            
            should "return 1 result" do
              assert_equal 1, @results.size
            end
            
            should "display the correct information for @pub1" do
              assert_summary_daily_deal_row_data(@results.first, {
                :name => @pub1.name,
                :purchasers => 1,
                :purchases => 1,
                :gross => @pub1_deal1.price,
                :net => @pub1_deal1.price - @pub1_deal2.price,
                :refunds => @pub1_deal2.price,
                :discounts => 0.00                
              })
            end
            
            
            
          end
      
        end
                  
      end
      
      def assert_summary_daily_deal_row_data(row, data = {})
        assert_equal data[:name], row.name, "expected publisher name"
        assert_equal data[:purchasers], row.daily_deal_purchasers_count, "expected purchasers count"
        assert_equal data[:purchases], row.daily_deal_purchases_total_quantity, "expected purchases count"        
        assert_equal data[:gross], row.daily_deal_purchases_gross, "expected gross"
        assert_equal data[:discounts], row.daily_deal_purchases_gross - row.daily_deal_purchases_actual_purchase_price, "expected discount"
        assert_equal data[:refunds], row.daily_deal_purchases_refund_amount, "expected refund amount"
        assert_equal data[:net], row.daily_deal_purchases_actual_purchase_price - row.daily_deal_purchases_refund_amount, "expected net"
      end
      
    end
    
  end
end