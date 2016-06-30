require File.join(File.dirname(__FILE__), "../test_helper")

class OptimalPurchaseTest < ActiveSupport::TestCase

  context "captured optimal purchase with successful optimal interaction" do
    setup do
      @daily_deal = Factory(:daily_deal, :price => 10)
      @captured_purchase = Factory(:captured_optimal_daily_deal_purchase, :daily_deal => @daily_deal)
    end

    should "look like the right captured purchase" do
      assert_instance_of OptimalPayment, @captured_purchase.daily_deal_payment
      assert @captured_purchase.daily_deal_payment.amount > 0
      assert_equal @daily_deal.price, @captured_purchase.daily_deal_payment.amount
      assert_equal @captured_purchase.actual_purchase_price, @captured_purchase.daily_deal_payment.amount
      assert_equal "captured", @captured_purchase.payment_status
    end

    should "be voidable or refundable" do
      @captured_purchase.voidable_or_refundable?
    end

    context "with successful optimal interaction" do
      setup do
        @captured_purchase.stubs(:optimal_webservice_void => stub(:success? => true, :errors => []))
        @captured_purchase.stubs(:optimal_webservice_refund => stub(:success? => true, :errors => []))
      end

      should "void properly" do
        @captured_purchase.optimal_payment_void_or_full_refund!(Factory(:admin))
        assert_equal "voided", @captured_purchase.payment_status
        assert_equal 0, @captured_purchase.daily_deal_payment.amount
        assert_equal "new_aaron", @captured_purchase.refunded_by
      end

      should "void properly even if string is sent as admin" do
        @captured_purchase.optimal_payment_void_or_full_refund!("admin_string")
        assert_equal "voided", @captured_purchase.payment_status
        assert_equal 0, @captured_purchase.daily_deal_payment.amount
        assert_equal "admin_string", @captured_purchase.refunded_by
      end

      should "refund properly" do
        now = Time.utc(2011, 3, 11, 2, 40)
        Timecop.freeze now do
          @captured_purchase.daily_deal_payment.payment_at = 3.days.ago
          @captured_purchase.daily_deal_payment.payment_gateway_receipt_id = "123456"
          @captured_purchase.save!
          assert_equal "captured", @captured_purchase.payment_status
          @captured_purchase.optimal_payment_void_or_full_refund!(Factory(:admin))
          assert_equal "refunded", @captured_purchase.payment_status
          assert_equal @captured_purchase.daily_deal_payment.amount, @captured_purchase.actual_purchase_price
          assert @captured_purchase.daily_deal_payment.amount > 0
          assert_equal @captured_purchase.daily_deal_payment.amount, @captured_purchase.refund_amount
          assert_equal "new_aaron", @captured_purchase.refunded_by
        end
      end
      should "refund partial amount properly" do
        now = Time.utc(2011, 3, 11, 2, 40)
        Timecop.freeze now do
          @captured_purchase.daily_deal_payment.payment_at = 3.days.ago
          @captured_purchase.daily_deal_payment.payment_gateway_receipt_id = "123456"
          @captured_purchase.save!
          assert_equal "captured", @captured_purchase.payment_status
          @captured_purchase.optimal_partial_refund!(Factory(:admin), 2.5)
          assert_equal "refunded", @captured_purchase.payment_status
          assert_equal @daily_deal.price, @captured_purchase.daily_deal_payment.amount
          assert_equal @captured_purchase.daily_deal_payment.amount, @captured_purchase.actual_purchase_price
          assert_equal 2.5, @captured_purchase.refund_amount
          assert_equal "new_aaron", @captured_purchase.refunded_by
        end
      end
    end

    context "with unsuccessful optimal interaction" do
      setup do
        @captured_purchase.stubs(:optimal_webservice_void => stub(:success? => false, :error_message => ""))
        @captured_purchase.stubs(:optimal_webservice_refund => stub(:success? => false, :error_message => ""))
      end
      should "raise and not change payment_status" do
        assert_equal "captured", @captured_purchase.payment_status
        assert_raise RuntimeError do
          @captured_purchase.optimal_payment_void_or_full_refund!(Factory(:admin))
        end
        assert_equal "captured", @captured_purchase.payment_status
      end
    end

  end

  context "authorized optimal purchase" do
    setup do
      @authorized_purchase = Factory(:authorized_optimal_daily_deal_purchase, :daily_deal => Factory(:daily_deal))
    end

    context "with successful optimal interaction" do
      setup do
        @authorized_purchase.stubs(:optimal_webservice_void => stub(:success? => true))
        @authorized_purchase.stubs(:optimal_webservice_refund => stub(:success? => true, :error_message => ""))
      end
      should "void properly" do
        assert_equal "authorized", @authorized_purchase.payment_status
        @authorized_purchase.optimal_payment_void_or_full_refund!(Factory(:admin))
        assert_equal "voided", @authorized_purchase.payment_status
        assert_equal 0, @authorized_purchase.daily_deal_payment.amount
        assert_equal "new_aaron", @authorized_purchase.refunded_by
      end
      should "should raise when an attempt is made to refund a non-refundable payment" do
        now = Time.utc(2011, 3, 11, 2, 40)
        Timecop.freeze now do
          @authorized_purchase.daily_deal_payment.payment_at = 3.days.ago
          @authorized_purchase.daily_deal_payment.payment_gateway_receipt_id = "123456"
          @authorized_purchase.save!
          assert_equal "authorized", @authorized_purchase.payment_status
          assert_raise RuntimeError do
            @authorized_purchase.optimal_payment_void_or_full_refund!(Factory(:admin))
          end
        end
      end
    end
    context "with unsuccessful optimal interaction" do
      setup do
        @authorized_purchase.stubs(:optimal_webservice_void => stub(:success? => false, :error_message => ""))
        @authorized_purchase.stubs(:optimal_webservice_refund => stub(:success? => false, :error_message => ""))
      end
      should "raise and not change payment_status" do
        assert_equal "authorized", @authorized_purchase.payment_status
        assert_raise RuntimeError do
          @authorized_purchase.optimal_payment_void_or_full_refund!(Factory(:admin))
        end
        assert_equal "authorized", @authorized_purchase.payment_status
      end
    end
  end

  context "pending optimal purchase" do
    setup do
      @pending_purchase = Factory(:pending_daily_deal_purchase)
    end
    should "not change payment_status when void is attempted" do
      assert_equal "pending", @pending_purchase.payment_status
      assert_raise RuntimeError do
        @pending_purchase.optimal_payment_void_or_full_refund!(Factory(:admin))
      end
      assert_equal "pending", @pending_purchase.payment_status
    end
    should "not change payment_status when refund is attempted" do
       @pending_purchase.stubs(:optimal_voidable? => false)
       assert_equal "pending", @pending_purchase.payment_status
       assert_raise RuntimeError do
        @pending_purchase.optimal_payment_void_or_full_refund!(Factory(:admin))
       end
       assert_equal "pending", @pending_purchase.payment_status
    end
  end

  context "refunded optimal purchase" do
    setup do
      @refunded_purchase = Factory(:refunded_optimal_payment_daily_deal_purchase)
      OptimalPayments::WebService.expects(:refund).never
    end
    should "not change payment_status when void attempt is made" do
      assert_equal "refunded", @refunded_purchase.payment_status
      assert_raise RuntimeError do
        @refunded_purchase.optimal_payment_void_or_full_refund!(Factory(:admin))
      end
      assert_equal "refunded", @refunded_purchase.payment_status
    end
    should "not change payment_status when refund is attempted" do
       @refunded_purchase.stubs(:optimal_voidable? => false )
       assert_equal "refunded", @refunded_purchase.payment_status
       assert_raise RuntimeError do
        @refunded_purchase.optimal_payment_void_or_full_refund!(Factory(:admin))
       end
       assert_equal "refunded", @refunded_purchase.payment_status
    end
  end

  context "voided optimal purchase" do
    setup do
      @voided_purchase = Factory(:voided_optimal_payment_daily_deal_purchase)
      OptimalPayments::WebService.expects(:void).never
    end
    should "not change payment_status when void attempt is made" do
      assert_equal "voided", @voided_purchase.payment_status
      assert_raise RuntimeError do
        @voided_purchase.optimal_payment_void_or_full_refund!(Factory(:admin))
      end
      assert_equal "voided", @voided_purchase.payment_status
    end
    should "not change payment_status when refund is attempted" do
       @voided_purchase.stubs(:optimal_voidable? => false)
       assert_equal "voided", @voided_purchase.payment_status
       assert_raise RuntimeError do
        @voided_purchase.optimal_payment_void_or_full_refund!(Factory(:admin))
       end
       assert_equal "voided", @voided_purchase.payment_status
    end
  end

end
