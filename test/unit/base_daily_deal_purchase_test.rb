# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../test_helper"

class BaseDailyDealPurchaseTest < ActiveSupport::TestCase
  include DailyDealPurchasesTestHelper

  context "the basics" do
    
    setup do
      @valid_attributes = { :daily_deal => (dd = Factory(:daily_deal)), :consumer => Factory(:consumer, :publisher => dd.publisher), :quantity => 2 }
      @valid_gift_attributes = @valid_attributes.merge({
        :quantity => 2,
        :gift => true,
        :recipient_names => ["Bess Rackham", "Harry Kidd"]
      })
      ActionMailer::Base.deliveries.clear
    end

    should "new daily deal purchase defaults to daily deal min quantity" do
      daily_deal = DailyDeal.new(daily_deals(:changos).attributes.merge( :price => 9.00, :min_quantity => 2 ))
      daily_deal_purchase = build_with_attributes( @valid_attributes.merge( :daily_deal => daily_deal ) )
      assert_equal daily_deal.min_quantity, daily_deal_purchase.quantity
    end
  
    should "daily deal purchase quantity is invalid" do
      daily_deal = DailyDeal.new(daily_deals(:changos).attributes.merge( :min_quantity => 2 ))
      (daily_deal_purchase = build_with_attributes( @valid_attributes.merge( :daily_deal => daily_deal, :quantity => 1 ) )).valid?
      assert_not_nil daily_deal_purchase.errors.on(:quantity)
      assert_match /is below the minimum of 2/, daily_deal_purchase.errors.on(:quantity)
    end
  
    should "daily deal quantity is nil" do
      daily_deal = Factory(:daily_deal)
      consumer = Factory(:consumer, :publisher => daily_deal.publisher)
      daily_deal.update_attribute :min_quantity, nil
      daily_deal_purchase = build_with_attributes( @valid_attributes.merge( :daily_deal => daily_deal, :consumer => consumer, :quantity => 1 ))
      assert daily_deal_purchase.valid?, daily_deal_purchase.errors.full_messages.join
    end
  
    should "daily deal purchase quantity is nil" do
      daily_deal = daily_deals(:changos)
      daily_deal_purchase = build_with_attributes(@valid_attributes.merge( :daily_deal => daily_deal, :quantity => nil))
      assert !daily_deal_purchase.valid?, "Should not be valid, and should not raise exception when validating"
    end
  
    should "create" do
      (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
      Factory(:pending_paypal_payment, :daily_deal_purchase => daily_deal_purchase)
      assert_equal "pending", daily_deal_purchase.payment_status, "Default payment status"
      assert !daily_deal_purchase.gift, "Default gift"
      assert daily_deal_purchase.analog_purchase_id.present?, "Analog purchase id should be present"
      assert_equal 30.00, daily_deal_purchase.total_price, "total_price"
      assert_match /\A[[:xdigit:]]{8}-([[:xdigit:]]{4}-){3}[[:xdigit:]]{12}\z/, daily_deal_purchase.uuid
    end
  
    should "invalid configurations" do
      assert build_with_attributes(@valid_attributes).valid?, "Valid attributes"
      [:daily_deal, :consumer].each do |key|
        assert build_with_attributes(@valid_attributes.merge(key => nil)).invalid?, key.to_s
      end
      assert build_with_attributes(@valid_attributes.merge(:gift => true)).invalid?, "Gift without recipients"
  
      payment_attrs = {
        :payment_status => "captured",
        :daily_deal_payment => Factory(:braintree_payment)
      }
      daily_deal_purchase = build_with_attributes(@valid_attributes.merge(payment_attrs))
      assert daily_deal_purchase.valid?, "Valid attributes: #{daily_deal_purchase.errors.full_messages.inspect}"
  
      payment_attrs.except(:payment_status).keys.each do |key|
        assert build_with_attributes(@valid_attributes.merge(payment_attrs.except(key))).invalid?, "Should not be valid with nil #{key}"
      end
    end
  
    should "attribute mass assignment has no effect" do
      @valid_attributes.merge!({
        :payment_status => "captured",
        :daily_deal_payment => Factory(:paypal_payment,
                                       :payment_at => "12:34:56 Jan 01, 2010 PST",
                                       :payment_gateway_id => "301181649",
                                       :analog_purchase_id => "1-BBP",
                                       :amount => 9.99)
      })
      old_daily_deal_purchase = build_with_attributes(@valid_attributes)
      new_daily_deal_purchase = old_daily_deal_purchase.dup
  
      updated_attributes = { :daily_deal => daily_deals(:burger_king), :consumer => users(:jane_public), :quantity => 3 }
      updated_attributes.keys.each { |key| assert updated_attributes[key] != @valid_attributes[key], key }
  
      new_daily_deal_purchase.attributes = updated_attributes
      @valid_attributes.keys.each { |key| assert_equal old_daily_deal_purchase.send(key), new_daily_deal_purchase.send(key) }
    end
    
  end

  fast_context "paypal actions" do

    setup do
      @valid_attributes = { :daily_deal => (dd = Factory(:daily_deal)), :consumer => Factory(:consumer, :publisher => dd.publisher), :quantity => 2 }
      @valid_gift_attributes = @valid_attributes.merge({
        :quantity => 2,
        :gift => true,
        :recipient_names => ["Bess Rackham", "Harry Kidd"]
      })
    end
    
    should "handle buy now" do
      DailyDealPayment.destroy_all
      daily_deal_purchase = Factory(:daily_deal_purchase,
                                    :quantity => @valid_attributes[:quantity],
                                    :daily_deal => @valid_attributes[:daily_deal],
                                    :consumer => @valid_attributes[:consumer])
      DailyDealPurchase.any_instance.expects(:enqueue_email).at_least_once
      Factory(:pending_paypal_payment, :daily_deal_purchase => daily_deal_purchase)
      assert_equal 0, daily_deal_purchase.daily_deal_certificates.count
  
      ipn_params = buy_now_ipn_params("invoice" => daily_deal_purchase.analog_purchase_id, "item_number" => daily_deal_purchase.paypal_item)
      DailyDealPurchase.handle_buy_now(ipn_params)
  
      assert_equal "captured", daily_deal_purchase.reload.payment_status
      assert_equal DateTime.parse("Jan 01, 2010 12:34:56 PST"), daily_deal_purchase.executed_at
  
      assert daily_deal_purchase.daily_deal_payment.present?
      assert_equal ipn_params["txn_id"], daily_deal_purchase.payment_gateway_id
      assert_equal ipn_params["receipt_id"], daily_deal_purchase.payment_gateway_receipt_id
      assert_equal ipn_params["invoice"], daily_deal_purchase.analog_purchase_id
      assert_equal ipn_params["payer_email"], daily_deal_purchase.payer_email
      assert_equal ipn_params["payer_status"], daily_deal_purchase.payer_status
      assert daily_deal_purchase.daily_deal_certificates.count > 0, "Should have some certificates after purchase"
      assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
    end
  
    should "handle buy now with invalid payment gross" do
      DailyDealPayment.destroy_all
      (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
      daily_deal_purchase.expects(:enqueue_email).never
      ipn_params = buy_now_ipn_params(
          "invoice" => daily_deal_purchase.analog_purchase_id,
          "item_number" => daily_deal_purchase.paypal_item,
          "payment_gross" => "1.99"
      )
      assert_raise RuntimeError do
        DailyDealPurchase.handle_buy_now(ipn_params)
      end
      assert_equal "pending", daily_deal_purchase.reload.payment_status
      assert_equal 0, daily_deal_purchase.daily_deal_certificates.count, "Should not create certificates"
    end
  
    should "handle buy now with unknown invoice" do
      DailyDealPayment.destroy_all
      (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
      daily_deal_purchase.expects(:enqueue_email).never
      ipn_params = buy_now_ipn_params(
          "invoice" => "1234",
          "item_number" => daily_deal_purchase.paypal_item
      )
      assert_raise RuntimeError do
        DailyDealPurchase.handle_buy_now ipn_params
      end
      assert_equal "pending", daily_deal_purchase.reload.payment_status
      assert_equal 0, daily_deal_purchase.daily_deal_certificates.count, "Should not create certificates"
    end
  
    should "handle chargeback" do
      DailyDealPayment.destroy_all
      (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
      DailyDealPurchase.any_instance.expects(:enqueue_email).at_least_once
      Factory(:pending_paypal_payment, :daily_deal_purchase => daily_deal_purchase)
  
      ipn_params = buy_now_ipn_params("invoice" => daily_deal_purchase.analog_purchase_id, "item_number" => daily_deal_purchase.paypal_item)
      DailyDealPurchase.handle_buy_now(ipn_params)
  
      ipn_params = chargeback_ipn_params(daily_deal_purchase.reload)
  
      assert_no_difference "daily_deal_purchase.daily_deal_certificates.count" do
        DailyDealPurchase.handle_chargeback ipn_params
      end
      assert_equal "reversed", daily_deal_purchase.reload.payment_status
      assert_equal ipn_params["txn_id"], daily_deal_purchase.payment_status_updated_by_txn_id
      assert daily_deal_purchase.daily_deal_certificates.count > 0, "Should have certificates after purchase"
      assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
    end
  
    should "handle chargeback reversal" do
      DailyDealPayment.destroy_all
      (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
      DailyDealPurchase.any_instance.expects(:enqueue_email).at_least_once
      Factory(:pending_paypal_payment, :daily_deal_purchase => daily_deal_purchase)
      ipn_params = buy_now_ipn_params("invoice" => daily_deal_purchase.analog_purchase_id, "item_number" => daily_deal_purchase.paypal_item)
      DailyDealPurchase.handle_buy_now(ipn_params)
  
      daily_deal_purchase.reload.update_attributes! :payment_status => "reversed"
  
      ipn_params = chargeback_reversal_ipn_params(daily_deal_purchase)
      assert_no_difference "daily_deal_purchase.daily_deal_certificates.count" do
        DailyDealPurchase.handle_chargeback_reversal ipn_params
      end
      assert_equal "captured", daily_deal_purchase.reload.payment_status
      assert_equal ipn_params["txn_id"], daily_deal_purchase.payment_status_updated_by_txn_id
      assert daily_deal_purchase.daily_deal_certificates.count > 0, "Should have certificates after purchase"
      assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
    end
  
    should "handle refund" do
      DailyDealPayment.destroy_all
      (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
      DailyDealPurchase.any_instance.expects(:enqueue_email).at_least_once
      Factory(:pending_paypal_payment, :daily_deal_purchase => daily_deal_purchase)
      ipn_params = buy_now_ipn_params("invoice" => daily_deal_purchase.analog_purchase_id, "item_number" => daily_deal_purchase.paypal_item)
      DailyDealPurchase.handle_buy_now(ipn_params)
  
      ipn_params = refund_ipn_params(daily_deal_purchase.reload)
  
      assert_no_difference "daily_deal_purchase.daily_deal_certificates.count" do
        DailyDealPurchase.handle_refund ipn_params
      end
      assert_equal "refunded", daily_deal_purchase.reload.payment_status
      assert_equal ipn_params["txn_id"], daily_deal_purchase.payment_status_updated_by_txn_id
      assert daily_deal_purchase.daily_deal_certificates.count > 0, "Should have certificates after purchase"
      assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
    end
  
    should "handle refund location required" do
      DailyDealPayment.destroy_all
      (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
      DailyDealPurchase.any_instance.expects(:enqueue_email).at_least_once
      Factory(:pending_paypal_payment, :daily_deal_purchase => daily_deal_purchase)
      ipn_params = buy_now_ipn_params("invoice" => daily_deal_purchase.analog_purchase_id, "item_number" => daily_deal_purchase.paypal_item)
      DailyDealPurchase.handle_buy_now(ipn_params)
  
      daily_deal = daily_deal_purchase.daily_deal
      Factory(:store, :advertiser => daily_deal.advertiser)
      Factory(:store, :advertiser => daily_deal.advertiser)
      daily_deal.advertiser.stores.reload
      daily_deal.update_attributes! :location_required => true
  
      ipn_params = refund_ipn_params(daily_deal_purchase.reload)
  
      assert_no_difference "daily_deal_purchase.daily_deal_certificates.count" do
        DailyDealPurchase.handle_refund ipn_params
      end
      assert_equal "refunded", daily_deal_purchase.reload.payment_status
      assert_equal ipn_params["txn_id"], daily_deal_purchase.payment_status_updated_by_txn_id
      assert daily_deal_purchase.daily_deal_certificates.count > 0, "Should have certificates after purchase"
      assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
    end
        
  end

  fast_context "braintree actions" do
    
    setup do
      @valid_attributes = { :daily_deal => (dd = Factory(:daily_deal)), :consumer => Factory(:consumer, :publisher => dd.publisher), :quantity => 2 }
      @valid_gift_attributes = @valid_attributes.merge({
        :quantity => 2,
        :gift => true,
        :recipient_names => ["Bess Rackham", "Harry Kidd"]
      }) 
    end
    
    should "should submit for settlement" do
      daily_deal = Factory(:daily_deal)
      daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal)
      daily_deal_purchase.expects(:enqueue_email).at_least_once
      assert !daily_deal_purchase.executed?, "Test purchase should not have been executed yet"
  
      braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::Authorized)
      daily_deal_purchase.handle_braintree_sale! braintree_transaction
      assert daily_deal_purchase.executed?, "Purchase should have been executed"
      assert daily_deal_purchase.payment_gateway_id.present?, "Purchase authorization should have set transaction ID"
      assert_equal 1, daily_deal_purchase.daily_deal_certificates.count, "Should not have certificates after authorization"
      assert_not_nil daily_deal_purchase.daily_deal_payment
  
      braintree_result = braintree_transaction_submitted_result(daily_deal_purchase)
      daily_deal_purchase.daily_deal.save!
      Braintree::Transaction.expects(:submit_for_settlement).with(daily_deal_purchase.payment_gateway_id).returns(braintree_result)
      assert_equal daily_deal_purchase.id, daily_deal_purchase.daily_deal_payment.daily_deal_purchase.id
      assert daily_deal_purchase.authorized?
      assert daily_deal_purchase.reload.submit_for_settlement!, "Should return truthy when submitted"
  
      daily_deal_purchase.reload
      assert daily_deal_purchase.executed?, "Purchase should have been executed"
      assert daily_deal_purchase.captured?, "Funds should have been captured"
  
      assert_equal 1, daily_deal_purchase.daily_deal_certificates(true).count, "Should have certificates after settlement"
      assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
      daily_deal_purchase.daily_deal_certificates.each { |certificate| assert_equal daily_deal_purchase.consumer.name, certificate.redeemer_name }
    end
  
    should "submit gift for settlement" do
      daily_deal_purchase = Factory(:pending_daily_deal_purchase, @valid_gift_attributes)
      daily_deal_purchase.expects(:enqueue_email).at_least_once
      assert !daily_deal_purchase.executed?, "Test purchase should not have been executed yet"
  
      braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::Authorized)
      daily_deal_purchase.handle_braintree_sale! braintree_transaction
      assert daily_deal_purchase.executed?, "Purchase should have been executed"
      assert daily_deal_purchase.payment_gateway_id.present?, "Purchase authorization should have set transaction ID"
      assert_equal 2, daily_deal_purchase.daily_deal_certificates.count, "Should not have certificates after authorization"
  
      braintree_result = braintree_transaction_submitted_result(daily_deal_purchase)
      daily_deal_purchase.daily_deal.save!
      Braintree::Transaction.expects(:submit_for_settlement).with(daily_deal_purchase.payment_gateway_id).returns(braintree_result)
      daily_deal_purchase.reload
      assert daily_deal_purchase.submit_for_settlement!, "Should return truthy when submitted"
  
      daily_deal_purchase.reload
      assert daily_deal_purchase.executed?, "Purchase should have been executed"
      assert daily_deal_purchase.captured?, "Funds should have been captured"
  
      assert_equal 2, daily_deal_purchase.daily_deal_certificates(true).count, "Should have certificates after settlement"
      assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
      assert_equal daily_deal_purchase.recipient_names, daily_deal_purchase.daily_deal_certificates.map(&:redeemer_name)
    end
  
    should "submit for settlement with braintree error result" do
      (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
      daily_deal_purchase.expects(:enqueue_email).at_least_once
      assert !daily_deal_purchase.executed?, "Test purchase should not have been executed yet"
  
      braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::Authorized)
      daily_deal_purchase.handle_braintree_sale! braintree_transaction
      assert daily_deal_purchase.executed?, "Purchase should have been executed"
      assert daily_deal_purchase.payment_gateway_id.present?, "Purchase authorization should have set transaction ID"
      assert_equal 2, daily_deal_purchase.daily_deal_certificates.count, "Should have certificates after authorization"
  
      daily_deal_purchase.daily_deal.save!
      braintree_result = mock.tap { |result| result.stubs(:success? => false) }
      Braintree::Transaction.expects(:submit_for_settlement).with(daily_deal_purchase.payment_gateway_id).returns(braintree_result)
      assert daily_deal_purchase.submit_for_settlement!, "Should return true even when submission fails"
  
      assert !daily_deal_purchase.captured?, "Funds should not have been captured"
      assert_equal 2, daily_deal_purchase.daily_deal_certificates(true).count, "Should have certificates"
    end
  
    should "submit for settlement after capture" do
      (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
      daily_deal_purchase.expects(:enqueue_email).at_least_once
      assert !daily_deal_purchase.executed?, "Test purchase should not have been executed yet"
  
      braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
      daily_deal_purchase.handle_braintree_sale! braintree_transaction
      assert daily_deal_purchase.captured?, "Funds should have been captured"
  
      daily_deal_purchase.daily_deal.save!
      braintree_result = braintree_transaction_submitted_result(daily_deal_purchase)
      Braintree::Transaction.expects(:submit_for_settlement).with(daily_deal_purchase.payment_gateway_id).returns(braintree_result)
      assert daily_deal_purchase.submit_for_settlement!, "submitted"
  
      assert daily_deal_purchase.captured?, "Funds not still be captured"
      assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Should have created more certificates"
    end       
    
    should "toggle allow execution for voided" do
      daily_deal_purchase = Factory.build(:voided_daily_deal_purchase)

      assert_nil   daily_deal_purchase.toggle_allow_execution!
      assert_equal daily_deal_purchase.allow_execution?, false
    end
  
    should "toggle allow execution" do
      daily_deal_purchase = Factory.build(:pending_daily_deal_purchase)
      assert !daily_deal_purchase.toggle_allow_execution!, "toggle_allow_execution!"
      assert_equal daily_deal_purchase.allow_execution?, false
    end
  
    should "to param" do
      (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
      assert_match /\A[[:xdigit:]]{8}-([[:xdigit:]]{4}-){3}[[:xdigit:]]{12}\z/, daily_deal_purchase.uuid
      assert_equal daily_deal_purchase.uuid, daily_deal_purchase.to_param
    end
  
    should "execute_without_payment raises if total_price is not zero" do
      daily_deal_purchase = Factory.create(:pending_daily_deal_purchase)
      assert daily_deal_purchase.total_price > 0.0, "Fixture should have positive total price"
  
      assert_raise RuntimeError do
        daily_deal_purchase.execute_without_payment!
      end
    end     
    
  end

  test "execute_without_payment sets payment_status to captured" do
    discount = Factory(:discount, :amount => 10.00)
    daily_deal = Factory(:daily_deal, :publisher => discount.publisher, :price => 5.00)
    consumer = Factory(:consumer, :publisher => daily_deal.publisher, :activated_at => nil)
    daily_deal_purchase = Factory.build(:pending_daily_deal_purchase, {
      :daily_deal => daily_deal,
      :discount => discount,
      :quantity => 2,
      :consumer => consumer
    })
    now = Time.zone.now
    Time.zone.stubs(:now).returns(now)
  
    assert_difference 'ActionMailer::Base.deliveries.size', 1, "Should deliver purchase confirmation" do
      daily_deal_purchase.execute_without_payment!
    end
    assert_equal "captured", daily_deal_purchase.payment_status
    assert_equal now, daily_deal_purchase.executed_at
  
    assert_equal 2, daily_deal_purchase.daily_deal_certificates.count
    assert consumer.active?, "Consumer should be active after purchase"
  end
      
  test "submit_for_settlement for free purchase when already captured" do
    discount = Factory(:discount, :amount => 10.00)
    daily_deal = Factory(:daily_deal, :publisher => discount.publisher, :price => 5.00)
    daily_deal_purchase = Factory.build(:pending_daily_deal_purchase, :daily_deal => daily_deal, :discount => discount, :quantity => 2)
    now = Time.zone.now
    Time.zone.stubs(:now).returns(now)
  
    daily_deal_purchase.execute_without_payment!
    assert_equal "captured", daily_deal_purchase.payment_status
    assert_equal now, daily_deal_purchase.executed_at
  
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert !daily_deal_purchase.submit_for_settlement!, "Should return falsey when submitted"
    end
    assert daily_deal_purchase.executed?, "Purchase should have been executed"
    assert daily_deal_purchase.captured?, "Should still be marked as captured"
    assert_equal 2, daily_deal_purchase.daily_deal_certificates.count
    assert_equal now, daily_deal_purchase.executed_at
  end
  
  test "credit_used defaults to zero" do
    assert_equal 0.00, DailyDealPurchase.new.credit_used
  end
  
  test "not valid with nil credit_used" do
    daily_deal_purchase = Factory.build(:pending_daily_deal_purchase, :credit_used => nil)
    assert daily_deal_purchase.invalid?, "Should not be valid with nil credit_used"
    assert_match /is not a number/, daily_deal_purchase.errors.on(:credit_used)
  end
  
  test "not valid with non numeric credit_used" do
    daily_deal_purchase = Factory.build(:pending_daily_deal_purchase, :credit_used => "xx.xx")
    assert daily_deal_purchase.invalid?, "Should not be valid with non-numeric credit_used"
    assert_match /is not a number/, daily_deal_purchase.errors.on(:credit_used)
  end
  
  test "not valid with negative credit_used" do
    daily_deal_purchase = Factory.build(:pending_daily_deal_purchase, :credit_used => -10.00)
    assert daily_deal_purchase.invalid?, "Should not be valid with negative credit_used"
    assert_match /must be greater than or equal to 0.0/, daily_deal_purchase.errors.on(:credit_used)
  end
  
  test "synchronize redeemers on certificates" do
    purchase = Factory(:captured_daily_deal_purchase, :quantity => 3, :gift => true, :recipient_names => ["Billy Bob", "Becky Sue", "Alfonz DeMato"])
    purchase = DailyDealPurchase.find(purchase.id, :include => :daily_deal_certificates)
    assert_equal 3, purchase.daily_deal_certificates.size
    assert_equal "Billy Bob", purchase.daily_deal_certificates[0].redeemer_name
    assert_equal "Becky Sue", purchase.daily_deal_certificates[1].redeemer_name
    assert_equal "Alfonz DeMato", purchase.daily_deal_certificates[2].redeemer_name
    purchase.recipient_names = ["Henry Ford", "Axle Rose", "Miss Piggy"]
    assert_equal 3, purchase.daily_deal_certificates.size
    assert_equal "Henry Ford", purchase.daily_deal_certificates[0].redeemer_name
    assert_equal "Axle Rose", purchase.daily_deal_certificates[1].redeemer_name
    assert_equal "Miss Piggy", purchase.daily_deal_certificates[2].redeemer_name
    purchase.save!
    purchase = DailyDealPurchase.find(purchase.id, :include => :daily_deal_certificates)
    assert_equal 3, purchase.daily_deal_certificates.size
    assert_equal "Henry Ford", purchase.daily_deal_certificates[0].redeemer_name
    assert_equal "Axle Rose", purchase.daily_deal_certificates[1].redeemer_name
    assert_equal "Miss Piggy", purchase.daily_deal_certificates[2].redeemer_name
  end
  
  test "find_braintree_transaction!" do
    ddp = Factory :daily_deal_purchase
    ddp.daily_deal_payment = BraintreePayment.new(:payment_gateway_id => "test_bt_tx_id", :payment_at => Time.now)
    ddp.save!
    Braintree::Transaction.expects(:find).with("test_bt_tx_id")
    ddp.find_braintree_transaction!
  end
  
  test "find_payment_status_update_transaction!" do
    refunded_ddp = Factory :refunded_daily_deal_purchase
    refunded_ddp.payment_status_updated_by_txn_id = "test_update_txn_id"
    Braintree::Transaction.expects(:find).with("test_update_txn_id")
    refunded_ddp.find_payment_status_update_transaction!
    captured_ddp = Factory :captured_daily_deal_purchase, :payment_status_updated_by_txn_id => nil
    captured_ddp.payment_status_updated_by_txn_id = nil
    assert_nil captured_ddp.find_payment_status_update_transaction!
  end
  
  test "update sent to publisher at" do
    start_time = Time.now
    purchase1 = Factory(:captured_daily_deal_purchase)
    purchase2 = Factory(:captured_daily_deal_purchase)
    purchase3 = Factory(:captured_daily_deal_purchase)
    sent_at = Time.utc(2010, 4, 22)
    assert_nil purchase1.sent_to_publisher_at
    assert_nil purchase2.sent_to_publisher_at
    assert_nil purchase3.sent_to_publisher_at
    DailyDealPurchase.update_sent_to_publisher_at(sent_at, [purchase1.id, purchase2.id, purchase3.id])
    assert_equal sent_at, purchase1.reload.sent_to_publisher_at
    assert_equal sent_at, purchase2.reload.sent_to_publisher_at
    assert_equal sent_at, purchase3.reload.sent_to_publisher_at
  end
  
  fast_context "daily_deal_purchase ready for fake execution" do
  
    setup do
      @advertiser = Factory(:advertiser, :name => "RIDEMAKERZ®")
      @consumer = Factory(:consumer, :first_name => "José", :last_name => "Ångström", :publisher => @advertiser.publisher)
      @daily_deal = Factory(:daily_deal, :advertiser => @advertiser)
      @daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer)
      @daily_deal_purchase.braintree_fake_execution!
    end
  
    should "set payment_gateway_id to fake something" do
      assert @daily_deal_purchase.payment_gateway_id.starts_with?("fake")
    end
  
    should "set payment status to authorized" do
      assert_equal "captured", @daily_deal_purchase.payment_status
    end

    should "not raise error when consumer does not have billing address" do
      publisher = Factory(:publisher,
                            :name => "Foo",
                            :label => "foo",
                            :theme => "enhanced",
                            :production_subdomain => "sb1",
                            :launched => true,
                            :payment_method  => "credit",
                            :require_billing_address => false)
      advertiser = Factory(:advertiser, :name => "Foo", :publisher => publisher)
      consumer = Factory(:consumer, :first_name => "John", :last_name => "Doe", :publisher => publisher)
      publisher.require_billing_address = true
      publisher.save!
      daily_deal = Factory(:daily_deal, :advertiser => advertiser)
      daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer)
  
      assert_equal true, daily_deal_purchase.daily_deal_certificates.empty?
      assert_raise(ActiveRecord::RecordInvalid) { daily_deal_purchase.braintree_fake_execution! }
    end
  
  end
  
  fast_context "quantity_excluding_refunds" do
    setup do
      @daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
    end
    
    should "be same as quantity if no refunds" do
      daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => 2, :daily_deal => @daily_deal)
      assert_equal 2, daily_deal_purchase.quantity
      assert_equal 2, daily_deal_purchase.quantity_excluding_refunds
    end
        
    fast_context "partial refunds" do
      setup do
        @daily_deal_purchase = partial_refund(@daily_deal, 2, 30)
      end
      
      should "only include non-refunded" do
        assert_equal 2, @daily_deal_purchase.quantity
        assert_equal 1, @daily_deal_purchase.quantity_excluding_refunds
      end
    end
    
    fast_context "full refunds" do
      setup do
        @daily_deal_purchase = full_refund(@daily_deal, 2)
      end
      
      should "be zero" do
        assert_equal 2, @daily_deal_purchase.quantity
        assert_equal 0, @daily_deal_purchase.quantity_excluding_refunds
      end
    end
    
    fast_context "refunded but all certificates active" do
      setup do
        @daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => 2, :daily_deal => @daily_deal)
        refunded_at = @daily_deal.start_at + 6.hours
        @daily_deal_purchase.refunded_at = refunded_at
        @daily_deal_purchase.save!
        @daily_deal_purchase.reload
      end
      
      should "be zero" do
        assert_equal true, @daily_deal_purchase.refunded_with_active_certificates?
        assert_equal 2, @daily_deal_purchase.quantity
        assert_equal 0, @daily_deal_purchase.quantity_excluding_refunds
      end
    end
    
  end
  
  fast_context "refunded with active certificates" do
    setup do
      @daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
    end
    
    should "return true if refunded but all certificates active" do
      daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => 2, :daily_deal => @daily_deal)
      refunded_at = @daily_deal.start_at + 6.hours
      daily_deal_purchase.refunded_at = refunded_at
      daily_deal_purchase.save!
      daily_deal_purchase.reload
      assert_equal true, daily_deal_purchase.refunded_with_active_certificates?
    end
    
    should "return false if not refunded" do
      daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => 2, :daily_deal => @daily_deal)
      assert_equal false, daily_deal_purchase.refunded_with_active_certificates?
    end
    
    fast_context "partial refund" do      
      should "return false" do
        @daily_deal_purchase = partial_refund(@daily_deal, 2, 30)
        assert_equal false, @daily_deal_purchase.refunded_with_active_certificates?
      end
    end
    
    fast_context "full refund" do      
      should "return false" do
        @daily_deal_purchase = full_refund(@daily_deal, 2)
        assert_equal false, @daily_deal_purchase.refunded_with_active_certificates?
      end
    end
    
  end

  test "market_must_belong_to_daily_deal" do
    daily_deal = daily_deal = Factory(:daily_deal)
    market_1 = Factory(:market, :publisher => daily_deal.publisher)
    market_2 = Factory(:market, :publisher => daily_deal.publisher)
    market_3 = Factory(:market)
    daily_deal.markets << market_1
    daily_deal.markets << market_2    
    ddp = Factory.build(:daily_deal_purchase, :daily_deal => daily_deal)
    ddp.market = market_3
    assert ddp.invalid?, "Should be invalid deal with market not belonging to publisher"
    assert "#{market_3} does not belong to the daily deal #{daily_deal.value_proposition}", ddp.errors.on(:market)
  end

  fast_context "allow_purchase_for_publisher?" do
    should "deny purchase if the deal's publisher is nil" do
      deal = Factory.build(:daily_deal, :publisher => nil)
      consumer = Factory.build(:consumer)
      purchase = Factory.build(:daily_deal_purchase, :consumer => consumer, :daily_deal => deal)
      assert !purchase.send(:allow_purchase_for_publisher?)
    end
    should "deny purchase if the consumer is nil" do
      purchase = Factory.build(:daily_deal_purchase, :consumer => nil)
      assert !purchase.send(:allow_purchase_for_publisher?)
    end
    should "deny purchase if deal is nil" do
      consumer = Factory.build(:consumer)
      purchase = Factory.build(:daily_deal_purchase, :consumer => consumer, :daily_deal => nil)
      assert !purchase.send(:allow_purchase_for_publisher?)
    end
    should "deny purchase if the consumer's publisher is nil" do
      consumer = Factory.build(:consumer, :publisher => nil)
      purchase = Factory.build(:daily_deal_purchase, :consumer => consumer)
      assert !purchase.send(:allow_purchase_for_publisher?)
    end
    should "allow purchase if consumer's publisher matches daily publisher" do
      publisher = Factory.build(:publisher)
      consumer = Factory.build(:consumer, :publisher => publisher)
      deal = Factory.build(:daily_deal, :publisher => publisher)
      purchase = Factory.build(:daily_deal_purchase, :daily_deal => deal, :consumer => consumer)
      assert purchase.send(:allow_purchase_for_publisher?)
    end
    should "deny purchase if publishers are different and publishing_group does NOT allow single sign on" do
      publishing_group = Factory.build(:publishing_group, :allow_single_sign_on => false)
      publisher = Factory.build(:publisher, :publishing_group => publishing_group)
      consumer = Factory.build(:consumer)
      deal = Factory.build(:daily_deal, :publisher => publisher)
      purchase = Factory.build(:daily_deal_purchase, :daily_deal => deal, :consumer => consumer)
      assert !purchase.send(:allow_purchase_for_publisher?)
    end
    should "allow purchase if allow_single_sign_on and same pub group" do
      publishing_group = Factory.build(:publishing_group, :allow_single_sign_on => true)
      publisher = Factory.build(:publisher, :publishing_group => publishing_group)
      publishing_same_group = Factory.build(:publisher, :publishing_group => publishing_group)
      consumer = Factory.build(:consumer, :publisher => publishing_same_group)
      deal = Factory.build(:daily_deal, :publisher => publisher)
      purchase = Factory.build(:daily_deal_purchase, :daily_deal => deal, :consumer => consumer)
      assert purchase.send(:allow_purchase_for_publisher?)
    end
    should "deny purchase if allow_single_sign_on and different pub group" do
      publishing_group = Factory.build(:publishing_group, :allow_single_sign_on => true)
      publisher = Factory.build(:publisher, :publishing_group => publishing_group)
      publisher_with_different_group = Factory.build(:publisher)
      consumer = Factory.build(:consumer, :publisher => publisher_with_different_group)
      deal = Factory.build(:daily_deal, :publisher => publisher)
      purchase = Factory.build(:daily_deal_purchase, :daily_deal => deal, :consumer => consumer)
      assert !purchase.send(:allow_purchase_for_publisher?)
    end
  end
  
  fast_context "redeemable_certificates" do
    
    setup do
      publisher = Factory :publisher
      advertiser = Factory :advertiser, :publisher => publisher
      daily_deal_1 = Factory :daily_deal, :advertiser => advertiser
      daily_deal_2 = Factory :side_daily_deal, :advertiser => advertiser
      ts_daily_deal_1 = Factory :travelsavers_daily_deal, :available_for_syndication => true
      daily_deal_3 = syndicate(ts_daily_deal_1, publisher)

      @consumer = Factory :consumer, :publisher => publisher
      @ddp1 = Factory :captured_daily_deal_purchase, :daily_deal => daily_deal_1, :quantity => 2, :consumer => @consumer
      @ddp2 = Factory :captured_daily_deal_purchase, :daily_deal => daily_deal_1, :quantity => 1, :consumer => @consumer
      @ddp3 = Factory :captured_daily_deal_purchase, :daily_deal => daily_deal_2, :quantity => 2, :consumer => @consumer
      @ddp4 = Factory :travelsavers_captured_daily_deal_purchase, :daily_deal => daily_deal_3, :consumer => @consumer
      Factory :successful_travelsavers_booking, :daily_deal_purchase => @ddp4
      
      @first_voucher, @second_voucher = @ddp1.daily_deal_certificates.all(:order => "id ASC")
      @third_voucher = @ddp2.daily_deal_certificates.first
      @fourth_voucher, @fifth_voucher = @ddp3.daily_deal_certificates.all(:order => "id ASC")
      
      @first_voucher.redeem!
      @fifth_voucher.refund!
    end
    
    should "return the redeemable certificates on a group of purchases, excluding vouchers on Travelsavers related purchases" do
      assert_equal [@second_voucher, @third_voucher, @fourth_voucher], @consumer.daily_deal_purchases.redeemable_certificates
    end

  end

  fast_context "#earned_discount" do
    should "return nil when no discount points to the purchase" do
      purchase = Factory(:daily_deal_purchase)
      assert_nil Discount.find_by_daily_deal_purchase_id(purchase.id)
      assert_nil purchase.earned_discount
    end
    should "return a discount when points to the purchase" do
      purchase = Factory(:daily_deal_purchase)
      discount = Factory(:discount, :daily_deal_purchase_id => purchase.id)
      assert_equal discount, Discount.find_by_daily_deal_purchase_id(purchase.id)
      assert_equal discount, purchase.earned_discount
    end
  end

  fast_context "belongs_to :consumer" do
    should "belong to a consumer" do
      base_purchase = DailyDealPurchase.new
      consumer = Factory(:consumer)
      assert_nil base_purchase.consumer
      base_purchase.consumer = consumer
      assert_equal consumer, base_purchase.consumer
    end
    should "make sure it works for a persisted object" do
      purchase = Factory(:daily_deal_purchase)
      assert purchase.consumer.kind_of?(Consumer)
    end
  end

  fast_context "#pay_using?" do
    should "delegate to the daily deal" do
      distributed_deal = Factory.build(:distributed_daily_deal)
      purchase = Factory.build(:pending_daily_deal_purchase, :daily_deal => distributed_deal)
      purchase.daily_deal.source_publisher.payment_method = "travelsavers"
      purchase.daily_deal.publisher.payment_method = "credit"
      assert purchase.pay_using?(:travelsavers)
    end
  end

  context "#daily_deal_variation_or_daily_deal_available?" do
    setup do
      @distributed_deal = Factory.build(:distributed_daily_deal)
      @distributed_deal.source.publisher.enable_daily_deal_variations = true
    end
    should "be active because the syndicated deal is active" do
      @distributed_deal.source.update_attributes :hide_at => 5.years.ago
      @purchase = Factory.build(:pending_daily_deal_purchase, :daily_deal => @distributed_deal)
      assert @purchase.daily_deal_variation_or_daily_deal_available?
    end
    should "be not be active because the syndicated deal is not active" do
      @distributed_deal.update_attributes :hide_at => 5.years.ago
      @purchase = Factory.build(:pending_daily_deal_purchase, :daily_deal => @distributed_deal)
      assert !@purchase.daily_deal_variation_or_daily_deal_available?
    end
    should "be active because the syndicated deal is active and the variation is active" do
      @distributed_deal.source.update_attributes :hide_at => 5.years.ago
      @variation = Factory.build(:daily_deal_variation, :daily_deal =>  @distributed_deal.source)
      @purchase = Factory.build(:pending_daily_deal_purchase, :daily_deal => @distributed_deal, :daily_deal_variation => @variation)
      assert @purchase.daily_deal_variation_or_daily_deal_available?
    end
    should "not be active because the deal is sold_out!" do
      @distributed_deal.update_attributes! :sold_out_at => Time.now
      @purchase = Factory.build(:pending_daily_deal_purchase, :daily_deal => @distributed_deal)
      assert !@purchase.daily_deal_variation_or_daily_deal_available?
    end
    should "not be active because the variation is sold_out!" do
      @variation = Factory.build(:daily_deal_variation, :daily_deal =>  @distributed_deal.source)
      @variation.update_attributes! :sold_out_at => Time.now
      @purchase = Factory.build(:pending_daily_deal_purchase, :daily_deal => @distributed_deal, :daily_deal_variation => @variation)
      assert !@purchase.daily_deal_variation_or_daily_deal_available?
    end
  end
end