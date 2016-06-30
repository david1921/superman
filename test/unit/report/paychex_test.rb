require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Report::PaychexTest

module Report
  
  class PaychexTest < ActiveSupport::TestCase
        
    context "Publisher#paychex_daily_deal_reports" do
      
      setup do
        Timecop.freeze(Time.parse("2011-07-20T09:00:00Z")) do
          @publishing_group = Factory :publishing_group_using_paychex,
                                      :label => "rr",
                                      :uses_paychex => true
          @publisher = Factory :publisher, :label => "clickedin-austin", :publishing_group => @publishing_group
          @discount = Factory :discount, :publisher => @publisher, :amount => 5, :code => "FIVER"
          @syndicated_publisher = Factory :publisher

          @advertiser_1 = Factory :advertiser, :publisher => @publisher
          @advertiser_2 = Factory :advertiser, :publisher => @publisher

          @a1_d1 = Factory :daily_deal, :advertiser => @advertiser_1, :value_proposition => "a1 d1", :price => 10,
                           :start_at => Time.parse("2011-07-21T09:00:00Z"), :hide_at => Time.parse("2011-07-24T09:00:00Z"),
                           :advertiser_revenue_share_percentage => 20
          @a1_d2 = Factory :side_daily_deal, :advertiser => @advertiser_2, :value_proposition => "a1 d2", :price => 20,
                           :start_at => Time.parse("2011-07-22T09:00:00Z"), :hide_at => Time.parse("2011-07-25T09:00:00Z"),
                           :advertiser_revenue_share_percentage => 25

          @a2_d1 = Factory :side_daily_deal_for_syndication, :advertiser => @advertiser_2, :value_proposition => "a2 d1", :price => 15,
                           :start_at => Time.parse("2011-08-01T09:00:00Z"), :hide_at => Time.parse("2011-08-02T09:00:00Z"), 
                           :advertiser_revenue_share_percentage => 15

          @a2_d1_syndicated = syndicate(@a2_d1, @syndicated_publisher)

          @a1_d1_p1 = Factory :captured_daily_deal_purchase, :daily_deal => @a1_d1,
                              :quantity => 2, :executed_at => @a1_d1.start_at + 1.minute
          @a1_d1_p2 = Factory :captured_daily_deal_purchase, :daily_deal => @a1_d1,
                              :quantity => 1, :executed_at => @a1_d1.start_at + 5.minutes
          @a1_d1_r1 = Factory :refunded_daily_deal_purchase, :daily_deal => @a1_d1,
                              :quantity => 1, :executed_at => @a1_d1.start_at + 20.minutes,
                              :refunded_at => @a1_d1.start_at + 2.days
                              
          @a1_d2_p1 = Factory :captured_daily_deal_purchase, :daily_deal => @a1_d2,
                              :quantity => 5, :executed_at => @a1_d2.start_at + 12.minutes,
                              :discount => @discount
          @a1_d2_p2 = Factory :captured_daily_deal_purchase, :daily_deal => @a1_d2,
                              :quantity => 1, :executed_at => @a1_d2.start_at + 30.minutes

          @a2_d1_p1 = Factory :captured_daily_deal_purchase, :daily_deal => @a2_d1,
                              :quantity => 2, :executed_at => @a2_d1.start_at + 1.minute
          @a2_d1_p2 = Factory :captured_daily_deal_purchase, :daily_deal => @a2_d1,
                              :quantity => 1, :executed_at => @a2_d1.start_at + 5.minutes
          @a2_d1_r1 = Factory :refunded_daily_deal_purchase, :daily_deal => @a2_d1,
                              :quantity => 4, :executed_at => @a2_d1.start_at + 20.minutes,
                              :refunded_at => @a2_d1.start_at + 3.months
                              
          @a2_d1_syn_p1 = Factory :captured_daily_deal_purchase, :daily_deal => @a2_d1_syndicated,
                                  :quantity => 2, :executed_at => @a2_d1_syndicated.start_at + 5.minutes
          @a2_d1_syn_r1 = Factory :refunded_daily_deal_purchase, :daily_deal => @a2_d1_syndicated,
                                  :quantity => 1, :executed_at => @a2_d1_syndicated.start_at + 2.hours,
                                  :refunded_at => @a2_d1_syndicated.start_at + 10.days
        end

      end
      
      context "total payment due calculations" do
        
        context "with default paychex options" do
          should "return 0 for deals that are still running" do
            query_date = Time.parse("2011-07-23T09:00:00Z")
            pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
            assert_equal 2, pc_deal_reports.length
            assert_equal 0, pc_deal_reports.first.paychex_total_payment_due(query_date)
            assert_equal 0, pc_deal_reports.second.paychex_total_payment_due(query_date)
          end

          should "return 0 within 4 days after of the deal end date" do
            query_date = Time.parse("2011-07-27T09:00:00Z")
            pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
            assert_equal 2, pc_deal_reports.length
            assert_equal 0, pc_deal_reports.first.paychex_total_payment_due(query_date)
            assert_equal 0, pc_deal_reports.second.paychex_total_payment_due(query_date)
          end

          should "return 80% of the amount owed 5 days after the deal ends" do
            query_date = Time.parse("2011-07-29T09:00:00Z")
            pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
            assert_equal 2, pc_deal_reports.length
            assert_equal 4.544, pc_deal_reports.first.paychex_total_payment_due(query_date)
            assert_equal 0, pc_deal_reports.second.paychex_total_payment_due(query_date)
          end

          should "return 80% of the amount owed 44 days after the deal ends" do
            query_date = Time.parse("2011-09-06T09:00:00Z")
            pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
            assert_equal 3, pc_deal_reports.length
            assert_equal 4.544, pc_deal_reports.first.paychex_total_payment_due(query_date)
            assert_equal 23.16, pc_deal_reports.second.paychex_total_payment_due(query_date)
            assert_equal 12.1212, pc_deal_reports.third.paychex_total_payment_due(query_date)
          end

          should "return 100% of the amount owed 46 days after the deal ends" do
            query_date = Time.parse("2011-09-07T09:00:00Z")
            pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
            assert_equal 3, pc_deal_reports.length
            assert_equal 5.68, pc_deal_reports.first.paychex_total_payment_due(query_date)
            assert_equal 23.16, pc_deal_reports.second.paychex_total_payment_due(query_date)
            assert_equal 12.1212, pc_deal_reports.third.paychex_total_payment_due(query_date)
          end

          should "return 100% of the amount owed 3 months after the deal ends" do
            query_date = Time.parse("2011-10-24T09:00:00Z")
            pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
            assert_equal 3, pc_deal_reports.length
            assert_equal 5.68, pc_deal_reports.first.paychex_total_payment_due(query_date)
            assert_equal 28.95, pc_deal_reports.second.paychex_total_payment_due(query_date)
            assert_equal 15.1515, pc_deal_reports.third.paychex_total_payment_due(query_date)          
          end
        end

        context "with custom paychex options" do
          setup do
            @publishing_group.update_attributes(
              :paychex_initial_payment_percentage => 90.0,
              :paychex_num_days_after_which_full_payment_released => 90
            )
          end

          should "return 0 for deals that are still running" do
            query_date = Time.parse("2011-07-23T09:00:00Z")
            pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
            assert_equal 2, pc_deal_reports.length
            assert_equal 0, pc_deal_reports.first.paychex_total_payment_due(query_date)
            assert_equal 0, pc_deal_reports.second.paychex_total_payment_due(query_date)
          end
          
          should "return 0 within 4 days after of the deal end date" do
            query_date = Time.parse("2011-07-27T09:00:00Z")
            pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
            assert_equal 2, pc_deal_reports.length
            assert_equal 0, pc_deal_reports.first.paychex_total_payment_due(query_date)
            assert_equal 0, pc_deal_reports.second.paychex_total_payment_due(query_date)
          end        
          
          should "return 90% of the amount owed 5 days after the deal ends" do
            query_date = Time.parse("2011-07-29T09:00:00Z")
            pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
            assert_equal 2, pc_deal_reports.length
            assert_equal 5.112, pc_deal_reports.first.paychex_total_payment_due(query_date)
            assert_equal 0, pc_deal_reports.second.paychex_total_payment_due(query_date)
          end
          
          should "return 90% of the amount owed 90 days after the deal ends" do
            query_date = Time.parse("2011-10-20T09:00:00Z")
            pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
            assert_equal 3, pc_deal_reports.length
            assert_equal 5.112, pc_deal_reports.first.paychex_total_payment_due(query_date)
            assert_equal 26.055, pc_deal_reports.second.paychex_total_payment_due(query_date)
            assert_equal 13.63635, pc_deal_reports.third.paychex_total_payment_due(query_date)
          end
          
          should "return 100% of the amount owed 92 days after the deal ends" do
            query_date = Time.parse("2011-10-23T09:00:00Z")
            pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
            assert_equal 3, pc_deal_reports.length
            assert_equal 5.68, pc_deal_reports.first.paychex_total_payment_due(query_date)
            assert_equal 26.055, pc_deal_reports.second.paychex_total_payment_due(query_date)
            assert_equal 13.63635, pc_deal_reports.third.paychex_total_payment_due(query_date)          
          end
          
          should "return 100% of the amount owed 3 months after the deal ends" do
            query_date = Time.parse("2011-11-01T09:00:00Z")
            pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
            assert_equal 3, pc_deal_reports.length
            assert_equal 5.68, pc_deal_reports.first.paychex_total_payment_due(query_date)
            assert_equal 28.95, pc_deal_reports.second.paychex_total_payment_due(query_date)
            assert_equal 6.1515, pc_deal_reports.third.paychex_total_payment_due(query_date)          
          end
        end

        context "with multi-voucher deal" do
          setup do
            @a2_d2 = Factory :daily_deal, :advertiser => @advertiser_2, :value_proposition => "a2 d2", :price => 30,
                             :start_at => Time.parse("2012-07-01T09:00:00Z"), :hide_at => Time.parse("2012-07-02T09:00:00Z"), 
                             :advertiser_revenue_share_percentage => 15, :certificates_to_generate_per_unit_quantity => 3
            @a2_d2_p1 = Factory :captured_daily_deal_purchase, :daily_deal => @a2_d2,
                                :quantity => 2, :executed_at => @a2_d2.start_at + 1.minute
          end

          should "return 0 within 4 days after of the deal end date" do
            query_date = Time.parse("2012-07-06T09:00:00Z")
            pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
            daily_deal = pc_deal_reports.find{|daily_deal| daily_deal.id == @a2_d2.id}
            assert_equal 60, daily_deal.gross_revenue_to_date
            assert_equal 0, daily_deal.paychex_total_payment_due(query_date)
          end

          should "return 100% of the amount owed 46 days after the deal ends" do
            query_date = Time.parse("2012-08-17T09:00:00Z")
            pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
            daily_deal = pc_deal_reports.find{|daily_deal| daily_deal.id == @a2_d2.id}
            assert_equal 60, daily_deal.gross_revenue_to_date
            assert_equal 0.033, daily_deal.paychex_credit_card_percentage.to_f
            assert_equal 0.033 * 60, daily_deal.paychex_credit_card_fee.to_f
            assert_equal ((60.0 - 0.0) * (15.0/100.0)) - (0.033 * ((15.0/100.0) * 60.0)), daily_deal.paychex_total_payment_due(query_date).to_f
          end

        end

      end
      
      context "number sold calculations" do
        
        should "return actual sales figures for deals that have sales, not including sales via syndication" do
          query_date = Time.parse("2011-07-21T09:02:00Z")
          pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
          assert_equal 1, pc_deal_reports.length
          assert_equal 2, pc_deal_reports.first.number_sold(query_date)
          
          query_date = Time.parse("2011-08-02T09:00:00Z")
          pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
          assert_equal 3, pc_deal_reports.length
          assert_equal 4, pc_deal_reports.first.number_sold(query_date)
          assert_equal 6, pc_deal_reports.second.number_sold(query_date)
          assert_equal 7, pc_deal_reports.third.number_sold(query_date)
        end
                
      end
      
      context "number refunded calculations, not including refunds via syndication" do
        
        should "return actual refund figures for deals that have refunds" do
          query_date = Time.parse("2011-07-24T09:00:00Z")
          pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
          assert_equal 2, pc_deal_reports.length
          assert_equal 1, pc_deal_reports.first.number_refunded(query_date)
          assert_equal 0, pc_deal_reports.second.number_refunded(query_date)
          
          query_date = Time.parse("2011-09-01T09:00:00Z")
          pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
          assert_equal 3, pc_deal_reports.length
          assert_equal 1, pc_deal_reports.first.number_refunded(query_date)
          assert_equal 0, pc_deal_reports.second.number_refunded(query_date)
          assert_equal 0, pc_deal_reports.third.number_refunded(query_date)
          
          query_date = Time.parse("2011-12-01T09:00:00Z")
          pc_deal_reports = @publisher.paychex_daily_deal_reports(query_date).sort_by(&:id)
          assert_equal 3, pc_deal_reports.length
          assert_equal 1, pc_deal_reports.first.number_refunded(query_date)
          assert_equal 0, pc_deal_reports.second.number_refunded(query_date)
          assert_equal 4, pc_deal_reports.third.number_refunded(query_date)
        end
        
      end
      
    end
    
  end
  
end
