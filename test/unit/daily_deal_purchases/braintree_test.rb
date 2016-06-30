# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchase::BraintreeTest < ActiveSupport::TestCase
  include DailyDealPurchasesTestHelper

  def setup
    @valid_attributes = { :daily_deal => (dd = Factory(:daily_deal)), :consumer => Factory(:consumer, :publisher => dd.publisher), :quantity => 2 }
    @valid_gift_attributes = @valid_attributes.merge({
      :quantity => 2,
      :gift => true,
      :recipient_names => ["Bess Rackham", "Harry Kidd"]
    })
    ActionMailer::Base.deliveries.clear
    super
  end

  test "void Braintree purchase location required" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase)
    daily_deal = daily_deal_purchase.daily_deal
    assert !daily_deal.location_required?, "location should not be required"
    Factory(:store, :advertiser => daily_deal.advertiser)
    Factory(:store, :advertiser => daily_deal.advertiser)

    daily_deal.advertiser(true)
    daily_deal.update_attributes! :location_required => true

    Braintree::Transaction.expects(:find).returns(braintree_sale_transaction(daily_deal_purchase))
    voided_result = braintree_transaction_voided_result(daily_deal_purchase)
    Braintree::Transaction.expects(:void).with(daily_deal_purchase.payment_gateway_id).returns(voided_result)

    assert_no_difference "daily_deal_purchase.daily_deal_certificates.count" do
      daily_deal_purchase.void_or_full_refund! Factory(:admin)
    end
    assert_equal "voided", daily_deal_purchase.reload.payment_status
    assert_equal 0, daily_deal_purchase.amount
  end

  test "handle braintree sale with authorization" do
    (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!

    assert !daily_deal_purchase.executed?, "Test purchase should not have been executed yet"
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.count

    braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::Authorized)

    daily_deal_purchase.handle_braintree_sale! braintree_transaction

    assert daily_deal_purchase.executed?, "Purchase should have been executed"
    assert_equal braintree_transaction.id, daily_deal_purchase.payment_gateway_id
    assert_equal braintree_transaction.created_at, daily_deal_purchase.payment_at
    assert_equal braintree_transaction.credit_card_details.last_4, daily_deal_purchase.credit_card_last_4
    assert_equal braintree_transaction.billing_details.postal_code, daily_deal_purchase.payer_postal_code
    assert_equal braintree_transaction.id, daily_deal_purchase.payment_status_updated_by_txn_id
    assert_equal "authorized", daily_deal_purchase.payment_status
    assert_equal braintree_transaction.created_at, daily_deal_purchase.executed_at

    assert daily_deal_purchase.braintree?

    assert_equal 2, daily_deal_purchase.daily_deal_certificates.count, "Should not have certificates after authorization"
    assert_equal 1, ActionMailer::Base.deliveries.size, "Should not have sent confirmation email after authorization"
  end

  test "handle braintree sale with facebook user" do
    publisher = Factory(:publisher, :label => "villagevoicemedia")
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    facebook_consumer = Factory(:facebook_consumer, :publisher => publisher, :token => '0')

    (daily_deal_purchase = build_with_attributes(
      :daily_deal => daily_deal,
      :consumer => facebook_consumer,
      :quantity => 1,
      :post_to_facebook => 1)
    ).save!
    assert_equal "pending", daily_deal_purchase.payment_status
    braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :payment_status => 'captured')
    daily_deal_purchase.handle_braintree_sale! braintree_transaction
    assert_equal "captured", daily_deal_purchase.payment_status
    assert daily_deal_purchase.facebook_user?
    assert daily_deal_purchase.post_to_facebook?
    assert_nothing_thrown { daily_deal_purchase.stubs(:post_purchase_to_fb_wall).returns({}) }
  end

  test "handle braintree sale with capture" do
    (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
    assert !daily_deal_purchase.executed?, "Test purchase should not have been executed yet"
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.count

    braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
    daily_deal_purchase.handle_braintree_sale! braintree_transaction

    assert daily_deal_purchase.executed?, "Purchase should have been executed"
    assert_equal braintree_transaction.id, daily_deal_purchase.payment_gateway_id
    assert_equal braintree_transaction.created_at, daily_deal_purchase.payment_at
    assert_equal braintree_transaction.credit_card_details.last_4, daily_deal_purchase.credit_card_last_4
    assert_equal braintree_transaction.billing_details.postal_code, daily_deal_purchase.payer_postal_code
    assert_equal braintree_transaction.id, daily_deal_purchase.payment_status_updated_by_txn_id
    assert_equal "captured", daily_deal_purchase.payment_status
    assert_equal braintree_transaction.created_at, daily_deal_purchase.executed_at

    assert daily_deal_purchase.daily_deal_certificates.count > 0, "Should have certificates after settlement"
    assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
    daily_deal_purchase.daily_deal_certificates.each { |certificate| assert_equal daily_deal_purchase.consumer.name, certificate.redeemer_name }
    assert_equal 1, ActionMailer::Base.deliveries.size, "Should have sent confirmation email after settlement"
  end

  test "handle braintree sale with capture with store" do
    (daily_deal_purchase = build_with_attributes(@valid_attributes.merge(:store => stores(:changos)))).save!
    assert !daily_deal_purchase.executed?, "Test purchase should not have been executed yet"
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.count

    braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
    daily_deal_purchase.handle_braintree_sale! braintree_transaction

    assert daily_deal_purchase.executed?, "Purchase should have been executed"
    assert_equal braintree_transaction.id, daily_deal_purchase.payment_gateway_id
    assert_equal braintree_transaction.created_at, daily_deal_purchase.payment_at
    assert_equal braintree_transaction.credit_card_details.last_4, daily_deal_purchase.credit_card_last_4
    assert_equal braintree_transaction.billing_details.postal_code, daily_deal_purchase.payer_postal_code
    assert_equal braintree_transaction.id, daily_deal_purchase.payment_status_updated_by_txn_id
    assert_equal "captured", daily_deal_purchase.payment_status
    assert_equal braintree_transaction.created_at, daily_deal_purchase.executed_at

    assert daily_deal_purchase.daily_deal_certificates.count > 0, "Should have certificates after settlement"
    assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
    daily_deal_purchase.daily_deal_certificates.each { |certificate| assert_equal daily_deal_purchase.consumer.name, certificate.redeemer_name }
    assert_equal 1, ActionMailer::Base.deliveries.size, "Should have sent confirmation email after settlement"
  end

  test "handle braintree sale of gift with capture" do
    (daily_deal_purchase = build_with_attributes(@valid_gift_attributes)).save!
    assert !daily_deal_purchase.executed?, "Test purchase should not have been executed yet"
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.count

    braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
    daily_deal_purchase.handle_braintree_sale! braintree_transaction

    assert daily_deal_purchase.executed?, "Purchase should have been executed"
    assert_equal braintree_transaction.id, daily_deal_purchase.payment_gateway_id
    assert_equal braintree_transaction.created_at, daily_deal_purchase.payment_at
    assert_equal braintree_transaction.credit_card_details.last_4, daily_deal_purchase.credit_card_last_4
    assert_equal braintree_transaction.billing_details.postal_code, daily_deal_purchase.payer_postal_code
    assert_equal braintree_transaction.id, daily_deal_purchase.payment_status_updated_by_txn_id
    assert_equal "captured", daily_deal_purchase.payment_status
    assert_equal braintree_transaction.created_at, daily_deal_purchase.executed_at

    assert daily_deal_purchase.daily_deal_certificates.count > 0, "Should have certificates after settlement"
    assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
    assert_equal daily_deal_purchase.recipient_names, daily_deal_purchase.daily_deal_certificates.map(&:redeemer_name)
    assert_equal 1, ActionMailer::Base.deliveries.size, "Should have sent confirmation email after settlement"
  end

  test "handle braintree sale with capture with bar code" do
    (daily_deal_purchase = build_with_attributes(@valid_attributes.merge(:quantity => 2))).save!
    assert !daily_deal_purchase.executed?, "Test purchase should not have been executed yet"
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.count

    daily_deal_purchase.daily_deal.bar_codes.create! :code => "12345678"
    daily_deal_purchase.daily_deal.bar_codes.create! :code => "90abcdef"

    braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
    daily_deal_purchase.handle_braintree_sale! braintree_transaction

    assert daily_deal_purchase.executed?, "Purchase should have been executed"
    assert_equal braintree_transaction.id, daily_deal_purchase.payment_gateway_id
    assert_equal braintree_transaction.created_at, daily_deal_purchase.payment_at
    assert_equal braintree_transaction.credit_card_details.last_4, daily_deal_purchase.credit_card_last_4
    assert_equal braintree_transaction.billing_details.postal_code, daily_deal_purchase.payer_postal_code
    assert_equal braintree_transaction.id, daily_deal_purchase.payment_status_updated_by_txn_id
    assert_equal "captured", daily_deal_purchase.payment_status
    assert_equal braintree_transaction.created_at, daily_deal_purchase.executed_at
    assert_equal 2, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
    assert_equal daily_deal_purchase.consumer.name, daily_deal_purchase.daily_deal_certificates.first.redeemer_name
    assert_equal "12345678", daily_deal_purchase.daily_deal_certificates.first.bar_code
    assert_equal daily_deal_purchase.consumer.name, daily_deal_purchase.daily_deal_certificates.second.redeemer_name
    assert_equal "90abcdef", daily_deal_purchase.daily_deal_certificates.second.bar_code
    assert_equal 1, ActionMailer::Base.deliveries.size, "Should have sent confirmation email after settlement"
  end

  test "handle braintree sale with purchase credit" do
    publisher = publishers(:sdh_austin)
    deal = Factory(:daily_deal, :publisher => publisher)
    consumer = publisher.consumers.build(
      :login => "consumer",
      :email => "email@example.com",
      :name => "Iceman",
      :agree_to_terms => true
    )
    consumer.password = "secret"
    consumer.password_confirmation = "secret"
    consumer.save!

    discount = Factory(:discount, :publisher => publisher, :amount => 5.00)
    (daily_deal_purchase = build_with_attributes(@valid_attributes.merge(:daily_deal => deal, :consumer => consumer, :discount => discount))).save!
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.count

    braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :amount => 25.0)
    daily_deal_purchase.handle_braintree_sale!(braintree_transaction)

    assert_equal "captured", daily_deal_purchase.reload.payment_status
    assert_equal consumer, daily_deal_purchase.consumer(true), "Should not create new Consumer"
  end

  test "handle braintree sale twice" do
    (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
    Factory(:pending_braintree_payment, :daily_deal_purchase => daily_deal_purchase)

    assert !daily_deal_purchase.executed?, "Test purchase should not have been executed yet"
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.count

    braintree_transaction = braintree_sale_transaction(daily_deal_purchase)
    daily_deal_purchase.handle_braintree_sale! braintree_transaction
    assert daily_deal_purchase.executed?, "Purchase should have been executed"

    ActionMailer::Base.deliveries.clear
    assert_raise BraintreePurchase::AlreadyExecutedError do
      daily_deal_purchase.handle_braintree_sale! braintree_transaction
    end
    assert daily_deal_purchase.executed?, "Purchase should still be marked as executed"
    assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Should not have created more certificates"
    assert_equal 0, ActionMailer::Base.deliveries.size, "Should not have sent another email"
  end

  test "handle braintree sale with bad amount" do
    (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
    assert !daily_deal_purchase.executed?, "Test purchase should not have been executed yet"
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.count

    braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :amount => 0.5 * daily_deal_purchase.total_price)
    assert_raise RuntimeError do
      daily_deal_purchase.handle_braintree_sale! braintree_transaction
    end
    assert !daily_deal_purchase.executed?, "Purchase should not have been executed"
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.count, "Should not have created certificates"
    assert_equal 0, ActionMailer::Base.deliveries.size, "Should not have sent email"
  end

  # You can bump up the "times" to try and replicate a Ruby big decimal bug.
  test "handle braintree sale amount that can cause BigDecimal error" do
    1.times do
      price = 10.0 + rand * 100.0
      daily_deal = Factory(:daily_deal, :price => price, :value => price * 2.0)
      daily_deal_purchase = Factory(:daily_deal_purchase, :daily_deal => daily_deal)
      assert !daily_deal_purchase.executed?, "Test purchase should not have been executed yet"
      assert_equal 0, daily_deal_purchase.daily_deal_certificates.count

      braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :amount => daily_deal_purchase.total_price)
      daily_deal_purchase.handle_braintree_sale! braintree_transaction
      assert daily_deal_purchase.executed?, "Purchase should not have been executed"
      assert_equal 1, daily_deal_purchase.daily_deal_certificates.count, "Should not have created certificates"
    end
  end

  test "handle braintree sale with bad order id" do
    (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
    assert !daily_deal_purchase.executed?, "Test purchase should not have been executed yet"
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.count

    braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :order_id => "XXX")
    assert_raise RuntimeError do
      daily_deal_purchase.handle_braintree_sale! braintree_transaction
    end
    assert !daily_deal_purchase.executed?, "Purchase should not have been executed"
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.count, "Should not have created certificates"
    assert_equal 0, ActionMailer::Base.deliveries.size, "Should not have sent email"
  end

  test "handle braintree sale with bad transaction type" do
    (daily_deal_purchase = build_with_attributes(@valid_attributes)).save!
    assert !daily_deal_purchase.executed?, "Test purchase should not have been executed yet"
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.count

    braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :type => "credit")
    assert_raise RuntimeError do
      daily_deal_purchase.handle_braintree_sale! braintree_transaction
    end
    assert !daily_deal_purchase.executed?, "Purchase should not have been executed"
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.count, "Should not have created certificates"
    assert_equal 0, ActionMailer::Base.deliveries.size, "Should not have sent email"
  end
end
