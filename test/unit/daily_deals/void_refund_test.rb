# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class VoidRefundTest < ActiveSupport::TestCase

  context "#void_or_full_refund!" do

    setup do
      daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
      @daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal)
      @admin = Factory :admin
      FakeWeb.allow_net_connect = false
    end

    should "have the correct setup" do
      assert_not_nil @daily_deal_purchase.daily_deal_payment
      assert_equal 30, @daily_deal_purchase.daily_deal_payment.amount
    end

    should "refund a captured purchase for the full amount, by default" do
      expect_braintree_full_refund(@daily_deal_purchase)
      assert_equal "captured", @daily_deal_purchase.payment_status
      assert_equal 0, @daily_deal_purchase.refund_amount
      @daily_deal_purchase.void_or_full_refund! @admin
      assert_equal "refunded", @daily_deal_purchase.payment_status
      assert_equal 30, @daily_deal_purchase.refund_amount
    end

    should "refund a captured Travelsavers purchase and cancel the booking" do
      deal = Factory :travelsavers_daily_deal, :price => 50
      purchase = Factory :travelsavers_captured_daily_deal_purchase, :daily_deal => deal
      booking = Factory :successful_travelsavers_booking, :daily_deal_purchase => purchase
      purchase = booking.daily_deal_purchase
      assert purchase.captured?
      assert_equal "booking_success_payment_success", booking.state
      assert_equal 0, purchase.refund_amount
      assert_equal 50, purchase.actual_purchase_price

      purchase.void_or_full_refund!(@admin)
      booking.reload
      assert purchase.refunded?
      assert_equal "booking_canceled_payment_unknown", booking.state
      assert_equal 50, purchase.refund_amount
      assert purchase.daily_deal_certificates.all?(&:refunded?)
    end

    should "void a purchase if it is not captured" do
      daily_deal_purchase = Factory(:captured_daily_deal_purchase)
      daily_deal = daily_deal_purchase.daily_deal
      assert !daily_deal.location_required?, "location should not be required"
      Factory(:store, :advertiser => daily_deal.advertiser)
      Factory(:store, :advertiser => daily_deal.advertiser)

      daily_deal.advertiser(true)
      daily_deal.update_attributes! :location_required => true

      expect_braintree_void(daily_deal_purchase)

      assert_no_difference "daily_deal_purchase.daily_deal_certificates.count" do
        daily_deal_purchase.void_or_full_refund! @admin
      end
      assert_equal "voided", daily_deal_purchase.reload.payment_status
      assert_equal 0, daily_deal_purchase.amount
    end

    should "raise an ArgumentError when trying to refund more than the actual purchase price" do
      expect_braintree_full_refund(@daily_deal_purchase)
      assert_raises(ArgumentError) { @daily_deal_purchase.void_or_full_refund! @admin, 31 }
    end

  end
  
  context "void_or_full_refund! when certificates_to_generate_per_unit_quantity > 1" do
    
    setup do
      daily_deal = Factory(:daily_deal, :value => 100, :price => 30, :certificates_to_generate_per_unit_quantity => 3)
      @daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => 2, :daily_deal => daily_deal)
      @admin = Factory :admin
    end
    
    should "refund a captured purchase for the full amount, by default, and mark all certificates refunded" do
      expect_braintree_full_refund(@daily_deal_purchase)
      assert_equal "captured", @daily_deal_purchase.payment_status
      assert_equal 6, @daily_deal_purchase.daily_deal_certificates.size
      assert @daily_deal_purchase.daily_deal_certificates.all? { |c| c.active? }
      assert_equal 0, @daily_deal_purchase.refund_amount
      @daily_deal_purchase.void_or_full_refund! @admin
      assert_equal "refunded", @daily_deal_purchase.payment_status
      assert_equal 60, @daily_deal_purchase.refund_amount
      assert @daily_deal_purchase.daily_deal_certificates.all? { |c| c.refunded? }
    end
    
  end

  context "void_or_full_refund! of a captured purchase when no payment was necessary for purchase" do
    setup do
      daily_deal = Factory(:daily_deal, :value => 100, :price => 5)
      @daily_deal_purchase = Factory(:captured_daily_deal_purchase_with_discount, :daily_deal => daily_deal, :quantity => 2)
      @admin = Factory :admin
    end

    should "have the correct setup" do
      assert_nil @daily_deal_purchase.daily_deal_payment
      assert_equal 0, @daily_deal_purchase.actual_purchase_price
    end

    should "mark purchase as refunded" do
      @daily_deal_purchase.void_or_full_refund!(@admin)
      assert_equal "refunded", @daily_deal_purchase.payment_status
      assert !@daily_deal_purchase.refunded_at.nil?
      assert_equal @daily_deal_purchase.refunded_by, @admin.login
      assert_equal 0, @daily_deal_purchase.refund_amount
      assert @daily_deal_purchase.daily_deal_certificates.all? { |c| c.refunded? }
    end
  end

  context "void_or_full_refund! of an authorized Travelsavers purchase" do
    setup do
      booking = Factory(:successful_travelsavers_booking_with_failed_payment)
      @daily_deal_purchase = booking.daily_deal_purchase
      @admin = Factory :admin
    end

    should "have the correct setup" do
      assert_nil @daily_deal_purchase.daily_deal_payment
    end

    should "mark purchase as voided" do
      @daily_deal_purchase.void_or_full_refund!(@admin)
      assert @daily_deal_purchase.voided?
      assert @daily_deal_purchase.refunded_at.present?
      assert @daily_deal_purchase.refunded_by.present?
      assert_equal 0, @daily_deal_purchase.refund_amount
      assert @daily_deal_purchase.daily_deal_certificates.all?(&:voided?)
    end
  end

  context "set_payment_status! of an authorized non-Travelsavers purchase" do
    setup do
      @daily_deal_purchase = Factory(:authorized_daily_deal_purchase)
      @admin = Factory :admin
    end

    should "not allow transition to refunded status" do
      e = assert_raises(RuntimeError) { @daily_deal_purchase.set_payment_status!("refunded") }
      assert_match /Bad authorized -> refunded/, e.message
      assert_equal "authorized", @daily_deal_purchase.payment_status
      assert @daily_deal_purchase.refunded_by.blank?
      assert_equal 0, @daily_deal_purchase.refund_amount
    end
  end

  context "changing the status of related certificates" do
    context "voiding and refunding" do
      setup do
        @daily_deal = Factory(:daily_deal, :price => 12)
        @daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 3)
      end
      should "be setup properly" do
        assert_equal 3, @daily_deal_purchase.daily_deal_certificates.size
        @daily_deal_purchase.daily_deal_certificates.each do |cert|
          assert_equal "active", cert.status
          assert_equal 0, cert.refund_amount
        end
      end
      should "make certs refunded on refund" do
        @daily_deal_purchase.update_attribute(:refund_amount, @daily_deal_purchase.total_paid)
        @daily_deal_purchase.send(:set_payment_status!, "refunded")
        @daily_deal_purchase.daily_deal_certificates.each do |cert|
          assert_equal "refunded", cert.status
          assert_equal 12, cert.refund_amount
        end
      end
      should "make certs voided on void" do
        @daily_deal_purchase.send(:set_payment_status!, "voided")
        @daily_deal_purchase.daily_deal_certificates.each do |cert|
          assert_equal "voided", cert.status
          assert_equal 0, cert.refund_amount
        end
      end
    end
    context "capture after voided" do
      setup do
        @daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => 3)
        class << @daily_deal_purchase
          def enqueue_email
            # do nothing
          end
        end
        @daily_deal_purchase.send(:set_payment_status!, "voided")
      end
      should "should reactivate certs" do
        @daily_deal_purchase.send(:set_payment_status!, "captured")
        assert_equal 3, @daily_deal_purchase.daily_deal_certificates.size
        @daily_deal_purchase.daily_deal_certificates.each do |cert|
          assert_equal "active", cert.status
          assert_equal 0, cert.refund_amount
        end
      end
    end
  end

  context "#partially_refunded?" do
    setup do
      deal = Factory(:daily_deal)
      discount = Factory(:discount, :publisher => deal.publisher, :amount => 15)
      @purchase = Factory(:captured_daily_deal_purchase, :quantity => 3, :daily_deal => deal, :discount => discount)
      @cert1 = Factory(:daily_deal_certificate, :daily_deal_purchase => @purchase)
      @cert2 = Factory(:daily_deal_certificate, :daily_deal_purchase => @purchase)
      @cert3 = Factory(:daily_deal_certificate, :daily_deal_purchase => @purchase)
    end

    should "be set up properly" do
      assert_equal 30, @purchase.actual_purchase_price, "was #{@purchase.actual_purchase_price}"
      assert_equal 0, @purchase.refund_amount
    end

    context "no refunds" do
      should "not be partially_refunded?" do
        assert !@purchase.partially_refunded?
      end
    end

    context "one of the certs gets refunded" do
      setup do
        @purchase.update_attribute(:refund_amount, 10)
      end
      should "be partially_refunded?" do
        assert @purchase.partially_refunded?
      end
    end

    context "fully refunded" do
      setup do
        @purchase.update_attribute(:refund_amount, @purchase.actual_purchase_price)
      end
      should "not be partially_refunded?" do
        assert !@purchase.partially_refunded?
      end
    end

  end

  context "#partial_refund!" do
    context "straightforward refunds" do
      setup do
        @daily_deal = Factory(:daily_deal, :price => 10)
        @purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 3)
        @admin = Factory(:admin)
      end
      should "have correct setup" do
        assert_not_nil @purchase.daily_deal_certificates
        assert_equal 3, @purchase.daily_deal_certificates.size
        assert_equal 30, @purchase.total_paid
        assert_equal 30, @purchase.actual_purchase_price
        assert_equal 0, @purchase.refund_amount
        assert_equal 3, @purchase.quantity
      end
      context "refund all certs" do
        setup do
          expect_braintree_full_refund(@purchase)
        end
        should "refund everything just right" do
          result = @purchase.partial_refund!(@admin, @purchase.daily_deal_certificates.collect(&:id).map(&:to_s))
          assert_equal "refunded", @purchase.payment_status
          assert_equal 3, @purchase.daily_deal_certificates.size
          @purchase.daily_deal_certificates.each do |cert|
            assert_equal "refunded", cert.status
            assert_equal 10, cert.refund_amount
          end
          assert_equal 30, @purchase.refund_amount
          assert_equal 30, @purchase.total_paid
          assert_equal 3, result[:number_of_certs_refunded]
          assert_equal 30, result[:amount_refunded]
        end
      end
      context "refund one cert" do
        setup do
          expect_braintree_partial_refund(@purchase, 10)
        end
        should "refund just the one cert" do
          @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificates.first.id.to_s])
          assert_equal "refunded", @purchase.payment_status
          assert_equal "refunded", @purchase.daily_deal_certificates.first.status
          assert_equal 10, @purchase.refund_amount
          assert_equal 30, @purchase.total_paid
        end
      end
      context "two consecutive refunds" do
        setup do
          Braintree::Transaction.expects(:find).returns(braintree_sale_transaction(@purchase, :status => Braintree::Transaction::Status::Settled)).at_least_once
          refunded_result = braintree_transaction_refunded_result(@purchase, :amount => 10)
          Braintree::Transaction.expects(:refund).with(@purchase.payment_gateway_id, 10).returns(refunded_result).at_least_once
        end
        should "should refund both certs and have the refund amount" do
          @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificates.first.id.to_s])
          @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificates.last.id.to_s])
          assert_equal "refunded", @purchase.payment_status
          assert_equal "refunded", @purchase.daily_deal_certificates.first.status
          assert_equal "active", @purchase.daily_deal_certificates.second.status
          assert_equal "refunded", @purchase.daily_deal_certificates.last.status
          assert_equal 10, @purchase.daily_deal_certificates.first.refund_amount
          assert_equal 0, @purchase.daily_deal_certificates.second.refund_amount
          assert_equal 10, @purchase.daily_deal_certificates.last.refund_amount
          assert_equal 20, @purchase.refund_amount
          assert_equal 30, @purchase.total_paid
        end
      end
      context "partial refunds until fully refund" do
        setup do
          Braintree::Transaction.expects(:find).returns(braintree_sale_transaction(@purchase, :status => Braintree::Transaction::Status::Settled)).at_least_once
          refunded_result = braintree_transaction_refunded_result(@purchase, :amount => 10)
          Braintree::Transaction.expects(:refund).with(@purchase.payment_gateway_id, 10).returns(refunded_result).times(3)
        end
        should "should refund both certs and have the refund amount" do
          @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificates.first.id.to_s])
          @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificates.second.id.to_s])
          @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificates.third.id.to_s])
          assert_equal "refunded", @purchase.payment_status
          assert_equal "refunded", @purchase.daily_deal_certificates.first.status
          assert_equal "refunded", @purchase.daily_deal_certificates.second.status
          assert_equal "refunded", @purchase.daily_deal_certificates.last.status
          assert_equal 10, @purchase.daily_deal_certificates.first.refund_amount
          assert_equal 10, @purchase.daily_deal_certificates.second.refund_amount
          assert_equal 10, @purchase.daily_deal_certificates.last.refund_amount
          assert_equal 30, @purchase.refund_amount
          assert_equal 30, @purchase.total_paid
        end
      end
      context "partial refund followed by full refund" do
        setup do
          Braintree::Transaction.expects(:find).returns(braintree_sale_transaction(@purchase, :status => Braintree::Transaction::Status::Settled)).at_least_once
          refunded_result = braintree_transaction_refunded_result(@purchase, :amount => 10)
          Braintree::Transaction.expects(:refund).with(@purchase.payment_gateway_id, 10).returns(refunded_result).times(1)
          refunded_result = braintree_transaction_refunded_result(@purchase, :amount => 20)
          Braintree::Transaction.expects(:refund).with(@purchase.payment_gateway_id).returns(refunded_result).times(1)
        end
        should "set status of all certs after full refund which follows partial refund" do
          @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificates.first.id.to_s])
          assert_equal "refunded", @purchase.payment_status
          assert_equal 10, @purchase.refund_amount
          assert_equal 30, @purchase.total_paid
          @purchase.void_or_full_refund!(@admin)
          assert_equal 30, @purchase.refund_amount
          assert_equal "refunded", @purchase.daily_deal_certificates.first.status
          assert_equal "refunded", @purchase.daily_deal_certificates.second.status
          assert_equal "refunded", @purchase.daily_deal_certificates.third.status
          assert_equal 10, @purchase.daily_deal_certificates.first.refund_amount
          assert_equal 10, @purchase.daily_deal_certificates.second.refund_amount
          assert_equal 10, @purchase.daily_deal_certificates.last.refund_amount
        end
      end
      context "partially refunding already refunded certs" do
        setup do
          expect_braintree_partial_refund(@purchase, 10)
        end
        should "should not refund the same cert twice" do
          @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificates.first.id.to_s])
          assert_equal "refunded", @purchase.payment_status
          assert_equal "refunded", @purchase.daily_deal_certificates.first.status
          assert_equal "active", @purchase.daily_deal_certificates.second.status
          assert_equal "active", @purchase.daily_deal_certificates.third.status
          assert_raise RuntimeError do
            @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificates.first.id.to_s])
          end
          assert_equal "refunded", @purchase.daily_deal_certificates.first.status
          assert_equal "active", @purchase.daily_deal_certificates.second.status
          assert_equal "active", @purchase.daily_deal_certificates.third.status
          assert_equal 10, @purchase.daily_deal_certificates.first.refund_amount
          assert_equal 0, @purchase.daily_deal_certificates.second.refund_amount
          assert_equal 0, @purchase.daily_deal_certificates.last.refund_amount
          assert_equal 10, @purchase.refund_amount
          assert_equal 30, @purchase.total_paid
        end
      end
    end

    context "messy refunds" do
      context "partial refunds with uneven amounts" do
        setup do
          @daily_deal = Factory(:daily_deal, :price => 20)
          discount = Factory(:discount, :amount => 10, :publisher => @daily_deal.publisher)
          @purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 3, :discount => discount)
          @admin = Factory(:admin)
        end

        should "handle consecutive refunds" do
          expect_braintree_partial_refund(@purchase, 20)
          @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificates.first.id.to_s])
          assert_equal "refunded", @purchase.payment_status
          assert_equal "refunded", @purchase.daily_deal_certificates.first.status
          assert_equal 20, @purchase.refund_amount

          expect_braintree_partial_refund(@purchase, 20)
          @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificates.second.id.to_s])
          assert_equal "refunded", @purchase.payment_status
          assert_equal "refunded", @purchase.daily_deal_certificates.second.status
          assert_equal 20 * 2, @purchase.refund_amount

          expect_braintree_partial_refund(@purchase, 10)
          @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificates.third.id.to_s])
          assert_equal "refunded", @purchase.payment_status
          assert_equal "refunded", @purchase.daily_deal_certificates.third.status
          assert_equal 50, @purchase.refund_amount
        end
      end
      
      context "partial refunds with deals with certificates_to_generate_per_unit_quantity > 1" do
        
        setup do
          @daily_deal = Factory :daily_deal, :quantity => 500, :price => 20, :certificates_to_generate_per_unit_quantity => 2
          @purchase = Factory :captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 3
          @admin = Factory :admin
          @c1, @c2, @c3, @c4, @c5, @c6 = @purchase.daily_deal_certificates
        end
        
        should "prohibit refunding only one voucher, as one is not a multiple of certificates_to_generate_per_unit_quantity" do
          Braintree::Transaction.expects(:refund).never
          begin
            @purchase.partial_refund!(@admin, [@c1.id])
          rescue RuntimeError => e
            assert_equal "number of vouchers to refund (1) must be a multiple of certificates_to_generate_per_unit_quantity (2), but is not", e.message
          else
            assert false, "should have raised an exception"
          end
          
          assert @purchase.captured?
          assert @purchase.refund_amount.zero?
          assert @purchase.daily_deal_certificates.each(&:reload).all? { |c| c.active? }
        end

        should "prohibit refunding only one voucher, as one is not a multiple of certificates_to_generate_per_unit_quantity " +
               "(example where same voucher is passed in twice)" do
          Braintree::Transaction.expects(:refund).never
          begin
            @purchase.partial_refund!(@admin, [@c1.id, @c1.id])
          rescue RuntimeError => e
            assert_equal "number of vouchers to refund (1) must be a multiple of certificates_to_generate_per_unit_quantity (2), but is not", e.message
          else
            assert false, "should have raised an exception"
          end
          
          assert @purchase.captured?
          assert @purchase.refund_amount.zero?
          assert @purchase.daily_deal_certificates.each(&:reload).all? { |c| c.active? }
        end
        
        should "permit refunding a number of vouchers that is a multiple of certificates_to_generate_per_unit_quantity (example with 4 vouchers)" do
          expect_braintree_partial_refund(@purchase, 40)
          certs_to_refund = [@c1, @c2, @c3, @c4]
          @purchase.partial_refund!(@admin, certs_to_refund.map(&:id))
          [@c1, @c2, @c3, @c4, @c5, @c6].each(&:reload)
          certs_to_refund.each { |c| assert c.refunded? }
          assert @purchase.refunded?
          assert_equal 40, @purchase.refund_amount
          assert @c5.active?
          assert @c6.active?
        end
        
      end

      context "discount dramatically exceeds price" do
        setup do
          @daily_deal = Factory(:daily_deal, :price => 20)
          discount = Factory(:discount, :amount => 55, :publisher => @daily_deal.publisher)
          @purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 3, :discount => discount)
          @admin = Factory(:admin)
        end

        should "never exceed payment amount" do
          expect_braintree_partial_refund(@purchase, 5)
          @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificate_ids.first])
          assert_equal "refunded", @purchase.payment_status
          assert_equal "refunded", @purchase.daily_deal_certificates.first.status
          assert_equal "active", @purchase.daily_deal_certificates.second.status
          assert_equal "active", @purchase.daily_deal_certificates.third.status
          assert_equal 5, @purchase.daily_deal_certificates.first.refund_amount, "was: #{@purchase.daily_deal_certificates.first.refund_amount}"
          assert_equal 0, @purchase.daily_deal_certificates.second.refund_amount
          assert_equal 0, @purchase.daily_deal_certificates.last.refund_amount
          assert_equal 5, @purchase.refund_amount
        end
      end
    end

    context "braintree exception" do
      setup do
        @daily_deal = Factory(:daily_deal, :price => 20)
        @purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 3)
        @admin = Factory(:admin)
        Braintree::Transaction.expects(:find).returns(braintree_sale_transaction(@purchase, :status => Braintree::Transaction::Status::Settled))
        Braintree::Transaction.expects(:refund).with(@purchase.payment_gateway_id, 20).raises(RuntimeError, "bogus!")
      end
      should "refund just the one cert" do
        assert_raise RuntimeError do
          @purchase.partial_refund!(@admin, [@purchase.daily_deal_certificates.first.id.to_s])
        end
        assert_equal "captured", @purchase.payment_status
        assert_equal "active", @purchase.daily_deal_certificates.first.status
        assert_equal 0, @purchase.refund_amount
        assert_equal 60, @purchase.total_paid
      end
    end

    context "with daily deal variations" do

      setup do
        @daily_deal = Factory(:daily_deal)
        @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)

        @variation_1 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 40.00, :price => 30.00)
        @variation_2 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 30.00, :price => 20.00)
        @variation_3 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 20.00, :price => 10.00)

        @purchase_1  = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 2, :daily_deal_variation => @variation_1)
        @purchase_2  = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1, :daily_deal_variation => @variation_2)
        @purchase_3  = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 3, :daily_deal_variation => @variation_3)        
      end

      should "be setup properly" do
        assert_equal 3, @daily_deal.daily_deal_variations.size
        
        assert_equal 2, @purchase_1.daily_deal_certificates.size
        assert_not_nil @purchase_1.daily_deal_payment
        assert_equal 60.00, @purchase_1.daily_deal_payment.amount.to_f

        assert_equal 1, @purchase_2.daily_deal_certificates.size
        assert_not_nil @purchase_2.daily_deal_payment
        assert_equal 20.00, @purchase_2.daily_deal_payment.amount.to_f

        assert_equal 3, @purchase_3.daily_deal_certificates.size
        assert_not_nil @purchase_3.daily_deal_payment
        assert_equal 30.00, @purchase_3.daily_deal_payment.amount.to_f

        assert_equal 110.00, @daily_deal.daily_deal_purchases.collect(&:total_paid).sum
        assert_equal 0.00, @daily_deal.daily_deal_purchases.collect(&:refund_amount).sum
      end

      context "with @purchase_1 refunded" do

        setup do
          expect_braintree_full_refund(@purchase_1)
          @purchase_1.void_or_full_refund! Factory(:admin)
          @daily_deal.reload          
        end

        should "total paid should remain the same and refund amount should increase" do
          assert_equal 60.00, @purchase_1.refund_amount
          assert_equal 110.00, @daily_deal.daily_deal_purchases.collect(&:total_paid).sum.to_f
          assert_equal 60.00, @daily_deal.daily_deal_purchases.collect(&:refund_amount).sum.to_f

          assert_equal 30.00, @purchase_1.daily_deal_certificates.first.refund_amount
          assert_equal 30.00, @purchase_1.daily_deal_certificates.last.refund_amount
        end

      end

      context "with @purchase_2 refunded" do
        
        setup do
          expect_braintree_full_refund(@purchase_2)
          @purchase_2.void_or_full_refund! Factory(:admin)
          @daily_deal.reload          
        end

        should "total paid should remain the same and refund amount should increase" do
          assert_equal 20.00, @purchase_2.refund_amount
          assert_equal 110.00, @daily_deal.daily_deal_purchases.collect(&:total_paid).sum.to_f
          assert_equal 20.00, @daily_deal.daily_deal_purchases.collect(&:refund_amount).sum.to_f

          assert_equal 20.00, @purchase_2.daily_deal_certificates.first.refund_amount
        end

      end

      context "with @purchase_3 refunded" do
        
        setup do
          expect_braintree_full_refund(@purchase_3)
          @purchase_3.void_or_full_refund! Factory(:admin)
          @daily_deal.reload          
        end

        should "total paid should remain the same and refund amount should increase" do
          assert_equal 30.00, @purchase_3.refund_amount
          assert_equal 110.00, @daily_deal.daily_deal_purchases.collect(&:total_paid).sum.to_f
          assert_equal 30.00, @daily_deal.daily_deal_purchases.collect(&:refund_amount).sum.to_f

          assert_equal 10.00, @purchase_3.daily_deal_certificates.first.refund_amount
          assert_equal 10.00, @purchase_3.daily_deal_certificates.second.refund_amount
          assert_equal 10.00, @purchase_3.daily_deal_certificates.last.refund_amount
        end

      end      


    end
  end

end
