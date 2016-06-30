require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Report::Publisher::DailyDealsSummaryTest
module Report
  module Publisher

    class DailyDealsSummaryTest < ActiveSupport::TestCase

      include ReportsTestHelper

      context "with no daily deals" do

        setup do
          @publisher = Factory(:publisher)
        end

        should "return no results" do
          assert @publisher.daily_deals_summary(22.days.ago..1.day.ago).empty?, "should have empty results"
        end
      
      end

      context "with at least one daily deal, but no purchases" do

        setup do
          @daily_deal = Factory(
            :daily_deal, 
            :value_proposition => "This is the value prop!",
            :start_at => 3.days.ago, 
            :hide_at => 10.days.from_now,
            :custom_1 => "Custom 1",
            :custom_2 => "Custom 2",
            :custom_3 => "Custom 3")
          @publisher  = @daily_deal.publisher          
        end

        context "with request within daily deal date range" do

          setup do
            @results = @publisher.daily_deals_summary(22.days.ago..30.days.from_now)
          end

          should "return one result" do
            assert_equal 1, @results.size, "should have one result"
          end

          should "return the appropriate data" do
            deal = @results.first
            assert_daily_deals_summary_row(deal, {
              :start_at => @daily_deal.start_at.strftime("%Y-%m-%d"),
              :hide_at => @daily_deal.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => nil,
              :advertiser => @daily_deal.advertiser.name,
              :advertiser_listing => @daily_deal.advertiser.listing,
              :value_proposition => @daily_deal.value_proposition,
              :listing => @daily_deal.listing,
              :accounting_id => @daily_deal.accounting_id,
              :total_purchases => 0,
              :total_purchasers => 0,
              :purchases_gross => 0,
              :discount => 0,
              :refunds_quantity => 0,
              :refunds_amount => 0,
              :purchases_amount => 0,
              :account_executive => nil,
              :advertiser_revenue_share_percentage => nil,
              :advertiser_credit_percentage => nil,
              :custom_1 => @daily_deal.custom_1,
              :custom_2 => @daily_deal.custom_2,
              :custom_3 => @daily_deal.custom_3
            })
          end

        end

        context "with request outside of the daily deal range" do

          setup do
            @results = @publisher.daily_deals_summary(1.year.ago..45.days.ago)
          end

          should "not return any results" do
            assert @results.empty?, "should have empty results"
          end
 
        end

      end   

      context "with at least one daily deal, with purchases" do

        setup do
          @daily_deal = Factory(
            :daily_deal, 
            :value_proposition => "I am deal with purchases",
            :start_at => 3.days.ago,
            :hide_at => 10.days.from_now,
            :price => 20.00,
            :value => 40.00
          )
          @publisher  = @daily_deal.publisher

          @purchase_1 = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1)
          @purchase_2 = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1)
        end

        context "with request within daily deal data range" do

          setup do
            @results = @publisher.daily_deals_summary(22.days.ago..30.days.from_now)
          end

          should "return on result" do
            assert_equal 1, @results.size, "should have one result"
          end

          should "return the appropriate data" do
            deal = @results.first
            assert_daily_deals_summary_row(deal, {
              :start_at => @daily_deal.start_at.strftime("%Y-%m-%d"),
              :hide_at => @daily_deal.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => nil,
              :advertiser => @daily_deal.advertiser.name,
              :advertiser_listing => @daily_deal.advertiser.listing,
              :value_proposition => @daily_deal.value_proposition,
              :listing => @daily_deal.listing,
              :accounting_id => @daily_deal.accounting_id,
              :total_purchases => 2,
              :total_purchasers => 2,
              :purchases_gross => 40.00,
              :discount => 0,
              :refunds_quantity => 0,
              :refunds_amount => 0,
              :purchases_amount => 40.00,
              :account_executive => nil,
              :advertiser_revenue_share_percentage => nil,
              :advertiser_credit_percentage => nil,
              :custom_1 => @daily_deal.custom_1,
              :custom_2 => @daily_deal.custom_2,
              :custom_3 => @daily_deal.custom_3
            })
           
          end

        end

      end

      context "with multiple deals, with purchases, discounts and refunds" do

        setup do
          @publisher    = Factory(:publisher)
          @daily_deal_1 = Factory(:daily_deal, :publisher => @publisher, :start_at => 7.days.ago, :hide_at => 6.days.ago, :price => 30.00)
          @daily_deal_2 = Factory(:daily_deal, :publisher => @publisher, :start_at => 5.days.ago, :hide_at => 4.days.ago, :price => 50.00)

          @daily_deal_1_purchase_1 = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal_1, :quantity => 1)
          @daily_deal_1_purchase_2 = Factory(:captured_daily_deal_purchase_with_discount, :daily_deal => @daily_deal_1, :quantity => 1)

          @daily_deal_2_purchase_1 = Factory(:pending_daily_deal_purchase, :daily_deal => @daily_deal_2, :quantity => 2)
          @daily_deal_2_purchase_2 = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal_2, :quantity => 1)
          @daily_deal_2_purchase_3 = Factory(:refunded_daily_deal_purchase, :daily_deal => @daily_deal_2, :quantity => 1)
        end

        context "with request within daily deal date ranges" do

          setup do
            @results = @publisher.daily_deals_summary(22.days.ago..30.days.from_now)
          end

          should "return 2 results" do
            assert_equal 2, @results.size, "there should be 2 results"
          end

          should "return the correct info for daily_deal_1" do
            deal = @results.first
            assert_daily_deals_summary_row(deal, {
              :start_at => @daily_deal_1.start_at.strftime("%Y-%m-%d"),
              :hide_at => @daily_deal_1.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => nil,
              :advertiser => @daily_deal_1.advertiser.name,
              :advertiser_listing => @daily_deal_1.advertiser.listing,
              :value_proposition => @daily_deal_1.value_proposition,
              :listing => @daily_deal_1.listing,
              :accounting_id => @daily_deal_1.accounting_id,
              :total_purchases => 2,
              :total_purchasers => 2,
              :purchases_gross => 60.00,
              :discount => 10.0,
              :refunds_quantity => 0,
              :refunds_amount => 0,
              :purchases_amount => 50.00,
              :account_executive => nil,
              :advertiser_revenue_share_percentage => nil,
              :advertiser_credit_percentage => nil,
              :custom_1 => @daily_deal_1.custom_1,
              :custom_2 => @daily_deal_1.custom_2,
              :custom_3 => @daily_deal_1.custom_3
            })

          end

          should "return the correct info for daily_deal_2" do
            deal = @results.last
            assert_daily_deals_summary_row(deal, {
              :start_at => @daily_deal_2.start_at.strftime("%Y-%m-%d"),
              :hide_at => @daily_deal_2.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => nil,
              :advertiser => @daily_deal_2.advertiser.name,
              :advertiser_listing => @daily_deal_2.advertiser.listing,
              :value_proposition => @daily_deal_2.value_proposition,
              :listing => @daily_deal_2.listing,
              :accounting_id => @daily_deal_2.accounting_id,
              :total_purchases => 2,
              :total_purchasers => 2,
              :purchases_gross => 100.00,
              :discount => 0,
              :refunds_quantity => 1,
              :refunds_amount => 50,
              :purchases_amount => 100.00,
              :account_executive => nil,
              :advertiser_revenue_share_percentage => nil,
              :advertiser_credit_percentage => nil,
              :custom_1 => @daily_deal_2.custom_1,
              :custom_2 => @daily_deal_2.custom_2,
              :custom_3 => @daily_deal_2.custom_3
            })
          end

        end

      end

      context "with publisher with markets" do

        setup do
          @publisher = Factory(:publisher)
          @market_1  = Factory(:market, :publisher => @publisher, :name => "Market 1")
          @market_2  = Factory(:market, :publisher => @publisher, :name => "Market 2")

          @market_1_deal_1 = Factory(:daily_deal, :publisher => @publisher, :start_at => 10.days.ago, :hide_at => 9.days.ago, :price => 20.00)
          @market_1_deal_1.markets << @market_1

          @market_1_deal_2 = Factory(:daily_deal, :publisher => @publisher, :start_at => 8.days.ago, :hide_at => 7.days.ago, :price => 30.00)
          @market_1_deal_2.markets << @market_1

          @market_2_deal_1 = Factory(:daily_deal, :publisher => @publisher, :start_at => 6.days.ago, :hide_at => 5.days.ago, :price => 40.00)
          @market_2_deal_1.markets << @market_2

          @market_2_deal_2 = Factory(:daily_deal, :publisher => @publisher, :start_at => 4.days.ago, :hide_at => 3.days.ago, :price => 50.00)
          @market_2_deal_2.markets << @market_2

          @market_2_deal_3 = Factory(:daily_deal, :publisher => @publisher, :start_at => 2.days.ago, :hide_at => 1.days.ago, :price => 60.00)
          @market_2_deal_3.markets << @market_2

          @publisher.reload
        end

        should "have 2 deals for @market_1" do
          assert_equal 2, @market_1.reload.daily_deals.size, "market_1 should have 2 deals"
        end

        should "have 3 deals for @market_2" do
          assert_equal 3, @market_2.reload.daily_deals.size, "market_2 should have 3 deals"
        end

        context "with purchases" do

          setup do
            @market_1_deal_1_purchase_1 = Factory(:captured_daily_deal_purchase, :quantity => 1, :daily_deal => @market_1_deal_1, :market => @market_1)
            @market_1_deal_1_purchase_2 = Factory(:captured_daily_deal_purchase, :quantity => 2, :daily_deal => @market_1_deal_1, :market => @market_1)
            @market_1_deal_2_purchase_1 = Factory(:refunded_daily_deal_purchase, :quantity => 1, :daily_deal => @market_1_deal_2, :market => @market_1)

            @market_2_deal_1_purchase_1 = Factory(:captured_daily_deal_purchase_with_discount, :quantity => 1, :daily_deal => @market_2_deal_1, :market => @market_2)
            @market_2_deal_2_purchase_1 = Factory(:captured_daily_deal_purchase, :quantity => 3, :daily_deal => @market_2_deal_2, :market => @market_2)
          end

          context "market_1" do

            setup do
              @results = @publisher.daily_deals_summary(22.days.ago..30.days.from_now, @market_1)
            end

            should "return 2 results" do
              assert_equal 2, @results.size, "should have two results for @market_1"
            end

            should "render the appropriate information for @market_1_deal_1" do
              deal = @results.first
              assert_daily_deals_summary_row(deal, {
                :start_at => @market_1_deal_1.start_at.strftime("%Y-%m-%d"),
                :hide_at => @market_1_deal_1.hide_at.strftime("%Y-%m-%d"),
                :source_publisher => nil,
                :advertiser => @market_1_deal_1.advertiser.name,
                :advertiser_listing => @market_1_deal_1.advertiser.listing,
                :value_proposition => @market_1_deal_1.value_proposition,
                :listing => @market_1_deal_1.listing,
                :accounting_id => @market_1_deal_1.accounting_id,
                :total_purchases => 3,
                :total_purchasers => 2,
                :purchases_gross => 60.00,
                :discount => 0,
                :refunds_quantity => 0,
                :refunds_amount => 0,
                :purchases_amount => 60.00,
                :account_executive => nil,
                :advertiser_revenue_share_percentage => nil,
                :advertiser_credit_percentage => nil,
                :custom_1 => @market_1_deal_1.custom_1,
                :custom_2 => @market_1_deal_1.custom_2,
                :custom_3 => @market_1_deal_1.custom_3
              })
            end

            should "render the appropriate information for @market_1_deal_2" do
              deal = @results.last
              assert_daily_deals_summary_row(deal, {
                :start_at => @market_1_deal_2.start_at.strftime("%Y-%m-%d"),
                :hide_at => @market_1_deal_2.hide_at.strftime("%Y-%m-%d"),
                :source_publisher => nil,
                :advertiser => @market_1_deal_2.advertiser.name,
                :advertiser_listing => @market_1_deal_2.advertiser.listing,
                :value_proposition => @market_1_deal_2.value_proposition,
                :listing => @market_1_deal_2.listing,
                :accounting_id => @market_1_deal_2.accounting_id,
                :total_purchases => 1,
                :total_purchasers => 1,
                :purchases_gross => 30.00,
                :discount => 0,
                :refunds_quantity => 1,
                :refunds_amount => 30.00,
                :purchases_amount => 30.00,
                :account_executive => nil,
                :advertiser_revenue_share_percentage => nil,
                :advertiser_credit_percentage => nil,
                :custom_1 => @market_1_deal_2.custom_1,
                :custom_2 => @market_1_deal_2.custom_2,
                :custom_3 => @market_1_deal_2.custom_3
              })
            end

          end

          context "market_2" do

            setup do
              @results = @publisher.daily_deals_summary(22.days.ago..30.days.from_now, @market_2)
            end

            should "return 2 results" do
              assert_equal 2, @results.size, "should have two results for @market_2, since only two deals have purchases"
            end

            should "render the appropriate information for @market_2_deal_1" do
              deal = @results.first
              assert_daily_deals_summary_row(deal, {
                :start_at => @market_2_deal_1.start_at.strftime("%Y-%m-%d"),
                :hide_at => @market_2_deal_1.hide_at.strftime("%Y-%m-%d"),
                :source_publisher => nil,
                :advertiser => @market_2_deal_1.advertiser.name,
                :advertiser_listing => @market_2_deal_1.advertiser.listing,
                :value_proposition => @market_2_deal_1.value_proposition,
                :listing => @market_2_deal_1.listing,
                :accounting_id => @market_2_deal_1.accounting_id,
                :total_purchases => 1,
                :total_purchasers => 1,
                :purchases_gross => 40.00,
                :discount => 10.00,
                :refunds_quantity => 0,
                :refunds_amount => 0,
                :purchases_amount => 30.00,
                :account_executive => nil,
                :advertiser_revenue_share_percentage => nil,
                :advertiser_credit_percentage => nil,
                :custom_1 => @market_2_deal_1.custom_1,
                :custom_2 => @market_2_deal_1.custom_2,
                :custom_3 => @market_2_deal_1.custom_3
              })
            end     

            should "render the appropriate information for @market_2_deal_2" do
              deal = @results.last
              assert_daily_deals_summary_row(deal, {
                :start_at => @market_2_deal_2.start_at.strftime("%Y-%m-%d"),
                :hide_at => @market_2_deal_2.hide_at.strftime("%Y-%m-%d"),
                :source_publisher => nil,
                :advertiser => @market_2_deal_2.advertiser.name,
                :advertiser_listing => @market_2_deal_2.advertiser.listing,
                :value_proposition => @market_2_deal_2.value_proposition,
                :listing => @market_2_deal_2.listing,
                :accounting_id => @market_2_deal_2.accounting_id,
                :total_purchases => 3,
                :total_purchasers => 1,
                :purchases_gross => 150.00,
                :discount => 0,
                :refunds_quantity => 0,
                :refunds_amount => 0,
                :purchases_amount => 150.00,
                :account_executive => nil,
                :advertiser_revenue_share_percentage => nil,
                :advertiser_credit_percentage => nil,
                :custom_1 => @market_2_deal_2.custom_1,
                :custom_2 => @market_2_deal_2.custom_2,
                :custom_3 => @market_2_deal_2.custom_3
              })
            end

          end


        end

      end

      context "with variations" do

        setup do
          @publisher    = Factory(:publisher, :enable_daily_deal_variations => true)
          @deal_1       = Factory(:daily_deal, :publisher => @publisher, :start_at => 10.days.ago, :hide_at => 9.days.ago, :price => 20.00)
          @deal_2       = Factory(:daily_deal, :publisher => @publisher, :start_at => 5.days.ago, :hide_at => 4.days.ago, :price => 35.00)

          @deal_1_variation_1 = Factory(:daily_deal_variation, :daily_deal => @deal_1, :price => 15.0, :value_proposition => "D1V1")
          @deal_1_variation_2 = Factory(:daily_deal_variation, :daily_deal => @deal_1, :price => 30.0, :value_proposition => "D1V2")

          @deal_2_variation_1 = Factory(:daily_deal_variation, :daily_deal => @deal_2, :price => 7.0, :value_proposition => "D2V1")
          @deal_2_variation_2 = Factory(:daily_deal_variation, :daily_deal => @deal_2, :price => 9.0, :value_proposition => "D2V2")
          @deal_2_variation_3 = Factory(:daily_deal_variation, :daily_deal => @deal_2, :price => 11.0, :value_proposition => "D2V3")
        end  

        context "with no purchases" do

          setup do
            @results = @publisher.daily_deals_summary(22.days.ago..30.days.from_now).sort do |a,b| 
              # just so we can have a consist return order
              a.daily_deal_or_variation_value_proposition <=> b.daily_deal_or_variation_value_proposition
            end
          end

          should "display 5 results for @publisher" do
            assert_equal 5, @results.size, "there should be 5 results based on the 5 variations"
          end

          should "render appropriate no purchase data for each of the variations" do
            expected_variations = [@deal_1_variation_1, @deal_1_variation_2, @deal_2_variation_1, @deal_2_variation_2, @deal_2_variation_3]
            expected_variations.each_with_index do |expected, index|
              actual   = @results[index]
              assert_daily_deals_summary_row(actual, {
                :start_at => expected.start_at.strftime("%Y-%m-%d"),
                :hide_at => expected.hide_at.strftime("%Y-%m-%d"),
                :source_publisher => expected.source_publisher.try(:name),
                :advertiser => expected.advertiser.name,
                :advertiser_listing => expected.advertiser.listing,
                :value_proposition => expected.value_proposition,
                :listing => expected.listing,
                :accounting_id => expected.daily_deal.accounting_id_for_variation(expected),
                :total_purchases => 0,
                :total_purchasers => 0,
                :purchases_gross => 0,
                :discount => 0,
                :refunds_quantity => 0,
                :refunds_amount => 0,
                :purchases_amount => 0,
                :account_executive => nil,
                :advertiser_revenue_share_percentage => nil,
                :advertiser_credit_percentage => nil,
                :custom_1 => expected.custom_1,
                :custom_2 => expected.custom_2,
                :custom_3 => expected.custom_3
              })            
            end
          end

        end

        context "with purchases, refunds and discounts" do

          setup do
            @deal_1_variation_1_purchase_1 = Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :daily_deal_variation => @deal_1_variation_1, :quantity => 2 )
            @deal_1_variation_1_purchase_2 = Factory(:refunded_daily_deal_purchase, :daily_deal => @deal_1, :daily_deal_variation => @deal_1_variation_1, :quantity => 1 )

            @deal_2_variation_1_purchase_1 = Factory(:captured_daily_deal_purchase_with_discount, :daily_deal => @deal_2, :daily_deal_variation => @deal_2_variation_1, :quantity => 2)
            @deal_2_variation_1_purchase_2 = Factory(:pending_daily_deal_purchase, :daily_deal => @deal_2, :daily_deal_variation => @deal_2_variation_1, :quantity => 3)

            @deal_2_variation_3_purchase_1 = Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :daily_deal_variation => @deal_2_variation_3, :quantity => 3)

            @results = @publisher.daily_deals_summary(22.days.ago..30.days.from_now).sort do |a,b|
              a.daily_deal_or_variation_value_proposition <=> b.daily_deal_or_variation_value_proposition
            end
          end 

          should "display 5 results for @publisher" do
            assert_equal 5, @results.size, "there should be 5 results based on the 5 variations"
          end

          should "render the appropriate data for @deal_1_variation_1" do
            actual    = @results[0]
            expected  = @deal_1_variation_1
            assert_daily_deals_summary_row(actual, {
              :start_at => expected.start_at.strftime("%Y-%m-%d"),
              :hide_at => expected.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => expected.source_publisher.try(:name),
              :advertiser => expected.advertiser.name,
              :advertiser_listing => expected.advertiser.listing,
              :value_proposition => expected.value_proposition,
              :listing => expected.listing,
              :accounting_id => @deal_1.accounting_id_for_variation(@deal_1_variation_1),
              :total_purchases => 3,
              :total_purchasers => 2,
              :purchases_gross => 45.0,
              :discount => 0,
              :refunds_quantity => 1,
              :refunds_amount => 15.00,
              :purchases_amount => 45.00,
              :account_executive => nil,
              :advertiser_revenue_share_percentage => nil,
              :advertiser_credit_percentage => nil,
              :custom_1 => expected.custom_1,
              :custom_2 => expected.custom_2,
              :custom_3 => expected.custom_3
            })                
          end

          should "render the appropriate data for @deal_1_variation_2 (no purchases)" do
            actual    = @results[1]
            expected  = @deal_1_variation_2
            assert_daily_deals_summary_row(actual, {
              :start_at => expected.start_at.strftime("%Y-%m-%d"),
              :hide_at => expected.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => expected.source_publisher.try(:name),
              :advertiser => expected.advertiser.name,
              :advertiser_listing => expected.advertiser.listing,
              :value_proposition => expected.value_proposition,
              :listing => expected.listing,
              :accounting_id => @deal_1.accounting_id_for_variation(@deal_1_variation_2),
              :total_purchases => 0,
              :total_purchasers => 0,
              :purchases_gross => 0,
              :discount => 0,
              :refunds_quantity => 0,
              :refunds_amount => 0,
              :purchases_amount => 0,
              :account_executive => nil,
              :advertiser_revenue_share_percentage => nil,
              :advertiser_credit_percentage => nil,
              :custom_1 => expected.custom_1,
              :custom_2 => expected.custom_2,
              :custom_3 => expected.custom_3
            })                
          end

          should "render the appropriate data for @deal_2_variation_1" do
            actual    = @results[2]
            expected  = @deal_2_variation_1
            assert_daily_deals_summary_row(actual, {
              :start_at => expected.start_at.strftime("%Y-%m-%d"),
              :hide_at => expected.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => expected.source_publisher.try(:name),
              :advertiser => expected.advertiser.name,
              :advertiser_listing => expected.advertiser.listing,
              :value_proposition => expected.value_proposition,
              :listing => expected.listing,
              :accounting_id => @deal_2.accounting_id_for_variation(@deal_2_variation_1),
              :total_purchases => 2,
              :total_purchasers => 1,
              :purchases_gross => 14.0,
              :discount => 10.0,
              :refunds_quantity => 0,
              :refunds_amount => 0,
              :purchases_amount => 4.0,
              :account_executive => nil,
              :advertiser_revenue_share_percentage => nil,
              :advertiser_credit_percentage => nil,
              :custom_1 => expected.custom_1,
              :custom_2 => expected.custom_2,
              :custom_3 => expected.custom_3
            })                
          end

          should "render the appropriate data for @deal_2_variation_2 (no purchases)" do
            actual    = @results[3]
            expected  = @deal_2_variation_2
            assert_daily_deals_summary_row(actual, {
              :start_at => expected.start_at.strftime("%Y-%m-%d"),
              :hide_at => expected.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => expected.source_publisher.try(:name),
              :advertiser => expected.advertiser.name,
              :advertiser_listing => expected.advertiser.listing,
              :value_proposition => expected.value_proposition,
              :listing => expected.listing,
              :accounting_id => @deal_2.accounting_id_for_variation(@deal_2_variation_2),
              :total_purchases => 0,
              :total_purchasers => 0,
              :purchases_gross => 0,
              :discount => 0,
              :refunds_quantity => 0,
              :refunds_amount => 0,
              :purchases_amount => 0,
              :account_executive => nil,
              :advertiser_revenue_share_percentage => nil,
              :advertiser_credit_percentage => nil,
              :custom_1 => expected.custom_1,
              :custom_2 => expected.custom_2,
              :custom_3 => expected.custom_3
            })                
          end

          should "render the appropriate data for @deal_2_variation_3" do
            actual    = @results[4]
            expected  = @deal_2_variation_3
            assert_daily_deals_summary_row(actual, {
              :start_at => expected.start_at.strftime("%Y-%m-%d"),
              :hide_at => expected.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => expected.source_publisher.try(:name),
              :advertiser => expected.advertiser.name,
              :advertiser_listing => expected.advertiser.listing,
              :value_proposition => expected.value_proposition,
              :listing => expected.listing,
              :accounting_id => @deal_2.accounting_id_for_variation(@deal_2_variation_3),
              :total_purchases => 3,
              :total_purchasers => 1,
              :purchases_gross => 33.00,
              :discount => 0,
              :refunds_quantity => 0,
              :refunds_amount => 0,
              :purchases_amount => 33.00,
              :account_executive => nil,
              :advertiser_revenue_share_percentage => nil,
              :advertiser_credit_percentage => nil,
              :custom_1 => expected.custom_1,
              :custom_2 => expected.custom_2,
              :custom_3 => expected.custom_3
            })                
          end        


        end

      end

      context "with daily deal missing listing" do

        setup do
          @publisher    = Factory(:publisher)
          @daily_deal_1 = Factory(:daily_deal, :publisher => @publisher, :start_at => 7.days.ago, :hide_at => 6.days.ago, :price => 30.00)
          @daily_deal_2 = Factory(:daily_deal, :publisher => @publisher, :start_at => 5.days.ago, :hide_at => 4.days.ago, :price => 50.00)

          @daily_deal_1.update_attribute(:listing, nil)
          @daily_deal_2.update_attribute(:listing, nil)

          @daily_deal_1_purchase_1 = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal_1, :quantity => 1)
          @daily_deal_1_purchase_2 = Factory(:captured_daily_deal_purchase_with_discount, :daily_deal => @daily_deal_1, :quantity => 1)

          @daily_deal_2_purchase_1 = Factory(:pending_daily_deal_purchase, :daily_deal => @daily_deal_2, :quantity => 2)
          @daily_deal_2_purchase_2 = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal_2, :quantity => 1)
          @daily_deal_2_purchase_3 = Factory(:refunded_daily_deal_purchase, :daily_deal => @daily_deal_2, :quantity => 1)
          @results = @publisher.daily_deals_summary(22.days.ago..30.days.from_now)
        end

        should "be no listing on @daily_deal_1 and @daily_deal_2" do
          assert_nil @daily_deal_1.listing
          assert_nil @daily_deal_2.listing
        end

        should "return two listings" do
          assert_equal 2, @results.size, "there should be two listings"
        end

      end
      
    end
    
  end
end