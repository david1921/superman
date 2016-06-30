require File.dirname(__FILE__) + "/../test_helper"

class DailyDealOrdersTest < ActionController::IntegrationTest
  test "purchase two deals" do
    publisher = Factory(:publisher, :shopping_cart => true)
    advertiser = Factory(:advertiser, :publisher => publisher)
    deal1 = Factory(:daily_deal, :publisher => publisher, :advertiser => advertiser)
    assert deal1.valid?
    deal2 = Factory(:side_daily_deal, :publisher => publisher, :advertiser => advertiser)
    assert deal2.valid?
    consumer = Factory(:consumer, :publisher => publisher, :password => "mickey", :password_confirmation => "mickey")

    # Sign in this time
    post publisher_daily_deal_sessions_path(publisher),
      :session => {
        :email => consumer.email,
        :password => "mickey"
      }
    assert_response :redirect
    assert_not_nil session[:user_id], "session :user_id"

    get public_deal_of_day_path(publisher.label)
    assert_response :success
    assert_add_to_cart deal1
    get daily_deals_public_index_path(publisher.label)
    assert_response :success
    assert_add_to_cart deal2

    assert_equal 2, consumer.daily_deal_purchases.size

    assert_equal 1, consumer.reload.daily_deal_orders.size
    daily_deal_order = consumer.daily_deal_orders.first

    transaction = braintree_transaction_submitted_result(daily_deal_order)
    transaction.transaction.expects(:id).at_least_once.returns("1")
    Braintree::TransparentRedirect.expects(:confirm).returns(transaction)

    get braintree_redirect_daily_deal_order_path(:id => daily_deal_order.to_param),
        :kind => "create_transaction",
        :hash => "c7520d7b430f03a767834f221a749a33776aa442",
        :http_status => "200"

    assert_response :redirect
    assert_redirected_to thank_you_daily_deal_order_path(daily_deal_order)
    assert_equal 2, daily_deal_order.reload.daily_deal_purchases.size
    assert_equal_arrays(consumer.daily_deal_purchases, daily_deal_order.daily_deal_purchases)
    assert_equal 30, daily_deal_order.total_price.to_f, "order total price"
    consumer.daily_deal_purchases(true).each do |purchase|
      assert_equal "captured", purchase.payment_status, "#{purchase.id}"
      assert_not_nil purchase.daily_deal_payment, "Should have payment"
      assert_equal 15, purchase.daily_deal_payment.amount.to_f, "amounts should match"
    end
    
    get thank_you_daily_deal_order_path(:id => daily_deal_order.to_param)
    assert_response :success
  end

  test "remove purchase from cart" do
    @publisher = Factory(:publisher, :shopping_cart => true)
    @advertiser = Factory(:advertiser, :publisher => @publisher)
    @deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
    @consumer = Factory(:consumer, :publisher => @publisher, :password => "mickey", :password_confirmation => "mickey")
    @order = Factory(:daily_deal_order, :consumer => @consumer)
    # @request.session[:daily_deal_order] = @order

    @daily_deal_purchase = Factory(:daily_deal_purchase, :daily_deal => @deal, :consumer => @consumer)

    @order.daily_deal_purchases << @daily_deal_purchase

    post publisher_daily_deal_sessions_path(@publisher),
      :session => {
        :email => @consumer.email,
        :password => @consumer.password
      }
    assert_response :redirect
    assert_not_nil session[:user_id], "session :user_id"

    assert_equal 1, @order.daily_deal_purchases.count

    delete publisher_daily_deal_purchase_path(@publisher, @daily_deal_purchase),
      :session => session.merge(:daily_deal_order => @order)

    assert_equal 0, @order.daily_deal_purchases.count
    assert_equal nil, DailyDealPurchase.find_by_id(@daily_deal_purchase.id)
  end

  def assert_add_to_cart(deal)
    # This proper REST route here is not entirely clear here. I've made some best guesses.
    # We want to use the existing new purchase page, but use DailyDealOrdersController for later pages.
    get new_daily_deal_daily_deal_purchase_path deal
    assert_response :success
    # If we use daily_deal_orders_path, we may need to dupe logic
    # If we use daily_deal_daily_deal_purchases_path, we need to add some logic to add the purchase to the order and redirect to somewhere else
    post daily_deal_daily_deal_purchases_path(deal), :daily_deal_purchase => {
            :quantity => "1",
            :gift => "0"
    }
    assert_not_nil(daily_deal_order = assigns(:daily_deal_order), "Assignment of @daily_deal_order")
    assert_redirected_to publisher_cart_path(daily_deal_order.consumer.publisher.label)
  end
end
