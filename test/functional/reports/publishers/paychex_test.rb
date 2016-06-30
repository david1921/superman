require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Reports::Publishers::PaychexTest

module Reports
  module Publishers
    class PaychexTest < ActionController::TestCase
      tests Reports::PublishersController

      test "paychex report should return a successful response" do
        publisher = Factory(:publisher_using_paychex)

        user = Factory(:user, :company => publisher)
        login_as user

        date = Time.zone.parse("Mar 14, 2011 07:00:00")

        get :paychex, :format => "html", :id => publisher.id, :date => date.to_s

        assert_response :success
      end

      context "paychex report" do

        setup do
          @publisher = Factory(:publisher_using_paychex)

          # The following test data setup was requested by Paychex

          @advertiser1 = Factory(:advertiser,
                                 :publisher => @publisher,
                                 :name => "Palio",
                                 :federal_tax_id => "12-345678")
          @advertiser2 = Factory(:advertiser, :publisher => @publisher)

          @deal_a1_1 = Factory(:daily_deal,
                               :advertiser => @advertiser1,
                               :value_proposition => "Huge deal on cakes",
                               :price => 30,
                               :advertiser_revenue_share_percentage => 30,
                               :start_at => Time.zone.parse("Mar 04, 2011 07:00:00"),
                               :hide_at => Time.zone.parse("Mar 04, 2011 17:00:00"))

          Factory(:captured_daily_deal_purchase,
                  :daily_deal => @deal_a1_1,
                  :executed_at => Time.zone.parse("Mar 04, 2011 07:01:00"),
                  :quantity => 1)
          Factory(:captured_daily_deal_purchase,
                  :daily_deal => @deal_a1_1,
                  :executed_at => Time.zone.parse("Mar 04, 2011 07:03:00"),
                  :quantity => 2)

          @deal_a1_2 = Factory(:daily_deal,
                               :advertiser => @advertiser1,
                               :price => 20,
                               :advertiser_revenue_share_percentage => 40,
                               :start_at => Time.zone.parse("Mar 17, 2011 07:00:00"),
                               :hide_at => Time.zone.parse("Mar 19, 2011 17:00:00"))

          Factory(:captured_daily_deal_purchase,
                  :daily_deal => @deal_a1_2,
                  :executed_at => Time.zone.parse("Mar 17, 2011 07:00:01"),
                  :quantity => 1)

          @deal_a2_1 = Factory(:daily_deal,
                               :advertiser => @advertiser2,
                               :price => 10,
                               :advertiser_revenue_share_percentage => 50,
                               :start_at => Time.zone.parse("Mar 04, 2011 08:00:00"),
                               :hide_at => Time.zone.parse("Mar 04, 2011 17:00:00"))

          Factory(:captured_daily_deal_purchase,
                  :daily_deal => @deal_a2_1,
                  :executed_at => Time.zone.parse("Mar 04, 2011 08:01:00"),
                  :quantity => 1)

          @deal_a2_2 = Factory(:daily_deal,
                               :advertiser => @advertiser2,
                               :price => 1500,
                               :advertiser_revenue_share_percentage => 25,
                               :start_at => Time.zone.parse("Mar 10, 2011 07:00:00"),
                               :hide_at => Time.zone.parse("Mar 10, 2011 17:00:00"))

          Factory(:captured_daily_deal_purchase,
                  :daily_deal => @deal_a2_2,
                  :executed_at => Time.zone.parse("Mar 10, 2011 10:00:00"),
                  :quantity => 10)

          user = Factory(:user, :company => @publisher)
          login_as user
        end

        should "render paychex report xml" do
          date = Time.zone.parse("Mar 14, 2011 07:00:00")

          get :paychex, :format => "xml", :id => @publisher.id, :date => date.to_s

          assert_response :success

          assert_select "daily_deals daily_deal", 3

          assert_select "daily_deals daily_deal##{@deal_a1_1.id}" do
            assert_select "payment_calc_date", "2011-03-14"
            assert_select "merchant_id", @advertiser1.id.to_s
            assert_select "merchant_name", @advertiser1.name
            assert_select "merchant_tax_id", @advertiser1.federal_tax_id
            assert_select "advertiser_split", :text => "30.0"
            assert_select "advertiser_share", "%.2f" % (90.0 * 0.3 - 0.033 * 0.3 * 90.0)
            assert_select "deal_id", @deal_a1_1.id.to_s
            assert_select "deal_headline", @deal_a1_1.value_proposition
            assert_select "deal_start_date", "2011-03-04"
            assert_select "deal_end_date", "2011-03-04"
            assert_select "number_sold", "3"
            assert_select "number_refunded", "0"
            assert_select "last_modified_by", ""
            assert_select "gross", "90.00"
            assert_select "refunds", "0.00"
            assert_select "credit_card_fee", "%.2f" % (0.033 * 90.0)
            assert_select "total_payment_due", "%.2f" % ((90.0 * 0.3 - 0.033 * 0.3 * 90.0) * 0.8)
            assert_select "currency_symbol", "$"
          end

          assert_select "daily_deals daily_deal##{@deal_a2_1.id}" do
            assert_select "payment_calc_date", "2011-03-14"
            assert_select "merchant_name", @advertiser2.name
            assert_select "merchant_tax_id", @advertiser2.federal_tax_id
            assert_select "advertiser_split", :text => "50.0"
            assert_select "advertiser_share", "%.2f" % (10.0 * 0.5 - 0.04 * 0.5 * 10.0)
            assert_select "deal_id", @deal_a2_1.id.to_s
            assert_select "deal_headline", @deal_a2_1.value_proposition
            assert_select "deal_start_date", "2011-03-04"
            assert_select "deal_end_date", "2011-03-04"
            assert_select "number_sold", "1"
            assert_select "number_refunded", "0"
            assert_select "last_modified_by", ""
            assert_select "gross", "10.00"
            assert_select "refunds", "0.00"
            assert_select "credit_card_fee", "%.2f" % (0.04 * 10.0)
            assert_select "total_payment_due", "%.2f" % ((10.0 * 0.5 - 0.04 * 0.5 * 10.0) * 0.8)
            assert_select "currency_symbol", "$"
          end
        end

        should "return properly named csv file" do
          date = Time.zone.parse("Mar 01, 2011 07:00:00")
          filename = "\"#{@publisher.name} Paychex Report, #{date.to_formatted_s(:db_date)}.csv\""
          get :paychex, :format => "csv", :id => @publisher.id, :date => date.to_s
          assert_response :success
          assert_equal("attachment; filename=#{filename}", @response.headers["Content-Disposition"])
          csv = FasterCSV.new(@response.binary_content).to_a
          assert_equal 1, csv.length
          assert_equal "Payment Period Ending", csv.shift[0]
        end

        should "return no results if date is before any deals started" do
          date = Time.zone.parse("Mar 01, 2011 07:00:00")
          get :paychex, :format => "csv", :id => @publisher.id, :date => date.to_s
          assert_response :success
          csv = FasterCSV.new(@response.binary_content).to_a
          assert_equal 1, csv.length
          assert_equal "Payment Period Ending", csv.shift[0]
        end

        should "return correct results after 1 pay period" do
          date = Time.zone.parse("Mar 15, 2011 07:00:00")

          get :paychex, :format => "csv", :id => @publisher.id, :date => date.to_s
          assert_response :success

          csv = FasterCSV.new(@response.binary_content).to_a
          assert_equal 4, csv.length

          assert_equal [
                         "Payment Period Ending", "Merchant ID", "Merchant Name", "Merchant Tax ID",
                         "Deal ID", "Deal Headline", "Deal Start Date", "Deal End Date",
                         "Last Modified By", "# Purchased", "Gross $", "CC Fee $", "# Refunds", "Refunds $",
                         "Adv. Split %", "Adv. Earned to Date $", "Adv. Due to Date $"
                       ], csv.shift

          assert_equal [
                         "2011-03-15",
                         @advertiser1.id.to_s,
                         "Palio",
                         "12-345678",
                         "BBD-" + @deal_a1_1.id.to_s,
                         "Huge deal on cakes",
                         "2011-03-04",
                         "2011-03-04",
                         "",
                         "3",
                         "90.00",
                         "%.2f" % (0.033*90.0),
                         "0",
                         "0.00",
                         "30.0",
                         "%.2f" % (90.0 * 0.3 - 0.033 * 0.3 * 90.0),
                         "%.2f" % ((90.0 * 0.3 - 0.033 * 0.3 * 90.0) * 0.8)
                       ], csv.shift

          assert_equal "BBD-" + @deal_a2_1.id.to_s, csv.shift[4]
          assert_equal "BBD-" + @deal_a2_2.id.to_s, csv.shift[4]
        end

        should "return correct results after 2 pay periods" do
          date = Time.zone.parse("Mar 30, 2011 07:00:00")

          get :paychex, :format => "csv", :id => @publisher.id, :date => date.to_s
          assert_response :success

          csv = FasterCSV.new(@response.binary_content).to_a
          assert_equal 5, csv.length

          assert_equal "Payment Period Ending", csv.shift[0]
          assert_equal "BBD-" + @deal_a1_1.id.to_s, csv.shift[4]
          assert_equal "BBD-" + @deal_a2_1.id.to_s, csv.shift[4]
          assert_equal "BBD-" + @deal_a2_2.id.to_s, csv.shift[4]
          assert_equal "BBD-" + @deal_a1_2.id.to_s, csv.shift[4]
        end

        should "return correct results after 3 pay periods" do
          date = Time.zone.parse("Apr 15, 2011 07:00:00")

          get :paychex, :format => "csv", :id => @publisher.id, :date => date.to_s
          assert_response :success

          csv = FasterCSV.new(@response.binary_content).to_a
          assert_equal 5, csv.length
        end

        should "return correct results after 4 pay periods" do
          date = Time.zone.parse("Apr 30, 2011 07:00:00")

          get :paychex, :format => "csv", :id => @publisher.id, :date => date.to_s
          assert_response :success

          csv = FasterCSV.new(@response.binary_content).to_a
          assert_equal 5, csv.length
        end

        should "return correct results after 5 pay periods" do
          date = Time.zone.parse("May 15, 2011 07:00:00")

          get :paychex, :format => "csv", :id => @publisher.id, :date => date.to_s
          assert_response :success

          csv = FasterCSV.new(@response.binary_content).to_a
          assert_equal 5, csv.length
        end

      end

    end
  end
end

