require File.dirname(__FILE__) + "/../test_helper"

class DailyDealOrdersControllerTest < ActionController::TestCase
  
  context "braintree redirect" do
    
    setup do
      @publisher = Factory(:publisher, :shopping_cart => true)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
      @consumer = Factory(:consumer, :publisher => @publisher, :password => "mickey", :password_confirmation => "mickey")
      @order = Factory(:daily_deal_order, :consumer => @consumer)
      session[:daily_deal_order] = @order      
      
      @purchase = Factory(:daily_deal_purchase, :daily_deal => @deal, :consumer => @consumer)
      @order.daily_deal_purchases << @purchase
    end
    
    context "for successful braintree request" do
      
      setup do
        @braintree_transaction = braintree_transaction_submitted_result(@order)
        Braintree::TransparentRedirect.expects(:confirm).returns(@braintree_transaction)
        get :braintree_redirect, :id => @order.to_param
      end
      
      should redirect_to("thank you daily deal order path") { thank_you_daily_deal_order_path(@order) }
      should "clear our daily_deal_order session variable" do
        assert_nil session[:daily_deal_order]
      end
    end
    
    context "for a successful redirect on an order with multiple items, one of which is $0" do
      
      setup do
        deal_2 = Factory :side_daily_deal, :advertiser => @advertiser, :price => 0, :min_quantity => 1
        @free_purchase = Factory(:daily_deal_purchase, :daily_deal => deal_2, :consumer => @consumer)
        @order.daily_deal_purchases << @free_purchase
        
        @braintree_transaction = braintree_transaction_submitted_result(@order)
        Braintree::TransparentRedirect.expects(:confirm).returns(@braintree_transaction)
      end
      
      should "call execute_without_payment! instead of handle_braintree_sale! on the free item only" do
        DailyDealPurchase.any_instance.expects(:handle_braintree_sale!).once
        DailyDealPurchase.any_instance.expects(:execute_without_payment!).once
        get :braintree_redirect, :id => @order.to_param
        assert_redirected_to thank_you_daily_deal_order_path(@order)
      end
      
      should "mark all purchases, and the order itself, as captured" do
        get :braintree_redirect, :id => @order.to_param
        @order.reload
        assert_redirected_to thank_you_daily_deal_order_path(@order)
        assert @order.captured?
        assert @order.daily_deal_purchases.all?(&:captured?)
      end
      
    end
    
    context "failed purchase" do
      
      setup do
        @braintree_transaction = braintree_transaction_failed_result(@order)
        get :braintree_redirect, :id => @order.to_param
      end
      
      should respond_with(:success)
      should render_template(:current)
      should "not remove the daily deal order session variable" do
        assert_not_nil session[:daily_deal_order]
      end
      
    end
    
    context "timeout on executing purchase" do
      
      setup do
        BraintreeGatewayResult.stubs(:create)

        DailyDealOrder.any_instance.expects(:handle_braintree_sale!).raises(Timeout::Error)
        DailyDealOrder.any_instance.expects(:executed?).returns(true)

        @braintree_transaction = mock("braintree_transaction")
        @braintree_transaction.expects(:success?).returns(true)
        @braintree_transaction.expects(:transaction).returns(Object.new)
        Braintree::TransparentRedirect.expects(:confirm).returns(@braintree_transaction)

        get :braintree_redirect, :id => @order.to_param
      end
      
      should redirect_to("thank you daily deal order path") { thank_you_daily_deal_order_path(@order) }
      should "clear our daily_deal_order session variable" do
        assert_nil session[:daily_deal_order]
      end
      
    end
    
    context "braintree redirect not found" do
      
      setup do
        Braintree::TransparentRedirect.stubs(:confirm).raises(Braintree::NotFoundError)
        get :braintree_redirect, :id => @order.to_param
      end
      
      should redirect_to("publisher cart") { publisher_cart_path(@publisher.label) }
      should "not remove the daily deal order session variable" do
        assert_not_nil session[:daily_deal_order]
      end
      
    end
    
    context "already excuted exception raised" do
      
      setup do
        DailyDealOrder.any_instance.expects(:handle_braintree_sale!).raises(DailyDealPurchase::AlreadyExecutedError)        
        
        @braintree_transaction = mock("braintree_transaction")
        @braintree_transaction.expects(:success?).returns(true)
        @braintree_transaction.expects(:transaction).returns(Object.new)
        Braintree::TransparentRedirect.expects(:confirm).returns(@braintree_transaction)
        
        get :braintree_redirect, :id => @order.to_param
      end
      
      should redirect_to("publisher cart") { publisher_cart_path(@publisher.label) }
      
    end
    
  end
  
  
  test "thank you" do
    publisher = Factory(:publisher, :shopping_cart => true)
    advertiser = Factory(:advertiser, :publisher => publisher)
    deal = Factory(:daily_deal, :publisher => publisher, :advertiser => advertiser)
    consumer = Factory(:consumer, :publisher => publisher, :password => "mickey", :password_confirmation => "mickey")
    order = Factory(:daily_deal_order, :consumer => consumer)
    order.daily_deal_purchases << Factory(:daily_deal_purchase, :daily_deal => deal, :consumer => consumer)

    get :thank_you, :id => order.to_param
    assert_response :success
  end
  
  fast_context "current" do
    
    fast_context "with default publisher" do

      setup do
        @publisher = Factory(:publisher)
      end

      fast_context "with no current cart in place" do

        setup do
          get :current, :label => @publisher.label
        end

        should render_with_layout("daily_deals")
        should render_template("current")

        should assign_to(:daily_deal_order)

        should "assigned daily deal order should be new record" do
          assert assigns(:daily_deal_order).new_record?
        end      

      end

      fast_context "with current order" do

        setup do
          daily_deal = Factory(:daily_deal, :publisher => @publisher)
          daily_deal_purchase = Factory(:daily_deal_purchase, :daily_deal => daily_deal)
          @order = daily_deal_purchase.consumer.daily_deal_orders.create!
          @order.daily_deal_purchases << daily_deal_purchase
          session[:daily_deal_order] = @order.uuid
          get :current, :label => @publisher.label
        end

        should render_with_layout("daily_deals")
        should render_template("current")

        should assign_to(:daily_deal_order)

        should "assign the daily deal order to an instance variable" do
          assert_equal @order, assigns(:daily_deal_order)
        end      

        should "have edit and delete links for each item" do
          @order.daily_deal_purchases.each do |ddp|
            assert_select "#daily_deal_purchase_#{ddp.id}" do
              assert_select "a.edit[href='#{edit_daily_deal_purchase_path(ddp)}']", :text => 'Change'
              assert_select "a.remove[href='#{publisher_daily_deal_purchase_path(@publisher, ddp)}']", :text => 'Remove'
            end
          end
        end

        fast_context "with unavailable item" do
          setup do
            @unavailable_ddp = Factory(:daily_deal_purchase)
            (dd = @unavailable_ddp.daily_deal).quantity = 0
            dd.save(false)
            assert @unavailable_ddp.daily_deal.sold_out?
            @order.daily_deal_purchases << @unavailable_ddp
            get :current, :label => @publisher.label
          end

          should "order's daily deal purchases should not have item with no quantity available" do
            assert_does_not_contain assigns(:daily_deal_order).daily_deal_purchases, @unavailable_ddp
          end
        end

        fast_context "with inactive item" do
          setup do
            @unavailable_ddp = Factory(:daily_deal_purchase)
            (dd = @unavailable_ddp.daily_deal).hide_at = 1.day.ago
            dd.save(false)
            assert !@unavailable_ddp.daily_deal.active?
            @order.daily_deal_purchases << @unavailable_ddp
            get :current, :label => @publisher.label
          end

          should "order's daily deal purchases should not have inactive item" do
            assert_does_not_contain assigns(:daily_deal_order).daily_deal_purchases, @unavailable_ddp
          end
        end
      end
      
      fast_context "with a previously completed order" do
        setup do
          @consumer = Factory(:consumer, :publisher => @publisher)
          @order = Factory(:daily_deal_order, :payment_status => 'captured', :consumer => @consumer)
        end

        should "create a new order" do
          login_as @consumer
          get :current, :label => @publisher.label
          assert_not_nil assigns(:daily_deal_order)
          assert_not_equal @order, assigns(:daily_deal_order)
        end
      end
      
      fast_context "with order with a single item whose price is $0" do
        
        setup do
          daily_deal = Factory(:daily_deal, :publisher => @publisher, :price => 0, :value => 20, :min_quantity => 1)
          daily_deal_purchase = Factory(:daily_deal_purchase, :daily_deal => daily_deal)
          @order = daily_deal_purchase.consumer.daily_deal_orders.create!
          @order.daily_deal_purchases << daily_deal_purchase
          session[:daily_deal_order] = @order.uuid
          get :current, :label => @publisher.label          
        end
        
        should "not show the braintree payment form" do
          assert_select "form#transparent_redirect_form", false
        end
        
        should "show a form to complete the purchase for free" do
          assert_select "form#free_purchase_form"
        end
        
      end
      
      fast_context "with order with multiple items, one of which is $0" do
        
        setup do
          daily_deal = Factory(:daily_deal, :publisher => @publisher, :price => 0, :value => 20, :min_quantity => 1)
          daily_deal_2 = Factory(:side_daily_deal, :publisher => @publisher, :price => 30, :value => 100)
          daily_deal_purchase = Factory(:daily_deal_purchase, :daily_deal => daily_deal)
          daily_deal_purchase_2 = Factory(:daily_deal_purchase, :daily_deal => daily_deal_2)
          @order = daily_deal_purchase.consumer.daily_deal_orders.create!
          @order.daily_deal_purchases << daily_deal_purchase
          @order.daily_deal_purchases << daily_deal_purchase_2
          assert @order.total_price > 0
          
          session[:daily_deal_order] = @order.uuid
          get :current, :label => @publisher.label          
        end

        should "show the braintree payment form" do
          assert_select "form#transparent_redirect_form"
        end
        
        should "not show the free purchase form" do
          assert_select "form#free_purchase_form", false
        end
        
      end
      
    end
    
    fast_context "execute_free" do
      
      setup do
        @publisher = Factory :publisher
        @advertiser = Factory :advertiser, :publisher => @publisher
        @daily_deal_1 = Factory :daily_deal, :price => 0, :min_quantity => 1, :value => 15, :advertiser => @advertiser
        daily_deal_purchase = Factory :daily_deal_purchase, :daily_deal => @daily_deal_1
        @order = Factory :daily_deal_order
        @order.daily_deal_purchases << daily_deal_purchase
        post :execute_free, :id => @order.to_param
        @order.reload
      end
      
      should "execute the order" do
        assert @order.captured?
        assert @order.daily_deal_purchases.first.captured?
      end
      
      should "redirect to the thank_you page" do
        assert_redirected_to thank_you_daily_deal_order_path(@order)
      end
            
    end
    
  end
end
