require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Report::Publisher::SyndicationDailyDealsSummaryTest
module Report
  module Publisher

    class SyndicationDailyDealsSummaryTest < ActiveSupport::TestCase

      include ReportsTestHelper

      context "with a syndicated daily deal" do

        setup do
          @source_deal = Factory(:daily_deal_for_syndication, :price => 30.00)
          @source_publisher = @source_deal.publisher

          @distributed_publisher = Factory(:publisher)
          @distributed_deal = syndicate( @source_deal, @distributed_publisher )
        end

        context "with purchases just on the source deal" do

          setup do
            @source_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @source_deal)            
            @results = @distributed_publisher.daily_deals_summary(22.days.ago..30.days.from_now)
          end

          should "return a result set of 1" do
            assert_equal 1, @results.size
          end

          should "return the appropriate data (no purchase data)" do
            deal = @results.first
            assert_daily_deals_summary_row(deal, {
              :start_at => @distributed_deal.start_at.strftime("%Y-%m-%d"),
              :hide_at => @distributed_deal.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => @distributed_deal.source_publisher.try(:name),
              :advertiser => @distributed_deal.advertiser.name,
              :advertiser_listing => @distributed_deal.advertiser.listing,
              :value_proposition => @distributed_deal.value_proposition,
              :accounting_id => @distributed_deal.accounting_id,
              :listing => @distributed_deal.listing,
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
              :custom_1 => @distributed_deal.custom_1,
              :custom_2 => @distributed_deal.custom_2,
              :custom_3 => @distributed_deal.custom_3
            })            
          end

        end

        context "with purchases on the distributed deal" do

          setup do
            @distributed_deal_purchase_1 = Factory(:captured_daily_deal_purchase, :quantity => 2, :daily_deal => @distributed_deal)
            @distributed_deal_purchase_2 = Factory(:refunded_daily_deal_purchase, :quantity => 1, :daily_deal => @distributed_deal)
            @results = @distributed_publisher.daily_deals_summary(22.days.ago..30.days.from_now)
          end

          should "return a result set of 1" do
            assert_equal 1, @results.size
          end

          should "return the appropriate data" do
            deal = @results.first
            assert_daily_deals_summary_row(deal, {
              :start_at => @distributed_deal.start_at.strftime("%Y-%m-%d"),
              :hide_at => @distributed_deal.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => @distributed_deal.source_publisher.try(:name),
              :advertiser => @distributed_deal.advertiser.name,
              :advertiser_listing => @distributed_deal.advertiser.listing,
              :value_proposition => @distributed_deal.value_proposition,
              :listing => @distributed_deal.listing,
              :accounting_id => @distributed_deal.accounting_id,
              :total_purchases => 3,
              :total_purchasers => 2,
              :purchases_gross => 90.00,
              :discount => 0,
              :refunds_quantity => 1,
              :refunds_amount => 30.00,
              :purchases_amount => 90.00,
              :account_executive => nil,
              :advertiser_revenue_share_percentage => nil,
              :advertiser_credit_percentage => nil,
              :custom_1 => @distributed_deal.custom_1,
              :custom_2 => @distributed_deal.custom_2,
              :custom_3 => @distributed_deal.custom_3
            })
          end

        end

      end

      context "with variations and syndication" do

        setup do
          @source_deal = Factory(:daily_deal_for_syndication, :price => 30.00)
          @source_publisher = @source_deal.publisher
          @source_publisher.update_attribute( :enable_daily_deal_variations, true )

          @variation_1 = Factory(:daily_deal_variation, :daily_deal => @source_deal, :price => 7.00, :value_proposition => "S1V1" )
          @variation_2 = Factory(:daily_deal_variation, :daily_deal => @source_deal, :price => 9.00, :value_proposition => "S1V2")
          @variation_3 = Factory(:daily_deal_variation, :daily_deal => @source_deal, :price => 11.00, :value_proposition => "S1V3" )

          @distributed_publisher = Factory(:publisher, :enable_daily_deal_variations => true)
          @distributed_deal = syndicate( @source_deal, @distributed_publisher )
        end

        context "with no purchases" do

          setup do
            @results = @distributed_publisher.daily_deals_summary(22.days.ago..30.days.from_now).sort do |a,b|
              a.daily_deal_or_variation_value_proposition <=> b.daily_deal_or_variation_value_proposition
            end
          end

          should "have 3 results for @distributed_publisher" do
            assert_equal 3, @results.size, "there should be 3 entries for @distributed_publisher"
          end

          should "render the appropriate data for @variation_1" do
            actual    = @results[0]
            expected  = @variation_1
            assert_daily_deals_summary_row(actual, {
              :start_at => expected.start_at.strftime("%Y-%m-%d"),
              :hide_at => expected.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => @distributed_deal.source_publisher.try(:name),
              :advertiser => expected.advertiser.name,
              :advertiser_listing => expected.advertiser.listing,
              :value_proposition => expected.value_proposition,
              :listing => expected.listing,
              :accounting_id => @distributed_deal.accounting_id_for_variation(@variation_1),
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

          should "render the appropriate data for @variation_2" do
            actual    = @results[1]
            expected  = @variation_2
            assert_daily_deals_summary_row(actual, {
              :start_at => expected.start_at.strftime("%Y-%m-%d"),
              :hide_at => expected.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => @distributed_deal.source_publisher.try(:name),
              :advertiser => expected.advertiser.name,
              :advertiser_listing => expected.advertiser.listing,
              :value_proposition => expected.value_proposition,
              :listing => expected.listing,
              :accounting_id => @distributed_deal.accounting_id_for_variation(@variation_2),
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

          should "render the appropriate data for @variation_3" do
            actual    = @results[2]
            expected  = @variation_3
            assert_daily_deals_summary_row(actual, {
              :start_at => expected.start_at.strftime("%Y-%m-%d"),
              :hide_at => expected.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => @distributed_deal.source_publisher.try(:name),
              :advertiser => expected.advertiser.name,
              :advertiser_listing => expected.advertiser.listing,
              :value_proposition => expected.value_proposition,
              :listing => expected.listing,
              :accounting_id => @distributed_deal.accounting_id_for_variation(@variation_3),
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

        context "with purchases with discounts, refunds across the different variations for @distributed_publisher" do

          setup do
            @variation_1_purchase_1 = Factory(:captured_daily_deal_purchase, :daily_deal => @distributed_deal, :daily_deal_variation => @variation_1, :quantity => 1)
            @variation_1_purchase_2 = Factory(:captured_daily_deal_purchase, :daily_deal => @distributed_deal, :daily_deal_variation => @variation_1, :quantity => 2)

            @variation_3_purchase_1 = Factory(:captured_daily_deal_purchase_with_discount, :daily_deal => @distributed_deal, :daily_deal_variation => @variation_3, :quantity =>1 )
            @variation_3_purchase_2 = Factory(:refunded_daily_deal_purchase, :daily_deal => @distributed_deal, :daily_deal_variation => @variation_3, :quantity => 1)

            @results = @distributed_publisher.daily_deals_summary(22.days.ago..30.days.from_now).sort do |a,b|
              a.daily_deal_or_variation_value_proposition <=> b.daily_deal_or_variation_value_proposition
            end            
          end

          should "return 3 results" do
            assert_equal 3, @results.size, "should have 3 results"
          end

          should "render the appropriate data for @variation_1" do
            actual    = @results[0]
            expected  = @variation_1
            assert_daily_deals_summary_row(actual, {
              :start_at => expected.start_at.strftime("%Y-%m-%d"),
              :hide_at => expected.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => @distributed_deal.source_publisher.try(:name),
              :advertiser => expected.advertiser.name,
              :advertiser_listing => expected.advertiser.listing,
              :value_proposition => expected.value_proposition,
              :listing => expected.listing,
              :accounting_id => @distributed_deal.accounting_id_for_variation(@variation_1),
              :total_purchases => 3,
              :total_purchasers => 2,
              :purchases_gross => 21.00,
              :discount => 0,
              :refunds_quantity => 0,
              :refunds_amount => 0,
              :purchases_amount => 21.00,
              :account_executive => nil,
              :advertiser_revenue_share_percentage => nil,
              :advertiser_credit_percentage => nil,
              :custom_1 => expected.custom_1,
              :custom_2 => expected.custom_2,
              :custom_3 => expected.custom_3
            })               
          end

          should "render the appropriate data for @variation_2" do
            actual    = @results[1]
            expected  = @variation_2
            assert_daily_deals_summary_row(actual, {
              :start_at => expected.start_at.strftime("%Y-%m-%d"),
              :hide_at => expected.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => @distributed_deal.source_publisher.try(:name),
              :advertiser => expected.advertiser.name,
              :advertiser_listing => expected.advertiser.listing,
              :value_proposition => expected.value_proposition,
              :listing => expected.listing,
              :accounting_id => @distributed_deal.accounting_id_for_variation(@variation_2),
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

          should "render the appropriate data for @variation_3" do
            actual    = @results[2]
            expected  = @variation_3
            assert_daily_deals_summary_row(actual, {
              :start_at => expected.start_at.strftime("%Y-%m-%d"),
              :hide_at => expected.hide_at.strftime("%Y-%m-%d"),
              :source_publisher => @distributed_deal.source_publisher.try(:name),
              :advertiser => expected.advertiser.name,
              :advertiser_listing => expected.advertiser.listing,
              :value_proposition => expected.value_proposition,
              :listing => expected.listing,
              :accounting_id => @distributed_deal.accounting_id_for_variation(@variation_3),
              :total_purchases => 2,
              :total_purchasers => 2,
              :purchases_gross => 22.00,
              :discount => 10.00,
              :refunds_quantity => 1,
              :refunds_amount => 11.00,
              :purchases_amount => 12.00,
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
      
    end
    
  end
end