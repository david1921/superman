# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchases::CertificatesTest < ActiveSupport::TestCase
  include DailyDealPurchasesTestHelper

  test "daily_deal_certificates_file_name with only ASCII characters" do
    advertiser = Factory(:advertiser, :name => "ACO Hardware")
    consumer = Factory(:consumer, :first_name => "Tom", :last_name => "Buscher", :publisher => advertiser.publisher)
    daily_deal = Factory(:daily_deal, :advertiser => advertiser)
    daily_deal_purchase = Factory(:daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer)

    assert_equal "tom_buscher_aco_hardware_#{daily_deal_purchase.id}.pdf", daily_deal_purchase.daily_deal_certificates_file_name
  end

  test "daily_deal_certificates_file_name with non ASCII characters" do
    advertiser = Factory(:advertiser, :name => "RIDEMAKERZ®")
    consumer = Factory(:consumer, :first_name => "José", :last_name => "Ångström", :publisher => advertiser.publisher)
    daily_deal = Factory(:daily_deal, :advertiser => advertiser)
    daily_deal_purchase = Factory(:daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer)

    assert_equal "jos_ngstrm_ridemakerz_#{daily_deal_purchase.id}.pdf", daily_deal_purchase.daily_deal_certificates_file_name
  end

  test "create_and_send_certificates with a custom certificate template" do
    publishing_group = Factory(:publishing_group, :label => "rr")
    daily_deal = Factory(:daily_deal, :publisher => Factory(:publisher, :publishing_group => publishing_group), :expires_on => Date.today + 1.month)
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :gift => true, :recipient_names => ["Joe Blow"])

    assert_difference 'ActionMailer::Base.deliveries.count' do
      daily_deal_purchase.send :create_certificates_and_send_email!
    end
    assert_equal 1, daily_deal_purchase.daily_deal_certificates.count
    assert_equal "Joe Blow", daily_deal_purchase.daily_deal_certificates.first.redeemer_name
  end

  context "#create_certificates" do
    context "no discount" do
      setup do
        @deal = Factory(:daily_deal, :price => 12)
        @purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @deal, :quantity => 3)
      end

      should "have correct setup" do
        assert_equal 36, @purchase.actual_purchase_price
      end

      should "set actual_purchase_prices correctly on certificates" do
        @purchase.daily_deal_certificates.each do |cert|
          assert_equal "active", cert.status
          assert_equal 12, cert.actual_purchase_price
        end
      end
    end

    context "discount" do
      setup do
        @deal = Factory(:daily_deal, :price => 20)
        discount = Factory(:discount, :amount => 10, :publisher => @deal.publisher)
        @purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @deal, :quantity => 3, :discount => discount)
      end

      should "set actual_purchase_prices correctly on certificates" do
        assert_equal 3, @purchase.daily_deal_certificates.size
        assert_equal 20, @purchase.daily_deal_certificates[0].actual_purchase_price, "was: #{@purchase.daily_deal_certificates[0].actual_purchase_price.to_s}"
        assert_equal 20, @purchase.daily_deal_certificates[1].actual_purchase_price, "was: #{@purchase.daily_deal_certificates[1].actual_purchase_price.to_s}"
        assert_equal 10, @purchase.daily_deal_certificates[2].actual_purchase_price, "was: #{@purchase.daily_deal_certificates[2].actual_purchase_price.to_s}"
      end
    end

    context "funky values" do
      setup do
        @deal = Factory(:daily_deal, :price => 40.45)
        discount = Factory(:discount, :amount => 21.35, :publisher => @deal.publisher)
        @purchase = Factory(:captured_daily_deal_purchase, :daily_deal=> @deal, :quantity => 3, :discount => discount)
      end

      should "set actual_purchase_prices correctly on certificates" do
        assert_equal 3, @purchase.daily_deal_certificates.size
        assert_equal 40.45, @purchase.daily_deal_certificates[0].actual_purchase_price, "was: #{@purchase.daily_deal_certificates[0].actual_purchase_price.to_s}"
        assert_equal 40.45, @purchase.daily_deal_certificates[1].actual_purchase_price, "was: #{@purchase.daily_deal_certificates[1].actual_purchase_price.to_s}"
        assert_equal 19.1, @purchase.daily_deal_certificates[2].actual_purchase_price, "was: #{@purchase.daily_deal_certificates[2].actual_purchase_price.to_s}"
      end
    end

    context "zeros abound" do
      setup do
        @deal = Factory(:daily_deal, :price => 0)
        @purchase = Factory(:captured_daily_deal_purchase, :daily_deal=> @deal, :quantity => 3)
        @purchase.daily_deal_payment.update_attribute(:amount, 0)
      end

      should "set actual_purchase_prices correctly on certificates" do
        assert_equal 3, @purchase.daily_deal_certificates.size
        assert_equal 0, @purchase.daily_deal_certificates[0].actual_purchase_price, "was: #{@purchase.daily_deal_certificates[0].actual_purchase_price.to_s}"
        assert_equal 0, @purchase.daily_deal_certificates[1].actual_purchase_price, "was: #{@purchase.daily_deal_certificates[1].actual_purchase_price.to_s}"
        assert_equal 0, @purchase.daily_deal_certificates[2].actual_purchase_price, "was: #{@purchase.daily_deal_certificates[2].actual_purchase_price.to_s}"
      end
    end

    context "discount dramatically exceeds daily_deal price" do
      setup do
        @daily_deal = Factory(:daily_deal, :price => 20)
        discount = Factory(:discount, :publisher => @daily_deal.publisher, :amount => 45)
        @purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 3, :discount => discount)
      end

      should "set actual_purchase_prices never exceeding actual_purchase_price of purchase" do
        assert_equal 3, @purchase.daily_deal_certificates.size
        assert_equal 15, @purchase.daily_deal_certificates[0].actual_purchase_price, "was: #{@purchase.daily_deal_certificates[0].actual_purchase_price.to_s}"
        assert_equal 0, @purchase.daily_deal_certificates[1].actual_purchase_price, "was: #{@purchase.daily_deal_certificates[1].actual_purchase_price.to_s}"
        assert_equal 0, @purchase.daily_deal_certificates[2].actual_purchase_price, "was: #{@purchase.daily_deal_certificates[2].actual_purchase_price.to_s}"
      end
    end
    
    context "when certificates_to_generate_per_unit_quantity > 1" do
      
      setup do
        @daily_deal = Factory :daily_deal, :price => 15, :value => 30, :certificates_to_generate_per_unit_quantity => 2
      end
      
      context "purchase quantity 1, gift" do
        
        setup do
          @purchase = Factory :authorized_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1, :recipient_names => ["Bob", "Alice"], :gift => true
          @purchase.payment_status = "captured"
          @purchase.create_certificates!
          @purchase.reload
        end
      
        should "generate 2 vouchers" do
          assert_equal 2, @purchase.daily_deal_certificates.size
        end
        
        should "allocate the 2 recipient names across the 2 vouchers" do
          assert_equal %w(Alice Bob), @purchase.daily_deal_certificates.map(&:redeemer_name).sort
        end
        
        should "allocate 2 serial numbers" do
          assert_equal 2, @purchase.daily_deal_certificates.count { |c| c.serial_number.present? }
        end
        
        should "set the actual purchase price of each voucher to 7.50" do
          assert @purchase.daily_deal_certificates.all? { |c| c.actual_purchase_price == 7.50 }
        end
        
      end
      
      context "purchase quantity 1, not a gift" do
        
        setup do
          @purchase = Factory :authorized_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1, :gift => false
          @purchase.payment_status = "captured"
          @purchase.create_certificates!
        end        
        
        should "generate 2 vouchers" do
          assert_equal 2, @purchase.daily_deal_certificates.size
        end
        
        should "allocate 2 serial numbers" do
          assert_equal 2, @purchase.daily_deal_certificates.count { |c| c.serial_number.present? }
        end
        
      end
      
      context "purchase quantity 2, not a gift" do
        
        setup do
          @purchase = Factory :authorized_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 2, :gift => false
          @purchase.payment_status = "captured"
          @purchase.create_certificates!
        end
        
        should "generate 4 vouchers" do
          assert_equal 4, @purchase.daily_deal_certificates.size
        end
        
        should "allocate 4 serial numbers" do
          assert_equal 4, @purchase.daily_deal_certificates.count { |c| c.serial_number.present? }
        end
        
      end
      
      context "when the deal price does not evenly divide across the voucher multiple" do
        
        setup do
          @daily_deal = Factory :daily_deal, :price => 10, :value => 30, :certificates_to_generate_per_unit_quantity => 3
          @purchase = Factory :pending_daily_deal_purchase, :daily_deal => @daily_deal
          @purchase.payment_status = "captured"
          @purchase.create_certificates!
        end
        
        should "divide the full actual purchase price across the vouchers" do
          assert_equal 3, @purchase.daily_deal_certificates.size
          assert_equal [3.33, 3.33, 3.34], @purchase.daily_deal_certificates.map(&:actual_purchase_price).sort
        end
        
      end
      
    end

  end

  test "send_certificates sets certificate_email_sent_at" do
    @deal = Factory(:daily_deal, :price => 0)
    @purchase = Factory(:captured_daily_deal_purchase, :daily_deal=> @deal, :quantity => 2)
    assert_nil @purchase.certificate_email_sent_at
    Timecop.freeze do
      @purchase.send(:enqueue_email)  # nefariously circumventing private method with send
      @purchase.reload
      assert_equal Time.zone.now, @purchase.certificate_email_sent_at
    end
  end

  context "recipient_names" do
    should "use consumer name for redeemer_name when recipient names are empty" do
      publisher = Factory(:publisher)
      advertiser = Factory(:advertiser, :publisher => publisher)
      deal = Factory(:daily_deal, :advertiser => advertiser)
      consumer = Factory(:consumer, :publisher => publisher, :first_name => "Joe", :last_name => "Blowsepi")
      purchase = Factory(:authorized_daily_deal_purchase, :daily_deal => deal, :consumer => consumer)
      purchase.recipient_names = ["", ""]
      purchase.payment_status = "captured"
      purchase.create_certificates!
      purchase.daily_deal_certificates.each do |cert|
        assert_equal "Joe Blowsepi", cert.redeemer_name
      end
      purchase.send(:synchronize_redeemers_names_on_certificates)
      purchase.daily_deal_certificates.each do |cert|
        assert_equal "Joe Blowsepi", cert.redeemer_name
      end
    end
  end
  
  context "with several daily deal purchases" do
    setup do
      @p1 = Factory(:pending_daily_deal_purchase)
      @p2 = Factory(:captured_daily_deal_purchase, :executed_at => Time.zone.local(2012, 1, 1, 7, 2, 1))
      @p3 = Factory(:refunded_daily_deal_purchase, :executed_at => Time.zone.local(2012, 1, 1, 7, 3, 2))
      @p4 = Factory(:pending_daily_deal_purchase)
      @p5 = Factory(:captured_daily_deal_purchase, :executed_at => Time.zone.local(2012, 1, 1, 7, 5, 3))
      @time = Time.zone.local(2012, 1, 1, 12, 34, 56)
    end
    
    should "send certificate emails for all captured purchases" do
      Timecop.freeze @time do
        assert_difference 'ActionMailer::Base.deliveries.size', 2 do
          calls = 0
          sent = DailyDealPurchase.send_unsent_certificate_email(5, Time.zone.local(2012, 1, 1, 7, 0, 0)) do |ddp|
            assert_equal @time, ddp.certificate_email_sent_at
            calls += 1
          end
          assert_equal 2, sent
          assert_equal 2, calls
        end
        assert_equal nil, @p1.reload.certificate_email_sent_at
        assert_equal @time, @p2.reload.certificate_email_sent_at
        assert_equal nil, @p3.reload.certificate_email_sent_at
        assert_equal nil, @p4.reload.certificate_email_sent_at
        assert_equal @time, @p5.reload.certificate_email_sent_at
      end
    end

    should "send certificate emails only if not already sent" do
      @p2.certificate_email_sent_at = @time - 1.hour
      @p2.save!
      
      Timecop.freeze @time do
        assert_difference 'ActionMailer::Base.deliveries.size', 1 do
          calls = 0
          sent = DailyDealPurchase.send_unsent_certificate_email(5, Time.zone.local(2012, 1, 1, 7, 0, 0)) do |ddp|
            assert_equal @time, ddp.certificate_email_sent_at
            calls += 1
          end
          assert_equal 1, sent
          assert_equal 1, calls
        end
        assert_equal nil, @p1.reload.certificate_email_sent_at
        assert_equal @time - 1.hour, @p2.reload.certificate_email_sent_at
        assert_equal nil, @p3.reload.certificate_email_sent_at
        assert_equal nil, @p4.reload.certificate_email_sent_at
        assert_equal @time, @p5.reload.certificate_email_sent_at
      end
    end

    should "send certificate emails only if executed after start_time" do
      Timecop.freeze @time do
        assert_difference 'ActionMailer::Base.deliveries.size', 1 do
          calls = 0
          sent = DailyDealPurchase.send_unsent_certificate_email(5, Time.zone.local(2012, 1, 1, 7, 3, 0)) do |ddp|
            assert_equal @time, ddp.certificate_email_sent_at
            calls += 1
          end
          assert_equal 1, sent
          assert_equal 1, calls
        end
        assert_equal nil, @p1.reload.certificate_email_sent_at
        assert_equal nil, @p2.reload.certificate_email_sent_at
        assert_equal nil, @p3.reload.certificate_email_sent_at
        assert_equal nil, @p4.reload.certificate_email_sent_at
        assert_equal @time, @p5.reload.certificate_email_sent_at
      end
    end

    should "send no more than count certificate emails" do
      Timecop.freeze @time do
        assert_difference 'ActionMailer::Base.deliveries.size', 1 do
          calls = 0
          sent = DailyDealPurchase.send_unsent_certificate_email(1, Time.zone.local(2012, 1, 1, 7, 0, 0)) do |ddp|
            assert_equal @time, ddp.certificate_email_sent_at
            calls += 1
          end
          assert_equal 1, sent
          assert_equal 1, calls
        end
        assert_equal nil, @p1.reload.certificate_email_sent_at
        assert_equal @time, @p2.reload.certificate_email_sent_at
        assert_equal nil, @p3.reload.certificate_email_sent_at
        assert_equal nil, @p4.reload.certificate_email_sent_at
        assert_equal nil, @p5.reload.certificate_email_sent_at
      end
    end
  end
  
  context "should send certificates" do
    should "be true for daily deal purchase" do
      @daily_deal_purchase = Factory(:daily_deal_purchase)
      assert @daily_deal_purchase.should_send_email?, "Should send certificates if daily deal purchase"
    end
    
    should "be false for off platform daily deal purchase" do
      @off_platform_daily_deal_purchase = Factory(:off_platform_daily_deal_purchase)
      assert !@off_platform_daily_deal_purchase.should_send_email?, "Should not send certificates if off platform daily deal purchase"
    end
  end

  context "#send_certificate_or_confirmation_email!" do
    context "certificate purchase" do
      should "deliver the certificate email and set certificate_email_sent_at" do
        Timecop.freeze do
          purchase = Factory(:captured_daily_deal_purchase)
          assert_nil purchase.certificate_email_sent_at
          DailyDealMailer.expects(:deliver_purchase_confirmation_with_certificates).with(purchase)
          purchase.send_email!
          assert_equal Time.zone.now, purchase.reload.certificate_email_sent_at
        end
      end
    end

    context "travelsavers purchase" do
      should "deliver the confirmation (non-certificate) email and set certificate_email_sent_at" do
        Timecop.freeze do
          purchase = Factory(:captured_daily_deal_purchase)
          purchase.stubs(:travelsavers?).returns(true)
          assert_nil purchase.certificate_email_sent_at
          DailyDealPurchaseMailer.expects(:deliver_confirmation).with(purchase)
          purchase.send_email!
          assert_equal Time.zone.now, purchase.reload.certificate_email_sent_at
        end
      end
    end

    context "email was already sent" do
      should "not deliver an email or update the certificate_email_sent_at" do
        purchase = Factory(:captured_daily_deal_purchase, :quantity => 1)
        @time = Time.zone.local(2012, 1, 2, 12, 34, 56)
        Timecop.freeze @time do
          purchase.certificate_email_sent_at = @time - 1.hour
          purchase.save!
          assert_no_difference 'ActionMailer::Base.deliveries.size' do
            purchase.send_email!
          end
          assert_equal @time - 1.hour, purchase.reload.certificate_email_sent_at
        end
      end

      should "deliver an email but not update the certificate_email_sent_at when passed :force true" do
        purchase = Factory(:captured_daily_deal_purchase, :quantity => 1)
        @time = Time.zone.local(2012, 1, 2, 12, 34, 56)
        Timecop.freeze @time do
          purchase.certificate_email_sent_at = @time - 1.hour
          purchase.save!
          assert_difference 'ActionMailer::Base.deliveries.size', 1 do
            purchase.send_email!(:force => true)
          end
          assert_equal @time - 1.hour, purchase.reload.certificate_email_sent_at
        end
      end
    end
  end
end
