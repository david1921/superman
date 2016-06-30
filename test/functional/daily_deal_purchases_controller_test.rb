# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + "/../test_helper"

class DailyDealPurchasesControllerTest < ActionController::TestCase
  include BraintreeHelper
  include DailyDealPurchasesTestHelper

  context "with a pending shopping cart" do
    setup do
      @consumer = Factory(:consumer, :publisher => Factory(:publisher, :shopping_cart => true))
      @daily_deal_order = Factory(:daily_deal_order, :consumer => @consumer)
      @daily_deal = Factory(:daily_deal, :price => 15, :value => 40, :publisher => @consumer.publisher)
      @request.session[:daily_deal_order] = @daily_deal_order.uuid
    end

    should "not ask for consumer details in new" do
      assert_no_difference '@daily_deal_order.daily_deal_purchases.count' do
        get :new, :daily_deal_id => @daily_deal.to_param
      end
      assert_response :success

      assert_select "input[name='consumer[name]']", false
      assert_select "input[name='consumer[email]']", false
      assert_select "input[name='consumer[password]']", false
      assert_select "input[name='consumer[password_confirmation]']", false

      assert_select "div#consumer div.static", :count => 1, :text => @consumer.name
      assert_select "div#consumer div.static", :count => 1, :text => @consumer.email
    end

    should "add purchase to the pending order in create" do
      assert_difference '@daily_deal_order.daily_deal_purchases.count' do
        post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_purchase => { :quantity => "1", :gift => "0" }
      end
      assert_equal @daily_deal_order, assigns(:daily_deal_order)
      assert @daily_deal_order.pending?
      assert_equal @consumer, @daily_deal_order.consumer

      assert_not_nil (daily_deal_purchase = assigns(:daily_deal_purchase)), "daily_deal_purchase"
      assert_equal @daily_deal_order, daily_deal_purchase.daily_deal_order
      assert_equal @consumer, daily_deal_purchase.consumer

      assert_equal @daily_deal_order.uuid, session[:daily_deal_order]
      assert_redirected_to publisher_cart_path(@consumer.publisher.label)
    end

    context "using the same discount code twice in a cart" do
      
      setup do
        @free_deal = Factory :side_daily_deal, :price => 0, :value => 25, :min_quantity => 1, :publisher => @consumer.publisher
        @discount = Factory :discount, :code => "FIFTEEN", :amount => 15, :publisher => @consumer.publisher
        @free_purchase = Factory :daily_deal_purchase, :daily_deal => @free_deal, :consumer => @consumer, :discount => @discount
        @daily_deal_order.daily_deal_purchases << @free_purchase
      end

      should "be prohibited (example simulating not using the Apply link)" do
        assert_no_difference 'DailyDealPurchase.count' do
          post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_purchase => { :quantity => "1", :gift => "0", :discount_code => @discount.code }
        end
        assert_response :success
        assert_template :new
        assert_nil assigns(:daily_deal_purchase).discount
        assert_select "div#errorExplanation ul li", :text => "discount 'FIFTEEN' has already been applied to another item in this cart" 
      end

      should "be prohibited (example using the Apply link)" do
        assert_no_difference 'DailyDealPurchase.count' do
          post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_purchase => { :quantity => "1", :gift => "0", :discount_uuid => @discount.uuid }
        end
        assert_response :success
        assert_template :new
        assert_nil assigns(:daily_deal_purchase).discount
        assert_select "div#errorExplanation ul li", :text => "discount 'FIFTEEN' has already been applied to another item in this cart" 
      end
    end
  end

  test "optimal_confirm with publisher with payment_method of optimal" do
    publisher           = Factory :publisher, :payment_method => "optimal"
    advertiser          = Factory :advertiser, :publisher_id => publisher.id
    daily_deal          = Factory :daily_deal, :advertiser_id => advertiser.id, :price => "15", :value => "30"
    daily_deal_purchase = Factory :pending_daily_deal_purchase, :daily_deal_id => daily_deal.id
    
    get :optimal_confirm, :id => daily_deal_purchase.to_param
    assert_response :success
    assert_template :optimal_confirm
    assert_layout   :optimal
    
    assert_equal OptimalPayments::Configuration.shop_id, assigns( :shop_id )
    assert assigns(:encoded_message), "should assign the encoded message"
    assert assigns( :signature ), "should assign the signature"
    assert assigns( :optimal_payment_url ), "should assign the url for the payment url"
    
    
  end
  
  test "optimal_return with pubisher with payment_method of optimal and confirmationNumber" do
    publisher           = Factory :publisher, :payment_method => "optimal"
    advertiser          = Factory :advertiser, :publisher_id => publisher.id
    daily_deal          = Factory :daily_deal, :advertiser_id => advertiser.id, :price => "15", :value => "30"
    daily_deal_purchase = Factory :pending_daily_deal_purchase, :daily_deal_id => daily_deal.id
    confirmation_number = "123123123"
    
    get :optimal_return, :id => daily_deal_purchase.to_param, :confirmationNumber => confirmation_number
    
    assert_redirected_to thank_you_daily_deal_purchase_path( daily_deal_purchase )
    assert_equal confirmation_number, daily_deal_purchase.reload.daily_deal_payment.payment_gateway_receipt_id
  end
  
  test "merchant_account_id is set in braintree transparent redirect form when mid set on publisher" do
    publishing_group = Factory(:publishing_group, :label => "freedom")
    publisher = Factory(:publisher, :label => "ocregister", :publishing_group => publishing_group, :merchant_account_id => "Freedom")
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal)
    set_purchase_session(daily_deal_purchase)

    get :confirm, :id => daily_deal_purchase.to_param
    assert_response :success
    assert_select "form#transparent_redirect_form", 1 do
      assert_select "input[name=tr_data][type=hidden]", 1
      assert_select "input[name=tr_data][type=hidden][value*=?]", "transaction%5Bmerchant_account_id%5D=Freedom", 1
    end
  end
  
  test "merchant_account_id is set in braintree transparent redirect form when mid set on publisher_group" do
    publishing_group = Factory(:publishing_group, :label => "freedom", :merchant_account_id => "Freedom")
    publisher = Factory(:publisher, :label => "ocregister", :publishing_group => publishing_group)
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal)
    set_purchase_session(daily_deal_purchase)
    
    get :confirm, :id => daily_deal_purchase.to_param
    assert_response :success
    assert_select "form#transparent_redirect_form", 1 do
      assert_select "input[name=tr_data][type=hidden]", 1
      assert_select "input[name=tr_data][type=hidden][value*=?]", "transaction%5Bmerchant_account_id%5D=Freedom", 1
    end
  end
  
  test "merchant_account_id is not set in braintree transparent redirect form when mid not set on pub or pub group" do
    publisher = Factory(:publisher, :label => "xxxxxxxxxx")
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal)
    set_purchase_session(daily_deal_purchase)
    
    get :confirm, :id => daily_deal_purchase.to_param
    assert_response :success
    assert_select "form#transparent_redirect_form", 1 do
      assert_select "input[name=tr_data][type=hidden]", 1
      assert_select "input[name=tr_data][type=hidden][value*=?]", "transaction%5Bmerchant_account_id%5D=", 0
    end
  end
  
  test "litle_report_group and litle_campaign are always set in braintree transparent redirect form" do
    publisher = Factory(:publisher, :label => "xxxxxxxxxx", :merchant_account_id => "Foo123")
    daily_deal = Factory(:daily_deal, :publisher => publisher, :listing => "12345")
    daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal)
    set_purchase_session(daily_deal_purchase)
    
    get :confirm, :id => daily_deal_purchase.to_param
    assert_response :success
    assert_select "form#transparent_redirect_form", 1 do
      assert_select "input[name=tr_data][type=hidden]", 1
      assert_select "input[name=tr_data][type=hidden][value*=?]", "transaction%5Bcustom_fields%5D%5Blitle_report_group%5D=Foo123", 1
      assert_select "input[name=tr_data][type=hidden][value*=?]", "transaction%5Bcustom_fields%5D%5Blitle_campaign%5D=BBD-#{daily_deal.id}", 1
    end
  end
  
  test "billing postal code is text in braintree transparent redirect form when zip blank" do
    publisher = Factory(:publisher, :label => "xxxxxxxxxx")
    consumer = Factory(:consumer, :publisher => publisher, :zip_code => nil)
    daily_deal = Factory(:daily_deal, :publisher => publisher, :listing => "12345")
    daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer)
    set_purchase_session(daily_deal_purchase)

    get :confirm, :id => daily_deal_purchase.to_param
    assert_response :success
    assert_select "form#transparent_redirect_form", 1 do
      assert_select "input[name='transaction[billing][postal_code]'][type=text]", 1
      assert_select "input[name='transaction[billing][postal_code]'][type=hidden]", 0
    end
  end
  
  test "review_and_buy_form AJAX" do
    daily_deal = Factory(:daily_deal, :requires_shipping_address => true)
    xhr :get, :review_and_buy_form, :daily_deal_id => daily_deal.to_param, :quantity => 1
    assert_response :success
    daily_deal_purchase = assigns(:daily_deal_purchase)
    assert_not_nil daily_deal_purchase, "@daily_deal_purchase"
    assert_equal false, daily_deal_purchase.gift?, "gift?"
    assert_equal 1, daily_deal_purchase.quantity, "quantity"
  end
  
  test "review_and_buy_form AJAX with DailyDeal#certificates_to_generate_per_unit_quantity > 1 and gift" do
    daily_deal = Factory :daily_deal, :requires_shipping_address => true, :certificates_to_generate_per_unit_quantity => 2
    xhr :get, :review_and_buy_form, :daily_deal_id => daily_deal.to_param, :quantity => 1, :gift => "1"
    assert_response :success
    assert_select "div.recipient", :count => 2
  end
  
  test "current with active deal" do
    daily_deal = Factory(:daily_deal)
    get :current, :label => daily_deal.publisher.label
    assert_response 302
    assert_redirected_to new_daily_deal_daily_deal_purchase_path(daily_deal)
  end

  context "daily deal placed by an affiliate" do
    setup do
      @daily_deal = Factory(:daily_deal)
      @publisher = Factory(:publisher)
      @affiliate_placement = @daily_deal.affiliate_placements.create!(:affiliate => @publisher)
    end
    
    should "associate the purchase with the affiliate on create if the placement_code cookie is set" do
      @request.cookies['placement_code'] = @affiliate_placement.uuid
  
      assert_difference "DailyDealPurchase.count" do
        post :create, {
          :daily_deal_id => @daily_deal.to_param, 
          :consumer => {
            :name => "Joe Blow",
            :email => "joe@blow.com",
            :password => "secret",
            :password_confirmation => "secret",
            :agree_to_terms => "1"
          }, 
          :daily_deal_purchase => { :quantity => "1", :gift => "0" }
        }
      end
      assert_equal @publisher, DailyDealPurchase.last.affiliate
    end
  end
end
