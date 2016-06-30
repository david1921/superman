require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Report::AdvertiserTest

module Report

  class AdvertiserTest < ActiveSupport::TestCase
    
    context "#purchased_daily_deal_certificates_for_period" do
    
      setup do
        DailyDealCertificate.delete_all
        DailyDealPurchase.delete_all
    
        @query_start_date = 3.weeks.ago
        @query_end_date = @query_start_date + 2.weeks
        
        @a1 = Factory :advertiser
        @dd_1 = Factory :daily_deal, :advertiser => @a1
        
        @ddp_1 = Factory :captured_daily_deal_purchase_no_certs, :daily_deal => @dd_1, :quantity => 2, :executed_at => @query_start_date + 1.minute
        @ddp_2 = Factory :captured_daily_deal_purchase_no_certs, :daily_deal => @dd_1, :executed_at => @query_start_date + 5.minutes
        @ddp_3 = Factory :captured_daily_deal_purchase_no_certs, :daily_deal => @dd_1, :executed_at => @query_end_date + 1.day

        @ddp_1_c1 = Factory :daily_deal_certificate, :serial_number => "serial1", :daily_deal_purchase => @ddp_1
        @ddp_1_c2 = Factory :daily_deal_certificate, :serial_number => "serial2", :daily_deal_purchase => @ddp_1
        @ddp_2_c1 = Factory :daily_deal_certificate, :serial_number => "serial3", :daily_deal_purchase => @ddp_2
        @ddp_3_c1 = Factory :daily_deal_certificate, :serial_number => "serial4", :daily_deal_purchase => @ddp_3
      end      
      
      should "return all certificates purchased in the specified time period" do
        purchased_dd_certs = @a1.purchased_daily_deal_certificates_for_period(@query_start_date..@query_end_date)
        assert_equal 3, purchased_dd_certs.length
        assert_equal ["serial1", "serial2", "serial3"], purchased_dd_certs.map(&:serial_number).sort
      end
      
      should "include refunded certificates that were purchased in the specified time period" +
             "and refunded in that period" do
        ddp_4 = Factory :refunded_daily_deal_purchase_no_certs, :daily_deal => @dd_1, :executed_at => @query_start_date + 4.hours
        ddp_4_c1 = Factory :daily_deal_certificate, :daily_deal_purchase => ddp_4, :serial_number => "serial5"
    
        purchased_dd_certs = @a1.purchased_daily_deal_certificates_for_period(@query_start_date..@query_end_date)
        assert_equal 4, purchased_dd_certs.length
        assert_equal ["serial1", "serial2", "serial3", "serial5"], purchased_dd_certs.map(&:serial_number).sort              
      end
      
      should "include refunded certificates that were purchased in the specified time period and refunded outside that period" do
        ddp_5 = Factory :refunded_daily_deal_purchase_no_certs, :daily_deal => @dd_1, :executed_at => @query_start_date + 7.hours, :refunded_at => @query_end_date + 1.week
        ddp_5_c1 = Factory :daily_deal_certificate, :daily_deal_purchase => ddp_5, :serial_number => "serial6"
        
        purchased_dd_certs = @a1.purchased_daily_deal_certificates_for_period(@query_start_date..@query_end_date)
        assert_equal 4, purchased_dd_certs.length
        assert_equal ["serial1", "serial2", "serial3", "serial6"], purchased_dd_certs.map(&:serial_number).sort                      
      end
    end
    
    context "purchased_daily_deal_certificates_for_period with syndicated deals" do
    
      setup do
        DailyDealCertificate.delete_all
        DailyDealPurchase.delete_all
    
        @query_start_date = 3.weeks.ago
        @query_end_date = @query_start_date + 2.weeks
        
        @source_deal = Factory(:daily_deal_for_syndication, :quantity => 3)
      
        @syndicated_deal_publisher_1 = Factory(:publisher)
        @syndicated_deal_1 = syndicate(@source_deal, @syndicated_deal_publisher_1)
        
        @syndicated_deal_publisher_2 = Factory(:publisher)
        @syndicated_deal_2 = syndicate(@source_deal, @syndicated_deal_publisher_2)
        
        @source_deal_consumer = Factory(:consumer, :first_name => "John", :last_name => "Smith", :publisher => @source_deal.publisher )
        @syndicated_deal_consumer_1 = Factory(:consumer, :first_name => "Jill", :last_name => "Smith", :publisher => @syndicated_deal_1.publisher )
        @syndicated_deal_consumer_2 = Factory(:consumer, :first_name => "Jane", :last_name => "Doe", :publisher => @syndicated_deal_2.publisher )
        
        @source_deal_purchase = Factory(:captured_daily_deal_purchase_no_certs, :daily_deal => @source_deal, :consumer => @source_deal_consumer, :quantity => 2, :executed_at => @query_start_date + 1.minute)
        @syndicated_deal_purchase_1 = Factory(:captured_daily_deal_purchase_no_certs, :daily_deal => @syndicated_deal_1, :consumer => @syndicated_deal_consumer_1, :executed_at => @query_start_date + 5.minutes)
        @syndicated_deal_purchase_2 = Factory(:captured_daily_deal_purchase_no_certs, :daily_deal => @syndicated_deal_2, :consumer => @syndicated_deal_consumer_2, :executed_at => @query_start_date + 1.day)
        @syndicated_deal_purchase_3 = Factory(:captured_daily_deal_purchase_no_certs, :daily_deal => @syndicated_deal_2, :consumer => @syndicated_deal_consumer_2, :executed_at => @query_start_date - 1.day)

        @source_deal_certificate = Factory :daily_deal_certificate, :serial_number => "serial0", :daily_deal_purchase => @source_deal_purchase
        @syndicated_deal_certificate_1 = Factory :daily_deal_certificate, :serial_number => "serial1", :daily_deal_purchase => @syndicated_deal_purchase_1
        @syndicated_deal_certificate_2 = Factory :daily_deal_certificate, :serial_number => "serial2", :daily_deal_purchase => @syndicated_deal_purchase_2
        @syndicated_deal_certificate_3 = Factory :daily_deal_certificate, :serial_number => "serial3", :daily_deal_purchase => @syndicated_deal_purchase_3
      end
      
      should "return certificates belonging to advertiser when company is source publisher" do
        purchased_dd_certs =
          @source_deal.advertiser.purchased_daily_deal_certificates_for_period(@query_start_date..@query_end_date, @source_deal.publisher)
          assert_equal ["serial0", "serial1", "serial2"], purchased_dd_certs.map(&:serial_number).sort
      end
      
      should "return all certificates for source deal advertiser if no company specified" do
        purchased_dd_certs = @source_deal.advertiser.purchased_daily_deal_certificates_for_period(@query_start_date..@query_end_date)
        assert_equal ["serial0", "serial1", "serial2"], purchased_dd_certs.map(&:serial_number).sort
      end
      
      should "return all certificates for advertiser when company is advertiser" do
        purchased_dd_certs = @source_deal.advertiser.purchased_daily_deal_certificates_for_period(@query_start_date..@query_end_date, @source_deal.advertiser)
        assert_equal ["serial0", "serial1", "serial2"], purchased_dd_certs.map(&:serial_number).sort
      end
      
      should "return certificates belonging to publisher when company is syndicated publisher" do
        purchased_dd_certs =
          @source_deal.advertiser.purchased_daily_deal_certificates_for_period(@query_start_date..@query_end_date, @syndicated_deal_2.publisher)
        assert_equal ["serial2"], purchased_dd_certs.map(&:serial_number).sort
      end
      
      should "return NO certificates belonging to publisher when company is other publisher" do
        purchased_dd_certs =
          @source_deal.advertiser.purchased_daily_deal_certificates_for_period(@query_start_date..@query_end_date, Factory(:publisher))
        assert_equal 0, purchased_dd_certs.length
      end
      
      should "return NO certificates belonging to advertiser when company is other advertiser" do
        purchased_dd_certs = 
          @source_deal.advertiser.purchased_daily_deal_certificates_for_period(@query_start_date..@query_end_date, Factory(:advertiser))
        assert_equal 0, purchased_dd_certs.length
      end
    end
    
    context "refunded_daily_deals_for_period with syndicated deals" do

      setup do
        DailyDealCertificate.delete_all
        DailyDealPurchase.delete_all

        @query_start_date = 3.weeks.ago
        @query_end_date = @query_start_date + 2.weeks
        
        @source_deal = Factory(:daily_deal_for_syndication, :quantity => 3)
      
        @syndicated_deal_publisher_1 = Factory(:publisher)
        @syndicated_deal_1 = syndicate(@source_deal, @syndicated_deal_publisher_1)
        
        @syndicated_deal_publisher_2 = Factory(:publisher)
        @syndicated_deal_2 = syndicate(@source_deal, @syndicated_deal_publisher_2)
        
        @source_deal_consumer = Factory(:consumer, :first_name => "John", :last_name => "Smith", :publisher => @source_deal.publisher )
        @syndicated_deal_consumer_1 = Factory(:consumer, :first_name => "Jill", :last_name => "Smith", :publisher => @syndicated_deal_1.publisher )
        @syndicated_deal_consumer_2 = Factory(:consumer, :first_name => "Jane", :last_name => "Doe", :publisher => @syndicated_deal_2.publisher )
        
        @source_deal_purchase = Factory(:refunded_daily_deal_purchase_no_certs,
                                        :daily_deal => @source_deal, 
                                        :consumer => @source_deal_consumer, 
                                        :quantity => 2, 
                                        :executed_at => @query_start_date + 1.minute, 
                                        :refunded_at => @query_start_date + 1.day)
        @syndicated_deal_purchase_1 = Factory(:refunded_daily_deal_purchase_no_certs,
                                              :daily_deal => @syndicated_deal_1, 
                                              :consumer => @syndicated_deal_consumer_1, 
                                              :executed_at => @query_start_date + 5.minutes, 
                                              :refunded_at => @query_start_date + 1.day)
        @syndicated_deal_purchase_2 = Factory(:refunded_daily_deal_purchase_no_certs,
                                              :daily_deal => @syndicated_deal_2, 
                                              :consumer => @syndicated_deal_consumer_2, 
                                              :executed_at => @query_start_date + 1.day, 
                                              :refunded_at => @query_start_date + 1.day)
        @syndicated_deal_purchase_3 = Factory(:refunded_daily_deal_purchase_no_certs,
                                              :daily_deal => @syndicated_deal_2, 
                                              :consumer => @syndicated_deal_consumer_2, 
                                              :executed_at => @query_start_date - 3.day, 
                                              :refunded_at => @query_start_date - 2.days)
        
        @source_deal_certificate = Factory :refunded_daily_deal_certificate, :serial_number => "serial0", :daily_deal_purchase => @source_deal_purchase
        @syndicated_deal_certificate_1 = Factory :refunded_daily_deal_certificate, :serial_number => "serial1", :daily_deal_purchase => @syndicated_deal_purchase_1
        @syndicated_deal_certificate_2 = Factory :refunded_daily_deal_certificate, :serial_number => "serial2", :daily_deal_purchase => @syndicated_deal_purchase_2
        @syndicated_deal_certificate_3 = Factory :refunded_daily_deal_certificate, :serial_number => "serial3", :daily_deal_purchase => @syndicated_deal_purchase_3
      end
      
      should "return purchases belonging to advertiser when company is source publisher" do
        refunded_deals =
          @source_deal.advertiser.refunded_daily_deal_certificates_for_period(@query_start_date..@query_end_date, @source_deal.publisher)
          assert_equal ["serial0", "serial1", "serial2"], refunded_deals.map(&:serial_number).sort
      end
      
      should "return all purchases for source deal advertiser if no company specified" do
        refunded_deals = @source_deal.advertiser.refunded_daily_deal_certificates_for_period(@query_start_date..@query_end_date)
        assert_equal ["serial0", "serial1", "serial2"], refunded_deals.map(&:serial_number).sort
      end
      
      should "return all purchases for advertiser when company is advertiser" do
        refunded_deals = @source_deal.advertiser.refunded_daily_deal_certificates_for_period(@query_start_date..@query_end_date, @source_deal.advertiser)
        assert_equal ["serial0", "serial1", "serial2"], refunded_deals.map(&:serial_number).sort
      end
      
      should "return purchases belonging to publisher when company is syndicated publisher" do
        refunded_deals =
          @source_deal.advertiser.refunded_daily_deal_certificates_for_period(@query_start_date..@query_end_date, @syndicated_deal_2.publisher)
        assert_equal ["serial2"], refunded_deals.map(&:serial_number).sort
      end
      
      should "return NO purchases belonging to publisher when company is other publisher" do
        refunded_deals =
          @source_deal.advertiser.refunded_daily_deal_certificates_for_period(@query_start_date..@query_end_date, Factory(:publisher))
        assert_equal 0, refunded_deals.length
      end
      
      should "return NO purchases belonging to advertiser when company is other advertiser" do
        refunded_deals = 
          @source_deal.advertiser.refunded_daily_deal_certificates_for_period(@query_start_date..@query_end_date, Factory(:advertiser))
        assert_equal 0, refunded_deals.length
      end
    end

    context "affiliated_daily_deal_certificates_for_period" do
      setup do
        @advertiser = Factory(:advertiser)
        @advertiser2 = Factory(:advertiser)

        @query_start_date = Time.zone.parse("Mar 01, 2011 07:00:00")
        @query_end_date = Time.zone.parse("Mar 10, 2011 07:00:00")

        @deal_1 = Factory(:daily_deal,
                         :publisher => @advertiser.publisher,
                         :advertiser => @advertiser,
                         :price => 20.00,
                         :start_at => Time.zone.parse("Mar 04, 2011 07:00:00"),
                         :hide_at => Time.zone.parse("Mar 04, 2011 17:00:00"),
                         :affiliate_revenue_share_percentage => 20.0)

        @deal_1_placement = Factory(:affiliate_placement, :placeable => @deal_1)

        @deal_1_purchase_1 = Factory(:captured_daily_deal_purchase_no_certs,
                                     :daily_deal => @deal_1,
                                     :executed_at => @deal_1.start_at + 1.minutes,
                                     :affiliate => @deal_1_placement.affiliate)

        @deal_1_certificate_1 = Factory(:daily_deal_certificate,
                                        :serial_number => "serial0",
                                        :daily_deal_purchase => @deal_1_purchase_1)

        @deal_1_purchase_2 = Factory(:captured_daily_deal_purchase_no_certs,
                                     :daily_deal => @deal_1,
                                     :executed_at => @deal_1.start_at + 9.minutes)
        @deal_1_certificate_2 = Factory(:daily_deal_certificate,
                                        :serial_number => "serial1",
                                        :daily_deal_purchase => @deal_1_purchase_2)

        @deal_2 = Factory(:daily_deal,
                         :publisher => @advertiser2.publisher,
                         :advertiser => @advertiser2,
                         :price => 15.00,
                         :start_at => Time.zone.parse("Mar 05, 2011 07:00:00"),
                         :hide_at => Time.zone.parse("Mar 05, 2011 17:00:00"),
                         :affiliate_revenue_share_percentage => 10.0)

        @deal_2_placement = Factory(:affiliate_placement, :placeable => @deal_2)

        @deal_2_purchase = Factory(:captured_daily_deal_purchase_no_certs,
                                   :daily_deal => @deal_2,
                                   :executed_at => @deal_2.start_at + 2.minutes,
                                   :affiliate => @deal_2_placement.affiliate)
        @deal_2_certificate = Factory(:daily_deal_certificate,
                                      :serial_number => "serial2",
                                      :daily_deal_purchase => @deal_2_purchase)
      end

      should "return all affilated deal certificates belonging to advertiser when company is publisher" do
        deals = @advertiser.affiliated_daily_deal_certificates_for_period(@query_start_date..@query_end_date, @advertiser.publisher)
        assert_equal ["serial0"], deals.map(&:serial_number).sort
      end

      should "return all affilated deals certificates belonging to advertiser when company is nil" do
        deals = @advertiser.affiliated_daily_deal_certificates_for_period(@query_start_date..@query_end_date)
        assert_equal ["serial0"], deals.map(&:serial_number).sort
      end

      should "return all affilated deals certificates belonging to advertiser when company is advertiser" do
        deals = @advertiser.affiliated_daily_deal_certificates_for_period(@query_start_date..@query_end_date, @advertiser)
        assert_equal ["serial0"], deals.map(&:serial_number).sort
      end

      should "return no deals certificates when company is other publisher" do
        deals = @advertiser.affiliated_daily_deal_certificates_for_period(@query_start_date..@query_end_date, @advertiser2.publisher)
        assert_equal [], deals.map(&:serial_number)
      end

      should "return no deals certificates when company is other advertiser" do
        deals = @advertiser.affiliated_daily_deal_certificates_for_period(@query_start_date..@query_end_date, @advertiser2)
        assert_equal [], deals.map(&:serial_number)
      end
    end
    
    context "purchased daily deal certificates for period with market" do
      setup do
        @report_date_begin = Time.zone.local(2011, 3, 1, 0, 0, 0)
        @report_date_end = Time.zone.local(2011, 3, 15, 0, 0, 0)
        
        @daily_deal = Factory(:daily_deal)
        @market_1 = Factory(:market, :publisher => @daily_deal.publisher);
        @market_2 = Factory(:market, :publisher => @daily_deal.publisher);
        @daily_deal.markets << @market_1
        @daily_deal.markets << @market_2
        
        @ddp_1 = Factory(:captured_daily_deal_purchase_no_certs, 
                         :daily_deal => @daily_deal, 
                         :quantity => 3,
                         :executed_at => @report_date_begin + 4.days, 
                         :market => @market_1)
                
        @ddp_2 = Factory(:captured_daily_deal_purchase_no_certs, 
                         :daily_deal => @daily_deal,
                         :quantity => 1,
                         :executed_at => @report_date_begin + 4.days, 
                         :market => @market_2)
        
        @ddp_1_c1 = Factory(:daily_deal_certificate, :serial_number => "serial1", :daily_deal_purchase => @ddp_1)
        @ddp_1_c2 = Factory(:daily_deal_certificate, :serial_number => "serial2", :daily_deal_purchase => @ddp_1)
        @ddp_1_c3 = Factory(:daily_deal_certificate, :serial_number => "serial3", :daily_deal_purchase => @ddp_1)
        @ddp_2_c1 = Factory(:daily_deal_certificate, :serial_number => "serial4", :daily_deal_purchase => @ddp_2)
      end
      
      should "return certificates in market" do
        purchased_dd_certs = @daily_deal.advertiser.purchased_daily_deal_certificates_for_period(@report_date_begin..@report_date_end, nil, @market_1)
        assert_equal 3, purchased_dd_certs.length
        assert_equal ["serial1", "serial2", "serial3"], purchased_dd_certs.map(&:serial_number).sort
      end
      
    end
    
    context "refunded daily deal certificates for period with market" do
      setup do
        @report_date_begin = Time.zone.local(2011, 3, 1, 0, 0, 0)
        @report_date_end = Time.zone.local(2011, 3, 15, 0, 0, 0)
        
        @daily_deal = Factory(:daily_deal)
        @market_1 = Factory(:market, :publisher => @daily_deal.publisher);
        @market_2 = Factory(:market, :publisher => @daily_deal.publisher);
        @daily_deal.markets << @market_1
        @daily_deal.markets << @market_2
        
        @ddp_1 = Factory(:captured_daily_deal_purchase_no_certs, 
                         :daily_deal => @daily_deal, 
                         :quantity => 3,
                         :executed_at => @report_date_begin + 4.days, 
                         :market => @market_1)
                
        @ddp_2 = Factory(:captured_daily_deal_purchase_no_certs, 
                         :daily_deal => @daily_deal,
                         :quantity => 1,
                         :executed_at => @report_date_begin + 4.days, 
                         :market => @market_2)
        
        Factory(:daily_deal_certificate, :serial_number => "serial1", :daily_deal_purchase => @ddp_1)
        Factory(:daily_deal_certificate, :serial_number => "serial2", :daily_deal_purchase => @ddp_1)
        Factory(:daily_deal_certificate, :serial_number => "serial3", :daily_deal_purchase => @ddp_1)
        Factory(:daily_deal_certificate, :serial_number => "serial4", :daily_deal_purchase => @ddp_2)
        refund_1 = Factory(:refunded_daily_deal_purchase, 
                                   :daily_deal => @daily_deal, 
                                   :executed_at => @report_date_begin + 1.days,
                                   :refunded_at => @report_date_begin + 1.days,
                                   :market => @market_1)
        refund_2 = Factory(:refunded_daily_deal_purchase, 
                                   :daily_deal => @daily_deal, 
                                   :executed_at => @report_date_begin + 2.days,
                                   :refunded_at => @report_date_begin + 1.days,
                                   :market => @market_1)
        @refunded_cert_1 = refund_1.daily_deal_certificates.first
        @refunded_cert_2 = refund_2.daily_deal_certificates.first
        Factory(:refunded_daily_deal_purchase, 
                :daily_deal => @daily_deal                           , 
                :executed_at => @report_date_begin + 2.days,
                :refunded_at => @report_date_begin + 1.days)
      end
      
      should "return certificates in market" do
        purchased_dd_certs = @daily_deal.advertiser.refunded_daily_deal_certificates_for_period(@report_date_begin..@report_date_end, nil, @market_1)
        assert_equal [@refunded_cert_1, @refunded_cert_2], purchased_dd_certs
        assert_equal 2, purchased_dd_certs.length
      end
      
    end

    context "#refunded_daily_deal_certificates_for_period" do
      should "sort by empty string when no consumer for purchase (i.e. off-platform purchase)" do
        purchase = Factory(:captured_off_platform_daily_deal_purchase, :quantity => 2, :gift => true, :recipient_names => ['One', 'Two'])
        certificates = purchase.daily_deal_certificates
        assert_equal 2, certificates.size
        certificates.map(&:refund!)

        refunded_certs = purchase.advertiser.refunded_daily_deal_certificates_for_period(1.day.ago..1.day.from_now, purchase.publisher)

        assert "An exception was not raised"
        assert_contains refunded_certs, certificates.first
        assert_contains refunded_certs, certificates.second
      end
    end

    private
    
    def syndicate(daily_deal, syndicated_publisher)
      daily_deal.syndicated_deals.build(:publisher_id => syndicated_publisher.id)
      daily_deal.save!
      daily_deal.syndicated_deals.last 
    end
    
  end

end
