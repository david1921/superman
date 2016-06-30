require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealOrderTest < ActiveSupport::TestCase
  
  fast_context "adding two items to a cart using the same discount code" do
    
    setup do
      @publisher = Factory :publisher
      @advertiser = Factory :advertiser, :publisher => @publisher
      @daily_deal_1 = Factory :daily_deal, :advertiser => @advertiser, :price => 0, :min_quantity => 1, :value => 20
      @daily_deal_2 = Factory :side_daily_deal, :advertiser => @advertiser, :price => 10, :value => 30
      @discount = Factory :discount, :publisher => @publisher, :code => "TENBUCKS", :amount => 10
      @order = Factory :daily_deal_order
    end
    
    should "be invalid" do
      purchase_1 = Factory :daily_deal_purchase, :daily_deal => @daily_deal_1, :discount => @discount, :daily_deal_order => @order
      purchase_2 = Factory.build :daily_deal_purchase, :daily_deal => @daily_deal_2, :discount => @discount, :daily_deal_order => @order
      assert purchase_2.invalid?
      assert_equal ["discount 'TENBUCKS' has already been applied to another item in this cart"], purchase_2.errors.full_messages
    end
    
  end
  
  test "create" do
    assert !DailyDealOrder.create.valid?, "not valid without consumer"
    consumer = Factory(:consumer)
    daily_deal_order = DailyDealOrder.create(:consumer => consumer)
    assert daily_deal_order.valid?, "valid with consumer"
    assert_equal [ daily_deal_order ], consumer.daily_deal_orders, "consumer.daily_deal_orders"
  end
  
  test "payment_gateway_id is unique" do
    assert DailyDealOrder.create(:payment_gateway_id => 1233, :consumer => Factory(:consumer)).valid?
    assert !DailyDealOrder.create(:payment_gateway_id => 1233, :consumer => Factory(:consumer)).valid?

    # Different consumers
    assert DailyDealOrder.create(:payment_gateway_id => nil, :consumer => Factory(:consumer)).valid?
    assert DailyDealOrder.create(:payment_gateway_id => nil, :consumer => Factory(:consumer)).valid?
  end
  
  test "analog_purchase_id" do
    daily_deal_order = Factory(:daily_deal_order)
    assert_equal "#{daily_deal_order.id}-DDO", daily_deal_order.analog_purchase_id
  end
  
  test "empty total_price" do
    daily_deal_order = Factory(:daily_deal_order)
    assert_equal 0, daily_deal_order.total_price
  end
  
  test "single purchase total_price" do
    daily_deal_order = Factory(:daily_deal_order)
    daily_deal_purchase = Factory(:daily_deal_purchase)
    daily_deal_order.daily_deal_purchases << daily_deal_purchase
    assert_equal daily_deal_purchase.price, daily_deal_order.total_price
  end
  
  test "many purchases total_price" do
    daily_deal_order = Factory(:daily_deal_order)

    daily_deal = Factory(:daily_deal, :price => 15)
    daily_deal_order.daily_deal_purchases << Factory(:daily_deal_purchase, :daily_deal => daily_deal)

    daily_deal = Factory(:daily_deal, :price => 20)
    daily_deal_order.daily_deal_purchases << Factory(:daily_deal_purchase, :daily_deal => daily_deal)

    assert_equal 35, daily_deal_order.total_price
  end
  
  test "total_value" do
    daily_deal_order = Factory(:daily_deal_order)

    daily_deal = Factory(:daily_deal, :price => 15, :value => 24)
    daily_deal_order.daily_deal_purchases << Factory(:daily_deal_purchase, :daily_deal => daily_deal)

    daily_deal = Factory(:daily_deal, :price => 20, :value => 99)
    daily_deal_order.daily_deal_purchases << Factory(:daily_deal_purchase, :daily_deal => daily_deal)

    assert_equal 123, daily_deal_order.total_value
  end
  
  test "quantity" do
    daily_deal_order = Factory(:daily_deal_order)

    daily_deal = Factory(:daily_deal, :price => 15, :value => 24)
    daily_deal_order.daily_deal_purchases << Factory(:daily_deal_purchase, :daily_deal => daily_deal)

    daily_deal = Factory(:daily_deal, :price => 20, :value => 99)
    daily_deal_order.daily_deal_purchases << Factory(:daily_deal_purchase, :daily_deal => daily_deal, :quantity => 2)

    assert_equal 3, daily_deal_order.quantity
  end
  
  test "publisher" do
    consumer = Factory(:consumer)
    daily_deal_order = DailyDealOrder.create(:consumer => consumer)
    assert_equal daily_deal_order.publisher, consumer.publisher, "publisher"
  end
  
  test "to_param" do
    daily_deal_order = Factory(:daily_deal_order)
    assert_equal daily_deal_order.uuid, daily_deal_order.to_param
  end
  
  test "payment_status" do
    daily_deal_order = Factory(:daily_deal_order)
    assert_equal "pending", daily_deal_order.payment_status, "payment_status"
    assert_equal false, daily_deal_order.executed?
  end
  
  test "handle_braintree_sale!" do
    ActionMailer::Base.deliveries.clear
    daily_deal_order = Factory(:daily_deal_order)

    daily_deal = Factory(:daily_deal, :price => 15)
    daily_deal_purchase = Factory(:daily_deal_purchase, :daily_deal => daily_deal)
    daily_deal_order.daily_deal_purchases << daily_deal_purchase
    
    assert !daily_deal_purchase.executed?, "purchase should not have been executed yet"
    assert_equal 0, daily_deal_purchase.daily_deal_certificates(true).count

    braintree_transaction = braintree_sale_transaction(daily_deal_order, :status => Braintree::Transaction::Status::SubmittedForSettlement)
    daily_deal_order.handle_braintree_sale! braintree_transaction

    daily_deal_purchase.reload
    daily_deal_order.reload
    assert daily_deal_purchase.executed?, "Purchase should have been executed"
    assert daily_deal_order.executed?, "Order should have been executed"
    assert_equal braintree_transaction.id, daily_deal_purchase.payment_gateway_id
    assert_equal braintree_transaction.id, daily_deal_order.payment_gateway_id
    assert_equal_date_times braintree_transaction.created_at, daily_deal_purchase.payment_at
    assert_equal braintree_transaction.credit_card_details.last_4, daily_deal_purchase.credit_card_last_4
    assert_equal braintree_transaction.billing_details.postal_code, daily_deal_purchase.payer_postal_code
    assert_equal braintree_transaction.id, daily_deal_purchase.payment_status_updated_by_txn_id
    assert_equal "captured", daily_deal_purchase.payment_status
    assert_equal_date_times braintree_transaction.created_at, daily_deal_purchase.executed_at
  
    assert daily_deal_purchase.daily_deal_certificates(true).count > 0, "Should have certificates after settlement"
    assert_equal daily_deal_purchase.quantity, daily_deal_purchase.daily_deal_certificates.count, "Certificate count"
    daily_deal_purchase.daily_deal_certificates.each { |certificate| assert_equal daily_deal_purchase.consumer.name, certificate.redeemer_name }
    assert_equal true, daily_deal_order.executed?, "Order should have been executed"
    assert_equal 1, ActionMailer::Base.deliveries.size, "Should have sent confirmation email after settlement"
  end
  
  context "pending order with several purchases" do
    setup do
      @daily_deal_order = Factory(:daily_deal_order)
      consumer = @daily_deal_order.consumer
      @publisher = consumer.publisher

      daily_deal = Factory(:daily_deal, :publisher => @publisher, :start_at => "July 01, 2010 00:00:00", :hide_at => "July 03, 2010 23:55:00", :quantity => 1)
      @daily_deal_order.daily_deal_purchases << (@daily_deal_purchase_1 = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer))
      
      daily_deal = Factory(:daily_deal, :publisher => @publisher, :start_at => "July 02, 2010 00:00:00", :hide_at => "July 04, 2010 23:55:00", :quantity => 1)
      @daily_deal_order.daily_deal_purchases << (@daily_deal_purchase_2 = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer))
      
      assert_equal "pending", @daily_deal_order.payment_status
      assert_equal "pending", @daily_deal_order.daily_deal_purchases.first.payment_status
      assert_equal "pending", @daily_deal_order.daily_deal_purchases.second.payment_status
    end
    
    should "on payment capture, should mark all the daily deal purchases as captured" do
      braintree_transaction = braintree_sale_transaction(@daily_deal_order, :status => Braintree::Transaction::Status::SubmittedForSettlement)
      @daily_deal_order.handle_braintree_sale! braintree_transaction
      
      assert_equal 2, @daily_deal_order.daily_deal_purchases.size
      assert_equal "captured", @daily_deal_order.payment_status
      assert_equal "captured", @daily_deal_order.daily_deal_purchases.first.payment_status
      assert_equal "captured", @daily_deal_order.daily_deal_purchases.second.payment_status
    end
    
    should "on payment capture, duplicate discount code should only be captured once" do
      discount = Factory(:discount, :publisher => @publisher)
      @daily_deal_order.daily_deal_purchases.each{|ddp| ddp.update_attribute(:discount_id, discount.id)}
      
      braintree_transaction = braintree_sale_transaction(@daily_deal_order, :status => Braintree::Transaction::Status::SubmittedForSettlement)
      @daily_deal_order.handle_braintree_sale! braintree_transaction      
      
      assert_equal 2, @daily_deal_order.daily_deal_purchases.size
      assert_equal "captured", @daily_deal_order.payment_status
      assert_equal "captured", @daily_deal_order.daily_deal_purchases.first.payment_status
      assert_equal "captured", @daily_deal_order.daily_deal_purchases.second.payment_status
    end
    
    should "not remove any purchases in cleanse if all purchases are available" do
      Timecop.freeze(Time.zone.parse("July 03, 2010 12:34:56")) do
        assert_equal @daily_deal_order, @daily_deal_order.cleanse!
        assert_equal [@daily_deal_purchase_1, @daily_deal_purchase_2].map(&:id).sort, @daily_deal_order.daily_deal_purchase_ids.sort
      end
    end

    should "remove a purchase in cleanse if the daily deal is sold out" do
      Timecop.freeze(Time.zone.parse("July 03, 2010 12:34:56")) do
        Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal_purchase_2.daily_deal)
        
        assert_equal @daily_deal_order, @daily_deal_order.cleanse!
        assert_equal [@daily_deal_purchase_1].map(&:id).sort, @daily_deal_order.daily_deal_purchase_ids.sort
      end
    end

    should "remove a purchase in cleanse if the daily deal is no longer active" do
      Timecop.freeze(Time.zone.parse("July 04, 2010 12:34:56")) do
        assert_equal @daily_deal_order, @daily_deal_order.cleanse!
        assert_equal [@daily_deal_purchase_2].map(&:id).sort, @daily_deal_order.daily_deal_purchase_ids.sort
      end
    end

    should "not remove any purchases in cleanse if the order has been executed" do
      Timecop.freeze(Time.zone.parse("July 04, 2010 12:34:56")) do
        Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal_purchase_2.daily_deal)
        @daily_deal_order.update_attributes! :payment_status => "captured"
        
        assert_equal @daily_deal_order, @daily_deal_order.cleanse!
        assert_equal [@daily_deal_purchase_1, @daily_deal_purchase_2].map(&:id).sort, @daily_deal_order.daily_deal_purchase_ids.sort
      end
    end
  end
end
