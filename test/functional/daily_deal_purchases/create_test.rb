# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::CreateTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper
  include Application::PasswordReset

  test "create with active consumer" do
    daily_deal = Factory(:daily_deal)
    consumer = Factory(:consumer, :publisher => daily_deal.publisher)

    assert_difference "DailyDealPurchase.count" do
      post_create_with_consumer_params(
        daily_deal,
        :name => "JP",
        :email => consumer.email,
        :password => "monkey",
        :password_confirmation => "monkey",
        :agree_to_terms => "1"
      )
      daily_deal_purchase = assigns(:daily_deal_purchase)
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)

      assert_equal consumer, daily_deal_purchase.consumer
      assert_equal nil, daily_deal_purchase.market
      assert_not_nil daily_deal_purchase.ip_address
      assert_equal consumer.id, session[:user_id], "Consumer should be logged in"
      assert_equal "John Public", consumer.reload.name, "Consumer name should not change"
      assert consumer.active?, "New consumer should still be active"
    end
  end

  test "create purchase with publisher that uses a shopping cart" do
    publisher = Factory(:publisher, :shopping_cart => true)
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :publisher => publisher, :advertiser => advertiser)
    consumer = Factory(:consumer, :publisher => publisher, :password => "mickey", :password_confirmation => "mickey")
    login_as consumer
    post :create, :daily_deal_id => daily_deal.to_param, :daily_deal_purchase => { :quantity => 1, :gift => "0"}
    assert_redirected_to publisher_cart_path(publisher.label)
    assert_equal 1, consumer.daily_deal_purchases.size
    assert_equal 1, consumer.daily_deal_orders.size
    assert_equal consumer.daily_deal_orders.first.daily_deal_purchases, consumer.daily_deal_purchases,
                 "the new order's purchases should be the same as the consumer's daily deal purchases"
  end

  test "create with active consumer and bad password" do
    daily_deal = Factory(:daily_deal)
    consumer = Factory(:consumer, :publisher => daily_deal.publisher)

    assert_no_difference "DailyDealPurchase.count" do
      post_create_with_consumer_params(
        daily_deal,
        :name => "JP",
        :email => consumer.email,
        :password => "simian",
        :password_confirmation => "simian",
        :agree_to_terms => "1"
      )
      assert_response :success
      assert_match(/account already exists/, flash[:warn])
      assert_template :new
      assert_nil session[:user_id], "Consumer should not be logged in"
      assert_equal "John Public", consumer.reload.name, "Consumer name should not change"
      assert consumer.active?, "New consumer should still be active"
    end
  end

  test "create with active consumer and forced password reset" do
    daily_deal = Factory(:daily_deal)
    consumer = Factory(:consumer, :publisher => daily_deal.publisher, :force_password_reset => true)

    assert_no_difference "DailyDealPurchase.count" do
      post_create_with_consumer_params(
        daily_deal,
        :name => "JP",
        :email => consumer.email,
        :password => "simian",
        :password_confirmation => "simian",
        :agree_to_terms => "1"
      )
      assert_match(/must.*reset/, flash[:warn])
      assert_redirected_to consumer_password_reset_path_or_url(daily_deal.publisher)
      assert_nil session[:user_id], "Consumer should not be logged in"
    end
  end

  test "create with inactive consumer" do
    daily_deal = Factory(:daily_deal)
    discount = Factory(:discount, :publisher => daily_deal.publisher, :amount => 10.00)
    consumer = Factory(:consumer, {
      :publisher => daily_deal.publisher,
      :discount_code => discount.code,
      :activated_at => nil,
      :activation_code => nil
    })
    assert !consumer.active?, "Consumer fixture should not be active"

    assert_difference "DailyDealPurchase.count" do
      post_create_with_consumer_params(
        daily_deal,
        :name => "Joseph Blow",
        :email => consumer.email,
        :password => "simian",
        :password_confirmation => "simian",
        :agree_to_terms => "1"
      )
      daily_deal_purchase = assigns(:daily_deal_purchase)
      assert_not_nil daily_deal_purchase, "Assignment of daily_deal_purchase"
      assert_equal discount, daily_deal_purchase.discount
      assert_equal daily_deal.price - 10.0, daily_deal_purchase.total_price

      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)
      assert_match(/deal credit has been applied/i, flash[:notice])

      consumer = daily_deal_purchase.consumer
      assert_not_nil consumer, "Daily deal purchase should have a consumer"
      assert_nil session[:user_id], "Consumer should not be logged in"

      assert_equal daily_deal.publisher, consumer.publisher, "New consumer should belong to daily-deal publisher"
      assert_equal "Joseph Blow", consumer.name
      assert_equal consumer.email, consumer.email
      assert !consumer.active?, "New consumer should not be active before purchase is complete"
    end
  end

  test "create with new consumer" do
    daily_deal = Factory(:daily_deal)
    assert_difference "DailyDealPurchase.count" do
      post_create_with_consumer_params(
        daily_deal,
        :name => "Joseph Blow",
        :email => "joe@blow.com",
        :password => "secret",
        :password_confirmation => "secret",
        :agree_to_terms => "1"
      )
      daily_deal_purchase = assigns(:daily_deal_purchase)
      assert_not_nil daily_deal_purchase, "Assignment of daily_deal_purchase"
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)

      consumer = daily_deal_purchase.consumer
      assert_not_nil consumer, "Daily deal purchase should have a consumer"
      assert_nil session[:user_id], "Consumer should not be logged in"

      assert_equal daily_deal.publisher, consumer.publisher, "New consumer should belong to daily-deal publisher"
      assert_equal nil, daily_deal_purchase.market
      assert_not_nil daily_deal_purchase.ip_address
      assert_equal "Joseph Blow", consumer.name
      assert_equal "joe@blow.com", consumer.email
      assert !consumer.active?, "New consumer should not be active before purchase is complete"
    end
  end

  test "currency code display when creating consumer with signup discount in USD" do
    discount = Factory :discount, :code => "TEST123", :amount => 3
    discount.publisher.update_attributes :currency_code => "USD"
    daily_deal = Factory :daily_deal, :publisher_id => discount.publisher.id

    post_create_with_consumer_params(
      daily_deal,
      { :name => "Joseph Blow",
        :email => "joe@blow.com",
        :password => "secret",
        :password_confirmation => "secret",
        :agree_to_terms => "1" },
      { :discount_code => "TEST123" }
    )

    assert_redirected_to confirm_daily_deal_purchase_path(assigns(:daily_deal_purchase))
    assert_match %r{\$\d+\.\d+ deal credit has been applied}i, flash[:notice]
  end

  test "currency code display when creating consumer with signup discount in GBP" do
    discount = Factory :discount, :code => "TEST123", :amount => 3
    discount.publisher.update_attributes :currency_code => "GBP"
    daily_deal = Factory :daily_deal, :publisher_id => discount.publisher.id

    post_create_with_consumer_params(
      daily_deal,
      { :name => "Joseph Blow",
        :email => "joe@blow.com",
        :password => "secret",
        :password_confirmation => "secret",
        :agree_to_terms => "1" },
      { :discount_code => "TEST123" }
    )

    assert_redirected_to confirm_daily_deal_purchase_path(assigns(:daily_deal_purchase))
    assert_match %r{\£\d+\.\d+ deal credit has been applied}i, flash[:notice]
  end

  test "currency code display when creating consumer with signup discount in CAD" do
    discount = Factory :discount, :code => "TEST123", :amount => 3
    discount.publisher.update_attributes :currency_code => "CAD"
    daily_deal = Factory :daily_deal, :publisher_id => discount.publisher.id

    post_create_with_consumer_params(
      daily_deal,
      { :name => "Joseph Blow",
        :email => "joe@blow.com",
        :password => "secret",
        :password_confirmation => "secret",
        :agree_to_terms => "1" },
      { :discount_code => "TEST123" }
    )

    assert_redirected_to confirm_daily_deal_purchase_path(assigns(:daily_deal_purchase))
    assert_match %r{C\$\d+\.\d+ deal credit has been applied}i, flash[:notice]
  end

  test "create with store id" do
    advertiser = Factory(:store).advertiser
    store = advertiser.stores.create!(
      :address_line_1 => "123 Main Street",
      :address_line_2 => "Suite 4",
      :city => "Hicksville",
      :state => "NY",
      :zip => "11801"
    )
    daily_deal = Factory(:daily_deal, :advertiser => advertiser, :location_required => true)

    assert_difference "DailyDealPurchase.count" do
      post :create,
           :daily_deal_id => daily_deal.to_param,
           :consumer => {
             :name => "Joseph Blow",
             :email => "joe@blow.com",
             :password => "secret",
             :password_confirmation => "secret",
             :agree_to_terms => "1"
           },
           :daily_deal_purchase => { :quantity => "1", :gift => "0", :store_id => store.to_param }

      daily_deal_purchase = assigns(:daily_deal_purchase)
      assert_not_nil daily_deal_purchase, "Assignment of daily_deal_purchase"
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)

      consumer = daily_deal_purchase.consumer
      assert_not_nil consumer, "Daily deal purchase should have a consumer"
      assert_nil session[:user_id], "Consumer should not be logged in"

      assert_equal daily_deal.publisher, consumer.publisher, "New consumer should belong to daily-deal publisher"
      assert_equal "Joseph Blow", consumer.name
      assert_equal "joe@blow.com", consumer.email
      assert !consumer.active?, "New consumer should not be active before purchase is complete"

      daily_deal_purchase = DailyDealPurchase.find(daily_deal_purchase.id)
      assert_equal 1, daily_deal_purchase.quantity, "quantity"
      assert_equal false, daily_deal_purchase.gift?, "gift?"
      assert_equal store, daily_deal_purchase.store(true), "Should set store"
    end
  end

  test "create as logged in consumer" do
    daily_deal = Factory(:daily_deal)
    consumer = Factory(:consumer, :publisher => daily_deal.publisher)

    assert_difference "DailyDealPurchase.count" do
      login_as consumer
      post_create_with_consumer_params daily_deal

      daily_deal_purchase = assigns(:daily_deal_purchase)
      assert_no_errors daily_deal_purchase
      assert !daily_deal_purchase.new_record?, "Should have saved new purchase"
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)

      assert_equal consumer, daily_deal_purchase.consumer
      assert_equal nil, daily_deal_purchase.market
      assert_equal consumer.id, session[:user_id], "Consumer should still be logged in"
      assert daily_deal_purchase.consumer.active?, "Existing consumer should still be active"
    end
  end

  test "create as new consumer with referral_code cookie" do
    daily_deal = Factory(:daily_deal)

    @request.cookies["referral_code"] = "abcd1234"
    assert_difference 'DailyDealPurchase.count' do
      post :create, :daily_deal_id => daily_deal.to_param, :consumer => {
        :name => "Joseph Blow",
        :email => "joe@blow.com",
        :password => "secret",
        :password_confirmation => "secret",
        :agree_to_terms => "1"
      },
      :daily_deal_purchase => { :quantity => "1", :gift => "0" }
    end
    daily_deal_purchase = assigns(:daily_deal_purchase)
    assert_not_nil daily_deal_purchase, "Assignment of @daily_deal_purchase"

    consumer = daily_deal_purchase.consumer
    assert_not_nil consumer, "Daily deal purchase should have a consumer"
    assert_equal "abcd1234", consumer.referral_code
    assert !consumer.changed.include?("referral_code"), "Referral code should have been saved"
    assert_nil session[:user_id], "Consumer should not be logged in"

    assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)
  end

  test "create as new consumer with ref cookie" do
    daily_deal = Factory(:daily_deal)

    @request.cookies["ref"] = "12345"
    assert_difference 'DailyDealPurchase.count' do
      post :create, :daily_deal_id => daily_deal.to_param, :consumer => {
        :name => "Joseph Blow",
        :email => "joe@blow.com",
        :password => "secret",
        :password_confirmation => "secret",
        :agree_to_terms => "1"
      },
      :daily_deal_purchase => { :quantity => "1", :gift => "0" }
    end
    daily_deal_purchase = assigns(:daily_deal_purchase)
    assert_not_nil daily_deal_purchase, "Assignment of @daily_deal_purchase"

    consumer = daily_deal_purchase.consumer
    assert_not_nil consumer, "Daily deal purchase should have a consumer"
    assert_equal "12345", daily_deal_purchase.visitors_referring_id
    assert_nil session[:user_id], "Consumer should not be logged in"

    assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)
  end

  test "create as new consumer with device and user_agent" do
    daily_deal = Factory(:daily_deal)

    @request.env["HTTP_USER_AGENT"] = "Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)"
    assert_difference 'DailyDealPurchase.count' do
      post :create, :daily_deal_id => daily_deal.to_param, :consumer => {
        :name => "Joseph Blow",
        :email => "joe@blow.com",
        :password => "secret",
        :password_confirmation => "secret",
        :agree_to_terms => "1",
        :device => "tablet"
      },
      :daily_deal_purchase => { :quantity => "1", :gift => "0" }
    end
    daily_deal_purchase = assigns(:daily_deal_purchase)
    assert_not_nil daily_deal_purchase, "Assignment of @daily_deal_purchase"

    consumer = daily_deal_purchase.consumer
    assert_not_nil consumer, "Daily deal purchase should have a consumer"
    assert_equal 'tablet', consumer.device
    assert_equal 'Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)', consumer.user_agent
  end

  test "create a new consumer for publisher with optimal payment method" do
    daily_deal = Factory(:daily_deal)
    daily_deal.publisher.update_attribute(:payment_method, 'optimal')
    assert daily_deal.publisher.pay_using?( :optimal )

    assert_difference 'DailyDealPurchase.count' do
      post :create, :daily_deal_id => daily_deal.to_param, :consumer => {
        :name => "Joseph Blow",
        :email => "joe@blow.com",
        :password => "secret",
        :password_confirmation => "secret",
        :agree_to_terms => "1",
        :device => "tablet"
      },
      :daily_deal_purchase => { :quantity => "1", :gift => "0" }
    end
    daily_deal_purchase = assigns(:daily_deal_purchase)

    assert_redirected_to optimal_confirm_daily_deal_purchase_path(daily_deal_purchase)
  end

  test "set DailyDealPurchase#actual_purchase_price and #gross_price when the DDP is created" do
    daily_deal = Factory(:daily_deal, :price => 15, :value => 40)
    daily_deal.publisher.update_attribute(:payment_method, 'optimal')
    assert daily_deal.publisher.pay_using?(:optimal)

    assert_difference 'DailyDealPurchase.count' do
      post :create, :daily_deal_id => daily_deal.to_param, :consumer => {
        :name => "Joseph Blow",
        :email => "joe@blow.com",
        :password => "secret",
        :password_confirmation => "secret",
        :agree_to_terms => "1",
        :device => "tablet"
      },
      :daily_deal_purchase => { :quantity => "1", :gift => "0" }
    end
    daily_deal_purchase = assigns(:daily_deal_purchase)
    assert_equal 15, daily_deal_purchase.gross_price
    assert_equal 15, daily_deal_purchase.actual_purchase_price
  end

  test "first create with shopping cart publisher adds purchase to pending order" do
    publisher = Factory(:publisher, :shopping_cart => true)
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :price => 15, :value => 40, :advertiser => advertiser)

    assert_difference 'DailyDealPurchase.count' do
      post :create, :daily_deal_id => daily_deal.to_param, :consumer => {
        :name => "Joseph Blow",
        :email => "joe@blow.com",
        :password => "secret",
        :password_confirmation => "secret",
        :agree_to_terms => "1",
        :device => "tablet"
      },
      :daily_deal_purchase => { :quantity => "1", :gift => "0" }
    end

    daily_deal_purchase = assigns(:daily_deal_purchase)
    assert_not_nil daily_deal_purchase, "@daily_deal_purchase"

    daily_deal_order = assigns(:daily_deal_order)
    assert_not_nil daily_deal_order, "@daily_deal_order"

    assert_equal daily_deal_order, daily_deal_purchase.daily_deal_order, "Should associate purchase with order"
    assert daily_deal_order.pending?

    assert_equal daily_deal_order.uuid, session[:daily_deal_order]
    assert_redirected_to publisher_cart_path(publisher.label)
  end

  test "invalid create for a publisher with optimal payment method" do
    daily_deal = Factory(:daily_deal)
    daily_deal.publisher.update_attribute(:payment_method, 'optimal')
    assert daily_deal.publisher.pay_using?( :optimal )

    assert_no_difference 'DailyDealPurchase.count' do
      post :create, :daily_deal_id => daily_deal.to_param, :consumer => {
        :name => "Joseph Blow",
        :email => "joe@blow.com",
        :password => "",
        :password_confirmation => "",
        :agree_to_terms => "1",
        :device => "tablet"
      },
      :daily_deal_purchase => { :quantity => "1", :gift => "0" }
    end

    assert_response :success
    assert_template :optimal
    assert_layout   :optimal

  end

  # test for exception: https://www.getexceptional.com/exceptions/8033468
  test "create with a blank quantity" do
    daily_deal = Factory(:daily_deal)

    assert_no_difference 'DailyDealPurchase.count' do
      post :create, :daily_deal_id => daily_deal.to_param, :consumer => {
        :name => "Joseph Blow",
        :email => "joe@blow.com",
        :password => "password",
        :password_confirmation => "password",
        :agree_to_terms => "1"
      },
      :daily_deal_purchase => { :quantity => "", :gift => "0" }
    end

    assert_response :success

  end

  test "shipping info post create" do
    daily_deal = Factory(:daily_deal, :requires_shipping_address => true)

    assert_difference 'DailyDealPurchase.count' do
      post :create,
           :daily_deal_id => daily_deal.to_param,
           :consumer => {
             :name => "Joseph Blow",
             :email => "joe@blow.com",
             :password => "secret",
             :password_confirmation => "secret",
             :agree_to_terms => "1"
          },
          :daily_deal_purchase => {
            :quantity => "1",
            :gift => "0",
            :recipients_attributes => {
              "0" => {
                :name => "Kick Ass",
                :address_line_1 => "104 Main",
                :city => "Memphis",
                :state => "TN",
                :zip => "19191"
              }
           },
          }
    end

    daily_deal_purchase = assigns(:daily_deal_purchase)
    assert_not_nil daily_deal_purchase, "Assignment of @daily_deal_purchase"
    assert_equal 1, daily_deal_purchase.recipients.size, "recipients"
    recipient = daily_deal_purchase.recipients.first
    assert_equal "Kick Ass", recipient.name, "name"
    assert_equal "104 Main", recipient.address_line_1, "address_line_1"

    consumer = daily_deal_purchase.consumer
    assert_not_nil consumer, "Daily deal purchase should have a consumer"
    assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)
  end

  context "daily deal variation" do

    setup do
      @daily_deal = Factory(:daily_deal)
      @publisher  = @daily_deal.publisher
      @publisher.update_attribute(:enable_daily_deal_variations, true)

      @consumer   = Factory(:consumer, :publisher => @publisher)

      @variation  = Factory(:daily_deal_variation, :daily_deal => @daily_deal)

      @daily_deal_purchase_attributes = { :quantity => "1", :gift => "0", :daily_deal_variation_id => @variation.to_param }
    end
  
    context "with existing customer" do

      setup do
        login_as @consumer
      end

      context "with pubilsher not enabled for daily deal variations" do

        setup do
          @publisher.update_attribute(:enable_daily_deal_variations, false)
        end

        should "create new daily deal purchase without daily deal variation" do
          post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_purchase => @daily_deal_purchase_attributes
          @daily_deal.reload
          assert_equal 1, @daily_deal.daily_deal_purchases.size
          
          purchase = @daily_deal.daily_deal_purchases.first
          assert purchase.pending?
          assert_nil purchase.daily_deal_variation
          assert_equal @consumer, purchase.consumer
        end

      end

      context "with publisher enabled for daily deal variations" do

        setup do
          @publisher.update_attribute(:enable_daily_deal_variations, true)
        end

        should "create new daily deal purchase WITH daily deal variation" do
          post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_purchase => @daily_deal_purchase_attributes
          @daily_deal.reload
          assert_equal 1, @daily_deal.daily_deal_purchases.size
          
          purchase = @daily_deal.daily_deal_purchases.first
          assert purchase.pending?
          assert_equal @variation, purchase.daily_deal_variation
          assert_equal @consumer, purchase.consumer
        end

        should "redirect to affiliate_url if affiliate_url is present" do
          url = "http://localhost/path/to/affiliate"
          @variation.update_attribute(:affiliate_url, url)
          post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_purchase => @daily_deal_purchase_attributes
          assert_redirected_to url
        end

      end


      
    end
    
    context "with new customer" do

      setup do
        @expected_consumer_count = Consumer.count + 1
        @consumer_attributes  = { 
          :name => "Joseph Blow", 
          :email => "joe@blow.com", 
          :password => "secret", 
          :password_confirmation => "secret", 
          :agree_to_terms => "1" 
        }
      end
      
      context "with a publisher not enabled for daily deal variations" do

        setup do
          @publisher.update_attribute(:enable_daily_deal_variations, false)
        end

        should "create new daily deal purchase without daily deal variation" do
          post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_purchase => @daily_deal_purchase_attributes, :consumer => @consumer_attributes
          @daily_deal.reload
          assert_equal 1, @daily_deal.daily_deal_purchases.size
          
          purchase = @daily_deal.daily_deal_purchases.first
          assert purchase.pending?
          assert_nil purchase.daily_deal_variation
          assert_equal @daily_deal.price * purchase.quantity, purchase.gross_price
          assert_equal @daily_deal.price, purchase.actual_purchase_price

          assert_equal @expected_consumer_count, Consumer.count, "should increase consumers by 1"
        end

      end

      context "with a publisher enabled for daily deal variations" do

        setup do
          @publisher.update_attribute(:enable_daily_deal_variations, true)
        end

        should "create new daily deal purchase WITH daily deal variation" do
          post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_purchase => @daily_deal_purchase_attributes, :consumer => @consumer_attributes
          @daily_deal.reload
          assert_equal 1, @daily_deal.daily_deal_purchases.size
          
          purchase = @daily_deal.daily_deal_purchases.first
          assert purchase.pending?
          assert_equal @variation, purchase.daily_deal_variation
          assert_equal @variation.price * purchase.quantity, purchase.gross_price, "should setup the gross price with variation in mind"
          assert_equal @variation.price, purchase.actual_purchase_price  

          assert_equal @expected_consumer_count, Consumer.count, "should increase consumers by 1"
        end

        should "render the new page because of a consumer validation failure and still have a daily_deal_variation present" do
          @daily_deal.publishing_group.update_attributes! :enable_daily_deal_variations => true
          @daily_deal.publisher.update_attributes! :enable_daily_deal_variations => false
          post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_purchase => @daily_deal_purchase_attributes, :consumer => {}
          assert_response :success
          assert_template "daily_deal_purchases/new"
          assert_select "input[type=hidden][name='daily_deal_purchase[daily_deal_variation_id]'][value='#{@variation.to_param}']", true
        end

      end
    end      
       


  end

end
