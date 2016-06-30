require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Reports::Publishers::PurchasedDailyDealsTest

module Reports
  module Publishers
    class PurchasedDailyDealsTest < ActionController::TestCase
      tests Reports::PublishersController

      test "purchased daily deals page" do
        daily_deal_purchase = Factory(:captured_daily_deal_purchase)
        user = Factory(:user, :company => daily_deal_purchase.publisher)
        login_as user
        get(:purchased_daily_deals,
            :id => daily_deal_purchase.publisher.to_param,
            :dates_begin => Time.zone.now.beginning_of_month.to_s,
            :dates_end => Time.zone.now.end_of_month.to_s
        )
        assert_response :success
        assert_equal daily_deal_purchase.daily_deal.publisher, assigns(:publisher)
        assert_nil assigns(:market)
      end

      test "purchased daily deals page as admin" do
        daily_deal_purchase = Factory(:captured_daily_deal_purchase)
        login_as Factory(:admin)
        get(:purchased_daily_deals,
            :id => daily_deal_purchase.publisher.to_param,
            :dates_begin => Time.zone.now.beginning_of_month.to_s,
            :dates_end => Time.zone.now.end_of_month.to_s
        )
        assert_response :success
        assert_equal daily_deal_purchase.daily_deal.publisher, assigns(:publisher)
        assert_nil assigns(:market)
      end

      test "purchased daily deals with market parameter" do
        @publisher = Factory(:publisher, :self_serve => true)
        daily_deal = Factory(:daily_deal, :publisher => @publisher)
        market = Factory(:market, :publisher => @publisher)
        daily_deal.markets << market

        daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal)
        user = Factory(:user, :company => @publisher)
        login_as user
        get(:purchased_daily_deals,
            :id => daily_deal.publisher.to_param,
            :dates_begin => (Time.zone.now - 2.days).to_s,
            :dates_end => (Time.zone.now + 2.days).to_s,
            :market_id => market.to_param
        )
        assert_response :success
        assert_equal daily_deal.publisher, assigns(:publisher)
        assert_equal market, assigns(:market)
      end

      test "purchased daily deals as admin with market parameter" do
        daily_deal = Factory(:daily_deal)
        market = Factory(:market, :publisher => daily_deal.publisher)
        daily_deal.markets << market

        daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :market => market)
        login_as Factory(:admin)
        get(:purchased_daily_deals,
            :id => daily_deal.publisher.to_param,
            :dates_begin => (Time.zone.now - 2.days).to_s,
            :dates_end => (Time.zone.now + 2.days).to_s,
            :market_id => market.to_param
        )
        assert_response :success
        assert_equal daily_deal.publisher, assigns(:publisher)
        assert_equal market, assigns(:market)
      end

      test "purchased daily deals by market page" do
        @publisher = Factory(:publisher, :self_serve => true)
        daily_deal = Factory(:daily_deal, :publisher => @publisher)
        market = Factory(:market, :publisher => @publisher)
        daily_deal.markets << market

        daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal)
        user = Factory(:user, :company => @publisher)
        login_as user
        get(:purchased_daily_deals_by_market,
            :id => daily_deal.publisher.to_param,
            :dates_begin => (Time.zone.now - 2.days).to_s,
            :dates_end => (Time.zone.now + 2.days).to_s
        )
        assert_response :success
        assert_equal daily_deal.publisher, assigns(:publisher)
      end

      test "purchased daily deals by market page as admin" do
        daily_deal = Factory(:daily_deal)
        market = Factory(:market, :publisher => daily_deal.publisher)
        daily_deal.markets << market

        daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :market => market)
        login_as Factory(:admin)
        get(:purchased_daily_deals_by_market,
            :id => daily_deal.publisher.to_param,
            :dates_begin => (Time.zone.now - 2.days).to_s,
            :dates_end => (Time.zone.now + 2.days).to_s
        )
        assert_response :success
        assert_equal daily_deal.publisher, assigns(:publisher)
      end

      test "purchased daily deals by market xml" do
        daily_deal = Factory(:daily_deal)
        market_1 = Factory(:market, :publisher => daily_deal.publisher)
        market_2 = Factory(:market, :publisher => daily_deal.publisher)
        daily_deal.markets << market_1
        daily_deal.markets << market_2
        daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => 2, :daily_deal => daily_deal, :market => market_1)
        daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :market => market_1)
        daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :market => market_2)
        login_as Factory(:admin)
        query_begin = (Time.zone.now - 2.days).to_formatted_s(:db_date)
        query_end = (Time.zone.now + 2.days).to_formatted_s(:db_date)
        get(:purchased_daily_deals_by_market,
            :format => "xml",
            :id => daily_deal.publisher.to_param,
            :dates_begin => query_begin,
            :dates_end => query_end
        )
        assert_response :success
        assert_equal daily_deal.publisher, assigns(:publisher)

        assert_select "markets market##{market_1.id}" do
          assert_select "market_name", market_1.name
          assert_select "market_href", "/reports/publishers/#{daily_deal.publisher.id}/markets/#{market_1.id}/purchased_daily_deals?dates_begin=#{query_begin}&amp;amp;dates_end=#{query_end}"
          assert_select "deals_count", "1"
          assert_select "currency_code", "USD"
          assert_select "currency_symbol", "$"
          assert_select "purchased_deals_count", "3"
          assert_select "deal_purchasers_count", "2"
          assert_select "purchased_deals_gross", "45.0"
          assert_select "purchased_deals_discount", "0.0"
          assert_select "purchased_deals_refund_amount", "0.0"
          assert_select "purchased_deals_amount", "45.0"
        end

        assert_select "markets market##{market_2.id}" do
          assert_select "market_name", market_2.name
          assert_select "market_href", "/reports/publishers/#{daily_deal.publisher.id}/markets/#{market_2.id}/purchased_daily_deals?dates_begin=#{query_begin}&amp;amp;dates_end=#{query_end}"
          assert_select "deals_count", "1"
          assert_select "currency_code", "USD"
          assert_select "currency_symbol", "$"
          assert_select "purchased_deals_count", "1"
          assert_select "deal_purchasers_count", "1"
          assert_select "purchased_deals_gross", "15.0"
          assert_select "purchased_deals_discount", "0.0"
          assert_select "purchased_deals_refund_amount", "0.0"
          assert_select "purchased_deals_amount", "15.0"
        end

      end

      test "purchased daily deals by market csv" do
        daily_deal = Factory(:daily_deal)
        market_1 = Factory(:market, :publisher => daily_deal.publisher) #9
        market_2 = Factory(:market, :publisher => daily_deal.publisher) #10
        daily_deal.markets << market_1
        daily_deal.markets << market_2
        daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => 2, :daily_deal => daily_deal, :market => market_1)
        daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :market => market_1)
        daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :market => market_2)
        login_as Factory(:admin)
        query_begin = (Time.zone.now - 2.days).to_formatted_s(:db_date)
        query_end = (Time.zone.now + 2.days).to_formatted_s(:db_date)
        get(:purchased_daily_deals_by_market,
            :format => "csv",
            :id => daily_deal.publisher.to_param,
            :dates_begin => query_begin,
            :dates_end => query_end
        )
        assert_response :success
        assert_equal daily_deal.publisher, assigns(:publisher)

        csv = FasterCSV.new(@response.binary_content)
        assert_equal [
                       "Market",
                       "Deals",
                       "Purchased",
                       "Purchasers",
                       "Currency Code",
                       "Gross",
                       "Discount",
                       "Refunds",
                       "Total"
                     ], csv.shift, "CSV headers"

        csv = csv.to_a.sort

        row = csv.shift
        assert_equal daily_deal.markets.sort.first.name, row[0]
        assert_equal "1", row[1]
        assert_equal "3", row[2]
        assert_equal "2", row[3]
        assert_equal "USD", row[4]
        assert_equal "45.0", row[5]
        assert_equal "0.0", row[6]
        assert_equal "0.0", row[7]
        assert_equal "45.0", row[8]

        row = csv.shift
        assert_equal daily_deal.markets.sort.second.name, row[0]
        assert_equal "1", row[1]
        assert_equal "1", row[2]
        assert_equal "1", row[3]
        assert_equal "USD", row[4]
        assert_equal "15.0", row[5]
        assert_equal "0.0", row[6]
        assert_equal "0.0", row[7]
        assert_equal "15.0", row[8]

      end

      test "xhr purchased daily deals with adv listing enabled" do
         publisher   = Factory(:publisher, :advertiser_has_listing => true)
         advertiser  = Factory(:advertiser, :publisher => publisher, :listing => "XYZ123")
         advertiser2 = Factory(:advertiser, :publisher => publisher, :listing => "ABC")
         daily_deal  = Factory(:daily_deal, :advertiser => advertiser)
         dd_purchase = Factory(:captured_daily_deal_purchase,
                               :executed_at => "Jun 30, 2010 16:34:56 PST",
                               :daily_deal => daily_deal)

         login_as Factory(:admin)

         dates = Time.zone.parse("Jun 10, 2010")..Time.zone.parse("Jun 30, 2010")

         xhr :get, :purchased_daily_deals, {
           :id           => publisher.to_param,
           :dates_begin  => dates.begin.to_s,
           :dates_end    => dates.end.to_s,
           :format       => "xml"
         }

         assert_select "daily_deals daily_deal##{daily_deal.listing}" do
           assert_select "publisher_advertiser_id", :text => "XYZ123"
         end
       end
       test "csv purchased daily deals" do
         dd = Factory(:daily_deal, :advertiser_revenue_share_percentage => 42, :advertiser_credit_percentage => 2,
                      :custom_1 => "custom one", :custom_2 => "custom two", :custom_3 => "custom three")
         ddp = Factory(:captured_daily_deal_purchase, :daily_deal => dd)
         publisher = dd.publisher

         login_as Factory(:user, :company => publisher)

         get :purchased_daily_deals,
             :id          => publisher.to_param,
             :dates_begin => Time.zone.now.beginning_of_month.to_s,
             :dates_end   => Time.zone.now.end_of_month.to_s,
             :format      => "csv"

         assert_response :success

         csv  = FasterCSV.new @response.binary_content
         row0 = csv.shift
         row1 = csv.shift
         headers = [ "Started At",
                     "Ended At",
                     "Advertiser",
                     "Publisher Advertiser ID",
                     "Accounting ID",
                     "Listing ID",
                     "Value",
                     "Purchased",
                     "Purchasers",
                     "Currency Code",
                     "Gross",
                     "Publisher Discount",
                     "Refunds #",
                     "Refunds #{publisher.currency_symbol}",
                     "Total",
                     "Account Executive",
                     "Advertiser Rev. %",
                     "Advertiser Credit %",
                     "Custom 1",
                     "Custom 2",
                     "Custom 3"
         ]

         assert_equal headers, row0, "first row should be headers"

         assert_equal dd.start_at.to_s(:compact), row1[0]
         assert_equal dd.hide_at.to_s(:compact), row1[1]
         assert_equal dd.advertiser_name, row1[2]
         assert_equal dd.advertiser.try(:listing), row1[3]
         assert_equal dd.accounting_id, row1[4]
         assert_equal dd.listing, row1[5]
         assert_equal dd.value_proposition, row1[6]
         assert_equal dd.currency_code, row1[9]
         assert_equal dd.account_executive, row1[15]
         assert_equal dd.advertiser_revenue_share_percentage.to_s, row1[16]
         assert_equal dd.advertiser_credit_percentage.to_s, row1[17]
         assert_equal dd.custom_1, row1[18]
         assert_equal dd.custom_2, row1[19]
         assert_equal dd.custom_3, row1[20]
       end

      context "xhr purchased daily deals" do
        setup do
          @publisher = publishers(:sdh_austin)
          @publisher.advertisers.destroy_all

          ConsumerMailer.stubs(:deliver_activation_request)
          valid_user_attributes = {
            :email => "joe@blow.com",
            :name => "Joe Blow",
            :password => "secret",
            :password_confirmation => "secret",
            :agree_to_terms => "1"
          }
          c_1 = @publisher.consumers.create!( valid_user_attributes.merge(:email => "jon@hello.com", :name => "Jon Smith") )
          @c_2 = c_2 = @publisher.consumers.create!( valid_user_attributes.merge(:email => "jill@hello.com", :name => "Jill Smith") )
          c_3 = @publisher.consumers.create!( valid_user_attributes.merge(:email => "cheap@hello.com", :name => "Cheap Skate") )

          @a_1 = @publisher.advertisers.create(:name => "A1")
          @a_2 = @publisher.advertisers.create(:name => "A2")
          @a_3 = @publisher.advertisers.create(:name => "A3")

          @d_1_1 = @a_1.daily_deals.create!(
            :value_proposition => "Daily Deal 1 For A1",
            :price => 39.00,
            :value => 81.00,
            :quantity => 100,
            :terms => "these are my terms",
            :description => "this is my description",
            :start_at => Time.zone.parse("June 29, 2010 23:00:00"),
            :hide_at => Time.zone.parse("July 15, 2010 22:55:00"),
            :expires_on => Date.parse("July 30, 2011"),
            :advertiser_credit_percentage => 2
          )

          p_1_1 = @d_1_1.daily_deal_purchases.build
          p_1_1.discount = @publisher.discounts.create!(:amount => 10, :code => "yyz")
          p_1_1.quantity = 1
          p_1_1.consumer = c_1
          p_1_1.save!
          p_1_1.payment_status = "captured"
          p_1_1.executed_at = "Jun 30, 2010 14:34:56 PST"
          p_1_1.daily_deal_payment = BraintreePayment.new
          p_1_1.daily_deal_payment.payment_gateway_id = "301181650"
          p_1_1.daily_deal_payment.amount = "29.00"
          p_1_1.daily_deal_payment.credit_card_last_4 = "5555"
          p_1_1.daily_deal_payment.payment_at = p_1_1.executed_at
          p_1_1.daily_deal_payment.save!
          p_1_1.save!
          p_1_1.create_certificates!

          p_1_2 = @d_1_1.daily_deal_purchases.build
          p_1_2.quantity = 3
          p_1_2.consumer = c_2
          p_1_2.save!
          p_1_2.payment_status = "captured"
          p_1_2.executed_at = "Jun 30, 2010 16:34:56 PST"
          p_1_2.daily_deal_payment = BraintreePayment.new
          p_1_2.daily_deal_payment.payment_gateway_id = "301181651"
          p_1_2.daily_deal_payment.amount = "117.00"
          p_1_2.daily_deal_payment.credit_card_last_4 = "5555"
          p_1_2.daily_deal_payment.payment_at = p_1_2.executed_at
          p_1_2.daily_deal_payment.save!
          p_1_2.save!
          p_1_2.create_certificates!
        end

        should "work great with a regular publisher user but not show source publisher" do
          login_as @publisher.users.first
          dates = Time.zone.parse("Jun 10, 2010")..Time.zone.parse("Jun 30, 2010")
          xhr :get, :purchased_daily_deals, {
            :id => @publisher.to_param,
            :dates_begin => dates.begin.to_s, :dates_end => dates.end.to_s,
            :format => "xml"
          }

          assert_select "daily_deals daily_deal##{@d_1_1.listing}" do
            assert_select "advertiser_name", @a_1.name
            assert_select "accounting_id", @d_1_1.accounting_id
            assert_select "listing", @d_1_1.listing
            assert_select "value_proposition", :text => @d_1_1.value_proposition
            assert_select "purchases_count", :text => "4"
            assert_select "purchasers_count", :text => "2"
            assert_select "started_at", :text => "06/29/10"
            assert_select "purchases_gross", :text => "156.0"
            assert_select "purchases_discount", :text => "10.0"
            assert_select "purchases_amount", :text => "146.0"
            assert_select "account_executive"
            assert_select "publisher_advertiser_id"
            assert_select "advertiser_credit_percentage", :text => "2.0"
            assert_select "source_publisher", :count => 0
          end
        end

        should "include non-voucher deals" do
          @non_voucher_deal = @a_1.daily_deals.create!(
              :value_proposition => "Daily Deal 1 For A1",
              :price => 0.00,
              :value => 81.00,
              :quantity => 1,
              :min_quantity => 1,
              :max_quantity => 1,
              :terms => "these are my terms",
              :description => "this is my description",
              :start_at => Time.zone.parse("June 29, 2010 23:00:00"),
              :hide_at => Time.zone.parse("July 31, 2010 22:55:00"),
              :expires_on => Date.parse("July 31, 2011"),
              :advertiser_credit_percentage => 2
          )

          p_1_2 = NonVoucherDailyDealPurchase.new
          p_1_2.daily_deal = @non_voucher_deal
          p_1_2.quantity = 1
          p_1_2.consumer = @c_2
          p_1_2.payment_status = "captured"
          p_1_2.executed_at = "Jun 29, 2010 16:34:56 PST"
          p_1_2.save!
          p_1_2.create_certificates!

          login_as @publisher.users.first
          dates = Time.zone.parse("Jun 10, 2010")..Time.zone.parse("Jun 30, 2010")
          xhr :get, :purchased_daily_deals, {
              :id => @publisher.to_param,
              :dates_begin => dates.begin.to_s, :dates_end => dates.end.to_s,
              :format => "xml"
          }



          assert_select "daily_deals daily_deal##{@non_voucher_deal.listing}" do
            assert_select "advertiser_name", @a_1.name
            assert_select "accounting_id", @non_voucher_deal.accounting_id
            assert_select "listing", @non_voucher_deal.listing
            assert_select "value_proposition", :text => @non_voucher_deal.value_proposition
            assert_select "purchases_count", :text => "1"
            assert_select "purchasers_count", :text => "1"
            assert_select "started_at", :text => "06/29/10"
            assert_select "purchases_gross", :text => "0.0"
            assert_select "purchases_discount", :text => "0.0"
            assert_select "purchases_amount", :text => "0.0"
            assert_select "account_executive"
            assert_select "publisher_advertiser_id"
            assert_select "advertiser_credit_percentage", :text => "2.0"
            assert_select "source_publisher", :count => 0
          end
        end
        should "show source publisher for admin user" do
          login_as @publisher.users.first
          dates = Time.zone.parse("Jun 10, 2010")..Time.zone.parse("Jun 30, 2010")
          xhr :get, :purchased_daily_deals, {
            :id => @publisher.to_param,
            :dates_begin => dates.begin.to_s, :dates_end => dates.end.to_s,
            :format => "xml"
          }

          assert_select "daily_deals daily_deal##{@d_1_1.listing}" do
            assert_select "source_publisher", :count => 0
          end
        end   
      end

      context "daily deal variations" do

        setup do
          @daily_deal = Factory(:daily_deal)
          @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)

          @variation_1 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 40.00, :price => 30.00, :value_proposition => "Variation 1 Prop")
          @variation_2 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 30.00, :price => 20.00, :value_proposition => "Variation 2 Prop")
          @variation_3 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 20.00, :price => 10.00, :value_proposition => "Variation 3 Prop")

          @purchase_1  = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 2, :daily_deal_variation => @variation_1)
          @purchase_2  = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1, :daily_deal_variation => @variation_2)
          @purchase_3  = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 3, :daily_deal_variation => @variation_3)        
        end

        should "setup the purchases and certs correctly" do
          assert_equal 2, @purchase_1.daily_deal_certificates.size
          assert_equal 30.00, @purchase_1.daily_deal_certificates.first.actual_purchase_price
          assert_equal 30.00, @purchase_1.daily_deal_certificates.last.actual_purchase_price

          assert_equal 1, @purchase_2.daily_deal_certificates.size

          assert_equal 3, @purchase_3.daily_deal_certificates.size
        end

        context "xml" do
          setup do
            login_as Factory(:admin)
            get(:purchased_daily_deals,
                :id => @daily_deal.publisher.to_param,
                :dates_begin => (Time.zone.now - 100.days).to_s,
                :dates_end => (Time.zone.now + 10.days).to_s,
                :format => "xml"
            )
          end

          should "render appropriate xml data for variation 1" do
            assert_select "daily_deals daily_deal##{@variation_1.listing}" do
              assert_select "accounting_id", @daily_deal.accounting_id_for_variation(@variation_1)
              assert_select "listing", @variation_1.listing
              assert_select "value_proposition", @variation_1.value_proposition
              assert_select "purchases_count", :text => "2"
              assert_select "purchasers_count", :text => "1"
              assert_select "purchases_gross", :text => "60.0"
              assert_select "purchases_discount", :text => "0.0"
              assert_select "purchases_amount", :text => "60.0"              
              assert_select "refunds_total_quantity", :text => "0"
              assert_select "refunds_total_amount", :text => "0.0"
            end
          end

          should "render appropriate xml data for variation 2" do
            assert_select "daily_deals daily_deal##{@variation_2.listing}" do
              assert_select "accounting_id", @daily_deal.accounting_id_for_variation(@variation_2)
              assert_select "listing", @variation_2.listing
              assert_select "value_proposition", @variation_2.value_proposition
              assert_select "purchases_count", :text => "1"
              assert_select "purchasers_count", :text => "1"
              assert_select "purchases_gross", :text => "20.0"
              assert_select "purchases_discount", :text => "0.0"
              assert_select "purchases_amount", :text => "20.0"              
              assert_select "refunds_total_quantity", :text => "0"
              assert_select "refunds_total_amount", :text => "0.0"              
            end
          end

          should "render appropriate xml data for variation 3" do
            assert_select "daily_deals daily_deal##{@variation_3.listing}" do
              assert_select "accounting_id", @daily_deal.accounting_id_for_variation(@variation_3)
              assert_select "listing", @variation_3.listing
              assert_select "value_proposition", @variation_3.value_proposition
              assert_select "purchases_count", :text => "3"
              assert_select "purchasers_count", :text => "1"
              assert_select "purchases_gross", :text => "30.0"
              assert_select "purchases_discount", :text => "0.0"
              assert_select "purchases_amount", :text => "30.0"   
              assert_select "refunds_total_quantity", :text => "0"
              assert_select "refunds_total_amount", :text => "0.0"                         
            end
          end          
        end

        context "csv" do
          setup do
            login_as Factory(:admin)
            get(:purchased_daily_deals,
                :id => @daily_deal.publisher.to_param,
                :dates_begin => (Time.zone.now - 100.days).to_s,
                :dates_end => (Time.zone.now + 10.days).to_s,
                :format => "csv"
            )
            @csv      = FasterCSV.new @response.binary_content
            @headers  = @csv.shift
            @rows     = sort_by_value_proposition(@csv.shift, @csv.shift, @csv.shift)
            @row1     = @rows[0]
            @row2     = @rows[1]
            @row3     = @rows[2]
          end

          should "render the appriopriate headers" do
            headers = [ "Started At",
                       "Ended At",
                       "Source Publisher",
                       "Advertiser",
                       "Publisher Advertiser ID",
                       "Accounting ID",
                       "Listing ID",
                       "Value",
                       "Purchased",
                       "Purchasers",
                       "Currency Code",
                       "Gross",
                       "Publisher Discount",
                       "Refunds #",
                       "Refunds #{@daily_deal.publisher.currency_symbol}",
                       "Total",
                       "Account Executive",
                       "Advertiser Rev. %",
                       "Advertiser Credit %",
                       "Custom 1",
                       "Custom 2",
                       "Custom 3"
            ]

            assert_equal headers, @headers, "first row should be headers"            
          end

          should "render appropriate csv data for variation 1" do
            assert_equal @daily_deal.start_at.to_s(:compact), @row1[0]
            assert_equal @daily_deal.hide_at.to_s(:compact), @row1[1]
            assert_equal @daily_deal.source_publisher, @row1[2]
            assert_equal @daily_deal.advertiser_name, @row1[3]
            assert_equal @daily_deal.advertiser.try(:listing), @row1[4]
            assert_equal @daily_deal.accounting_id_for_variation(@variation_1), @row1[5]
            assert_equal @variation_1.listing, @row1[6]
            assert_equal @variation_1.value_proposition, @row1[7]
            assert_equal "2", @row1[8]
            assert_equal "1", @row1[9]
            assert_equal "USD", @row1[10]
            assert_equal "60.0", @row1[11]
            assert_equal "0.0", @row1[12]
            assert_equal "0", @row1[13]
            assert_equal "0.0", @row1[14]
            assert_equal "60.0", @row1[15]
          end

          should "render appropriate csv data for variation 2" do
            assert_equal @daily_deal.start_at.to_s(:compact), @row2[0]
            assert_equal @daily_deal.hide_at.to_s(:compact), @row2[1]
            assert_equal @daily_deal.source_publisher, @row2[2]
            assert_equal @daily_deal.advertiser_name, @row2[3]
            assert_equal @daily_deal.advertiser.try(:listing), @row2[4]
            assert_equal @daily_deal.accounting_id_for_variation(@variation_2), @row2[5]
            assert_equal @variation_2.listing, @row2[6]
            assert_equal @variation_2.value_proposition, @row2[7]
            assert_equal "1", @row2[8]
            assert_equal "1", @row2[9]
            assert_equal "USD", @row2[10]
            assert_equal "20.0", @row2[11]
            assert_equal "0.0", @row2[12]
            assert_equal "0", @row2[13]
            assert_equal "0.0", @row2[14]
            assert_equal "20.0", @row2[15]
          end 

          should "render appropriate csv data for variation 3" do
            assert_equal @daily_deal.start_at.to_s(:compact), @row3[0]
            assert_equal @daily_deal.hide_at.to_s(:compact), @row3[1]
            assert_equal @daily_deal.source_publisher, @row3[2]
            assert_equal @daily_deal.advertiser_name, @row3[3]
            assert_equal @daily_deal.advertiser.try(:listing), @row3[4]
            assert_equal @daily_deal.accounting_id_for_variation(@variation_3), @row3[5]
            assert_equal @variation_3.listing, @row3[6]
            assert_equal @variation_3.value_proposition, @row3[7]
            assert_equal "3", @row3[8]
            assert_equal "1", @row3[9]
            assert_equal "USD", @row3[10]
            assert_equal "30.0", @row3[11]
            assert_equal "0.0", @row3[12]
            assert_equal "0", @row3[13]
            assert_equal "0.0", @row3[14]
            assert_equal "30.0", @row3[15]
          end 

        end

        context "with refunds" do

          setup do
            @refund = Factory(:refunded_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 2, :daily_deal_variation => @variation_1)
          end

          should "have a variation associated with the refund" do
            assert_equal @variation_1, @refund.daily_deal_variation
          end

          context "xml" do

            setup do
              login_as Factory(:admin)
              get(:purchased_daily_deals,
                  :id => @daily_deal.publisher.to_param,
                  :dates_begin => (Time.zone.now - 100.days).to_s,
                  :dates_end => (Time.zone.now + 10.days).to_s,
                  :format => "xml"
              )
            end

            should "render appropriate xml data for variation 1" do
              assert_select "daily_deals daily_deal##{@variation_1.listing}" do
                assert_select "accounting_id", @daily_deal.accounting_id_for_variation(@variation_1)
                assert_select "listing", @variation_1.listing
                assert_select "value_proposition", @variation_1.value_proposition
                assert_select "purchases_count", :text => "4"
                assert_select "purchasers_count", :text => "2"
                assert_select "purchases_gross", :text => "120.0"
                assert_select "purchases_discount", :text => "0.0"
                assert_select "purchases_amount", :text => "60.0"              
                assert_select "refunds_total_quantity", :text => "2"
                assert_select "refunds_total_amount", :text => "60.0"
              end
            end

            should "render appropriate xml data for variation 2" do
              assert_select "daily_deals daily_deal##{@variation_2.listing}" do
                assert_select "accounting_id", @daily_deal.accounting_id_for_variation(@variation_2)
                assert_select "listing", @variation_2.listing
                assert_select "value_proposition", @variation_2.value_proposition
                assert_select "purchases_count", :text => "1"
                assert_select "purchasers_count", :text => "1"
                assert_select "purchases_gross", :text => "20.0"
                assert_select "purchases_discount", :text => "0.0"
                assert_select "purchases_amount", :text => "20.0"              
                assert_select "refunds_total_quantity", :text => "0"
                assert_select "refunds_total_amount", :text => "0.0"              
              end
            end

            should "render appropriate xml data for variation 3" do
              assert_select "daily_deals daily_deal##{@variation_3.listing}" do
                assert_select "accounting_id", @daily_deal.accounting_id_for_variation(@variation_3)
                assert_select "listing", @variation_3.listing
                assert_select "value_proposition", @variation_3.value_proposition
                assert_select "purchases_count", :text => "3"
                assert_select "purchasers_count", :text => "1"
                assert_select "purchases_gross", :text => "30.0"
                assert_select "purchases_discount", :text => "0.0"
                assert_select "purchases_amount", :text => "30.0"   
                assert_select "refunds_total_quantity", :text => "0"
                assert_select "refunds_total_amount", :text => "0.0"                         
              end
            end 
          end



        end

      end

      private

      # to ensure the variation rows are order by listing/id
      # since the daily deals summary report returns by daily deal start at and
      # each of the variations have the same deal it sometimes would fail without
      # this setup.
      def sort_by_value_proposition(*rows)
        rows.sort{|a,b| a[7] <=> b[7]}
      end
    end
  end
end

