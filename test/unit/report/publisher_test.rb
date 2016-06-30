require File.dirname(__FILE__) + "/../../test_helper"

class Report::PublisherTest < ActiveSupport::TestCase

  test "click counts only return requested click_type" do
    publisher = Factory(:publisher)

    no_type_total = no_type_offers = no_type_daily_deals =
      facebook_total = facebook_offers = facebook_daily_deals =
      twitter_total = twitter_offers = twitter_daily_deals = 0

    2.times do
      count = Factory(:click_count_daily_deal, :publisher => publisher, :mode => '').count
      no_type_total += count
      no_type_daily_deals += count
    end

    2.times do
      count = Factory(:click_count_offer, :publisher => publisher, :mode => '').count
      no_type_total += count
      no_type_offers += count
    end

    2.times do
      count = Factory(:click_count_daily_deal, :publisher => publisher, :mode => 'twitter').count
      twitter_total += count
      twitter_daily_deals += count
    end

    2.times do
      count = Factory(:click_count_offer, :publisher => publisher, :mode => 'twitter').count
      twitter_total += count
      twitter_offers += count
    end

    2.times do
      count = Factory(:click_count_daily_deal, :publisher => publisher, :mode => 'facebook').count
      facebook_total += count
      facebook_daily_deals += count
    end
    2.times do
      count = Factory(:click_count_offer, :publisher => publisher, :mode => 'facebook').count
      facebook_total += count
      facebook_offers += count
    end

    Timecop.freeze(Time.zone.local(2008, 10, 4, 12, 34, 56)) do
      dates = Date.new(2008, 9, 1) .. Date.new(2008, 9, 30)
      assert_equal publisher.clicks_count(dates), no_type_total
      assert_equal publisher.clicks_count(dates, 'Offer'), no_type_offers
      assert_equal publisher.clicks_count(dates, 'DailyDeal'), no_type_daily_deals

      assert_equal publisher.facebooks_count(dates), facebook_total
      assert_equal publisher.facebooks_count(dates, 'Offer'), facebook_offers
      assert_equal publisher.facebooks_count(dates, 'DailyDeal'), facebook_daily_deals

      assert_equal publisher.twitters_count(dates), twitter_total
      assert_equal publisher.twitters_count(dates, 'Offer'), twitter_offers
      assert_equal publisher.twitters_count(dates, 'DailyDeal'), twitter_daily_deals
    end

  end
  
  context "click counts when there are clicks on the 'boundary' days of the requested report period" do
    
    setup do
      ClickCount.delete_all
      @offer = Factory :offer
      
      # not counted
      Timecop.freeze(Time.parse("2011-09-30T23:59:59Z"))
      @offer.record_click @offer.publisher.id
      
      # counted
      Timecop.freeze(Time.zone.parse("2011-09-30 23:59:59"))
      @offer.record_click @offer.publisher.id
      
      # counted
      Timecop.freeze(Time.zone.parse("2011-10-01 00:00:00"))
      @offer.record_click @offer.publisher.id
      @offer.record_click @offer.publisher.id
      
      # counted
      Timecop.freeze(Time.zone.parse("2011-10-15 12:34:00"))
      @offer.record_click @offer.publisher.id
      
      # counted
      Timecop.freeze(Time.parse("2011-10-31T23:59:59Z"))
      @offer.record_click @offer.publisher.id
      
      # counted
      Timecop.freeze(Time.zone.parse("2011-10-31 23:59:59"))
      @offer.record_click @offer.publisher.id
      @offer.record_click @offer.publisher.id
      @offer.record_click @offer.publisher.id
      
      # counted
      Timecop.freeze(Time.zone.parse("2011-11-01 00:00:00"))
      @offer.record_click @offer.publisher.id
      
      # not counted
      Timecop.freeze(Time.zone.parse("2011-11-02 00:00:00"))
      @offer.record_click @offer.publisher.id      
      
      Timecop.return
      
      @dates = Date.new(2011, 10, 1) .. Date.new(2011, 10, 31)
    end
    
    should "include those clicks in #clicks_count" do
      assert_equal 9, @offer.publisher.clicks_count(@dates, 'Offer')
    end
    
    should "include those clicks in #advertisers_with_web_offers_counts" do
      assert_equal 9, @offer.publisher.advertisers_with_web_offers_counts(@dates).first.clicks_count.to_i
    end
    
  end

  context "consumers_totals" do
    setup do
      @publisher1 = Factory(:publisher)
      @publisher2 = Factory(:publisher)
    end

    should "return 0 when there are no signups" do
      assert_equal 0, @publisher1.consumers_totals
    end

    context "with signups" do
      setup do
        # make some signups in date range
        Timecop.freeze(Time.zone.local(2010, 10, 4, 4, 6, 8)) do
          Factory(:consumer, :publisher => @publisher1)
          Factory(:subscriber, :publisher => @publisher1, :email => "test@example.com")
          Factory(:subscriber, :publisher => @publisher1, :email => "test@example.com")
          Factory(:consumer, :publisher => @publisher2)
        end
        # make a signups outside of date range
        Timecop.freeze(Time.zone.local(2010, 10, 5, 4, 6, 8)) do
          Factory(:consumer, :publisher => @publisher1)
        end
      end

      should "count all signups in a given date range" do
        dates = Time.zone.local(2010, 10, 4, 0, 0, 0) .. Time.zone.local(2010, 10, 5, 0, 0, 0)
        assert_equal 2, @publisher1.consumers_totals(:date_range => dates)
      end

      should "count all signpus when no date range given" do
        assert_equal 3, @publisher1.consumers_totals
      end
    end

  end

  context "with various purchases and refunds" do

    setup do
      DailyDeal.delete_all

      @publisher_1 = Factory :publisher, :label => "testpub1"
      @publisher_2 = Factory :publisher, :label => "testpub2"

      @advertiser_1 = Factory :advertiser, :publisher => @publisher_1, :label => "testadvertiser1"
      @advertiser_2 = Factory :advertiser, :publisher => @publisher_1, :label => "testadvertiser2"
      @advertiser_3 = Factory :advertiser, :publisher => @publisher_1, :label => "testadvertiser3"
      @advertiser_4 = Factory :advertiser, :publisher => @publisher_1, :label => "testadvertiser4"

      a1_deal_1_start = Time.parse("Wed, 26 Jan 2011 15:02:06 PST -08:00")
      a1_deal_2_start = Time.parse("Wed, 02 Feb 2011 15:02:32 PST -08:00")
      a2_deal_1_start = Time.parse("Wed, 17 Feb 2011 15:02:45 PST -08:00")
      a2_deal_2_start = Time.parse("Wed, 17 Feb 2011 15:03:45 PST -08:00")
      a4_deal_1_start = Time.parse("Wed, 16 Feb 2011 15:03:00 PST -08:00")
      a4_deal_2_start = Time.parse("Wed, 18 Feb 2011 15:03:00 PST -08:00")

      @a1_deal_1 = Factory :daily_deal, :advertiser => @advertiser_1, :value_proposition => "advertiser 1, deal 1",
                           :value => 100, :price => 55, :start_at => a1_deal_1_start, :hide_at => a1_deal_1_start + 3.days,
                          :custom_1 => "a1_deal_1 custom one", :custom_2 => "a1_deal_1 custom two", :custom_3 => "a1_deal_1 custom three"
      @a1_deal_2 = Factory :daily_deal, :advertiser => @advertiser_1, :value_proposition => "advertiser 1, deal 2",
                           :value => 30, :price => 10, :start_at => a1_deal_2_start, :hide_at => a1_deal_2_start + 3.days,
                          :custom_1 => "a1_deal_2 custom one", :custom_2 => "a1_deal_2 custom two", :custom_3 => "a1_deal_2 custom three"
      @a2_deal_1 = Factory :daily_deal, :advertiser => @advertiser_2, :value_proposition => "advertiser 2, deal 1",
                           :value => 40, :price => 15, :start_at => a2_deal_1_start, :hide_at => a2_deal_1_start + 3.days,
                          :custom_1 => "a2_deal_1 custom one", :custom_2 => "a2_deal_1 custom two", :custom_3 => "a2_deal_1 custom three"
      @a2_deal_2 = Factory :daily_deal, :advertiser => @advertiser_2, :value_proposition => "advertiser 2, deal 2",
                           :value => 40, :price => 15, :start_at => a2_deal_2_start, :hide_at => a2_deal_2_start + 3.days,
                          :custom_1 => "a2_deal_2 custom one", :custom_2 => "a2_deal_2 custom two", :custom_3 => "a2_deal_2 custom three"
      @a4_deal_1 = Factory :daily_deal, :advertiser => @advertiser_4, :value_proposition => "advertiser 4, deal 1",
                           :value => 25, :price => 10, :start_at => a4_deal_1_start, :hide_at => a4_deal_1_start + 3.days,
                          :custom_1 => "a4_deal_1 custom one", :custom_2 => "a4_deal_1 custom two", :custom_3 => "a4_deal_1 custom three"
      @a4_deal_2 = Factory :daily_deal, :advertiser => @advertiser_4, :value_proposition => "advertiser 4, deal 2",
                           :value => 25, :price => 10, :certificates_to_generate_per_unit_quantity => 3,
                           :start_at => a4_deal_2_start, :hide_at => a4_deal_2_start + 3.days

      Factory :authorized_daily_deal_purchase, :daily_deal => @a1_deal_1, :executed_at => @a1_deal_1.start_at + 5.minutes
      3.times { |n| Factory :captured_daily_deal_purchase, :daily_deal => @a1_deal_1, :executed_at => @a1_deal_1.start_at + (n * 20.minutes) }
      Factory :voided_daily_deal_purchase, :daily_deal => @a2_deal_1, :executed_at => a2_deal_1_start + 10.seconds
      Factory :pending_daily_deal_purchase, :daily_deal => @a2_deal_1, :executed_at => a2_deal_2_start + 10.seconds
      2.times { |n| Factory :authorized_daily_deal_purchase, :daily_deal => @a4_deal_1, :executed_at => a4_deal_1_start + (n * 12.minutes) }
      Factory :captured_daily_deal_purchase, :daily_deal => @a4_deal_1, :quantity => 3, :executed_at => a4_deal_1_start + 25.minutes
      Factory :captured_daily_deal_purchase, :daily_deal => @a4_deal_1, :executed_at => @a4_deal_1.start_at + 1.day
      Factory :captured_daily_deal_purchase, :daily_deal => @a1_deal_1, :executed_at => @a1_deal_1.start_at.beginning_of_month - 7.days
      Factory :captured_daily_deal_purchase, :daily_deal => @a1_deal_1, :executed_at => Time.now + 7.days
      Factory :captured_daily_deal_purchase, :daily_deal => @a4_deal_2, :quantity => 2, :executed_at => @a4_deal_2.start_at + 1.day
    end

    context "daily_deals_summary" do

      should "show the started at, value propositions, num purchased, num purchasers, gross, custom values and total " +
             "for all a publisher's advertisers that have purchases in a given date range" do
        purchased_daily_deals = @publisher_1.daily_deals_summary(@a1_deal_1.start_at.beginning_of_month..Time.now)

        first_deal = purchased_daily_deals[0]
        assert_equal "2011-01-26", first_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 1, deal 1", first_deal.value_proposition
        assert_equal 3, first_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 3, first_deal.daily_deal_purchasers_count.to_i
        assert_equal 165, first_deal.daily_deal_purchases_gross.to_i
        assert_equal 165, first_deal.daily_deal_purchases_amount.to_i
        assert_equal "a1_deal_1 custom one", first_deal.custom_1
        assert_equal "a1_deal_1 custom two", first_deal.custom_2
        assert_equal "a1_deal_1 custom three", first_deal.custom_3

        second_deal = purchased_daily_deals[1]
        assert_equal "2011-02-02", second_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 1, deal 2", second_deal.value_proposition
        assert_equal 0, second_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, second_deal.daily_deal_purchasers_count.to_i
        assert_equal 0, second_deal.daily_deal_purchases_gross.to_i
        assert_equal 0, second_deal.daily_deal_purchases_amount.to_i
        assert_equal "a1_deal_2 custom one", second_deal.custom_1
        assert_equal "a1_deal_2 custom two", second_deal.custom_2
        assert_equal "a1_deal_2 custom three", second_deal.custom_3
        
        third_deal = purchased_daily_deals[2]
        assert_equal "2011-02-16", third_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 4, deal 1", third_deal.value_proposition
        assert_equal 4, third_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 2, third_deal.daily_deal_purchasers_count.to_i
        assert_equal 40, third_deal.daily_deal_purchases_gross.to_i
        assert_equal 40, third_deal.daily_deal_purchases_amount.to_i
        assert_equal "a4_deal_1 custom one", third_deal.custom_1
        assert_equal "a4_deal_1 custom two", third_deal.custom_2
        assert_equal "a4_deal_1 custom three", third_deal.custom_3
        
        fourth_deal = purchased_daily_deals[3]
        assert_equal "2011-02-17", fourth_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 2, deal 1", fourth_deal.value_proposition
        assert_equal 0, fourth_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, fourth_deal.daily_deal_purchasers_count.to_i
        assert_equal 0, fourth_deal.daily_deal_purchases_gross.to_i
        assert_equal 0, fourth_deal.daily_deal_purchases_amount.to_i
        assert_equal "a2_deal_1 custom one", fourth_deal.custom_1
        assert_equal "a2_deal_1 custom two", fourth_deal.custom_2
        assert_equal "a2_deal_1 custom three", fourth_deal.custom_3
        
        fifth_deal = purchased_daily_deals[4]
        assert_equal "2011-02-17", fifth_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 2, deal 2", fifth_deal.value_proposition
        assert_equal 0, fifth_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, fifth_deal.daily_deal_purchasers_count.to_i
        assert_equal 0, fifth_deal.daily_deal_purchases_gross.to_i
        assert_equal 0, fifth_deal.daily_deal_purchases_amount.to_i
        assert_equal "a2_deal_2 custom one", fifth_deal.custom_1
        assert_equal "a2_deal_2 custom two", fifth_deal.custom_2
        assert_equal "a2_deal_2 custom three", fifth_deal.custom_3

        sixth_deal = purchased_daily_deals[5]
        assert_equal "2011-02-18", sixth_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 4, deal 2", sixth_deal.value_proposition
        assert_equal 2, sixth_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 1, sixth_deal.daily_deal_purchasers_count.to_i
        assert_equal 20, sixth_deal.daily_deal_purchases_gross.to_i
        assert_equal 20, sixth_deal.daily_deal_purchases_amount.to_i
        
        assert_equal 6, purchased_daily_deals.length
      end

      should "show the number of refunds and refund total, while gross stays the same, and total subtracts the refund amount" do
        Factory :refunded_daily_deal_purchase, :quantity => 2, :daily_deal => @a1_deal_1, :refunded_at => @a1_deal_1.start_at + 6.hours
        refunded_purchase2 = Factory :refunded_daily_deal_purchase, :daily_deal => @a1_deal_1, :refunded_at => @a1_deal_1.start_at + 7.hours
        Factory :refunded_daily_deal_purchase, :daily_deal => @a4_deal_1, :refunded_at => @a4_deal_1.start_at + 1.day
        assert_equal 55, refunded_purchase2.refund_amount
        assert_equal 1, refunded_purchase2.daily_deal_certificates.size
        assert_equal "refunded", refunded_purchase2.daily_deal_certificates[0].status
        assert_equal 55, refunded_purchase2.daily_deal_certificates[0].refund_amount
        Factory :refunded_daily_deal_purchase, :daily_deal => @a4_deal_2, :refunded_at => @a4_deal_2.start_at + 1.day

        purchased_daily_deals = @publisher_1.daily_deals_summary(@a1_deal_1.start_at.beginning_of_month..Time.now)

        first_deal = purchased_daily_deals[0]
        assert_equal "2011-01-26", first_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 1, deal 1", first_deal.value_proposition
        assert_equal 6, first_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 5, first_deal.daily_deal_purchasers_count.to_i
        assert_equal 330, first_deal.daily_deal_purchases_gross.to_i
        assert_equal 330, first_deal.daily_deal_purchases_amount.to_i
        assert_equal 3, first_deal.daily_deal_refunded_voucher_count.to_i
        assert_equal 165, first_deal.daily_deal_refunds_total_amount.to_i
        
        second_deal = purchased_daily_deals[1]
        assert_equal "2011-02-02", second_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 1, deal 2", second_deal.value_proposition
        assert_equal 0, second_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, second_deal.daily_deal_purchasers_count.to_i
        assert_equal 0, second_deal.daily_deal_purchases_gross.to_i
        assert_equal 0, second_deal.daily_deal_purchases_amount.to_i
        assert_equal 0, second_deal.daily_deal_refunded_voucher_count.to_i
        assert_equal 0, second_deal.daily_deal_refunds_total_amount.to_i
        
        third_deal = purchased_daily_deals[2]
        assert_equal "2011-02-16", third_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 4, deal 1", third_deal.value_proposition
        assert_equal 5, third_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 3, third_deal.daily_deal_purchasers_count.to_i
        assert_equal 50, third_deal.daily_deal_purchases_gross.to_i
        assert_equal 50, third_deal.daily_deal_purchases_amount.to_i
        assert_equal 1, third_deal.daily_deal_refunded_voucher_count.to_i
        assert_equal 10, third_deal.daily_deal_refunds_total_amount.to_i
        
        fourth_deal = purchased_daily_deals[3]
        assert_equal "2011-02-17", fourth_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 2, deal 1", fourth_deal.value_proposition
        assert_equal 0, fourth_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, fourth_deal.daily_deal_purchasers_count.to_i
        assert_equal 0, fourth_deal.daily_deal_purchases_gross.to_i
        assert_equal 0, fourth_deal.daily_deal_purchases_amount.to_i
        assert_equal 0, fourth_deal.daily_deal_refunded_voucher_count.to_i
        assert_equal 0, fourth_deal.daily_deal_refunds_total_amount.to_i
        
        fifth_deal = purchased_daily_deals[4]
        assert_equal "2011-02-17", fifth_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 2, deal 2", fifth_deal.value_proposition
        assert_equal 0, fifth_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, fifth_deal.daily_deal_purchasers_count.to_i
        assert_equal 0, fifth_deal.daily_deal_purchases_gross.to_i
        assert_equal 0, fifth_deal.daily_deal_purchases_amount.to_i
        assert_equal 0, fifth_deal.daily_deal_refunded_voucher_count.to_i
        assert_equal 0, fifth_deal.daily_deal_refunds_total_amount.to_i
        
        sixth_deal = purchased_daily_deals[5]
        assert_equal "2011-02-18", sixth_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 4, deal 2", sixth_deal.value_proposition
        assert_equal 3, sixth_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 2, sixth_deal.daily_deal_purchasers_count.to_i
        assert_equal 30, sixth_deal.daily_deal_purchases_gross.to_i
        assert_equal 30, sixth_deal.daily_deal_purchases_amount.to_i
        assert_equal 1, sixth_deal.daily_deal_refunded_voucher_count.to_i
        assert_equal 10, sixth_deal.daily_deal_refunds_total_amount.to_i
        
        assert_equal 6, purchased_daily_deals.length
      end

      should "exclude partial refunds" do
        purchase1 = Factory :captured_daily_deal_purchase, :quantity => 2, :daily_deal => @a1_deal_1
        Factory :refunded_daily_deal_purchase, :daily_deal => @a1_deal_1, :refunded_at => @a1_deal_1.start_at + 7.hours
        purchased_daily_deals = @publisher_1.daily_deals_summary(@a1_deal_1.start_at.beginning_of_month..Time.now)
        assert_equal 6, purchased_daily_deals.length
        expect_braintree_partial_refund(purchase1, 55)
        purchase1.partial_refund!(Factory(:admin), [purchase1.daily_deal_certificates.first.id.to_s])
        refunded_at = @a1_deal_1.start_at + 6.hours
        purchase1.update_attributes!(:refunded_at => refunded_at)
        purchase1.daily_deal_certificates.first.update_attributes!(:refunded_at => refunded_at)
        assert_equal "refunded", purchase1.payment_status
        assert_equal 2, purchase1.daily_deal_certificates.size
        assert_equal "refunded", purchase1.daily_deal_certificates.first.status
        assert_equal "active", purchase1.daily_deal_certificates.second.status
        assert_equal 55, purchase1.daily_deal_certificates.first.actual_purchase_price
        assert_equal 55, purchase1.daily_deal_certificates.second.actual_purchase_price
        assert_equal 55, purchase1.daily_deal_certificates.first.refund_amount
        assert_equal 0, purchase1.daily_deal_certificates.second.refund_amount

        purchased_daily_deals = @publisher_1.daily_deals_summary(@a1_deal_1.start_at.beginning_of_month..Time.now)
        assert_equal 6, purchased_daily_deals.length
        first_deal = purchased_daily_deals[0]
        assert_equal 6, first_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 5, first_deal.daily_deal_purchasers_count.to_i
        assert_equal 330, first_deal.daily_deal_purchases_gross.to_i
        assert_equal 330, first_deal.daily_deal_purchases_amount.to_i
        assert_equal 2, first_deal.daily_deal_refunded_voucher_count.to_i
        assert_equal 110, first_deal.daily_deal_refunds_total_amount.to_i
      end

      should "include purchases that were made in the specified time period but /later/ refunded in the purchase counts" do
        query_start_date = Time.parse("2011-01-01")
        query_end_date = Time.parse("2011-01-31")

        refunded1 = Factory :refunded_daily_deal_purchase, :daily_deal => @a1_deal_1, :executed_at => @a1_deal_1.start_at + 20.minutes,
                            :refunded_at => @a1_deal_1.start_at + 2.days
        refunded2 = Factory :refunded_daily_deal_purchase, :daily_deal => @a1_deal_1, :quantity => 2, :executed_at => @a1_deal_1.start_at + 9.hours,
                            :refunded_at => Time.parse("2011-02-13")

        assert_equal 1, refunded1.daily_deal_certificates.size
        assert_equal 2, refunded2.daily_deal_certificates.size
        assert_equal "refunded", refunded1.daily_deal_certificates[0].status
        assert_equal "refunded", refunded2.daily_deal_certificates[0].status
        assert_equal "refunded", refunded2.daily_deal_certificates[1].status

        purchased_daily_deals = @publisher_1.daily_deals_summary(query_start_date..query_end_date)

        first_deal = purchased_daily_deals[0]
        assert_equal "2011-01-26", first_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 1, deal 1", first_deal.value_proposition
        assert_equal 6, first_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 5, first_deal.daily_deal_purchasers_count.to_i
        assert_equal 330, first_deal.daily_deal_purchases_gross.to_i
        assert_equal 330, first_deal.daily_deal_purchases_amount.to_i
        assert_equal 1, first_deal.daily_deal_refunded_voucher_count.to_i
        assert_equal 55, first_deal.daily_deal_refunds_total_amount.to_i
        
        assert_equal 1, purchased_daily_deals.length
      end
      
      should "include deals purchased before the specified time period, but refunded within it" do
        query_start_date = Time.parse("2011-02-01")
        query_end_date = Time.parse("2011-02-28")

        refunded_purchase = Factory :refunded_daily_deal_purchase, :daily_deal => @a1_deal_1, :quantity => 2, :executed_at => @a1_deal_1.start_at + 9.hours,
                                    :refunded_at => Time.parse("2011-02-13")

        assert_equal 110, refunded_purchase.daily_deal_payment.amount
        assert_equal 110, refunded_purchase.refund_amount

        purchased_daily_deals = @publisher_1.daily_deals_summary(query_start_date..query_end_date)

        first_deal = purchased_daily_deals[0]
        assert_equal "2011-01-26", first_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 1, deal 1", first_deal.value_proposition
        assert_equal 0, first_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, first_deal.daily_deal_purchasers_count.to_i
        assert_equal 0, first_deal.daily_deal_purchases_gross.to_i
        assert_equal 0, first_deal.daily_deal_purchases_amount.to_i
        assert_equal 2, first_deal.daily_deal_refunded_voucher_count.to_i
        assert_equal 110, first_deal.daily_deal_refunds_total_amount.to_i
        
        second_deal = purchased_daily_deals[1]
        assert_equal "2011-02-02", second_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 1, deal 2", second_deal.value_proposition
        assert_equal 0, second_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, second_deal.daily_deal_purchasers_count.to_i
        assert_equal 0, second_deal.daily_deal_purchases_gross.to_i
        assert_equal 0, second_deal.daily_deal_purchases_amount.to_i
        assert_equal 0, second_deal.daily_deal_refunded_voucher_count.to_i
        assert_equal 0, second_deal.daily_deal_refunds_total_amount.to_i

        third_deal = purchased_daily_deals[2]
        assert_equal "2011-02-16", third_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 4, deal 1", third_deal.value_proposition
        assert_equal 4, third_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 2, third_deal.daily_deal_purchasers_count.to_i
        assert_equal 40, third_deal.daily_deal_purchases_gross.to_i
        assert_equal 40, third_deal.daily_deal_purchases_amount.to_i
        assert_equal 0, third_deal.daily_deal_refunded_voucher_count.to_i
        assert_equal 0, third_deal.daily_deal_refunds_total_amount.to_i
        
        fourth_deal = purchased_daily_deals[3]
        assert_equal "2011-02-17", fourth_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 2, deal 1", fourth_deal.value_proposition
        assert_equal 0, fourth_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, fourth_deal.daily_deal_purchasers_count.to_i
        assert_equal 0, fourth_deal.daily_deal_purchases_gross.to_i
        assert_equal 0, fourth_deal.daily_deal_purchases_amount.to_i
        assert_equal 0, fourth_deal.daily_deal_refunded_voucher_count.to_i
        assert_equal 0, fourth_deal.daily_deal_refunds_total_amount.to_i
        
        fifth_deal = purchased_daily_deals[4]
        assert_equal "2011-02-17", fifth_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 2, deal 2", fifth_deal.value_proposition
        assert_equal 0, fifth_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, fifth_deal.daily_deal_purchasers_count.to_i
        assert_equal 0, fifth_deal.daily_deal_purchases_gross.to_i
        assert_equal 0, fifth_deal.daily_deal_purchases_amount.to_i
        assert_equal 0, fourth_deal.daily_deal_refunded_voucher_count.to_i
        assert_equal 0, fourth_deal.daily_deal_refunds_total_amount.to_i

        sixth_deal = purchased_daily_deals[5]
        assert_equal "2011-02-18", sixth_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 4, deal 2", sixth_deal.value_proposition
        assert_equal 2, sixth_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 1, sixth_deal.daily_deal_purchasers_count.to_i
        assert_equal 20, sixth_deal.daily_deal_purchases_gross.to_i
        assert_equal 20, sixth_deal.daily_deal_purchases_amount.to_i
        
        assert_equal 6, purchased_daily_deals.length
      end

      should "calculate counts and gross with discounts applied" do
        discount_1 = Factory :discount, :publisher => @publisher_1, :amount => 5
        discount_2 = Factory :discount, :publisher => @publisher_1, :amount => 20
        #A4_1 - 2 authorized purchases - 0 certs
        2.times { |n| Factory :authorized_daily_deal_purchase, :daily_deal => @a4_deal_1, :executed_at => @a4_deal_1.start_at + (n * 12.minutes) }

        #A4_1 - 2 captured purchases - 4 active certs
        Factory :captured_daily_deal_purchase_with_discount, :daily_deal => @a4_deal_1, :quantity => 3, :discount => discount_1, :executed_at => @a4_deal_1.start_at + 25.minutes
        Factory :captured_daily_deal_purchase_with_discount, :daily_deal => @a4_deal_1, :discount => discount_2, :executed_at => @a4_deal_1.start_at + 1.day

        #A4_1 - 2 authorized purchases - 0 certs
        2.times { |n| Factory :authorized_daily_deal_purchase, :daily_deal => @a4_deal_2, :executed_at => @a4_deal_2.start_at + (n * 12.minutes) }
        #A4_1 - 2 captured purchases - 4 active certs
        discount_3 = Factory :discount, :publisher => @publisher_1, :amount => 7
        purchase = Factory :captured_daily_deal_purchase, :daily_deal => @a4_deal_2, :quantity => 3, :discount => discount_3, :executed_at => @a4_deal_2.start_at + 25.minutes
        purchase.discount = discount_3
        purchase.send(:set_actual_purchase_price!)

        purchased_daily_deals = @publisher_1.daily_deals_summary(@a1_deal_1.start_at.beginning_of_month..Time.now)

        first_deal = purchased_daily_deals[0]
        assert_equal "2011-01-26", first_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 1, deal 1", first_deal.value_proposition
        assert_equal 3, first_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 3, first_deal.daily_deal_purchasers_count.to_i
        assert_equal 165, first_deal.daily_deal_purchases_gross.to_i
        assert_equal 165, first_deal.daily_deal_purchases_amount.to_i
        
        second_deal = purchased_daily_deals[1]
        assert_equal "2011-02-02", second_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 1, deal 2", second_deal.value_proposition
        assert_equal 0, second_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, second_deal.daily_deal_purchasers_count.to_i
        assert_equal 0, second_deal.daily_deal_purchases_gross.to_i
        assert_equal 0, second_deal.daily_deal_purchases_amount.to_i

        third_deal = purchased_daily_deals[2]
        assert_equal "2011-02-16", third_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 4, deal 1", third_deal.value_proposition
        assert_equal 8, third_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 4, third_deal.daily_deal_purchasers_count.to_i
        assert_equal 80, third_deal.daily_deal_purchases_gross.to_i
        assert_equal 60, third_deal.daily_deal_purchases_amount.to_i
        
        fourth_deal = purchased_daily_deals[3]
        assert_equal "2011-02-17", fourth_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 2, deal 1", fourth_deal.value_proposition
        assert_equal 0, fourth_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, fourth_deal.daily_deal_purchasers_count.to_i
        assert_equal 0, fourth_deal.daily_deal_purchases_gross.to_i
        assert_equal 0, fourth_deal.daily_deal_purchases_amount.to_i
        assert_equal 0, fourth_deal.daily_deal_refunded_voucher_count.to_i
        assert_equal 0, fourth_deal.daily_deal_refunds_total_amount.to_i
        
        fifth_deal = purchased_daily_deals[4]
        assert_equal "2011-02-17", fifth_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 2, deal 2", fifth_deal.value_proposition
        assert_equal 0, fifth_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, fifth_deal.daily_deal_purchasers_count.to_i
        assert_equal 0, fifth_deal.daily_deal_purchases_gross.to_i
        assert_equal 0, fifth_deal.daily_deal_purchases_amount.to_i
        assert_equal 0, fourth_deal.daily_deal_refunded_voucher_count.to_i
        assert_equal 0, fourth_deal.daily_deal_refunds_total_amount.to_i

        sixth_deal = purchased_daily_deals[5]
        assert_equal "2011-02-18", sixth_deal.start_at.strftime("%Y-%m-%d")
        assert_equal "advertiser 4, deal 2", sixth_deal.value_proposition
        assert_equal 5, sixth_deal.daily_deal_purchases_total_quantity.to_i
        assert_equal 2, sixth_deal.daily_deal_purchasers_count.to_i
        assert_equal 50, sixth_deal.daily_deal_purchases_gross.to_i
        assert_equal 43, sixth_deal.daily_deal_purchases_amount.to_i
        
        assert_equal 6, purchased_daily_deals.length
      end

      should "not include offplatform purchases" do
        publisher = Factory(:publisher)
        deal = Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => publisher))
        ddp = Factory(:captured_daily_deal_purchase, :daily_deal => deal)
        admin = Factory(:admin)
        create_captured_off_platform_purchase(:daily_deal => deal)
        create_refunded_off_platform_purchase(admin, :daily_deal => deal)
        past_refund = create_refunded_off_platform_purchase_outside_timeperiod(admin, :daily_deal => deal, :executed_at => 2.days.ago)
        # Force the purchase status to be refunded (and set refunded_at) to ensure off-platform purchases are excluded if the report is ever rewritten to find refunds at the certificate level (off-platform purchases are only refunded at the certificate level with the current API)
        past_refund.update_attribute(:payment_status, 'refunded')
        past_refund.update_attribute(:refunded_at, Time.zone.now)

        daily_deals = publisher.daily_deals_summary(1.day.ago..1.day.from_now)
        result = daily_deals.select{|d| d.id == deal.id}.first

        assert_equal 1, result.daily_deal_purchasers_count
        assert_equal 1, result.daily_deal_purchases_total_quantity
        assert_equal deal.price, result.daily_deal_purchases_gross
        assert_equal ddp.daily_deal_certificates.first.actual_purchase_price, result.daily_deal_purchases_amount
        assert_equal 0, result.daily_deal_refunds_total_amount
        assert_equal 0, result.daily_deal_refunded_voucher_count
      end
    end

    context ".all_with_purchased_daily_deal_counts" do
      
      should "return a row for each of the given publishers with purchase transactions in the given period" do
        purchased_deals_rows = Publisher.all_with_purchased_daily_deal_counts(@a1_deal_1.start_at.beginning_of_month..Time.now, @publisher_1)
        assert_equal 1, purchased_deals_rows.length
      end
      
      should "report # deals, purchased, purchasers, currency code, gross, and totals for only deals that have sales" do
        purchased_deals_rows = Publisher.all_with_purchased_daily_deal_counts(@a1_deal_1.start_at.beginning_of_month..Time.now, @publisher_1)
        assert_equal 1, purchased_deals_rows.length

        first_row = purchased_deals_rows.first
        assert_equal 3, first_row.daily_deals_count
        assert_equal 9, first_row.daily_deal_purchases_total_quantity
        assert_equal 6, first_row.daily_deal_purchasers_count
        assert_equal "USD", first_row.currency_code
        assert_equal 225, first_row.daily_deal_purchases_gross
        assert_equal 225, first_row.daily_deal_purchases_actual_purchase_price
      end
      
      should "include refund amounts for each publisher" do
        refunded_purchase = Factory :refunded_daily_deal_purchase, :daily_deal => @a1_deal_1, :quantity => 2, :executed_at => @a1_deal_1.start_at + 9.hours,
                                    :refunded_at => Time.parse("2011-02-13")
        
        purchased_deals_rows = Publisher.all_with_purchased_daily_deal_counts(@a1_deal_1.start_at.beginning_of_month..Time.now, @publisher_1)
        assert_equal 1, purchased_deals_rows.length
        
        first_row = purchased_deals_rows.first
        assert_equal 335, first_row.daily_deal_purchases_gross
        assert_equal 335, first_row.daily_deal_purchases_actual_purchase_price
        assert_equal 110, first_row.daily_deal_purchases_refund_amount
      end
      
      should "not include purchases executed in the reporting period but refunded outside it in the refund totals" do
        refunded_purchase = Factory :refunded_daily_deal_purchase, :daily_deal => @a1_deal_1, :quantity => 2, :executed_at => @a1_deal_1.start_at + 9.hours,
                                    :refunded_at => Time.now + 1.week
        
        purchased_deals_rows = Publisher.all_with_purchased_daily_deal_counts(@a1_deal_1.start_at.beginning_of_month..Time.now, @publisher_1)
        assert_equal 1, purchased_deals_rows.length
        
        first_row = purchased_deals_rows.first
        assert_equal 335, first_row.daily_deal_purchases_gross
        assert_equal 335, first_row.daily_deal_purchases_actual_purchase_price
        assert_equal 0, first_row.daily_deal_purchases_refund_amount        
      end
      
      should "include purchases executed outside the reporting period but refunded inside the reporting period in the refund totals" do
        right_now = Time.now
        daily_deal = Factory :daily_deal, :price => 30, :value => 70, :start_at => right_now, :hide_at => right_now + 1.month
        
        captured_purchase = Factory :captured_daily_deal_purchase, :daily_deal => daily_deal, :quantity => 1, :executed_at => right_now + 2.days
        refunded_purchase = Factory :refunded_daily_deal_purchase, :daily_deal => daily_deal, :quantity => 2, :executed_at => right_now + 5.minutes,
                                    :refunded_at => right_now + 3.days
        
        purchased_deals_rows = Publisher.all_with_purchased_daily_deal_counts((right_now + 1.day)..(right_now + 4.days), daily_deal.publisher)
        assert_equal 1, purchased_deals_rows.length
        
        first_row = purchased_deals_rows.first
        assert_equal 30, first_row.daily_deal_purchases_gross
        assert_equal 30, first_row.daily_deal_purchases_actual_purchase_price
        assert_equal 60, first_row.daily_deal_purchases_refund_amount        
      end

      should "not include offplatform purchases" do
        publisher = Factory(:publisher)
        deal = Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => publisher))
        ddp = Factory(:captured_daily_deal_purchase, :daily_deal => deal)
        admin = Factory(:admin)
        create_captured_off_platform_purchase(:daily_deal => deal)
        create_refunded_off_platform_purchase(admin, :daily_deal => deal)
        create_refunded_off_platform_purchase_outside_timeperiod(admin, :daily_deal => deal, :executed_at => 2.days.ago)

        publishers = Publisher.all_with_purchased_daily_deal_counts(1.day.ago..1.day.from_now, [publisher.id])
        result = publishers.select{|p| p.id == publisher.id}.first

        assert_equal 1, result.daily_deal_purchases_total_quantity
        assert_equal deal.price, result.daily_deal_purchases_gross
        assert_equal ddp.daily_deal_certificates.first.actual_purchase_price, result.daily_deal_purchases_actual_purchase_price
        assert_equal 0, result.daily_deal_purchases_refund_amount
      end
    end
    
    context "#daily_deals_with_refund_counts" do

      setup do
        Factory :refunded_daily_deal_purchase, :daily_deal => @a1_deal_1, :executed_at => @a1_deal_1.start_at + 20.minutes,
                :refunded_at => @a1_deal_1.start_at + 2.days
        Factory :refunded_daily_deal_purchase, :daily_deal => @a1_deal_1, :quantity => 2, :executed_at => @a1_deal_1.start_at + 9.hours,
                :refunded_at => Time.parse("2011-02-13")
      end

      should "return one result for a given publisher" do
        refunds = @publisher_1.daily_deals_with_refund_counts(@a1_deal_1.start_at.beginning_of_month..Time.now)
        assert_equal 1, refunds.size
      end
      
      should "include the # of refunds, # of people refunded, refund gross and refund amount" do
        refunds = @publisher_1.daily_deals_with_refund_counts(@a1_deal_1.start_at.beginning_of_month..Time.now)
        assert_equal 1, refunds.size

        refund_row = refunds.first
        assert_equal 2, refund_row.daily_deal_refunded_purchasers_count
        assert_equal 2, refund_row.daily_deal_refunded_purchases_count
        assert_equal 3, refund_row.daily_deal_vouchers_refunded_count
        assert_equal 165, refund_row.daily_deal_refunds_gross
        assert_equal 165, refund_row.daily_deal_refunds_amount
        assert_equal "a1_deal_1 custom one", refund_row.custom_1
        assert_equal "a1_deal_1 custom two", refund_row.custom_2
        assert_equal "a1_deal_1 custom three", refund_row.custom_3
      end

      context "with refunded daily_deal_purchase that has no payment" do
        setup do
          @daily_deal = Factory(:daily_deal, :value => 100, :price => 5, :publisher => @publisher_1)
          @daily_deal_purchase = Factory(:captured_daily_deal_purchase_with_discount, :daily_deal => @daily_deal, :quantity => 2)
          @admin = Factory :admin
          @daily_deal_purchase.void_or_full_refund!(@admin)
        end

        should "have correct setup" do
          assert_nil @daily_deal_purchase.daily_deal_payment
          assert_equal 0, @daily_deal_purchase.actual_purchase_price
        end

        should "show refund with correct values" do
          refunds = @publisher_1.daily_deals_with_refund_counts(@daily_deal.start_at.beginning_of_month..Time.now)
          assert_equal 1, refunds.size

          refund_row = refunds.first
          assert_equal 1, refund_row.daily_deal_refunded_purchasers_count
          assert_equal 1, refund_row.daily_deal_refunded_purchases_count
          assert_equal 2, refund_row.daily_deal_vouchers_refunded_count
          assert_equal 10, refund_row.daily_deal_refunds_gross
          assert_equal 0, refund_row.daily_deal_refunds_amount
        end
      end
      
    end
    
  end

  context "#daily_deals_with_refund_counts partial - simple full and partial" do
    setup do
      @admin = Factory(:admin)
      @deal = Factory(:daily_deal, :price => 12, :start_at => 4.days.ago)
      @purchase = Factory(:captured_daily_deal_purchase, :quantity => 3, :daily_deal => @deal)
    end
    context "full refunds" do
      setup do
        expect_braintree_full_refund(@purchase)
        @purchase.void_or_full_refund!(@admin)
      end
      should "have correct summary data" do
        refunds = @deal.publisher.daily_deals_with_refund_counts(7.days.ago..Time.now)
        assert_equal 1, refunds.size
        assert_equal 1, refunds.first.daily_deal_refunded_purchasers_count
        assert_equal 3, refunds.first.daily_deal_vouchers_refunded_count
        assert_equal 36, refunds.first.daily_deal_refunds_gross
        assert_equal 36, refunds.first.daily_deal_refunds_amount
      end
    end
    context "partial refunds" do
      setup do
        expect_braintree_partial_refund(@purchase, 12)
        @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificates.first.id])
      end
      should "have correct summary data" do
        refunds = @deal.publisher.daily_deals_with_refund_counts(7.days.ago..Time.now)
        assert_equal 1, refunds.size
        assert_equal 1, refunds.first.daily_deal_refunded_purchasers_count
        assert_equal 1, refunds.first.daily_deal_vouchers_refunded_count
        assert_equal 12, refunds.first.daily_deal_refunds_gross
        assert_equal 12, refunds.first.daily_deal_refunds_amount
      end
    end
    context "partial refund outside the report dates" do
      context "1 day ago" do
        setup do
          Timecop.freeze(4.days.ago) do
            expect_braintree_partial_refund(@purchase, 12)
            @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificates.first.id])
          end
          Timecop.freeze(2.days.ago) do
            expect_braintree_partial_refund(@purchase, 12)
            @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificates.second.id])
          end
        end
        should "include both partial refunds if reporting window includes them" do
          refunds = @deal.publisher.daily_deals_with_refund_counts(5.days.ago..Time.zone.now)
          assert_equal 1, refunds.size
          assert_equal 1, refunds.first.daily_deal_refunded_purchasers_count
          assert_equal 1, refunds.first.daily_deal_refunded_purchases_count
          assert_equal 2, refunds.first.daily_deal_vouchers_refunded_count
          assert_equal 24, refunds.first.daily_deal_refunds_gross
          assert_equal 24, refunds.first.daily_deal_refunds_amount
        end
        should "include only include one partial refunds if reporting window only includes one" do
          refunds = @deal.publisher.daily_deals_with_refund_counts(3.days.ago..Time.zone.now)
          assert_equal 1, refunds.size
          assert_equal 1, refunds.first.daily_deal_refunded_purchasers_count
          assert_equal 1, refunds.first.daily_deal_refunded_purchases_count
          assert_equal 1, refunds.first.daily_deal_vouchers_refunded_count
          assert_equal 12, refunds.first.daily_deal_refunds_gross
          assert_equal 12, refunds.first.daily_deal_refunds_amount
        end
      end
    end
  end

  context "#all_with_affiliated_daily_deal_counts" do
    should "return the expected data" do
      publisher = Factory(:publisher, :name => "Publisher 1")

      deal = Factory(:daily_deal,
                     :publisher => publisher,
                     :price => 20.00,
                     :start_at => Time.zone.parse("Mar 04, 2011 07:00:00"),
                     :hide_at => Time.zone.parse("Mar 04, 2011 17:00:00"),
                     :affiliate_revenue_share_percentage => 10.0)

      placement = Factory(:affiliate_placement, :placeable => deal)

      Factory(:captured_daily_deal_purchase,
              :daily_deal => deal,
              :executed_at => deal.start_at + 1.minutes,
              :quantity => 2,
              :affiliate => placement.affiliate)

      dates = Time.zone.parse("Mar 01, 2011")..Time.zone.parse("Mar 09, 2011")

      affiliated_deals_rows = Publisher.all_with_affiliated_daily_deal_counts(dates, publisher)

      row = affiliated_deals_rows.shift
      assert_equal "USD", row.currency_code
      assert_equal "$", row.currency_symbol
      assert_equal 1, row.daily_deals_count
      assert_equal 1, row.daily_deal_purchasers_count
      assert_equal 2, row.daily_deal_purchases_total_quantity
      assert_equal 40.0, row.daily_deal_affiliate_gross
      assert_equal 4.0, row.daily_deal_affiliate_payout
    end

  end

  test "daily_deals_with_affiliated_daily_deal_counts" do
    publisher = Factory(:publisher, :name => "Publisher 1")

    a_1 = Factory(:advertiser, :publisher => publisher)
    a_2 = Factory(:advertiser, :publisher => publisher)

    a_1_d_1 = Factory(:daily_deal,
                      :publisher => publisher,
                      :advertiser => a_1,
                      :price => 20.00,
                      :start_at => Time.zone.parse("Mar 04, 2011 07:00:00"),
                      :hide_at => Time.zone.parse("Mar 04, 2011 17:00:00"),
                      :affiliate_revenue_share_percentage => 20.0,
                      :custom_1 => "a1d1 custom one",
                      :custom_2 => "a1d1 custom two",
                      :custom_3 => "a1d1 custom three"
    )

    a_1_d_1_placement_1 = Factory(:affiliate_placement, :placeable => a_1_d_1)

    Factory(:captured_daily_deal_purchase,
            :daily_deal => a_1_d_1,
            :executed_at => a_1_d_1.start_at + 1.minutes,
            :affiliate => a_1_d_1_placement_1.affiliate)
    Factory(:captured_daily_deal_purchase,
            :daily_deal => a_1_d_1,
            :executed_at => a_1_d_1.start_at + 5.minutes,
            :affiliate => a_1_d_1_placement_1.affiliate,
            :quantity => 5)
    Factory(:captured_daily_deal_purchase,
            :daily_deal => a_1_d_1,
            :executed_at => a_1_d_1.start_at + 9.minutes)

    a_1_d_2 = Factory(:daily_deal,
                      :publisher => publisher,
                      :advertiser => a_1,
                      :price => 15.00,
                      :start_at => Time.zone.parse("Mar 05, 2011 07:00:00"),
                      :hide_at => Time.zone.parse("Mar 05, 2011 17:00:00"),
                      :affiliate_revenue_share_percentage => 10.0,
                      :custom_1 => "a1d2 custom one",
                      :custom_2 => "a1d2 custom two",
                      :custom_3 => "a1d2 custom three"
    )

    a_1_d_2_placement_1 = Factory(:affiliate_placement, :placeable => a_1_d_2)
    a_1_d_2_placement_2 = Factory(:affiliate_placement, :placeable => a_1_d_2)

    Factory(:captured_daily_deal_purchase,
            :daily_deal => a_1_d_2,
            :executed_at => a_1_d_2.start_at + 2.minutes,
            :affiliate => a_1_d_2_placement_2.affiliate)

    a_2_d_1 = Factory(:daily_deal,
                      :publisher => publisher,
                      :advertiser => a_2,
                      :price => 10.00,
                      :start_at => Time.zone.parse("Mar 06, 2011 07:00:00"),
                      :hide_at => Time.zone.parse("Mar 06, 2011 17:00:00"),
                      :affiliate_revenue_share_percentage => 5.0)

    Factory(:captured_daily_deal_purchase, :daily_deal => a_2_d_1)

    dates = Time.zone.parse("Mar 01, 2011")..Time.zone.parse("Mar 09, 2011")

    affiliated_deals_rows = publisher.daily_deals_with_affiliated_daily_deal_counts(dates)

    assert_equal a_1_d_1.id, affiliated_deals_rows[0].id
    assert_equal a_1_d_1.advertiser.name, affiliated_deals_rows[0].advertiser.name
    assert_equal a_1_d_1.value_proposition, affiliated_deals_rows[0].value_proposition
    assert_equal Time.zone.parse("Mar 04, 2011 07:00:00"), affiliated_deals_rows[0].start_at
    assert_equal 6, affiliated_deals_rows[0].daily_deal_affiliate_total_quantity
    assert_equal 2, affiliated_deals_rows[0].daily_deal_purchasers_count
    assert_equal 120.0, affiliated_deals_rows[0].daily_deal_affiliate_gross
    assert_equal 20.0, affiliated_deals_rows[0].affiliate_revenue_share_percentage
    assert_equal 24.0, affiliated_deals_rows[0].daily_deal_affiliate_payout
    assert_equal "USD", affiliated_deals_rows[0].currency_code
    assert_equal "$", affiliated_deals_rows[0].currency_symbol
    assert_equal "a1d1 custom one", affiliated_deals_rows[0].custom_1
    assert_equal "a1d1 custom two", affiliated_deals_rows[0].custom_2
    assert_equal "a1d1 custom three", affiliated_deals_rows[0].custom_3

    assert_equal a_1_d_2.id, affiliated_deals_rows[1].id
    assert_equal a_1_d_2.advertiser.name, affiliated_deals_rows[1].advertiser.name
    assert_equal a_1_d_2.value_proposition, affiliated_deals_rows[1].value_proposition
    assert_equal Time.zone.parse("Mar 05, 2011 07:00:00"), affiliated_deals_rows[1].start_at
    assert_equal 1, affiliated_deals_rows[1].daily_deal_affiliate_total_quantity
    assert_equal 1, affiliated_deals_rows[1].daily_deal_purchasers_count
    assert_equal 15.0, affiliated_deals_rows[1].daily_deal_affiliate_gross
    assert_equal 10.0, affiliated_deals_rows[1].affiliate_revenue_share_percentage
    assert_equal 1.5, affiliated_deals_rows[1].daily_deal_affiliate_payout
    assert_equal "USD", affiliated_deals_rows[1].currency_code
    assert_equal "$", affiliated_deals_rows[1].currency_symbol
    assert_equal "a1d2 custom one", affiliated_deals_rows[1].custom_1
    assert_equal "a1d2 custom two", affiliated_deals_rows[1].custom_2
    assert_equal "a1d2 custom three", affiliated_deals_rows[1].custom_3

    assert_equal 2, affiliated_deals_rows.length
  end

  context "all_with_purchased_daily_deal_counts_by_market" do
    context "with setup" do
      setup do
        setup_market_tests
      end

      context "no refunds or discounts" do

        setup do
          #market 1 purchases
          3.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + (n * 20.minutes), :market => @market_1) }
          2.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :executed_at => @report_date_begin + (n * 12.minutes), :market => @market_1) }
          Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :quantity => 3, :executed_at => @report_date_begin + 4.days, :market => @market_1)
          #no market
          Factory(:captured_daily_deal_purchase, :daily_deal => @deal_3, :quantity => 2, :executed_at => @report_date_begin + 25.minutes)
          Factory(:captured_daily_deal_purchase, :daily_deal => @deal_4, :executed_at => @report_date_end - 6.minutes)
          #market 2
          Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + 1.hour, :market => @market_2)
          Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :executed_at => @report_date_begin + 10.days, :market => @market_2)
          #market 3
          2.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + (n * 12.minutes), :market => @market_3) }
          Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :executed_at => @report_date_begin + 25.minutes, :market => @market_3)
          Factory(:captured_daily_deal_purchase, :daily_deal => @deal_3, :quantity => 2, :executed_at => @report_date_begin + 12.days, :market => @market_3)
        end

        should "summarize deals by market" do

          markets = Publisher.all_with_purchased_daily_deal_counts_by_market(@report_date_begin..@report_date_end, @publisher)

          nm = markets[0]
          assert_equal "No Market", nm.name
          assert_equal 2, nm.daily_deals_count
          assert_equal 3, nm.daily_deal_purchases_total_quantity
          assert_equal 2, nm.daily_deal_purchasers_count
          assert_equal "USD", nm.currency_code
          assert_equal 45, nm.daily_deal_purchases_gross
          assert_equal 0, nm.daily_deal_purchases_refund_amount
          assert_equal 45, nm.daily_deal_purchases_actual_purchase_price

          m1 = markets[1]
          assert_equal "market 1", m1.name
          assert_equal 3, m1.daily_deals_count
          assert_equal 11, m1.daily_deal_purchases_total_quantity
          assert_equal 7, m1.daily_deal_purchasers_count
          assert_equal "USD", m1.currency_code
          assert_equal 165, m1.daily_deal_purchases_gross
          assert_equal 0, m1.daily_deal_purchases_refund_amount
          assert_equal 165, m1.daily_deal_purchases_actual_purchase_price

          m2 = markets[2]
          assert_equal "market 2", m2.name
          assert_equal 2, m2.daily_deals_count
          assert_equal 2, m2.daily_deal_purchases_total_quantity
          assert_equal 2, m2.daily_deal_purchasers_count
          assert_equal "USD", m2.currency_code
          assert_equal 30, m2.daily_deal_purchases_gross
          assert_equal 0, m2.daily_deal_purchases_refund_amount
          assert_equal 30, m2.daily_deal_purchases_actual_purchase_price

          m3 = markets[3]
          assert_equal "market 3", m3.name
          assert_equal 3, m3.daily_deals_count
          assert_equal 5, m3.daily_deal_purchases_total_quantity
          assert_equal 4, m3.daily_deal_purchasers_count
          assert_equal "USD", m3.currency_code
          assert_equal 75, m3.daily_deal_purchases_gross
          assert_equal 0, m3.daily_deal_purchases_refund_amount
          assert_equal 75, m3.daily_deal_purchases_actual_purchase_price

          assert_equal 4, markets.length
        end

      end

      context "refunds" do

        setup do
          #market 1 purchases
          3.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + (n * 20.minutes), :market => @market_1) }
          2.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :executed_at => @report_date_begin + (n * 12.minutes), :market => @market_1) }
          Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :quantity => 3, :executed_at => @report_date_begin + 4.days, :market => @market_1)

          #no market
          Factory(:captured_daily_deal_purchase, :daily_deal => @deal_3, :quantity => 2, :executed_at => @report_date_begin + 25.minutes)
          Factory(:captured_daily_deal_purchase, :daily_deal => @deal_4, :executed_at => @report_date_end - 6.minutes)
        end

        should "include refund amounts for each market" do
          Factory(:refunded_daily_deal_purchase,
                  :daily_deal => @deal_1,
                  :executed_at => @report_date_begin + 1.day,
                  :refunded_at => (@report_date_begin + 2.days).strftime("%Y-%m-%d"),
                  :market => @market_1)
          Factory(:refunded_daily_deal_purchase,
                  :daily_deal => @deal_3,
                  :executed_at => @report_date_begin + 3.days,
                  :refunded_at => (@report_date_begin + 4.days).strftime("%Y-%m-%d"),
                  :market => nil)
          Factory(:refunded_daily_deal_purchase,
                  :daily_deal => @deal_1,
                  :executed_at => @report_date_begin + 1.day,
                  :refunded_at => (@report_date_begin + 2.days).strftime("%Y-%m-%d"),
                  :market => @market_4)
          Factory(:refunded_daily_deal_purchase,
                  :daily_deal => @deal_7,
                  :executed_at => @report_date_begin + 1.day,
                  :refunded_at => (@report_date_begin + 2.days).strftime("%Y-%m-%d"),
                  :market => @market_1)
          markets = Publisher.all_with_purchased_daily_deal_counts_by_market(@report_date_begin..@report_date_end, @publisher)

          nm = markets[0]
          assert_equal "No Market", nm.name
          assert_equal 2, nm.daily_deals_count
          assert_equal 4, nm.daily_deal_purchases_total_quantity
          assert_equal 3, nm.daily_deal_purchasers_count
          assert_equal "USD", nm.currency_code
          assert_equal 60, nm.daily_deal_purchases_gross
          assert_equal 15, nm.daily_deal_purchases_refund_amount
          assert_equal 60, nm.daily_deal_purchases_actual_purchase_price

          m1 = markets[1]
          assert_equal "market 1", m1.name
          assert_equal 3, m1.daily_deals_count
          assert_equal 13, m1.daily_deal_purchases_total_quantity
          assert_equal 9, m1.daily_deal_purchasers_count
          assert_equal "USD", m1.currency_code
          assert_equal 195, m1.daily_deal_purchases_gross
          assert_equal 30, m1.daily_deal_purchases_refund_amount
          assert_equal 195, m1.daily_deal_purchases_actual_purchase_price

          m4 = markets[2]
          assert_equal "market 4", m4.name
          assert_equal 1, m4.daily_deals_count
          assert_equal 1, m4.daily_deal_purchases_total_quantity
          assert_equal 1, m4.daily_deal_purchasers_count
          assert_equal "USD", m4.currency_code
          assert_equal 15, m4.daily_deal_purchases_gross
          assert_equal 15, m4.daily_deal_purchases_refund_amount
          assert_equal 15, m4.daily_deal_purchases_actual_purchase_price

          assert_equal 3, markets.length
        end

        should "not include purchases executed in the reporting period but refunded outside it in the refund totals" do
          Factory(:refunded_daily_deal_purchase,
                  :daily_deal => @deal_1,
                  :executed_at => @report_date_begin + 1.day,
                  :refunded_at => (@report_date_end + 2.days).strftime("%Y-%m-%d"),
                  :market => @market_1)
          Factory(:refunded_daily_deal_purchase,
                  :daily_deal => @deal_3,
                  :executed_at => @report_date_begin + 3.days,
                  :refunded_at => (@report_date_end + 4.days).strftime("%Y-%m-%d"),
                  :market => nil)
          Factory(:refunded_daily_deal_purchase,
                  :daily_deal => @deal_1,
                  :executed_at => @report_date_begin + 1.day,
                  :refunded_at => (@report_date_end + 2.days).strftime("%Y-%m-%d"),
                  :market => @market_4)

          markets = Publisher.all_with_purchased_daily_deal_counts_by_market(@report_date_begin..@report_date_end, @publisher)

          nm = markets[0]
          assert_equal "No Market", nm.name
          assert_equal 2, nm.daily_deals_count
          assert_equal 4, nm.daily_deal_purchases_total_quantity
          assert_equal 3, nm.daily_deal_purchasers_count
          assert_equal "USD", nm.currency_code
          assert_equal 60, nm.daily_deal_purchases_gross
          assert_equal 0, nm.daily_deal_purchases_refund_amount
          assert_equal 60, nm.daily_deal_purchases_actual_purchase_price

          m1 = markets[1]
          assert_equal "market 1", m1.name
          assert_equal 3, m1.daily_deals_count
          assert_equal 12, m1.daily_deal_purchases_total_quantity
          assert_equal 8, m1.daily_deal_purchasers_count
          assert_equal "USD", m1.currency_code
          assert_equal 180, m1.daily_deal_purchases_gross
          assert_equal 0, m1.daily_deal_purchases_refund_amount
          assert_equal 180, m1.daily_deal_purchases_actual_purchase_price

          m4 = markets[2]
          assert_equal "market 4", m4.name
          assert_equal 1, m4.daily_deals_count
          assert_equal 1, m4.daily_deal_purchases_total_quantity
          assert_equal 1, m4.daily_deal_purchasers_count
          assert_equal "USD", m4.currency_code
          assert_equal 15, m4.daily_deal_purchases_gross
          assert_equal 0, m4.daily_deal_purchases_refund_amount
          assert_equal 15, m4.daily_deal_purchases_actual_purchase_price

          assert_equal 3, markets.length
        end

        should "include purchases executed outside the reporting period but refunded inside the reporting period in the refund totals" do
          right_now = Time.now

          daily_deal = Factory(:daily_deal,
                               :price => 30,
                               :value => 70,
                               :start_at => right_now,
                               :hide_at => right_now + 1.month)
          market = Factory(:market, :publisher => daily_deal.publisher, :name => "foo")
          daily_deal.markets << market

          captured_purchase = Factory(:captured_daily_deal_purchase,
                                      :daily_deal => daily_deal,
                                      :quantity => 1,
                                      :executed_at => right_now + 2.days,
                                      :market => market)
          refunded_purchase = Factory(:refunded_daily_deal_purchase,
                                      :daily_deal => daily_deal,
                                      :quantity => 2,
                                      :executed_at => right_now + 5.minutes,
                                      :refunded_at => right_now + 3.days,
                                      :market => market)

          markets = Publisher.all_with_purchased_daily_deal_counts_by_market((right_now + 1.day)..(right_now + 4.days), daily_deal.publisher)

          m = markets.first
          assert_equal "foo", m.name
          assert_equal 30, m.daily_deal_purchases_gross
          assert_equal 30, m.daily_deal_purchases_actual_purchase_price
          assert_equal 60, m.daily_deal_purchases_refund_amount
          assert_equal 1, markets.length
        end

      end

      context "discount" do
        setup do
          #market 1 purchases
          3.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + (n * 20.minutes), :market => @market_1) }
          2.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :executed_at => @report_date_begin + (n * 12.minutes), :market => @market_1) }
          Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :quantity => 3, :executed_at => @report_date_begin + 4.days, :market => @market_1)

          #no market
          Factory(:captured_daily_deal_purchase, :daily_deal => @deal_3, :quantity => 2, :executed_at => @report_date_begin + 25.minutes)
          Factory(:captured_daily_deal_purchase, :daily_deal => @deal_4, :executed_at => @report_date_end - 6.minutes)

          #discount purchases
          Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + 25.minutes, :market => @market_1, :discount => @discount_1)
          Factory(:captured_daily_deal_purchase, :daily_deal => @deal_4, :quantity => 2, :executed_at => @report_date_end - 6.minutes, :discount => @discount_2)
        end

        should "include discounts" do

          markets = Publisher.all_with_purchased_daily_deal_counts_by_market(@report_date_begin..@report_date_end, @publisher)

          nm = markets[0]
          assert_equal "No Market", nm.name
          assert_equal 75, nm.daily_deal_purchases_gross
          assert_equal 0, nm.daily_deal_purchases_refund_amount
          assert_equal 55, nm.daily_deal_purchases_actual_purchase_price

          m1 = markets[1]
          assert_equal "market 1", m1.name
          assert_equal 180, m1.daily_deal_purchases_gross
          assert_equal 0, m1.daily_deal_purchases_refund_amount
          assert_equal 175, m1.daily_deal_purchases_actual_purchase_price

          assert_equal 2, markets.length
        end
      end
    end

    should "not include offplatform purchases" do
      publisher = Factory(:publisher)
      market = Factory(:market, :publisher => publisher)
      deal = Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => publisher))
      deal.markets << market
      ddp = Factory(:captured_daily_deal_purchase, :daily_deal => deal, :market => market)
      create_captured_off_platform_purchase(:daily_deal => deal, :market => market)
      past_refunded_opddp = create_refunded_off_platform_purchase_outside_timeperiod(Factory(:admin), :daily_deal => deal, :executed_at => 2.days.ago, :market => market)

      markets = Publisher.all_with_purchased_daily_deal_counts_by_market(1.day.ago..1.day.from_now, publisher)
      result = markets.select{|m| m.id == market.id}.first

      assert_equal 1, result.daily_deal_purchasers_count
      assert_equal ddp.daily_deal_certificates.count, result.daily_deal_purchases_total_quantity
      assert_equal deal.price, result.daily_deal_purchases_gross
      assert_equal ddp.daily_deal_certificates.first.actual_purchase_price, result.daily_deal_purchases_actual_purchase_price
      assert_equal 0, result.daily_deal_purchases_refund_amount
    end

  end
  
  context "daily_deals_summary" do
    
    setup do
      setup_market_tests
    end
    
    context "no refunds or discounts" do
      
      setup do
        #market 1 purchases
        3.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + (n * 20.minutes), :market => @market_1) }
        2.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :executed_at => @report_date_begin + (n * 12.minutes), :market => @market_1) }
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :quantity => 3, :executed_at => @report_date_begin + 4.days, :market => @market_1)
        #no market
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_3, :quantity => 2, :executed_at => @report_date_begin + 25.minutes)
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_4, :executed_at => @report_date_end - 6.minutes)
        #market 2
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + 1.hour, :market => @market_2)
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :executed_at => @report_date_begin + 10.days, :market => @market_2)
        #market 3
        2.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + (n * 12.minutes), :market => @market_3) }
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :executed_at => @report_date_begin + 25.minutes, :market => @market_3)
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_3, :quantity => 2, :executed_at => @report_date_begin + 12.days, :market => @market_3)
      end
      
      should "list deals with no market" do
        deals = @publisher.daily_deals_summary(@report_date_begin..@report_date_end)
        
        d1 = deals[0]
        assert_equal "2011-03-04", d1.start_at.strftime("%Y-%m-%d")
        assert_equal "deal_3", d1.value_proposition
        assert_equal 2, d1.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, d1.daily_deal_refunded_voucher_count
        assert_equal 1, d1.daily_deal_purchasers_count.to_i
        assert_equal 30, d1.daily_deal_purchases_gross.to_i
        assert_equal 0, d1.daily_deal_refunds_total_amount.to_i
        assert_equal 30, d1.daily_deal_purchases_amount.to_i
        
        
        d2 = deals[1]
        assert_equal "2011-03-09", d2.start_at.strftime("%Y-%m-%d")
        assert_equal "deal_4", d2.value_proposition
        assert_equal 1, d2.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, d2.daily_deal_refunded_voucher_count
        assert_equal 1, d2.daily_deal_purchasers_count.to_i
        assert_equal 15, d2.daily_deal_purchases_gross.to_i
        assert_equal 0, d2.daily_deal_refunds_total_amount.to_i
        assert_equal 15, d2.daily_deal_purchases_amount.to_i
        
        assert_equal 2, deals.length
      end
      
      should "list deals in market" do
        deals = @publisher.daily_deals_summary(@report_date_begin..@report_date_end, @market_1)
        
        d1 = deals[0]
        assert_equal "2011-02-26", d1.start_at.strftime("%Y-%m-%d")
        assert_equal "deal_1", d1.value_proposition
        assert_equal 3, d1.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, d1.daily_deal_refunded_voucher_count
        assert_equal 3, d1.daily_deal_purchasers_count.to_i
        assert_equal 45, d1.daily_deal_purchases_gross.to_i
        assert_equal 0, d1.daily_deal_refunds_total_amount.to_i
        assert_equal 45, d1.daily_deal_purchases_amount.to_i
        
        d2 = deals[1]
        assert_equal "2011-03-02", d2.start_at.strftime("%Y-%m-%d")
        assert_equal "deal_2", d2.value_proposition
        assert_equal 5, d2.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, d2.daily_deal_refunded_voucher_count
        assert_equal 3, d2.daily_deal_purchasers_count.to_i
        assert_equal 75, d2.daily_deal_purchases_gross.to_i
        assert_equal 0, d2.daily_deal_refunds_total_amount.to_i
        assert_equal 75, d2.daily_deal_purchases_amount.to_i
        
        d3 = deals[2]
        assert_equal "2011-03-09", d3.start_at.strftime("%Y-%m-%d")
        assert_equal "deal_7", d3.value_proposition
        assert_equal 3, d3.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, d3.daily_deal_refunded_voucher_count
        assert_equal 1, d3.daily_deal_purchasers_count.to_i
        assert_equal 45, d3.daily_deal_purchases_gross.to_i
        assert_equal 0, d3.daily_deal_refunds_total_amount.to_i
        assert_equal 45, d3.daily_deal_purchases_amount.to_i
        
        assert_equal 3, deals.length
      end
      
      should "include zero purchase deals in market" do
        @deal_8 = Factory(:daily_deal, 
                          :publisher => @publisher, 
                          :advertiser => @advertiser_1,
                          :value_proposition => "deal_8",
                          :start_at => @report_date_begin - 3.days,
                          :hide_at => @report_date_end - 5.days)
        @deal_8.markets << @market_1
        
        deals = @publisher.daily_deals_summary(@report_date_begin..@report_date_end, @market_1)
        
        d1 = deals[0]
        assert_equal "2011-02-26", d1.start_at.strftime("%Y-%m-%d")
        assert_equal "deal_1", d1.value_proposition
        assert_equal 3, d1.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, d1.daily_deal_refunded_voucher_count
        assert_equal 3, d1.daily_deal_purchasers_count.to_i
        assert_equal 45, d1.daily_deal_purchases_gross.to_i
        assert_equal 0, d1.daily_deal_refunds_total_amount.to_i
        assert_equal 45, d1.daily_deal_purchases_amount.to_i
        
        d2 = deals[1]
        assert_equal "2011-03-02", d2.start_at.strftime("%Y-%m-%d")
        assert_equal "deal_2", d2.value_proposition
        assert_equal 5, d2.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, d2.daily_deal_refunded_voucher_count
        assert_equal 3, d2.daily_deal_purchasers_count.to_i
        assert_equal 75, d2.daily_deal_purchases_gross.to_i
        assert_equal 0, d2.daily_deal_refunds_total_amount.to_i
        assert_equal 75, d2.daily_deal_purchases_amount.to_i
        
        d3 = deals[2]
        assert_equal "2011-03-09", d3.start_at.strftime("%Y-%m-%d")
        assert_equal "deal_7", d3.value_proposition
        assert_equal 3, d3.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, d3.daily_deal_refunded_voucher_count
        assert_equal 1, d3.daily_deal_purchasers_count.to_i
        assert_equal 45, d3.daily_deal_purchases_gross.to_i
        assert_equal 0, d3.daily_deal_refunds_total_amount.to_i
        assert_equal 45, d3.daily_deal_purchases_amount.to_i
        
        assert_equal 3, deals.length
      end
      
    end
      
    context "refunds" do
      
      setup do
        #market 1 purchases
        3.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + (n * 20.minutes), :market => @market_1) }
        2.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :executed_at => @report_date_begin + (n * 12.minutes), :market => @market_1) }
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :quantity => 3, :executed_at => @report_date_begin + 4.days, :market => @market_1)
        #should not show up
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + 1.hour, :market => @market_2)
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_4, :executed_at => @report_date_end - 6.minutes)
      end
      
      should "show the number of refunds and refund total, while gross stays the same, and total subtracts the refund amount" do
        
        Factory(:refunded_daily_deal_purchase, 
                :quantity => 2, 
                :daily_deal => @deal_1, 
                :executed_at => @report_date_begin + 23.minutes, 
                :refunded_at => @report_date_begin + 6.hours,
                :market => @market_1)
        Factory(:refunded_daily_deal_purchase, 
                :daily_deal => @deal_2, 
                :executed_at => @report_date_begin + 20.minutes, 
                :refunded_at => @report_date_begin + 1.day,
                :market => @market_1)

        discount = Factory :discount, :publisher => @deal_2.publisher, :amount => 15
        purchase = Factory(:captured_daily_deal_purchase,
                           :daily_deal => @deal_2,
                           :executed_at => @report_date_begin + 20.minutes,
                           :refunded_at => @report_date_begin + 1.day,
                           :discount => discount,
                           :market => @market_1)
        purchase.daily_deal_payment.destroy
        admin = Factory :admin
        Timecop.freeze(@report_date_begin + 40.minutes) do
          purchase.reload.void_or_full_refund!(admin)
        end
        assert_equal 0, purchase.actual_purchase_price

        Factory(:refunded_daily_deal_purchase, 
                :daily_deal => @deal_7, 
                :executed_at => @report_date_begin + 20.minutes, 
                :refunded_at => @report_date_begin + 1.day,
                :market => @market_1)
        
        deals = @publisher.daily_deals_summary(@report_date_begin..@report_date_end, @market_1)
        
        d1 = deals[0]
        assert_equal "2011-02-26", d1.start_at.strftime("%Y-%m-%d")
        assert_equal "deal_1", d1.value_proposition
        assert_equal 5, d1.daily_deal_purchases_total_quantity.to_i
        assert_equal 4, d1.daily_deal_purchasers_count.to_i
        assert_equal 75, d1.daily_deal_purchases_gross.to_i
        assert_equal 2, d1.daily_deal_refunded_voucher_count
        assert_equal 30, d1.daily_deal_refunds_total_amount.to_i
        assert_equal 75, d1.daily_deal_purchases_amount.to_i
        
        d2 = deals[1]
        assert_equal "2011-03-02", d2.start_at.strftime("%Y-%m-%d")
        assert_equal "deal_2", d2.value_proposition
        assert_equal 7, d2.daily_deal_purchases_total_quantity.to_i
        assert_equal 5, d2.daily_deal_purchasers_count.to_i
        assert_equal 105, d2.daily_deal_purchases_gross.to_i
        assert_equal 2, d2.daily_deal_refunded_voucher_count
        assert_equal 15, d2.daily_deal_refunds_total_amount.to_i
        assert_equal 90, d2.daily_deal_purchases_amount.to_i


        d3 = deals[2]
        assert_equal "2011-03-09", d3.start_at.strftime("%Y-%m-%d")
        assert_equal "deal_7", d3.value_proposition
        assert_equal 4, d3.daily_deal_purchases_total_quantity.to_i
        assert_equal 1, d3.daily_deal_refunded_voucher_count
        assert_equal 2, d3.daily_deal_purchasers_count.to_i
        assert_equal 60, d3.daily_deal_purchases_gross.to_i
        assert_equal 15, d3.daily_deal_refunds_total_amount.to_i
        assert_equal 60, d3.daily_deal_purchases_amount.to_i
        
        assert_equal 3, deals.length
        
      end
    
      should "exclude partial refunds" do
        purchase1 = Factory(:captured_daily_deal_purchase, 
                            :quantity => 2, 
                            :daily_deal => @deal_1, 
                            :executed_at => @report_date_begin + 20.minutes,
                            :market => @market_1)
        
        deals = @publisher.daily_deals_summary(@report_date_begin..@report_date_end, @market_1)
        
        assert_equal 3, deals.length
        expect_braintree_partial_refund(purchase1, 15)
        purchase1.partial_refund!(Factory(:admin), [purchase1.daily_deal_certificates.first.id.to_s])
        refunded_at = purchase1.executed_at + 1.days
        purchase1.update_attributes!(:refunded_at => refunded_at)
        purchase1.daily_deal_certificates.first.update_attributes!(:refunded_at => refunded_at)
        
        assert_equal "refunded", purchase1.payment_status
        assert_equal 2, purchase1.daily_deal_certificates.size
        assert_equal "refunded", purchase1.daily_deal_certificates.first.status
        assert_equal "active", purchase1.daily_deal_certificates.second.status
        assert_equal 15, purchase1.daily_deal_certificates.first.actual_purchase_price
        assert_equal 15, purchase1.daily_deal_certificates.second.actual_purchase_price
        assert_equal 15, purchase1.daily_deal_certificates.first.refund_amount
        assert_equal 0, purchase1.daily_deal_certificates.second.refund_amount
    
        deals = @publisher.daily_deals_summary(@report_date_begin..@report_date_end, @market_1)
        
        assert_equal 3, deals.length
        d1 = deals[0]
        assert_equal "2011-02-26", d1.start_at.strftime("%Y-%m-%d")
        assert_equal "deal_1", d1.value_proposition
        assert_equal 5, d1.daily_deal_purchases_total_quantity.to_i
        assert_equal 1, d1.daily_deal_refunded_voucher_count
        assert_equal 4, d1.daily_deal_purchasers_count.to_i
        assert_equal 75, d1.daily_deal_purchases_gross.to_i
        assert_equal 15, d1.daily_deal_refunds_total_amount.to_i
        assert_equal 75, d1.daily_deal_purchases_amount.to_i
      end
      
            
      should "include purchases that were made in the specified time period but /later/ refunded in the purchase counts" do
        
        Factory(:refunded_daily_deal_purchase, 
                :daily_deal => @deal_1,
                :executed_at => @report_date_begin + 1.day,
                :refunded_at => (@report_date_end + 2.days).strftime("%Y-%m-%d"),
                :market => @market_1)
        
        deals = @publisher.daily_deals_summary(@report_date_begin..@report_date_end, @market_1)
        
        d1 = deals[0]
        assert_equal "2011-02-26", d1.start_at.strftime("%Y-%m-%d")
        assert_equal "deal_1", d1.value_proposition
        assert_equal 4, d1.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, d1.daily_deal_refunded_voucher_count
        assert_equal 4, d1.daily_deal_purchasers_count.to_i
        assert_equal 60, d1.daily_deal_purchases_gross.to_i
        assert_equal 0, d1.daily_deal_refunds_total_amount.to_i
        assert_equal 60, d1.daily_deal_purchases_amount.to_i
    
        assert_equal 3, deals.length
        
      end
      
      should "include deals purchased before the specified time period, but refunded within it" do
        refunded_purchase = Factory(:refunded_daily_deal_purchase, 
                                    :daily_deal => @deal_1, 
                                    :quantity => 2, 
                                    :executed_at => @report_date_begin - 12.days,
                                    :refunded_at => @report_date_begin + 2.days,
                                    :market => @market_1)
        
        assert_equal 30, refunded_purchase.daily_deal_payment.amount
        assert_equal 30, refunded_purchase.refund_amount
        
        deals = @publisher.daily_deals_summary(@report_date_begin..@report_date_end, @market_1)
        
        d1 = deals[0]
        assert_equal "deal_1", d1.value_proposition
        assert_equal "2011-02-26", d1.start_at.strftime("%Y-%m-%d")
        assert_equal 2, d1.daily_deal_refunded_voucher_count.to_i
        assert_equal 30, d1.daily_deal_refunds_total_amount.to_i
        assert_equal 3, d1.daily_deal_purchases_total_quantity.to_i
        assert_equal 3, d1.daily_deal_purchasers_count.to_i
        assert_equal 45, d1.daily_deal_purchases_gross.to_i
        assert_equal 45, d1.daily_deal_purchases_amount.to_i
        
        assert_equal 3, deals.length
      end
      
    end
    
    context "discounts" do

      setup do
        #market 1 purchases
        3.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + (n * 20.minutes), :market => @market_1) }
        2.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :executed_at => @report_date_begin + (n * 12.minutes), :market => @market_1) }
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :quantity => 3, :executed_at => @report_date_begin + 4.days, :market => @market_1)

        #no market
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_3, :quantity => 2, :executed_at => @report_date_begin + 25.minutes)
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_4, :executed_at => @report_date_end - 6.minutes)
      
        #discount purchases
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + 25.minutes, :market => @market_1, :discount => @discount_1)
      end
    
      should "include discounts" do
      
        deals = @publisher.daily_deals_summary(@report_date_begin..@report_date_end, @market_1)

        d1 = deals[0]
        assert_equal "2011-02-26", d1.start_at.strftime("%Y-%m-%d")
        assert_equal "deal_1", d1.value_proposition
        assert_equal 4, d1.daily_deal_purchases_total_quantity.to_i
        assert_equal 0, d1.daily_deal_refunded_voucher_count
        assert_equal 4, d1.daily_deal_purchasers_count.to_i
        assert_equal 60, d1.daily_deal_purchases_gross.to_i
        assert_equal 0, d1.daily_deal_refunds_total_amount.to_i
        assert_equal 55, d1.daily_deal_purchases_amount.to_i
      
        assert_equal 3, deals.length
      end

    end
    
  end
  
  context "all_with_refunded_daily_deal_counts_by_market" do

    context "with setup" do
      setup do
        setup_market_tests
        #market 1 purchases
        3.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + (n * 20.minutes), :market => @market_1) }
        2.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :executed_at => @report_date_begin + (n * 12.minutes), :market => @market_1) }
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :quantity => 3, :executed_at => @report_date_begin + 4.days, :market => @market_1)
        #should not show up
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + 1.hour, :market => @market_2)
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_4, :executed_at => @report_date_end - 6.minutes)
        #refunded purchases
        Factory(:refunded_daily_deal_purchase,
                :quantity => 2,
                :daily_deal => @deal_1,
                :executed_at => @report_date_begin + 23.minutes,
                :refunded_at => @report_date_begin + 6.hours,
                :market => @market_1)
        Factory(:refunded_daily_deal_purchase,
                :daily_deal => @deal_2,
                :executed_at => @report_date_begin + 20.minutes,
                :refunded_at => @report_date_begin + 1.day,
                :market => @market_1)
        Factory(:refunded_daily_deal_purchase,
                :daily_deal => @deal_2,
                :quantity => 2,
                :executed_at => @report_date_begin + 20.minutes,
                :refunded_at => @report_date_begin + 1.day)
        Factory(:refunded_daily_deal_purchase,
                :daily_deal => @deal_7,
                :quantity => 2,
                :executed_at => @report_date_begin + 20.minutes,
                :refunded_at => @report_date_begin + 1.day,
                :market => @market_1)
        #Should not be returned
        Factory(:refunded_daily_deal_purchase,
                :executed_at => @report_date_begin + 20.minutes,
                :refunded_at => @report_date_begin + 1.day)
        Factory(:refunded_daily_deal_purchase,
                :daily_deal => @deal_1,
                :executed_at => @report_date_begin + 20.minutes,
                :refunded_at => @report_date_begin - 1.day)
      end

      should "return refunded deals by market" do

        markets = Publisher.all_with_refunded_daily_deal_counts_by_market(@report_date_begin..@report_date_end, @publisher)

        nm = markets[0]
        assert_equal "No Market", nm.name
        assert_equal "$", nm.currency_symbol
        assert_equal 1, nm.daily_deals_count
        assert_equal 1, nm.daily_deal_purchasers_count
        assert_equal 2, nm.daily_deal_refunded_vouchers_count
        assert_equal 30.0, nm.daily_deal_refunded_vouchers_gross
        assert_equal 30.0, nm.daily_deal_refunded_vouchers_amount

        m1 = markets[1]
        assert_equal @market_1.name, m1.name
        assert_equal "$", m1.currency_symbol
        assert_equal 3, m1.daily_deals_count
        assert_equal 3, m1.daily_deal_purchasers_count
        assert_equal 7, m1.daily_deal_refunded_vouchers_count
        assert_equal 75.0, m1.daily_deal_refunded_vouchers_gross
        assert_equal 75.0, m1.daily_deal_refunded_vouchers_amount

        assert_equal 2, markets.length

      end
    end

    should "not include offplatform purchase refunds" do
      publisher = Factory(:publisher)
      market = Factory(:market, :publisher => publisher)
      deal = Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => publisher))
      deal.markets << market
      refunded_ddp = Factory(:refunded_daily_deal_purchase, :daily_deal => deal, :market => market)
      admin = Factory(:admin)
      refunded_opddp = create_refunded_off_platform_purchase(admin, :daily_deal => deal, :market => market)

      markets = Publisher.all_with_refunded_daily_deal_counts_by_market(1.day.ago..1.day.from_now, publisher)
      result = markets.select{|m| m.id == market.id}.first

      assert_equal 1, result.daily_deal_purchasers_count
      assert_equal refunded_ddp.daily_deal_certificates.refunded.count, result.daily_deal_refunded_vouchers_count
      assert_equal deal.price, result.daily_deal_refunded_vouchers_gross
      assert_equal refunded_ddp.daily_deal_certificates.sum(:refund_amount), result.daily_deal_refunded_vouchers_amount
    end

  end
  
  context "daily_deals_with_refund_counts" do
    context "with setup" do
      setup do
        setup_market_tests
        #market 1 purchases
        3.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + (n * 20.minutes), :market => @market_1) }
        2.times { |n| Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :executed_at => @report_date_begin + (n * 12.minutes), :market => @market_1) }
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_2, :quantity => 3, :executed_at => @report_date_begin + 4.days, :market => @market_1)
        #should not show up
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + 1.hour, :market => @market_2)
        Factory(:captured_daily_deal_purchase, :daily_deal => @deal_4, :executed_at => @report_date_end - 6.minutes)
        #refunded purchases
        Factory(:refunded_daily_deal_purchase,
                :quantity => 2,
                :daily_deal => @deal_1,
                :executed_at => @report_date_begin + 23.minutes,
                :refunded_at => @report_date_begin + 6.hours,
                :market => @market_1)
        Factory(:refunded_daily_deal_purchase,
                :daily_deal => @deal_2,
                :executed_at => @report_date_begin + 20.minutes,
                :refunded_at => @report_date_begin + 1.day,
                :market => @market_1)
        Factory(:refunded_daily_deal_purchase,
                :daily_deal => @deal_2,
                :quantity => 3,
                :executed_at => @report_date_begin + 20.minutes,
                :refunded_at => @report_date_begin + 1.day)
        Factory(:refunded_daily_deal_purchase,
                :daily_deal => @deal_7,
                :quantity => 2,
                :executed_at => @report_date_begin + 20.minutes,
                :refunded_at => @report_date_begin + 1.day,
                :market => @market_1)
        #Should not be returned
        Factory(:refunded_daily_deal_purchase,
                :executed_at => @report_date_begin + 20.minutes,
                :refunded_at => @report_date_begin + 1.day)
        Factory(:refunded_daily_deal_purchase,
                :daily_deal => @deal_1,
                :executed_at => @report_date_begin + 20.minutes,
                :refunded_at => @report_date_begin - 1.day)
      end

      should "return refunded deals in market" do

        deals = @publisher.daily_deals_with_refund_counts(@report_date_begin..@report_date_end, @market_1)

        d1 = deals[0]
        assert_equal "USD", d1.currency_code
        assert_equal "$", d1.currency_symbol
        assert_equal 1, d1.daily_deal_refunded_purchasers_count
        assert_equal 1, d1.daily_deal_refunded_purchases_count
        assert_equal 2, d1.daily_deal_vouchers_refunded_count
        assert_equal 30.0, d1.daily_deal_refunds_gross
        assert_equal 30.0, d1.daily_deal_refunds_amount

        d2 = deals[1]
        assert_equal "USD", d2.currency_code
        assert_equal "$", d2.currency_symbol
        assert_equal 1, d2.daily_deal_refunded_purchasers_count
        assert_equal 1, d2.daily_deal_refunded_purchases_count
        assert_equal 1, d2.daily_deal_vouchers_refunded_count
        assert_equal 15.0, d2.daily_deal_refunds_gross
        assert_equal 15.0, d2.daily_deal_refunds_amount

        d3 = deals[2]
        assert_equal "USD", d3.currency_code
        assert_equal "$", d3.currency_symbol
        assert_equal 1, d3.daily_deal_refunded_purchasers_count
        assert_equal 1, d3.daily_deal_refunded_purchases_count
        assert_equal 4, d3.daily_deal_vouchers_refunded_count
        assert_equal 30.0, d3.daily_deal_refunds_gross.to_f
        assert_equal 30.0, d3.daily_deal_refunds_amount

        assert_equal 3, deals.length

      end

      should "return refunded deals without market" do

        deals = @publisher.daily_deals_with_refund_counts(@report_date_begin..@report_date_end, nil)

        d = deals[0]
        assert_equal "USD", d.currency_code
        assert_equal "$", d.currency_symbol
        assert_equal 1, d.daily_deal_refunded_purchasers_count
        assert_equal 1, d.daily_deal_refunded_purchases_count
        assert_equal 3, d.daily_deal_vouchers_refunded_count
        assert_equal 45.0, d.daily_deal_refunds_gross
        assert_equal 45.0, d.daily_deal_refunds_amount

        assert_equal 1, deals.length

      end
    end

    should "not include offplatform purchase refunds" do
      publisher = Factory(:publisher)
      deal = Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => publisher))
      refunded_ddp = Factory(:refunded_daily_deal_purchase, :daily_deal => deal)
      admin = Factory(:admin)
      create_refunded_off_platform_purchase(admin, :daily_deal => deal)

      daily_deals = publisher.daily_deals_with_refund_counts(1.day.ago..1.day.from_now)
      result = daily_deals.select{|dd| dd.id == deal.id}.first

      assert_equal 1, result.daily_deal_refunded_purchasers_count
      assert_equal 1, result.daily_deal_refunded_purchases_count
      assert_equal refunded_ddp.daily_deal_certificates.refunded.count, result.daily_deal_vouchers_refunded_count
      assert_equal deal.price * refunded_ddp.daily_deal_certificates.count, result.daily_deal_refunds_gross
      assert_equal refunded_ddp.daily_deal_certificates.sum(:refund_amount), result.daily_deal_refunds_amount
    end
  end

  context "#all_with_refunded_daily_deal_counts" do
    should "handle multi-voucher deals" do
      publisher = Factory(:publisher)
      deal = Factory(:daily_deal,
                     :advertiser => Factory(:advertiser, :publisher => publisher),
                     :certificates_to_generate_per_unit_quantity => 2)
      refunded_ddp = Factory(:refunded_daily_deal_purchase, :daily_deal => deal, :quantity => 2)

      publishers = Publisher.all_with_refunded_daily_deal_counts(1.day.ago..1.day.from_now, [publisher.id])
      result = publishers.select{|p| p.id == publisher.id}.first

      assert_equal 1, result.daily_deal_purchasers_count
      assert_equal 4, result.daily_deal_refunded_vouchers_count
      assert_equal 30, result.daily_deal_refunded_vouchers_gross
      assert_equal 30, result.daily_deal_refunded_vouchers_amount
    end

    should "not include offplatform purchase refunds" do
      publisher = Factory(:publisher)
      deal = Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => publisher))
      refunded_ddp = Factory(:refunded_daily_deal_purchase, :daily_deal => deal)
      admin = Factory(:admin)
      create_refunded_off_platform_purchase(admin, :daily_deal => deal)

      publishers = Publisher.all_with_refunded_daily_deal_counts(1.day.ago..1.day.from_now, [publisher.id])
      result = publishers.select{|p| p.id == publisher.id}.first

      assert_equal 1, result.daily_deal_purchasers_count
      assert_equal refunded_ddp.daily_deal_certificates.refunded.count, result.daily_deal_refunded_vouchers_count
      assert_equal deal.price, result.daily_deal_refunded_vouchers_gross
      assert_equal refunded_ddp.daily_deal_certificates.sum(:refund_amount), result.daily_deal_refunded_vouchers_amount
    end
  end

  private 
  
  def setup_market_tests
    @report_date_begin = Time.zone.local(2011, 3, 1, 0, 0, 0)
    @report_date_end = Time.zone.local(2011, 3, 15, 0, 0, 0)
    @publisher = Factory(:publisher)
    @discount_1 = Factory(:discount, :publisher => @publisher, :amount => 5)
    @discount_2 = Factory(:discount, :publisher => @publisher, :amount => 20)
    @advertiser_1 = Factory(:advertiser)
    @advertiser_2 = Factory(:advertiser)
    @advertiser_3 = Factory(:advertiser)
    
    @deal_1 = Factory(:daily_deal, 
                      :publisher => @publisher, 
                      :advertiser => @advertiser_1,
                      :value_proposition => "deal_1",
                      :start_at => @report_date_begin - 3.days,
                      :hide_at => @report_date_end - 5.days)
    @deal_2 = Factory(:daily_deal, 
                      :publisher => @publisher, 
                      :advertiser => @advertiser_2,
                      :value_proposition => "deal_2",
                      :start_at => @report_date_begin + 1.days,
                      :hide_at => @report_date_end - 1.days)
    @deal_3 = Factory(:daily_deal, 
                      :publisher => @publisher, 
                      :advertiser => @advertiser_1,
                      :value_proposition => "deal_3",
                      :start_at => @report_date_begin + 3.days,
                      :hide_at => @report_date_begin + 4.days)
    @deal_4 = Factory(:daily_deal, 
                      :publisher => @publisher, 
                      :advertiser => @advertiser_3,
                      :value_proposition => "deal_4",
                      :start_at => @report_date_begin + 8.days,
                      :hide_at => @report_date_end + 10.days)
    #different publisher
    @deal_5 = Factory(:daily_deal                  ,
                      :value_proposition => "deal_5",
                      :start_at => @report_date_begin - 3.days,
                      :hide_at => @report_date_end + 5.days)
    #outside date range
    @deal_6 = Factory(:daily_deal, 
                      :publisher => @publisher, 
                      :advertiser => @advertiser_3,
                      :value_proposition => "deal_6",
                      :start_at => @report_date_begin - 8.days,
                      :hide_at => @report_date_begin - 6.days)
    #multi-voucher deal
    @deal_7 = Factory(:daily_deal, 
                      :publisher => @publisher, 
                      :advertiser => @advertiser_3,
                      :value_proposition => "deal_7",
                      :certificates_to_generate_per_unit_quantity => 2,
                      :start_at => @report_date_begin + 8.days,
                      :hide_at => @report_date_end + 10.days)
    
    @market_1 = Factory(:market, :publisher => @publisher, :name => "market 1")
    @market_2 = Factory(:market, :publisher => @publisher, :name => "market 2")
    @market_3 = Factory(:market, :publisher => @publisher, :name => "market 3")
    @market_4 = Factory(:market, :publisher => @publisher, :name => "market 4")
    
    @deal_1.markets << @market_1
    @deal_1.markets << @market_2
    @deal_1.markets << @market_3
    @deal_1.markets << @market_4
    @deal_2.markets << @market_1
    @deal_2.markets << @market_2
    @deal_2.markets << @market_3
    @deal_3.markets << @market_3
    @deal_7.markets << @market_1
    
    #authorized excluded from report
    Factory(:authorized_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin + 1.second, :market => @market_1)
    #voided excluded from report
    Factory(:voided_daily_deal_purchase, :daily_deal => @deal_2, :executed_at => @report_date_begin + 1.minute, :market => @market_2)
    #pending excluded from report
    Factory(:pending_daily_deal_purchase, :daily_deal => @deal_3, :executed_at => @report_date_begin + 1.hour, :market => @market_3)
    #before report start
    Factory(:captured_daily_deal_purchase, :daily_deal => @deal_1, :executed_at => @report_date_begin - 1.days, :market => @market_1)
    # during report
    Factory(:captured_daily_deal_purchase, :daily_deal => @deal_7, :executed_at => @report_date_begin + 1.hour, :market => @market_1, :quantity => 3)
    #after report end
    Factory(:captured_daily_deal_purchase, :daily_deal => @deal_3, :executed_at => @report_date_end + 9.days, :market => @market_3)
  end

  def create_captured_off_platform_purchase(options)
    Factory(:off_platform_daily_deal_purchase, options).tap do |opddp|
      opddp.capture!
    end
  end

  def create_refunded_off_platform_purchase(admin, options)
    Factory(:off_platform_daily_deal_purchase, options).tap do |refunded_opddp|
      refunded_opddp.capture!
      refunded_opddp.partial_refund!(admin, refunded_opddp.daily_deal_certificate_ids)
    end
  end

  def create_refunded_off_platform_purchase_outside_timeperiod(admin, options)
    Factory(:off_platform_daily_deal_purchase, options).tap do |refunded_opddp|
      refunded_opddp.capture!
      refunded_opddp.partial_refund!(admin, refunded_opddp.daily_deal_certificate_ids)
    end
  end

end
