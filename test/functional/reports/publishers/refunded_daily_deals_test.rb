require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Reports::Publishers::RefundedDailyDealsTest

module Reports
  module Publishers
    class RefundedDailyDealsTest < ActionController::TestCase
      tests Reports::PublishersController

      test "refunded daily deals page" do
        refunded_daily_deal_purchase = Factory(:refunded_daily_deal_purchase)
        user = Factory(:user, :company => refunded_daily_deal_purchase.daily_deal.publisher)
        login_as user
        get(:refunded_daily_deals,
            :id => refunded_daily_deal_purchase.daily_deal.publisher.to_param,
            :dates_begin => Time.zone.now.beginning_of_month.to_s,
            :dates_end => Time.zone.now.end_of_month.to_s
        )
        assert_response :success
        assert_equal refunded_daily_deal_purchase.daily_deal.publisher, assigns(:publisher)
        assert_nil assigns(:market)
      end

      test "refunded daily deals page as admin" do
        refunded_daily_deal_purchase = Factory(:refunded_daily_deal_purchase)
        login_as Factory(:admin)
        get(:refunded_daily_deals,
            :id => refunded_daily_deal_purchase.daily_deal.publisher.to_param,
            :dates_begin => Time.zone.now.beginning_of_month.to_s,
            :dates_end => Time.zone.now.end_of_month.to_s
        )
        assert_response :success
        assert_equal refunded_daily_deal_purchase.daily_deal.publisher, assigns(:publisher)
        assert_nil assigns(:market)
      end

      test "refunded daily deals by market page" do
        refunded_daily_deal_purchase = Factory(:refunded_daily_deal_purchase)
        user = Factory(:user, :company => refunded_daily_deal_purchase.daily_deal.publisher)
        login_as user
        get(:refunded_daily_deals_by_market,
            :id => refunded_daily_deal_purchase.daily_deal.publisher.to_param,
            :dates_begin => Time.zone.now.beginning_of_month.to_s,
            :dates_end => Time.zone.now.end_of_month.to_s
        )
        assert_response :success
        assert_equal refunded_daily_deal_purchase.daily_deal.publisher, assigns(:publisher)
        assert_nil assigns(:market)
      end

      test "refunded daily deals by market page as admin" do
        refunded_daily_deal_purchase = Factory(:refunded_daily_deal_purchase)
        login_as Factory(:admin)
        get(:refunded_daily_deals_by_market,
            :id => refunded_daily_deal_purchase.daily_deal.publisher.to_param,
            :dates_begin => Time.zone.now.beginning_of_month.to_s,
            :dates_end => Time.zone.now.end_of_month.to_s
        )
        assert_response :success
        assert_equal refunded_daily_deal_purchase.daily_deal.publisher, assigns(:publisher)
        assert_nil assigns(:market)
      end

      context "refunded daily deals by market" do
        setup do
          setup_market_tests
          login_as Factory(:admin)
        end

        should "render xml" do

          get(:refunded_daily_deals_by_market,
              :format => "xml",
              :id => @publisher.to_param,
              :dates_begin => @report_date_begin.to_formatted_s(:db_date),
              :dates_end => @report_date_end.to_formatted_s(:db_date)
          )
          assert_response :success
          assert_equal @publisher, assigns(:publisher)

          formatted_begin_date = @report_date_begin.to_formatted_s(:db_date)
          formatted_end_date = @report_date_end.to_formatted_s(:db_date)
          assert_select "markets market" do
            assert_select "market_name", "No Market"
            assert_select "market_href", "/reports/publishers/#{@publisher.id}/refunded_daily_deals?dates_begin=#{formatted_begin_date}&amp;amp;dates_end=#{formatted_end_date}"
            assert_select "deals_count", "1"
            assert_select "currency_code", "USD"
            assert_select "currency_symbol", "$"
            assert_select "refunded_vouchers_count", "2"
            assert_select "deal_purchasers_count", "1"
            assert_select "refunded_deals_gross", "30.0"
            assert_select "refunded_deals_discount", "0.0"
            assert_select "refunded_deals_amount", "30.0"
          end

          assert_select "markets market##{@market_1.id}" do
            assert_select "market_name", @market_1.name
            assert_select "market_href", "/reports/publishers/#{@publisher.id}/markets/#{@market_1.id}/refunded_daily_deals?dates_begin=#{formatted_begin_date}&amp;amp;dates_end=#{formatted_end_date}"
            assert_select "deals_count", "1"
            assert_select "currency_code", "USD"
            assert_select "currency_symbol", "$"
            assert_select "refunded_vouchers_count", "2"
            assert_select "deal_purchasers_count", "1"
            assert_select "refunded_deals_gross", "30.0"
            assert_select "refunded_deals_discount", "0.0"
            assert_select "refunded_deals_amount", "30.0"
          end

          assert_select "markets market##{@market_2.id}" do
            assert_select "market_name", @market_2.name
            assert_select "market_href", "/reports/publishers/#{@publisher.id}/markets/#{@market_2.id}/refunded_daily_deals?dates_begin=#{formatted_begin_date}&amp;amp;dates_end=#{formatted_end_date}"
            assert_select "deals_count", "2"
            assert_select "currency_code", "USD"
            assert_select "currency_symbol", "$"
            assert_select "refunded_vouchers_count", "4"
            assert_select "deal_purchasers_count", "2"
            assert_select "refunded_deals_gross", "60.0"
            assert_select "refunded_deals_discount", "5.0"
            assert_select "refunded_deals_amount", "55.0"
          end

        end

        should "render csv" do

          get(:refunded_daily_deals_by_market,
              :format => "csv",
              :id => @publisher.to_param,
              :dates_begin => @report_date_begin.to_formatted_s(:db_date),
              :dates_end => @report_date_end.to_formatted_s(:db_date)
          )
          assert_response :success
          assert_equal @publisher, assigns(:publisher)

          csv = FasterCSV.new(@response.binary_content)
          assert_equal [
                         "Market",
                         "Deals w/ Refunds",
                         "Refunded Vouchers",
                         "Purchasers",
                         "Currency Code",
                         "Gross Refunded",
                         "Discount",
                         "Total Refunded"
                       ], csv.shift, "CSV headers"

          row = csv.shift
          assert_equal "No Market", row[0]
          assert_equal "1", row[1]
          assert_equal "2", row[2]
          assert_equal "1", row[3]
          assert_equal "USD", row[4]
          assert_equal "30.0", row[5]
          assert_equal "0.0", row[6]
          assert_equal "30.0", row[7]

          row = csv.shift
          assert_equal @market_1.name, row[0]
          assert_equal "1", row[1]
          assert_equal "2", row[2]
          assert_equal "1", row[3]
          assert_equal "USD", row[4]
          assert_equal "30.0", row[5]
          assert_equal "0.0", row[6]
          assert_equal "30.0", row[7]

          row = csv.shift
          assert_equal @market_2.name, row[0]
          assert_equal "2", row[1]
          assert_equal "4", row[2]
          assert_equal "2", row[3]
          assert_equal "USD", row[4]
          assert_equal "60.0", row[5]
          assert_equal "5.0", row[6]
          assert_equal "55.0", row[7]

        end

      end

      context "refunded daily deals with market filter" do
        setup do
          setup_market_tests
          login_as Factory(:admin)
        end

        should "render xml with deals in market only" do
          formatted_date_begin = @report_date_begin.to_formatted_s(:db_date)
          formatted_date_end = @report_date_end.to_formatted_s(:db_date)
          get(:refunded_daily_deals,
              :format => "xml",
              :id => @publisher.to_param,
              :market_id => @market_2.to_param,
              :dates_begin => formatted_date_begin,
              :dates_end => formatted_date_end
          )
          assert_response :success
          assert_equal @publisher, assigns(:publisher)
          assert_equal @market_2, assigns(:market)

          assert_select "daily_deals daily_deal##{@daily_deal_1.id}" do
            assert_select "advertiser_name", @daily_deal_1.advertiser.name
            assert_select "advertiser_href", "/reports/advertisers/#{@daily_deal_1.advertiser.id}/markets/#{@market_2.id}/refunded_daily_deals?dates_begin=#{formatted_date_begin}&amp;amp;dates_end=#{formatted_date_end}"
            assert_select "accounting_id", @daily_deal_1.accounting_id
            assert_select "listing", @daily_deal_1.listing
            assert_select "value_proposition", "deal_1"
            assert_select "currency_code", "USD"
            assert_select "currency_symbol", "$"
            assert_select "refunded_purchases_count", "1"
            assert_select "refunded_purchasers_count", "1"
            assert_select "refunded_vouchers_count", "1"
            assert_select "refunds_gross", "15.0"
            assert_select "refunds_discount", "0.0"
            assert_select "refunds_amount", "15.0"
          end

          assert_select "daily_deals daily_deal##{@daily_deal_2.id}" do
            assert_select "advertiser_name", @daily_deal_2.advertiser.name
            assert_select "advertiser_href", "/reports/advertisers/#{@daily_deal_2.advertiser.id}/markets/#{@market_2.id}/refunded_daily_deals?dates_begin=#{formatted_date_begin}&amp;amp;dates_end=#{formatted_date_end}"
            assert_select "accounting_id", @daily_deal_2.accounting_id
            assert_select "listing", @daily_deal_2.listing
            assert_select "value_proposition", "deal_2"
            assert_select "currency_code", "USD"
            assert_select "currency_symbol", "$"
            assert_select "refunded_purchases_count", "1"
            assert_select "refunded_purchasers_count", "1"
            assert_select "refunded_vouchers_count", "3"
            assert_select "refunds_gross", "45.0"
            assert_select "refunds_discount", "5.0"
            assert_select "refunds_amount", "40.0"
          end

        end

        should "render csv with deals in market only" do
          get(:refunded_daily_deals,
              :format => "csv",
              :id => @publisher.to_param,
              :market_id => @market_2.to_param,
              :dates_begin => @report_date_begin.to_formatted_s(:db_date),
              :dates_end => @report_date_end.to_formatted_s(:db_date)
          )
          assert_response :success
          assert_equal @publisher, assigns(:publisher)
          assert_equal @market_2, assigns(:market)

          csv = FasterCSV.new(@response.binary_content)

          assert_equal [
                         "Started At",
                         "Advertiser",
                         "Accounting ID",
                         "Listing",
                         "Value Proposition",
                         "Purchasers Refunded",
                         "Purchases Refunded",
                         "Vouchers Refunded",
                         "Currency Code",
                         "Gross Refunded",
                         "Discount",
                         "Total Refunded",
                         "Custom 1",
                         "Custom 2",
                         "Custom 3"
                       ], csv.shift, "CSV headers"

          row = csv.shift
          assert_equal @daily_deal_1.start_at.to_s(:compact), row[0]
          assert_equal @daily_deal_1.advertiser_name, row[1]
          assert_equal @daily_deal_1.accounting_id, row[2]
          assert_equal @daily_deal_1.listing, row[3]
          assert_equal @daily_deal_1.value_proposition, row[4]
          assert_equal "1", row[5]
          assert_equal "1", row[6]
          assert_equal "1", row[7]
          assert_equal "USD", row[8]
          assert_equal "15.0", row[9]
          assert_equal "0.0", row[10]
          assert_equal "15.0", row[11]
          assert_equal nil, row[12]
          assert_equal nil, row[13]
          assert_equal nil, row[14]

          row = csv.shift
          assert_equal @daily_deal_2.start_at.to_s(:compact), row[0]
          assert_equal @daily_deal_2.advertiser_name, row[1]
          assert_equal @daily_deal_2.accounting_id, row[2]
          assert_equal @daily_deal_2.listing, row[3]
          assert_equal @daily_deal_2.value_proposition, row[4]
          assert_equal "1", row[5]
          assert_equal "1", row[6]
          assert_equal "3", row[7]
          assert_equal "USD", row[8]
          assert_equal "45.0", row[9]
          assert_equal "5.0", row[10]
          assert_equal "40.0", row[11]
          assert_equal nil, row[12]
          assert_equal nil, row[13]
          assert_equal nil, row[14]

        end

      end

      test "csv refunded daily deals" do
        refunded_daily_deal_purchase = Factory(:refunded_daily_deal_purchase)
        dd = refunded_daily_deal_purchase.daily_deal
        dd.update_attributes(:advertiser_revenue_share_percentage => 42, :advertiser_credit_percentage => 2,
                             :custom_1 => "custom one", :custom_2 => "custom two", :custom_3 => "custom three")
        dd.update_attribute(:price, 99.99)
        publisher = dd.publisher

        login_as Factory(:user, :company => publisher)

        get :refunded_daily_deals,
            :id          => publisher.to_param,
            :dates_begin => Time.zone.now.beginning_of_month.to_s,
            :dates_end   => Time.zone.now.end_of_month.to_s,
            :format      => "csv"

        assert_response :success

        csv  = FasterCSV.new @response.binary_content
        row0 = csv.shift
        row1 = csv.shift

        headers = ["Started At",
                   "Advertiser",
                   "Accounting ID",
                   "Listing",
                   "Value Proposition",
                   "Purchasers Refunded",
                   "Purchases Refunded",
                   "Vouchers Refunded",
                   "Currency Code",
                   "Gross Refunded",
                   "Discount",
                   "Total Refunded",
                   "Custom 1",
                   "Custom 2",
                   "Custom 3"
        ]

        assert_equal headers, row0, "first row should be headers"

        assert_equal dd.start_at.to_s(:compact), row1[0]
        assert_equal dd.advertiser_name, row1[1]
        assert_equal dd.accounting_id, row1[2]
        assert_equal dd.listing, row1[3]
        assert_equal dd.value_proposition, row1[4]
        assert_equal "1", row1[5] # Purchasers Refunded
        assert_equal "1", row1[6] # Purchases Refunded
        assert_equal "1", row1[7] # Vouchers Refunded
        assert_equal dd.currency_code, row1[8]
        assert_equal "99.99", row1[9] # Gross Refunded
        assert_equal "84.99", row1[10] # Discount
        assert_equal "15.0", row1[11] # Total Refunded
        assert_equal dd.custom_1, row1[12]
        assert_equal dd.custom_2, row1[13]
        assert_equal dd.custom_3, row1[14]
      end

      context "daily deal variations" do

        setup do
          @daily_deal = Factory(:daily_deal)
          @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)

          @variation_1 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 40.00, :price => 30.00)
          @variation_2 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 30.00, :price => 20.00)
          @variation_3 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 20.00, :price => 10.00)

          @purchase_1  = Factory(:refunded_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 2, :daily_deal_variation => @variation_1)
          @purchase_2  = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1, :daily_deal_variation => @variation_2)
          @purchase_3  = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 3, :daily_deal_variation => @variation_3)        
        end

        context "xml" do

          setup do
            login_as Factory(:admin)
            get(:refunded_daily_deals,
              :id => @daily_deal.publisher.to_param,
              :dates_begin => Time.zone.now.beginning_of_month.to_s,
              :dates_end => Time.zone.now.end_of_month.to_s,
              :format => "xml")
          end

          should "render the appropriate data" do
            assert_select "daily_deals daily_deal##{@daily_deal.id}" do
              assert_select "advertiser_name", @daily_deal.advertiser.name
              assert_select "accounting_id", @daily_deal.accounting_id
              assert_select "listing", @daily_deal.listing
              assert_select "value_proposition", @daily_deal.value_proposition
              assert_select "currency_code", "USD"
              assert_select "currency_symbol", "$"
              assert_select "refunded_purchases_count", "1"
              assert_select "refunded_purchasers_count", "1"
              assert_select "refunded_vouchers_count", "2"
              assert_select "refunds_gross", "60.0"
              assert_select "refunds_discount", "0.0"
              assert_select "refunds_amount", "60.0"              
            end
          end

        end

      end

      private

      def setup_market_tests
        @report_date_begin = (Time.zone.now - 2.days)
        @report_date_end = (Time.zone.now + 2.days)
        @publisher = Factory(:publisher)
        @daily_deal_1 = Factory(:daily_deal, :publisher => @publisher, :value_proposition => "deal_1")
        @daily_deal_2 = Factory(:side_daily_deal, :publisher => @publisher, :value_proposition => "deal_2")
        @market_1 = Factory(:market, :publisher => @publisher, :name => "Z Market A")
        @market_2 = Factory(:market, :publisher => @publisher, :name => "Z Market B")
        @daily_deal_1.markets << @market_1
        @daily_deal_1.markets << @market_2
        @daily_deal_2.markets << @market_2
        Factory(:captured_daily_deal_purchase, :quantity => 3, :daily_deal => @daily_deal_1, :market => @market_1)
        Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal_1, :market => @market_2)
        Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal_2, :market => @market_2)
        Factory(:refunded_daily_deal_purchase,
                :quantity => 2,
                :daily_deal => @daily_deal_1,
                :executed_at => @report_date_begin + 23.minutes,
                :refunded_at => @report_date_begin + 6.hours,
                :market => @market_1)
        Factory(:refunded_daily_deal_purchase,
                :daily_deal => @daily_deal_1,
                :executed_at => @report_date_begin + 20.minutes,
                :refunded_at => @report_date_begin + 1.day,
                :market => @market_2)
        Factory(:refunded_daily_deal_purchase,
                :daily_deal => @daily_deal_2,
                :quantity => 3,
                :executed_at => @report_date_begin + 20.minutes,
                :refunded_at => @report_date_begin + 1.day,
                :discount => Factory(:discount, :publisher => @publisher, :amount => 5),
                :market => @market_2)
        Factory(:refunded_daily_deal_purchase,
                :daily_deal => @daily_deal_2,
                :quantity => 2,
                :executed_at => @report_date_begin + 20.minutes,
                :refunded_at => @report_date_begin + 1.day)
        #Should not be returned
        Factory(:refunded_daily_deal_purchase,
                :executed_at => @report_date_begin + 20.minutes,
                :refunded_at => @report_date_begin + 1.day)
        Factory(:refunded_daily_deal_purchase,
                :daily_deal => @daily_deal_1,
                :executed_at => @report_date_begin + 20.minutes,
                :refunded_at => @report_date_begin - 1.day)
      end

    end

  end
end

