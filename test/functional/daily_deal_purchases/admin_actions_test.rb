require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::AdminActionsTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  test "admin_partial_refund with partial refund for purchase executed and settled" do
    daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => 2, :daily_deal => daily_deal)
    daily_deal_purchase.create_certificates!
    Braintree::Transaction.expects(:find).returns(braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::Settled))
    refunded_result = braintree_transaction_refunded_result(daily_deal_purchase, :amount => 30)
    Braintree::Transaction.expects(:refund).with(daily_deal_purchase.payment_gateway_id, 30).returns(refunded_result)
    login_as :aaron
    certificate_param = { daily_deal_purchase.daily_deal_certificates.first.id.to_s => {"refunded" => "1"},
                          daily_deal_purchase.daily_deal_certificates.second.id.to_s => {"refunded" => "0"} }
    post :admin_partial_refund, :id => daily_deal_purchase.to_param, :format => "js", :daily_deal_certificate => certificate_param
    assert_response :redirect
    assert_redirected_to daily_deal_purchases_consumers_admin_edit_url(daily_deal_purchase.id)
    assert_nil flash[:warn]
    assert_equal "Refunded 1 voucher for a total of $30.00", flash[:notice]

    assert_equal daily_deal_purchase.consumer, assigns(:consumer)
    assert_equal "refunded", daily_deal_purchase.reload.payment_status
    assert_equal "aaron", daily_deal_purchase.refunded_by
    assert_equal 60, daily_deal_purchase.amount.to_i
    assert_equal 30, daily_deal_purchase.refund_amount
    assert_equal refunded_result.transaction.id, daily_deal_purchase.payment_status_updated_by_txn_id
  end

  test "admin_partial_refund with partial refund for optimal purchase" do
    daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
    daily_deal_purchase = Factory(:captured_optimal_daily_deal_purchase, :quantity => 2, :daily_deal => daily_deal)
    daily_deal_purchase.daily_deal_payment.payment_gateway_receipt_id = "12345"
    daily_deal_purchase.daily_deal_payment.save!
    daily_deal_purchase.create_certificates!
    OptimalPayments::WebService.stubs(:void => stub(:success? => true))
    login_as :aaron
    certificate_param = { daily_deal_purchase.daily_deal_certificates.first.id.to_s => {"refunded" => "1"},
                          daily_deal_purchase.daily_deal_certificates.second.id.to_s => {"refunded" => "0"} }
    post :admin_partial_refund, :id => daily_deal_purchase.to_param, :format => "js", :daily_deal_certificate => certificate_param
    assert_response :redirect
    assert_redirected_to daily_deal_purchases_consumers_admin_edit_url(daily_deal_purchase.id)
    assert_nil flash[:notice]
    assert_match(/There was an error processing the partial refund: Purchase cannot be partially refunded until midnight Eastern time on day of purchase./i, flash[:warn])

    assert_equal "captured", daily_deal_purchase.reload.payment_status
    assert_equal 60, daily_deal_purchase.amount.to_i
    assert_equal 0, daily_deal_purchase.refund_amount
  end

  test "admin_partial_refund with partial refund for optimal purchase that can be refunded" do
    daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
    daily_deal_purchase = Factory(:captured_optimal_daily_deal_purchase, :quantity => 2, :daily_deal => daily_deal)
    daily_deal_purchase.daily_deal_payment.payment_gateway_receipt_id = "12345"
    daily_deal_purchase.daily_deal_payment.payment_at = 3.days.ago
    daily_deal_purchase.daily_deal_payment.save!
    daily_deal_purchase.create_certificates!
    OptimalPayments::WebService.stubs(:refund => stub(:success? => true))
    login_as :aaron
    certificate_param = { daily_deal_purchase.daily_deal_certificates.first.id.to_s => {"refunded" => "1"},
                          daily_deal_purchase.daily_deal_certificates.second.id.to_s => {"refunded" => "0"} }
    post :admin_partial_refund, :id => daily_deal_purchase.to_param, :format => "js", :daily_deal_certificate => certificate_param
    assert_response :redirect
    assert_redirected_to daily_deal_purchases_consumers_admin_edit_url(daily_deal_purchase.id)
    assert_nil flash[:warn]
    assert_equal "Refunded 1 voucher for a total of $30.00", flash[:notice]

    assert_equal daily_deal_purchase.consumer, assigns(:consumer)
    assert_equal "refunded", daily_deal_purchase.reload.payment_status
    assert_equal "aaron", daily_deal_purchase.refunded_by
    assert_equal 60, daily_deal_purchase.amount.to_i
    assert_equal 30, daily_deal_purchase.refund_amount
  end

  context "with an Entertainment purchase" do
    setup do
      @daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => 2)
      DailyDealPurchase.any_instance.stubs(:production_entertainment_refund? => true)
      
      sale_transaction = braintree_sale_transaction(@daily_deal_purchase, {
        :status => Braintree::Transaction::Status::Settled
      })
      @txn_id = @daily_deal_purchase.daily_deal_payment.payment_gateway_id
      assert @txn_id.present?, "Factory payment should have a transaction ID"

      login_as :aaron
    end
   
    should "not void or refund in admin_partial_refund" do
      @daily_deal_purchase.create_certificates!
      certificate_param = { @daily_deal_purchase.daily_deal_certificates.first.id.to_s => {"refunded" => "1"}}
      
      Braintree::Transaction.expects(:find).never
      Braintree::Transaction.expects(:void).never
      Braintree::Transaction.expects(:refund).never

      assert_no_difference '@daily_deal_purchase.reload.amount' do
        post :admin_partial_refund, :id => @daily_deal_purchase.to_param, :format => "js", :daily_deal_certificate => certificate_param
        assert_response :redirect
        assert_redirected_to daily_deal_purchases_consumers_admin_edit_url(@daily_deal_purchase.id)
        assert_match(/error processing the partial refund/i, flash[:warn])
        assert_match(/entertainment braintree transaction #{@txn_id} for \$15.00/i, flash[:warn])
      end
      assert_equal @daily_deal_purchase.consumer, assigns(:consumer)
      assert_equal "captured", @daily_deal_purchase.reload.payment_status
      assert_nil @daily_deal_purchase.refunded_by
    end
  end

  context "partial refunds" do
    setup do
      @purchase = Factory(:daily_deal_purchase)
    end
    context "admin_partial_refund_index" do
      should "route properly" do
        assert_routing "/daily_deal_purchases/15/admin_partial_refund_index", :controller => "daily_deal_purchases", :action => "admin_partial_refund_index", :id => "15"
      end
      context "authorization" do
        should "need to be admin to get to the partial refund index" do
          login_as :quentin
          get :admin_partial_refund_index, :id => "#{@purchase.uuid}", :format =>"js"
          assert_response :forbidden
        end
        should "be able to access partial refund index if admin" do
          login_as :aaron
          get :admin_partial_refund_index, :id => "#{@purchase.uuid}", :format =>"js"
          assert_response :success
        end
      end
      context "stuff on the partial refund index page" do
        setup do
          @cert1 = Factory(:daily_deal_certificate, :daily_deal_purchase => @purchase)
          @cert2 = Factory(:daily_deal_certificate, :daily_deal_purchase => @purchase)
          @cert3 = Factory(:daily_deal_certificate, :daily_deal_purchase => @purchase)
        end
        should "have a row for each certificate" do
          login_as :aaron
          get :admin_partial_refund_index, :id => "#{@purchase.uuid}", :format =>"js"
          assert_response :success
          assert_layout "application"
          assert_select "tr.certificate", 3
        end
      end
    end
  end

  test "print vouchers link" do
    daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
    purchase = Factory(:captured_daily_deal_purchase, :quantity => 2, :daily_deal => daily_deal)

    login_as :aaron
    get :consumers_admin_index, :consumer_id => purchase.consumer.to_param
    assert_response :success
    assert_template :consumers_admin_index
    assert_layout :application

    href = publisher_consumer_daily_deal_purchase_url(daily_deal.publisher.to_param, purchase.consumer.to_param, purchase.to_param, :format => :pdf)
    assert_select "a[href='#{href}']", :text => "Print", :count => 1
    assert_select "a[href='#{href}']", :text => "Partially Refunded", :count => 0
    assert_equal false, @response.body.include?("<td class=\"status\">Refunded</td>")
    assert_equal false, @response.body.include?("<td class=\"status\">Partially Refunded</td>")
  end

  test "print vouchers link for full refund" do
    daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
    purchase = Factory(:captured_daily_deal_purchase, :quantity => 2, :daily_deal => daily_deal)
    expect_braintree_full_refund(purchase)
    purchase.void_or_full_refund!(Factory(:admin))
    refunded_at = daily_deal.start_at + 6.hours
    purchase.update_attributes!(:refunded_at => refunded_at)
    purchase.daily_deal_certificates.each { |c| c.update_attributes!(:refunded_at => refunded_at) }
    assert purchase.fully_refunded?

    login_as :aaron
    get :consumers_admin_index, :consumer_id => purchase.consumer.to_param
    assert_response :success
    assert_template :consumers_admin_index
    assert_layout :application

    href = publisher_consumer_daily_deal_purchase_url(daily_deal.publisher.to_param, purchase.consumer.to_param, purchase.to_param, :format => :pdf)
    assert_select "a[href='#{href}']", :text => "Print", :count => 1
    assert_select "a[href='#{href}']", :text => "Partially Refunded", :count => 0
    assert_equal true, @response.body.include?("<td class=\"status\">Refunded</td>")
    assert_equal false, @response.body.include?("<td class=\"status\">Partially Refunded</td>")
  end

  test "print vouchers link for partial refund" do
    daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
    purchase = partially_refunded_purchase(daily_deal, 2, 30)

    login_as :aaron
    get :consumers_admin_index, :consumer_id => purchase.consumer.to_param
    assert_response :success
    assert_template :consumers_admin_index
    assert_layout :application

    href = publisher_consumer_daily_deal_purchase_url(daily_deal.publisher.to_param, purchase.consumer.to_param, purchase.to_param, :format => :pdf)
    assert_select "a[href='#{href}']", :text => "Print", :count => 1
    assert_select "a[href='#{href}']", :text => "Partially Refunded", :count => 1
    assert_equal false, @response.body.include?("<td class=\"status\">Refunded</td>")
    assert_equal false, @response.body.include?("<td class=\"status\">Partially Refunded</td>")
  end

  test "consumers_admin_index is admin only" do
    consumer = Factory(:consumer)
    with_admin_user_required(:quentin, :aaron) do
      get :consumers_admin_index, :consumer_id => consumer.id
    end
  end

  context "can_manage_consumers" do

    setup do
      @publisher = Factory(:publisher, :self_serve => true)
      @consumer  = Factory(:consumer, :publisher => @publisher)
      @user      = Factory(:user, :company => @publisher)
    end

    context "consumers_admin_index" do

      should "allow self serve publisher user who can manage consumers view the consumers_admin_index" do
        @user.update_attribute(:can_manage_consumers, true)
        login_as @user
        get :consumers_admin_index, :consumer_id => @consumer.to_param
        assert_response :success
        assert_template :consumers_admin_index
      end

      should "not all self server publisher user who can not manage consumers view the consuemrs_admin_index" do
        @user.update_attribute(:can_manage_consumers, false)
        login_as @user
        get :consumers_admin_index, :consumer_id => @consumer.to_param
        assert_redirected_to "/"
      end

    end

    context "consumers_admin_edit" do

      setup do
        @deal     = Factory(:daily_deal, :publisher => @publisher)
        @purchase = Factory(:captured_daily_deal_purchase, :consumer => @consumer, :daily_deal => @deal)
      end

      should "allow self serve publisher user who can manage consumers view the consumers_admin_edit" do
        @user.update_attribute(:can_manage_consumers, true)
        login_as @user
        get :consumers_admin_edit, :id => @purchase.id
        assert_response :success
        assert_template :edit
      end

      should "NOT all self serve publisher user who can NOT manage consumer view the consumers_admin_edit" do
        @user.update_attribute(:can_manage_consumers, false)
        login_as @user
        get :consumers_admin_edit, :id => @purchase.id
        assert_redirected_to "/"
      end

      context "recipient name fields" do

        setup do
          @admin = Factory(:admin)
          login_as @admin
        end

        should "generate correct number of recipient name input fields for default values" do
          get :consumers_admin_edit, :id => @purchase.id
          assert_select "input[name='daily_deal_purchase[recipient_names][]']", 1
        end

        should "generate correct number of recipients name input fields for greater quantities" do
          deal_with_more_certificates_to_generate = Factory(:side_daily_deal, :publisher => @publisher, :certificates_to_generate_per_unit_quantity => 3)
          purchase_with_more_recipients = Factory(:captured_daily_deal_purchase, :consumer => @consumer, :quantity => 5, :daily_deal => deal_with_more_certificates_to_generate)

          get :consumers_admin_edit, :id => purchase_with_more_recipients.id
          assert_select "input[name='daily_deal_purchase[recipient_names][]']", 15
        end

      end

      context "consumers_admin_update" do

        should "allow self serve publisher user who can manage consumers to post to consumers_admin_update" do
          @user.update_attribute(:can_manage_consumers, true)
          login_as @user
          assert !@purchase.gift?, "should not be a gift"
          post :consumers_admin_update, :id => @purchase.id, :daily_deal_purchase => {:gift => 1, :recipient_names => "Jill Smith"}
          assert_redirected_to consumers_daily_deal_purchases_admin_index_path(@purchase.consumer)
          assert @purchase.reload.gift?, "should be a gift"
        end

      end

    end

  end

  context "consumers_admin_edit for a captured Travelsavers purchase" do

    setup do
      @booking = Factory :successful_travelsavers_booking
      @purchase = @booking.daily_deal_purchase
      login_as(Factory(:admin))
      get :consumers_admin_edit, :id => @purchase.id
      assert_response :success
    end
    
    should "show the booking reference number" do
      assert_select "label[for=daily_deal_purchase_confirmation_number]", "TS Booking Reference:"
      assert_select "input#daily_deal_purchase_confirmation_number[disabled=disabled][value=36329883]"
    end

    should "show the booking status from Travelsavers" do
      assert_select "label[for=daily_deal_purchase_ts_booking_status]", "TS Booking Status:"
      assert_select "input#daily_deal_purchase_ts_booking_status[disabled=disabled][value=Success]"
    end

    should "show the payment status from Travelsavers" do
      assert_select "label[for=daily_deal_purchase_ts_payment_status]", "TS Payment Status:"
      assert_select "input#daily_deal_purchase_ts_payment_status[disabled=disabled][value=Success]"
    end
    
    should "not show the 'Quantity' input" do
      assert_select "input#daily_deal_purchase_quantity", false
    end

    should "show the actual_purchase_price for 'Total paid'" do
      assert @booking.daily_deal_purchase.actual_purchase_price.present?
      assert_select "#daily_deal_purchase_total_paid[value=#{"%.2f" % @booking.daily_deal_purchase.actual_purchase_price}]"
    end

    should "show 0.00 for refund amount" do
      assert_select "#daily_deal_purchase_refund_amount[value=0.00]"
    end

    should "not show the 'Gift' checkbox" do
      assert_select "#daily_deal_purchase_gift", false
    end

    should "not show the 'Certificate Number' field" do
      assert_select "#daily_deal_purchase_certificate_serial_number_0", false
    end

  end

  context "consumers_admin_edit for an authorized Travelsavers purchase" do

    setup do
      @booking = Factory :successful_travelsavers_booking_with_failed_payment
      @purchase = @booking.daily_deal_purchase
      assert @purchase.authorized?
      login_as(Factory(:admin))
      get :consumers_admin_edit, :id => @purchase.id
      assert_response :success
    end
 
    should "show the 'Total paid' as 0.00" do
      assert_select "#daily_deal_purchase_total_paid[value=0.00]"     
    end

  end

  context "consumers_admin_edit for a refunded Travelsavers purchase" do

    setup do
      @booking = Factory :cancelled_travelsavers_booking_with_payment_status_unknown
      @purchase = @booking.daily_deal_purchase
      @purchase.set_payment_status!("captured")
      @purchase.reload
      @admin = Factory(:admin)
      @purchase.void_or_full_refund!(@admin)
      login_as(@admin)
      get :consumers_admin_edit, :id => @purchase.id
      assert_response :success
    end

    should "show the purchase status as refunded" do
      assert_select "#daily_deal_purchase_payment_status[value=Refunded]"
    end

    should "show the refund_amount in the 'Amount refunded'" do
      assert_select "#daily_deal_purchase_total_paid[value=#{"%.2f" % @purchase.actual_purchase_price}]"
      assert_select "#daily_deal_purchase_refund_amount[value=15.00]"
    end

  end

  context "consumers_admin_edit when DailyDeal#certificates_to_generate_per_unit_quantity > 1" do
    
    setup do
      @admin = Factory :admin
      @daily_deal = Factory :daily_deal, :certificates_to_generate_per_unit_quantity => 3, :requires_shipping_address => true
      @purchase = Factory.build :captured_daily_deal_purchase, :daily_deal => @daily_deal, :gift => true, :quantity => 1
      @purchase.recipients_attributes = [
        { :name => "Bob", :address_line_1 => "Foo", :city => "Bar", :state => "AL", :zip => "90210" },
        { :name => "Alice", :address_line_1 => "Foo", :city => "Bar", :state => "AL", :zip => "90210" },
        { :name => "Tom", :address_line_1 => "Foo", :city => "Bar", :state => "AL", :zip => "90210" }
      ]
      @purchase.recipient_names = %w(Bob Alice Tom)
      @purchase.save!
    end
    
    should "show each recipient" do
      login_as @admin
      get :consumers_admin_edit, :id => @purchase.id
      assert_response :success
      
      assert_select "input[name='daily_deal_purchase[recipient_names][]'][value=Bob]"
      assert_select "input[name='daily_deal_purchase[recipient_names][]'][value=Alice]"
      assert_select "input[name='daily_deal_purchase[recipient_names][]'][value=Tom]"
    end
    
  end
  test "consumers_admin_index shows all purchases" do
    publisher = Factory(:publisher)
    daily_deal1 = Factory(:daily_deal, :publisher => publisher, :start_at => 3.days.ago, :hide_at => 2.days.ago)
    daily_deal2 = Factory(:daily_deal, :publisher => publisher, :start_at => Time.zone.now, :hide_at => Time.zone.now.tomorrow)
    consumer = Factory(:consumer, :publisher => publisher)
    purchase1 = Factory(:authorized_daily_deal_purchase, :consumer => consumer, :daily_deal => daily_deal1)
    purchase1 = Factory(:authorized_daily_deal_purchase, :consumer => consumer, :daily_deal => daily_deal2)
    with_user_required(:aaron) do
      get :consumers_admin_index, :consumer_id => consumer.id
    end
    assert_response :success
    assert_layout "application"
    assert_select "table tr", :count => 3
  end

  test "consumers_admin_index shows Arrived As column" do
    publisher = Factory(:publisher)
    daily_deal1 = Factory(:daily_deal,
                          :publisher => publisher,
                          :start_at => 3.days.ago,
                          :hide_at => 2.days.ago)
    daily_deal2 = Factory(:daily_deal,
                          :publisher => publisher,
                          :start_at => Time.zone.now,
                          :hide_at => Time.zone.now.tomorrow,
                          :certificates_to_generate_per_unit_quantity => 3)
    consumer = Factory(:consumer, :publisher => publisher)
    purchase1 = Factory(:authorized_daily_deal_purchase, :consumer => consumer, :daily_deal => daily_deal1)
    purchase1 = Factory(:authorized_daily_deal_purchase, :consumer => consumer, :daily_deal => daily_deal2)
    with_user_required(:aaron) do
      get :consumers_admin_index, :consumer_id => consumer.id
    end
    assert_select "th", "Deal Arrived As"
    assert_select '.certificates_to_generate_per_unit_quantity', 2
  end

  test "consumers_admin_index can show OffPlatformDailyDealCertificates" do
    cert = Factory(:off_platform_daily_deal_certificate)
    Factory(:off_platform_daily_deal_certificate, :consumer => cert.consumer, :redeemed => true, :redeemed_at => 3.years.ago)
    with_user_required(:aaron) do
      get :consumers_admin_index, :consumer_id => cert.consumer.id
    end
    assert_response :success
    assert_layout "application"
    assert_select "table tr", :count => 3
  end

  test "consumers_admin_edit requires admin" do
    daily_deal_purchase = Factory(:daily_deal_purchase)
    with_admin_user_required(:quentin, :aaron) do
      get :consumers_admin_edit, :id => daily_deal_purchase.id
    end
    assert_response :success
    assert_layout "application"
  end

  context "consumers_admin_edit through consumers_admin_update" do
    setup do
      @publisher = Factory(:publisher)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @advertiser.stores.clear
      @store1 = Factory(:store, :advertiser => @advertiser, :address_line_1 => "store1 addr")
      @store2 = Factory(:store, :advertiser => @advertiser, :address_line_1 => "store2 addr")
      @store3 = Factory(:store, :advertiser => @advertiser, :address_line_1 => "store3 addr")
      @advertiser = Advertiser.find(@advertiser.id)
      assert_equal @advertiser, @store1.advertiser
      @daily_deal = Factory(:daily_deal, :advertiser => @advertiser, :location_required => true)
      @consumer = Factory(:consumer, :publisher => @publisher)
      @purchase = Factory(:captured_daily_deal_purchase, :consumer => @consumer, :daily_deal => @daily_deal, :store => @store1)
      assert_equal @daily_deal, @purchase.daily_deal
      assert_equal @advertiser, @purchase.daily_deal.advertiser
      assert_equal 3, @advertiser.stores.size
      assert_equal 3, @purchase.daily_deal.advertiser.stores.size
      with_user_required(:aaron) do
        get :consumers_admin_edit, :id => @purchase.id
      end
      assert_response :success
    end

    should "have correct options for stores" do
      assert_select "form[action='/daily_deal_purchases/consumers_admin_update/#{@purchase.id}?method=post']", :count => 1 do
        assert_select "option[value=#{@store1.id}]"
        assert_select "option[value=#{@store2.id}]"
        assert_select "option[value=#{@store3.id}]"
      end
    end

    should "update store and recipients and redeemers on certificates" do
      assert_equal @store1, @purchase.store
      assert_nil @purchase.recipient_names
      post :consumers_admin_update, :id => @purchase.id, :daily_deal_purchase => {
        :store_id => @store3.id,
        :recipient_names => ["joe blow", "sam spade", "bob jones"]
      }
      post_update_purchase = DailyDealPurchase.find(@purchase.id)
      assert_equal @store3, post_update_purchase.store
      assert_equal ["joe blow", "sam spade", "bob jones"], post_update_purchase.recipient_names
    end

    should "change to gift and modify recipient properly" do
      assert !@purchase.gift?
      assert_nil @purchase.recipient_names
      @purchase.send("create_certificates!")
      assert_equal 1, @purchase.daily_deal_certificates.size
      post :consumers_admin_update, :id => @purchase.id, :daily_deal_purchase => {
        :gift => 1,
        :store_id => @store3.id,
        :recipient_names => "jill blow"
      }
      post_update_purchase = DailyDealPurchase.find(@purchase.id, :include => :daily_deal_certificates)
      assert_equal @store3, post_update_purchase.store
      assert_equal ["jill blow"], post_update_purchase.recipient_names
      assert post_update_purchase.gift?
      assert_equal 1, post_update_purchase.daily_deal_certificates.size
      assert_equal "jill blow", post_update_purchase.daily_deal_certificates[0].redeemer_name
    end

    should "not change to gift if there are no recipients" do
      assert !@purchase.gift?
      assert_nil @purchase.recipient_names
      post :consumers_admin_update, :id => @purchase.id, :daily_deal_purchase => {
        :gift => 1,
        :store_id => @store1.id,
        :recipient_names => ""
      }
      post_update_purchase = DailyDealPurchase.find(@purchase.id)
      assert !post_update_purchase.gift?
    end
  end

  test "admin index" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    login_as Factory(:admin)
    get :admin_index, :daily_deal_id => daily_deal_purchase.daily_deal.to_param
    assert_response :success
    assert_layout "application"
    assert_select ".toggle_allow_execution a.allow", 0
    assert_select ".toggle_allow_execution a.disallow", 0
  end

  test "admin index shows allow purchase link" do
    daily_deal_purchase = Factory(:voided_daily_deal_purchase)
    login_as Factory(:admin)
    get :admin_index, :daily_deal_id => daily_deal_purchase.daily_deal.to_param
    assert_response :success
    assert_layout "application"
    assert_select ".toggle_allow_execution a.allow", 0
    assert_select ".toggle_allow_execution a.disallow", 0
  end

  test "toggle allow execution should only update voided purchases" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    login_as Factory(:admin)
    get :toggle_allow_execution, :id => daily_deal_purchase.to_param
    assert !assigns(:daily_deal_purchase).allow_execution?, "Should not toggle allow_execution"
    assert_redirected_to daily_deal_daily_deal_purchases_admin_index_path(daily_deal_purchase.daily_deal)
    assert_not_nil flash[:warn], "Should give flash warning"
  end

  test "toggle allow execution on" do
    daily_deal_purchase = Factory(:voided_daily_deal_purchase)
    login_as Factory(:admin)
    get :toggle_allow_execution, :id => daily_deal_purchase.to_param
    assert !assigns(:daily_deal_purchase).allow_execution?, "Should not toggle allow_execution"
    assert_redirected_to daily_deal_daily_deal_purchases_admin_index_path(daily_deal_purchase.daily_deal)
  end

  test "toggle allow execution off" do
    daily_deal_purchase = Factory(:voided_daily_deal_purchase, :allow_execution => true)
    login_as Factory(:admin)
    get :toggle_allow_execution, :id => daily_deal_purchase.to_param
    assert assigns(:daily_deal_purchase).allow_execution?, "Should toggle allow_execution"
    assert_redirected_to daily_deal_daily_deal_purchases_admin_index_path(daily_deal_purchase.daily_deal)
  end
end
