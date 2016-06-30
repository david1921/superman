require File.dirname(__FILE__) + "/../test_helper"

class CyberSourceControllerTest < ActionController::TestCase
  [:receipt, :decline].each do |action|
    should  "raise if orderNumber parameter is missing in #{action}" do
      assert_raise ActiveRecord::RecordNotFound do
        post action
      end
    end

    should "raise if the order number does not match a daily-deal-purchase in #{action}" do
      assert_raise ActiveRecord::RecordNotFound do
        post action, { :orderNumber => "#{DailyDealPurchase.last.id + 1}-BBP" }
      end
    end
    
    should "raise if the order matches a daily-deal purchase lacking CyberSource credentials in #{action}" do
      daily_deal_purchase = Factory(:pending_daily_deal_purchase)
      assert_raise RuntimeError do
        post action, { :orderNumber => daily_deal_purchase.cyber_source_order_number }
      end
    end
    
    context "for a daily-deal purchase having CyberSource credentials" do
      setup do
        init_cyber_source_credentials_for_tests("entertainment")
        daily_deal = Factory(:daily_deal, :publisher => Factory(:publisher, :label => "entertainment"))
        @daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal)
        @order_number = @daily_deal_purchase.cyber_source_order_number
      end
      
      should "raise if the order-number signature is missing in #{action}" do
        assert_raise RuntimeError do
          post action, :orderNumber => @order_number
        end
      end

      should "raise if the order-number signature is wrong in #{action}" do
        assert_raise RuntimeError do
          post action, :orderNumber => @order_number, :orderNumber_publicSignature => "xxxx"
        end
      end

      context "and a valid order-number signature" do
        setup do
          @order_number_signature = @daily_deal_purchase.cyber_source_credentials.signature(@order_number)
        end

        should "raise if the transaction signature is missing in #{action}" do
          assert_raise RuntimeError do
            post action, {
              :orderNumber => @order_number,
              :orderNumber_publicSignature => @order_number_signature,
              :signedFields => "orderNumber"
            }
          end
        end

        should "raise if the transaction signature is wrong in #{action}" do
          assert_raise RuntimeError do
            post action, {
              :orderNumber => @order_number,
              :orderNumber_publicSignature => @order_number_signature,
              :signedFields => "orderNumber",
              :signedDataPublicSignature => "xxxx"
            }
          end
        end
      end
    end
  end

  context "with valid parameters for decline of an entertainment purchase" do
    setup do
      init_cyber_source_credentials_for_tests("entertainment")
      publisher = Factory(:publisher_using_cyber_source, :label => "entertainment")
      daily_deal = Factory(:daily_deal, :publisher => publisher, :value => 25.00, :price => 12.00, :listing => "ABCD-1234")
      consumer = Factory(:billing_address_consumer, :publisher => publisher, :email => "john@public.com")
      @daily_deal_purchase = Factory(:pending_daily_deal_purchase, :consumer => consumer, :daily_deal => daily_deal, :quantity => 1)
      credentials = @daily_deal_purchase.cyber_source_credentials
      order_number = @daily_deal_purchase.cyber_source_order_number
      @params = HashWithIndifferentAccess.new(
        "decision" => "REJECT",
        "ccAuthReply_reasonCode" => "102",
        "paymentOption" => "card",
        "orderPage_serialNumber" => "3294982392010176056165",
        "orderNumber" => order_number,
        "orderAmount" => "12.00",
        "orderCurrency" => "usd",
        "orderPage_transactionType" => "sale",
        "billTo_firstName" => "Joe",
        "billTo_lastName" => "Blow",
        "billTo_street1" => "430 Stevens Avenue",
        "billTo_street2" => "Suite 350",
        "billTo_city" => "Solana Beach",
        "billTo_state" => "CA",
        "billTo_postalCode" => "92075",
        "billTo_country" => "us",
        "billTo_email" => "joe@blow.com",
        "card_cardType" => "001",
        "card_accountNumber" => "############1111",
        "card_expirationMonth" => "01",
        "card_expirationYear" => "2012",
        "InvalidField0" => "card_accountNumber",
        "InvalidField1" => "card_expirationYear",
        "orderAmount_publicSignature" => "gthjq81yiKH51sbXe/QmFGwAwJY=",
        "reasonCode" => "102",
        "signedFields" => "billTo_lastName,_method,orderPage_serialNumber,orderAmount_publicSignature,orderCurrency,card_expirationYear,card_accountNumber,reasonCode,billTo_firstName,commit,orderPage_transactionType,ccAuthReply_reasonCode,authenticity_token,card_expirationMonth,orderNumber,orderCurrency_publicSignature,decision_publicSignature,orderAmount,billTo_street2,orderNumber_publicSignature,card_cardType,billTo_street1,decision,paymentOption,billTo_city,billTo_state,merchantID,billTo_postalCode,billTo_country",
        "orderCurrency_publicSignature" => "E20BlD9FRqZe5STTQLwtpz2HgaE=",
        "decision_publicSignature" => "qPaVtMOBnN8jWQGUIbmhCWSEy+Q=",
        "transactionSignature" => "n7YgoegXgk3tywK7tuYAptg8VzE=",
        "authenticity_token" => "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        "_method" => "put",
        "commit" => "Buy Now"
      )
      @params["orderNumber_publicSignature"] = credentials.signature(order_number)
      @params["signedDataPublicSignature"] = CyberSource::Context::Base.transaction_signature(@params, credentials)
      CyberSourceGatewayResult.destroy_all
    end
    
    should "create a CyberSource gateway result record in the decline action" do
      post :decline, @params
      
      assert_equal 1, CyberSourceGatewayResult.count
      cyber_source_gateway_result = CyberSourceGatewayResult.last
      assert_equal @daily_deal_purchase, cyber_source_gateway_result.daily_deal_purchase
      assert_equal true, cyber_source_gateway_result.error
      assert_match /Expiration Year was invalid/, cyber_source_gateway_result.error_message
      assert_match /Card Number was invalid/, cyber_source_gateway_result.error_message
    end
    
    should "render entertainment custom fields in the decline action" do
      post :decline, @params
      
      assert_select "input[type=hidden][name=billTo_email][value='john@public.com']", 1
      assert_select "input[type=hidden][name=merchantDefinedData1][value=52278]", 1
      assert_select "input[type=hidden][name=merchantDefinedData2][value=entertainment]", 1
      assert_select "input[type=hidden][name=merchantDefinedData3][value=ABCD-1234]", 1
    end
      
    should "render daily-deal-purchase confirmation page from decline action" do
      post :decline, @params
      assert_response :success
      assert_theme_layout "entertainment/layouts/daily_deals"
      assert_template "daily_deal_purchases/confirm"

      assert_select "input[type=hidden][name=orderNumber]", 1
      assert_select "input[type=hidden][name=orderNumber][value='#{@daily_deal_purchase.cyber_source_order_number}']", 1
      assert_select "input[type=hidden][name=orderPage_receiptResponseURL][value='https://sb1.analoganalytics.com/cybersource/receipt']", 1
      assert_select "input[type=hidden][name=orderPage_declineResponseURL][value='https://sb1.analoganalytics.com/cybersource/decline']", 1

      assert_select "input#cyber_source_order_billing_first_name[name=billTo_firstName][value=Joe]", 1
      assert_select "input#cyber_source_order_billing_last_name[name=billTo_lastName][value=Blow]", 1
      assert_select "input#cyber_source_order_billing_address_line_1[name=billTo_street1][value='430 Stevens Avenue']", 1
      assert_select "input#cyber_source_order_billing_address_line_2[name=billTo_street2][value='Suite 350']", 1
      assert_select "input#cyber_source_order_billing_city[name=billTo_city][value='Solana Beach']", 1
      assert_select "select#cyber_source_order_billing_state[name=billTo_state]", 1
      assert_select "input#cyber_source_order_billing_postal_code[name=billTo_postalCode][value='92075']", 1
      assert_select "select#cyber_source_order_billing_country[name=billTo_country]", 1 do
        assert_select "option", 2
        assert_select "option[value=us][selected=selected]", :count => 1, :text => "United States"
      end
      #
      # No value shown or selected for card attributes
      #
      assert_select "select#cyber_source_order_card_type[name=card_cardType]", 1 do
        assert_select "option", 5
        assert_select "option[selected]", 0
      end
      assert_select ".fieldWithErrors input#cyber_source_order_card_number[name=card_accountNumber]", 1
      assert_select ".fieldWithErrors input#cyber_source_order_card_number[name=card_accountNumber][value]", 0
      
      assert_select "select#cyber_source_order_card_expiration_month[name=card_expirationMonth]", 1 do
        assert_select "option", 12
        assert_select "option[selected]", 0
      end
      assert_select ".fieldWithErrors select#cyber_source_order_card_expiration_year[name=card_expirationYear]", 1 do
        assert_select "option[selected]", 0
      end
      assert_select "input#cyber_source_order_card_cvv[name=card_cvNumber]", 1
      assert_select "input#cyber_source_order_card_cvv[name=card_cvNumber][value]", 0

      assert_select ".daily_deal_payment_errors ul li", 2
      assert_select ".daily_deal_payment_errors ul li", :text => "Card Number was invalid", :count => 1
      assert_select ".daily_deal_payment_errors ul li", :text => "Expiration Year was invalid", :count => 1
    end
  end
  
  context "with valid parameters for receipt of an entertainment purchase" do
    setup do
      init_cyber_source_credentials_for_tests("entertainment")
      publisher = Factory(:publisher_using_cyber_source, :label => "entertainment")
      daily_deal = Factory(:daily_deal, :publisher => publisher, :value => 25.00, :price => 14.00)
      consumer = Factory(:billing_address_consumer, :publisher => publisher)
      @daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal, :quantity => 1, :consumer => consumer)
      @credentials = @daily_deal_purchase.cyber_source_credentials
      order_number = @daily_deal_purchase.cyber_source_order_number
      @params = HashWithIndifferentAccess.new(
        "orderNumber" => order_number,
        "orderAmount" => "14.00",
        "orderAmount_publicSignature" => "/VqOw/NLJxU7WNnXSpyAe5Yzkng=",
        "orderCurrency" => "usd",
        "orderCurrency_publicSignature" => "E20BlD9FRqZe5STTQLwtpz2HgaE=",
        "requestID" => "3308155091680178147615",
        "reconciliationID" => "2723074429",
        "decision" => "ACCEPT",
        "decision_publicSignature" => "m+836YlHz5nMo490oGLzG0VtapM=",
        "reasonCode" => "100",
        "ccAuthReply_reasonCode" => "100",
        "ccAuthReply_authorizationCode" => "123456",
        "ccAuthReply_avsCode" => "Y",
        "ccAuthReply_processorResponse" => "A",
        "ccAuthReply_amount" => "14.00",
        "ccAuthReply_authorizedDateTime" => "2012-03-03T225829Z",
        "ccAuthReply_cardBIN" => "411111",
        "ccAuthReply_avsCodeRaw" => "YYY",
        "merchantID" => "ep_cookie",
        "orderPage_requestToken" => "Ahj//wSRZqu/sQ1xpiI+ICmTdkzYN2jRk5Tfs1e/wQCm/Zq9/gtIF14ID4ZNJMq6PSZ+0DAnIs1Xf2Ia40xEfAAA7QSq",
        "orderPage_transactionType" => "sale",
        "orderPage_serialNumber" => "3294982392010176056165",
        "billTo_firstName" => "John",
        "billTo_lastName" => "Public",
        "billTo_street1" => "123 Main Street",
        "billTo_street2" => "Apartment 4",
        "billTo_city" => "Solana Beach",
        "billTo_state" => "CA",
        "billTo_postalCode" => "92075",
        "billTo_country" => "us",
        "billTo_email" => "john@public.com",
        "card_cardType" => "001",
        "card_accountNumber" => "411111######1111",
        "card_expirationMonth" => "01",
        "card_expirationYear" => "2015",
        "signedFields" => "billTo_lastName,_method,orderPage_serialNumber,ccAuthReply_avsCodeRaw,orderAmount_publicSignature,orderCurrency,card_expirationYear,card_accountNumber,reasonCode,billTo_firstName,commit,requestID,orderPage_transactionType,ccAuthReply_reasonCode,authenticity_token,ccAuthReply_authorizationCode,card_expirationMonth,orderNumber,orderCurrency_publicSignature,reconciliationID,ccAuthReply_avsCode,orderPage_requestToken,ccAuthReply_processorResponse,ccAuthReply_amount,decision_publicSignature,ccAuthReply_authorizedDateTime,orderAmount,billTo_street2,orderNumber_publicSignature,card_cardType,ccAuthReply_cardBIN,billTo_street1,decision,paymentOption,billTo_city,billTo_state,merchantID,billTo_postalCode,billTo_country",
        "authenticity_token" => "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        "paymentOption" => "card",
        "transactionSignature" => "KXyJpD6rgcLpfu8XpKv2EetC+58=",
        "_method" => "put",
        "commit" => "Buy Now"
      )
      @params["orderNumber_publicSignature"] = @credentials.signature(order_number)
      @params["signedDataPublicSignature"] = CyberSource::Context::Base.transaction_signature(@params, @credentials)
      ActionMailer::Base.deliveries.clear
      CyberSourceGatewayResult.destroy_all
      @host = @daily_deal_purchase.daily_deal.publisher.daily_deal_host
    end
    
    should "raise in receipt if the order type does not match the purchase" do
      @params["orderPage_transactionType"] = "authorize"
      @params["signedDataPublicSignature"] = CyberSource::Context::Base.transaction_signature(@params, @credentials)
      assert_raise RuntimeError do
        post :receipt, @params
      end
      assert_nil @controller.send(:current_consumer)
      assert @daily_deal_purchase.pending?, "Purchase should still be pending"
      assert_equal 0, ActionMailer::Base.deliveries.size
    end

    should "raise in receipt if the order amount does not match the purchase" do
      @params["orderAmount"] = "12.00"
      @params["orderAmount_publicSignature"] = @credentials.signature(@params["orderAmount"])
      @params["signedDataPublicSignature"] = CyberSource::Context::Base.transaction_signature(@params, @credentials)
      assert_raise RuntimeError do
        post :receipt, @params
      end
      assert_nil @controller.send(:current_consumer)
      assert @daily_deal_purchase.pending?, "Purchase should still be pending"
      assert_equal 0, ActionMailer::Base.deliveries.size
    end

    should "raise in receipt if the order currency does not match the purchase" do
      @params["orderCurrency"] = "gbp"
      @params["orderCurrency_publicSignature"] = @credentials.signature(@params["orderCurrency"])
      @params["signedDataPublicSignature"] = CyberSource::Context::Base.transaction_signature(@params, @credentials)
      assert_raise RuntimeError do
        post :receipt, @params
      end
      assert_nil @controller.send(:current_consumer)
      assert @daily_deal_purchase.pending?, "Purchase should still be pending"
      assert_equal 0, ActionMailer::Base.deliveries.size
    end
    
    should "capture a pending purchase in receipt" do
      assert_difference 'ActionMailer::Base.deliveries.size' do
        post :receipt, @params
        assert_redirected_to thank_you_daily_deal_purchase_url(@daily_deal_purchase, :protocol => "https", :host => @host)
        assert_equal @daily_deal_purchase.consumer, @controller.send(:current_consumer)
        
        analytics = flash[:analytics_tag]
        assert_equal 1, analytics[:quantity]
        assert_equal 14.0, analytics[:value]
        assert_equal @daily_deal_purchase.id, analytics[:sale_id]
        assert_equal @daily_deal_purchase.daily_deal.id, analytics[:item_id]
      end
      assert @daily_deal_purchase.reload.captured?, "Purchase should be captured"
      assert_equal DateTime.new(2012, 3, 3, 22, 58, 29), @daily_deal_purchase.executed_at
      assert_equal "3308155091680178147615", @daily_deal_purchase.payment_status_updated_by_txn_id
      
      payment = @daily_deal_purchase.daily_deal_payment
      assert CyberSourcePayment === payment, "Payment type should be CyberSourcePayment"
      assert_equal "3308155091680178147615", payment.payment_gateway_id
      assert_equal "2723074429", payment.payment_gateway_receipt_id
      assert_equal DateTime.new(2012, 3, 3, 22, 58, 29), payment.payment_at
      assert_equal 14.0, payment.amount
      assert_equal "John Public", payment.name_on_card, "should set name on card"
      assert_equal "John", payment.billing_first_name, "should set billing_first_name"
      assert_equal "Public", payment.billing_last_name, "should set billing_last_name"
      assert_equal "1111", payment.credit_card_last_4
      assert_equal "92075", payment.payer_postal_code
      assert_equal "ACCEPT", payment.payer_status
    end
    
    should "create a CyberSource gateway result record in receipt" do
      post :receipt, @params
      
      assert_equal 1, CyberSourceGatewayResult.count
      cyber_source_gateway_result = CyberSourceGatewayResult.last
      assert_equal @daily_deal_purchase, cyber_source_gateway_result.daily_deal_purchase
      assert_equal false, cyber_source_gateway_result.error
      assert_nil cyber_source_gateway_result.error_message
    end

    should "store the cardholder name, billing address, BIN and last 4 of card number in payment record" do
      post :receipt, @params

      payment = @daily_deal_purchase.reload.daily_deal_payment
      assert_equal "John Public", payment.name_on_card
      assert_equal "123 Main Street", payment.billing_address_line_1
      assert_equal "Apartment 4", payment.billing_address_line_2
      assert_equal "Solana Beach", payment.billing_city
      assert_equal "CA", payment.billing_state
      assert_equal "92075", payment.payer_postal_code
      assert_equal "411111", payment.credit_card_bin
      assert_equal "1111", payment.credit_card_last_4
    end

    context "and when the purchase has already been executed" do
      setup do
        @execute = lambda do |request_id|
          Factory(:cyber_source_payment, :daily_deal_purchase => @daily_deal_purchase, :payment_gateway_id => request_id)
          @daily_deal_purchase.reload
          @daily_deal_purchase.payment_status = "captured"
          @daily_deal_purchase.save!
        end
      end

      should "not void the order in receipt when the request ID of the new order is the same as the request ID of the original order" do
        @execute.call("3308155091680178147615")
        
        CyberSource::Gateway.expects(:void).never
        
        assert_no_difference 'ActionMailer::Base.deliveries.size' do
          post :receipt, @params
          assert_redirected_to public_deal_of_day_url(@daily_deal_purchase.publisher.label, :host => @host)
        end
      end

      should "void the order in receipt when the request ID of the new order is not the same as the request ID of the original order" do
        @execute.call("3308768036750178147616")
        
        instant = Time.zone.parse("Jan 02, 2012 12:34:56 UTC")
        reference = "#{@daily_deal_purchase.analog_purchase_id}-20120102123456"
        CyberSource::Gateway.expects(:void).with(@credentials, "3308155091680178147615", reference).returns(nil)
        
        Timecop.freeze instant do
          assert_no_difference 'ActionMailer::Base.deliveries.size' do
            post :receipt, @params
            assert_redirected_to public_deal_of_day_url(@daily_deal_purchase.publisher.label, :host => @host)
          end
        end
      end
    end
  end
end
