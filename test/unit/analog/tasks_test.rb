require File.join(File.dirname(__FILE__), "..", "..", "test_helper")

# hydra class Analog::TasksTest

module Analog
  
  class TasksTest < ActiveSupport::TestCase

    context ".send_daily_deal_purchase_summary_report!" do

      setup do
        ActionMailer::Base.deliveries.clear

        yesterday_start = Time.zone.now.yesterday.beginning_of_day
  
        gbp_pub_1 = Factory :gbp_publisher, :name => "GBP 1"
        gbp_pub_2 = Factory :gbp_publisher, :name => "GBP 2"
        gbp_pub_3 = Factory :gbp_publisher, :name => "GBP 3"
        
        gbp_advertiser_1 = Factory :advertiser, :publisher => gbp_pub_1
        gbp_advertiser_2 = Factory :advertiser, :publisher => gbp_pub_1
        gbp_advertiser_3 = Factory :advertiser, :publisher => gbp_pub_2

        gbp_deal_1 = Factory :daily_deal, :advertiser => gbp_advertiser_1, :price => 18, :value => 50
        gbp_deal_2 = Factory :side_daily_deal, :advertiser => gbp_advertiser_2, :price => 23, :value => 60

        gbp_ddp_pending = Factory :pending_daily_deal_purchase, :daily_deal => gbp_deal_1, :executed_at => yesterday_start + 1.minute
        gbp_ddp_authorized = Factory :authorized_daily_deal_purchase, :daily_deal => gbp_deal_2, :executed_at => yesterday_start + 5.minutes
        gbp_ddp_captured_1 = Factory :captured_daily_deal_purchase, :daily_deal => gbp_deal_2, :executed_at => yesterday_start + 30.minutes
        gbp_ddp_captured_2 = Factory :captured_daily_deal_purchase, :daily_deal => gbp_deal_2, :executed_at => yesterday_start + 10.hours 
        gbp_ddp_captured_3 = Factory :captured_daily_deal_purchase, :daily_deal => gbp_deal_1, :executed_at => yesterday_start + 18.hours

        older_gbp_ddp_captured_1 = Factory :captured_daily_deal_purchase, :daily_deal => gbp_deal_2, :executed_at => 5.days.ago
        older_gbp_ddp_captured_2 = Factory :captured_daily_deal_purchase, :daily_deal => gbp_deal_2, :executed_at => 7.days.ago
        older_gbp_ddp_captured_3 = Factory :captured_daily_deal_purchase, :daily_deal => gbp_deal_1, :executed_at => 12.days.ago
  
        can_pub_1 = Factory :cad_publisher, :name => "can 1"
        can_pub_2 = Factory :cad_publisher, :name => "can 2"
        can_pub_3 = Factory :cad_publisher, :name => "can 3"
        
        cad_advertiser_1 = Factory :advertiser, :publisher => can_pub_1
        cad_advertiser_2 = Factory :advertiser, :publisher => can_pub_1
        cad_advertiser_3 = Factory :advertiser, :publisher => can_pub_2

        can_deal_1 = Factory :daily_deal, :advertiser => cad_advertiser_1, :price => 24, :value => 48
        can_deal_2 = Factory :side_daily_deal, :advertiser => cad_advertiser_2, :price => 17, :value => 59

        can_ddp_pending = Factory :pending_daily_deal_purchase, :daily_deal => can_deal_1, :executed_at => yesterday_start + 1.minute
        can_ddp_authorized = Factory :authorized_daily_deal_purchase, :daily_deal => can_deal_2, :executed_at => yesterday_start + 5.minutes
        can_ddp_captured_1 = Factory :captured_daily_deal_purchase, :daily_deal => can_deal_2, :executed_at => yesterday_start + 30.minutes
        can_ddp_captured_2 = Factory :captured_daily_deal_purchase, :daily_deal => can_deal_2, :executed_at => yesterday_start + 10.hours 
        can_ddp_captured_3 = Factory :captured_daily_deal_purchase, :daily_deal => can_deal_1, :executed_at => yesterday_start + 18.hours

        older_can_ddp_captured_1 = Factory :captured_daily_deal_purchase, :daily_deal => can_deal_2, :executed_at => 5.days.ago
        older_can_ddp_captured_2 = Factory :captured_daily_deal_purchase, :daily_deal => can_deal_2, :executed_at => 7.days.ago
        older_can_ddp_captured_3 = Factory :captured_daily_deal_purchase, :daily_deal => can_deal_1, :executed_at => 12.days.ago
        
        usd_pub_1 = Factory :usd_publisher, :name => "USD 1"
        usd_pub_2 = Factory :usd_publisher, :name => "USD 2"
        usd_pub_3 = Factory :usd_publisher, :name => "USD 3"

        usd_advertiser_1 = Factory :advertiser, :publisher => usd_pub_1
        usd_advertiser_2 = Factory :advertiser, :publisher => usd_pub_2
        usd_advertiser_3 = Factory :advertiser, :publisher => usd_pub_2

        usd_deal_1 = Factory :daily_deal, :advertiser => usd_advertiser_1, :price => 12, :value => 30 
        usd_deal_2 = Factory :side_daily_deal, :advertiser => usd_advertiser_2, :price => 18, :value => 40

        usd_ddp_pending = Factory :pending_daily_deal_purchase, :daily_deal => usd_deal_1, :executed_at => yesterday_start + 45.minutes
        usd_ddp_authorized = Factory :authorized_daily_deal_purchase, :daily_deal => usd_deal_2, :executed_at => yesterday_start + 3.hours
        usd_ddp_captured_1 = Factory :captured_daily_deal_purchase, :daily_deal => usd_deal_2, :executed_at => yesterday_start + 4.hours
        usd_ddp_captured_2 = Factory :captured_daily_deal_purchase, :daily_deal => usd_deal_2, :executed_at => yesterday_start + 7.hours
        usd_ddp_captured_3 = Factory :captured_daily_deal_purchase, :daily_deal => usd_deal_1, :executed_at => yesterday_start + 9.hours
        usd_ddp_captured_4 = Factory :captured_daily_deal_purchase, :daily_deal => usd_deal_1, :executed_at => yesterday_start + 12.hours
        usd_ddp_captured_5 = Factory :captured_daily_deal_purchase, :daily_deal => usd_deal_1, :executed_at => yesterday_start + 22.hours

        older_usd_ddp_captured_1 = Factory :captured_daily_deal_purchase, :daily_deal => usd_deal_2, :executed_at => 5.days.ago
        older_usd_ddp_captured_2 = Factory :captured_daily_deal_purchase, :daily_deal => usd_deal_2, :executed_at => 7.days.ago
        older_usd_ddp_captured_3 = Factory :captured_daily_deal_purchase, :daily_deal => usd_deal_1, :executed_at => 12.days.ago    
      end

      should "call DailyDeal.publishers_with_purchase_totals_for_24h_and_30d once with :usd and once with :gbp" do
        usd_totals = DailyDeal.publishers_with_purchase_totals_for_24h_and_30d(:usd)
        gbp_totals = DailyDeal.publishers_with_purchase_totals_for_24h_and_30d(:gbp)
        can_totals = DailyDeal.publishers_with_purchase_totals_for_24h_and_30d(:cad)
        DailyDeal.expects(:publishers_with_purchase_totals_for_24h_and_30d).once.with(:usd).returns(usd_totals)
        DailyDeal.expects(:publishers_with_purchase_totals_for_24h_and_30d).once.with(:gbp).returns(gbp_totals)
        DailyDeal.expects(:publishers_with_purchase_totals_for_24h_and_30d).once.with(:cad).returns(can_totals)
        Analog::Tasks.send_daily_deal_purchase_summary_report!
      end
      
      should "call AnalogMailer.deliver_daily_purchase_summary_report send reports for each currency" do
        AnalogMailer.expects(:deliver_daily_purchase_summary_report).times(3)
        Analog::Tasks.send_daily_deal_purchase_summary_report!
      end
      
      should "show the currency symbol in each report subject" do
        Analog::Tasks.send_daily_deal_purchase_summary_report!
        
        sorted_deliveries = ActionMailer::Base.deliveries.sort { |d1, d2| d1.subject <=> d2.subject }
        assert_equal 3, sorted_deliveries.size
        
        assert_equal "Daily-deal purchase summary (CAD)", sorted_deliveries.first.subject
        assert_equal "Daily-deal purchase summary (GBP)", sorted_deliveries.second.subject
        assert_equal "Daily-deal purchase summary (USD)", sorted_deliveries.third.subject
      end
      
      should "show the currency symbol in each report body" do
        Analog::Tasks.send_daily_deal_purchase_summary_report!
        
        sorted_deliveries = ActionMailer::Base.deliveries.sort { |d1, d2| d1.subject <=> d2.subject }
        assert_equal 3, sorted_deliveries.size
        
        assert_match %r{class="publisher-24-hour-total">C\$58.00</td}, sorted_deliveries.first.body
        assert_match %r{class="publisher-30-day-total">C\$116.00</td}, sorted_deliveries.first.body

        assert_match %r{class="publisher-24-hour-total">£64.00</td}, sorted_deliveries.second.body
        assert_match %r{class="publisher-30-day-total">£128.00</td}, sorted_deliveries.second.body

        assert_match %r{class="publisher-24-hour-total">\$36.00</td}, sorted_deliveries.third.body
        assert_match %r{class="publisher-30-day-total">\$72.00</td}, sorted_deliveries.third.body   
      end
      
    end
    
  end
  
end
