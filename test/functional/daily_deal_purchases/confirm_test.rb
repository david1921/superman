require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::ConfirmTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper
  include DailyDealPurchaseHelper

  test "confirm for ocregister expired deal" do
    publisher = Factory.build(:publisher, :label => "ocregister")
    daily_deal = Factory.build(:daily_deal, :publisher => publisher, :hide_at => 1.days.ago)
    daily_deal_purchase = Factory(:voided_daily_deal_purchase, :daily_deal => daily_deal)
    set_purchase_session(daily_deal_purchase)
    get :confirm, :id => daily_deal_purchase.to_param
    assert_response :success
    assert_select "#credit_card_buy_now", 0
  end

  test "confirm for ocregister expired deal allow execution" do
    publisher = Factory.build(:publisher, :label => "ocregister", :payment_method => "credit")
    daily_deal = Factory.build(:daily_deal, :publisher => publisher, :hide_at => 1.days.ago)
    daily_deal_purchase = Factory(:voided_daily_deal_purchase, :daily_deal => daily_deal, :allow_execution => true)
    set_purchase_session(daily_deal_purchase)
    get :confirm, :id => daily_deal_purchase.to_param
    assert_response :success
    assert_select "#credit_card_buy_now", 1
  end

  test "confirm with publisher payment method paypal" do
    daily_deal_purchase = Factory(:paypal_daily_deal_purchase)
    assert_equal daily_deal_purchase.publisher, daily_deal_purchase.daily_deal.publisher, "Fixtures for consumer and daily deal should belong to the same publisher"

    assert daily_deal_purchase.publisher.pay_using?(:paypal), "publisher should be setup for paying using paypal"
    set_purchase_session(daily_deal_purchase)

    get :confirm, :id => daily_deal_purchase.to_param
    assert_response :success
    assert_equal daily_deal_purchase, assigns(:daily_deal_purchase)
    assert_not_nil assigns(:paypal_configuration), "should assign paypal configuration"
    assert_nil session[:user_id], "Consumer should not be logged in"

    

    assert_select "div#payment_method_credit", 0
    assert_select "div#payment_method_free", 0
    assert_select "div#payment_method_paypal", 1 do
      assert_select "form", 1
    end
  end

  test "confirm for nydailynews" do
    publisher = Factory(:publisher, :label => 'nydailynews')
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    pending_daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    set_purchase_session(pending_daily_deal_purchase)

    get :confirm, :id => pending_daily_deal_purchase.to_param

    assert_select "#transparent_redirect_form" do      
      
      assert_select "label[for='transaction_credit_card_cardholder_name']", :text => "Cardholder Name *:"
      assert_select "input[name='transaction[credit_card][cardholder_name]'][type='text']"
    
      assert_select "label[for='transaction_credit_card_number']", :text => "Card Number *:"
      assert_select "input[name='transaction[credit_card][number]'][type='text']"
    
      assert_select "label", :text => "Expiration Date:"
      assert_select ".expiration_date" do
        assert_select "select[name='transaction[credit_card][expiration_month]']"
        assert_select "select[name='transaction[credit_card][expiration_year]']"
      end        
    
      assert_select "label[for='transaction_credit_card_cvv']", :text => "CVV *:"
      assert_select "div.input" do
        assert_select "div.transaction_credit_card_cvv" do
          assert_select "input[name='transaction[credit_card][cvv]'][type='text'][size='4']"
          assert_select "a[href='/en/what-is-cvv']", :text => "What's this?"
        end
      end
    
      assert_select "label[for='transaction_billing_postal_code']", :text => "Billing ZIP Code *:"
      assert_select "input[name='transaction[billing][postal_code]'][type='text'][size='10']"
      
    end
  end

  test "confirm with publisher payment method credit" do
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    assert_equal daily_deal_purchase.consumer.publisher,
                 daily_deal_purchase.daily_deal.publisher,
                 "Fixtures for consumer and daily deal should belong to the same publisher"
    set_purchase_session(daily_deal_purchase)

    get :confirm, :id => daily_deal_purchase.to_param
    assert_response :success
    assert_equal daily_deal_purchase, assigns(:daily_deal_purchase)
    assert_nil assigns(:paypal_configuration), "should not set paypal configuration for non paypal purchase"
    assert_nil session[:user_id], "Consumer should not be logged in"

    assert_select "input#tr_data[value=?]", /.*settlement%5D=true.*/
    assert_select "div#payment_method_paypal", 0
    assert_select "div#payment_method_free", 0
    assert_select "div#payment_method_credit", 1 do
      assert_select "form", 1
    end
  end

  test "confirm with publisher payment method credit capture_on_purchase false" do
    AppConfig.capture_on_purchase = false
    daily_deal_purchase = Factory(:pending_daily_deal_purchase)
    assert_equal daily_deal_purchase.consumer.publisher,
                 daily_deal_purchase.daily_deal.publisher,
                 "Fixtures for consumer and daily deal should belong to the same publisher"
    set_purchase_session(daily_deal_purchase)

    get :confirm, :id => daily_deal_purchase.to_param
    assert_response :success
    assert_equal daily_deal_purchase, assigns(:daily_deal_purchase)
    assert_nil assigns(:paypal_configuration), "should not set paypal configuration for non paypal purchase"
    assert_nil session[:user_id], "Consumer should not be logged in"

    assert_select "input#tr_data[value=?]", /.*settlement%5D=false.*/
    assert_select "div#payment_method_paypal", 0
    assert_select "div#payment_method_free", 0
    assert_select "div#payment_method_credit", 1 do
      assert_select "form", 1
    end
  end

  test "confirm with entercom capture_on_purchase false" do
    AppConfig.capture_on_purchase = false
    publishing_group = Factory(:publishing_group, :label => "entercomnew")
    entercom_austin = Factory(:publisher, :label => "entercom-austin", :publishing_group => publishing_group)
    daily_deal = Factory(:daily_deal, :publisher => entercom_austin)
    daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal)
    assert_equal daily_deal_purchase.consumer.publisher,
                 daily_deal_purchase.daily_deal.publisher,
                 "Fixtures for consumer and daily deal should belong to the same publisher"
    set_purchase_session(daily_deal_purchase)

    get :confirm, :id => daily_deal_purchase.to_param
    assert_response :success
    assert_equal daily_deal_purchase, assigns(:daily_deal_purchase)
    assert_nil assigns(:paypal_configuration), "should not set paypal configuration for non paypal purchase"
    assert_nil session[:user_id], "Consumer should not be logged in"

    assert_select "input#tr_data[value=?]", /.*settlement%5D=false.*/
    assert_select "div#payment_method_paypal", 0
    assert_select "div#payment_method_free", 0
    assert_select "div#payment_method_credit", 1 do
      assert_select "form", 1
    end
  end

  test "confirm with free purchase" do
    discount = Factory(:discount, :amount => 10.00)
    daily_deal = Factory(:daily_deal, :publisher => discount.publisher, :value => 10.00, :price => 5.00)
    daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal, :discount => discount, :quantity => 2)
    set_purchase_session(daily_deal_purchase)

    get :confirm, :id => daily_deal_purchase.to_param

    assert_response :success
    assert_equal daily_deal_purchase, assigns(:daily_deal_purchase)
    assert_nil session[:user_id], "Consumer should not be logged in"

    assert_select "*", /get a \$20.00 value for free/i
    assert_select "div#payment_method_paypal", 0
    assert_select "div#payment_method_credit", 0
    assert_select "div#payment_method_free", 1 do
      assert_select "form[method=post][action='#{execute_free_daily_deal_purchase_path(daily_deal_purchase)}']", 1 do
        assert_select "input[type=submit]", 1
      end
    end
  end

  test "confirm with USD publisher" do
    usd_publisher = Factory :publisher, :currency_code => "USD"
    usd_advertiser = Factory :advertiser, :publisher_id => usd_publisher.id
    usd_daily_deal = Factory :daily_deal, :advertiser_id => usd_advertiser.id, :price => "15", :value => "30"
    usd_daily_deal_purchase = Factory :pending_daily_deal_purchase, :daily_deal_id => usd_daily_deal.id
    set_purchase_session(usd_daily_deal_purchase)

    get :confirm, :id => usd_daily_deal_purchase.to_param
    assert_response :success
    assert_select "h2.buy_now_proposition", :text => "Buy a $30.00 Value for $15.00 Now", :count => 1
    assert_select "label[for=transaction_billing_postal_code]", :text => "Billing ZIP Code *:"
    assert_select "div#credit_card_logos" do
      assert_select "img[src^=/images/credit_card_logos]"
    end
  end

  test "confirm with GBP publisher" do
    gbp_publisher = Factory :publisher, :currency_code => "GBP"
    gbp_advertiser = Factory :advertiser, :publisher_id => gbp_publisher.id
    gbp_daily_deal = Factory :daily_deal, :advertiser_id => gbp_advertiser.id, :price => "15", :value => "30"
    gbp_daily_deal_purchase = Factory :pending_daily_deal_purchase, :daily_deal_id => gbp_daily_deal.id
    set_purchase_session(gbp_daily_deal_purchase)

    get :confirm, :id => gbp_daily_deal_purchase.to_param
    assert_response :success
    assert_select "h2.buy_now_proposition", :text => "Buy a £30.00 Value for £15.00 Now", :count => 1
    assert_select "label[for=transaction_billing_postal_code]", :text => "Billing Postcode *:"
    assert_select "div#credit_card_logos" do
      assert_select "img[src^=/images/gbp_credit_card_logos]"
    end
  end

  test "confirm with CAD publisher" do
    cad_publisher = Factory :cad_publisher
    cad_advertiser = Factory :advertiser, :publisher_id => cad_publisher.id
    cad_daily_deal = Factory :daily_deal, :advertiser_id => cad_advertiser.id, :price => "15", :value => "30"
    cad_daily_deal_purchase = Factory :pending_daily_deal_purchase, :daily_deal_id => cad_daily_deal.id
    set_purchase_session(cad_daily_deal_purchase)

    get :confirm, :id => cad_daily_deal_purchase.to_param
    assert_response :success
    assert_select "h2.buy_now_proposition", :text => "Buy a C$30.00 Value for C$15.00 Now", :count => 1
    assert_select "label[for=transaction_billing_postal_code]", :text => "Billing Postal Code *:"
    assert_select "div#credit_card_logos" do
      assert_select "img[src^=/images/credit_card_logos]"
    end
  end

  test "confirm with EUR publisher" do
    eur_publisher = Factory :publisher, :currency_code => "EUR"
    eur_advertiser = Factory :advertiser, :publisher_id => eur_publisher.id
    eur_daily_deal = Factory :daily_deal, :advertiser_id => eur_advertiser.id, :price => "15", :value => "30"
    eur_daily_deal_purchase = Factory :pending_daily_deal_purchase, :daily_deal_id => eur_daily_deal.id
    set_purchase_session(eur_daily_deal_purchase)

    get :confirm, :id => eur_daily_deal_purchase.to_param
    assert_response :success
    assert_select "h2.buy_now_proposition", :text => "Buy a €30.00 Value for €15.00 Now", :count => 1
    assert_select "label[for=transaction_billing_postal_code]", :text => "Billing Postal Code *:"
    assert_select "div#credit_card_logos" do
      assert_select "img[src^=/images/credit_card_logos]"
    end
  end

  test "confirm with EUR publisher with paypal account" do
    eur_publisher = Factory :publisher, :currency_code => "EUR", :payment_method => "paypal"
    eur_advertiser = Factory :advertiser, :publisher_id => eur_publisher.id
    eur_daily_deal = Factory :daily_deal, :advertiser_id => eur_advertiser.id, :price => "15", :value => "30"
    eur_daily_deal_purchase = Factory :pending_daily_deal_purchase, :daily_deal_id => eur_daily_deal.id
    set_purchase_session(eur_daily_deal_purchase)

    get :confirm, :id => eur_daily_deal_purchase.to_param
    assert_response :success
    assert_select "input[type=hidden][name='currency_code'][value='EUR']"
  end

  context "for Travelsavers deal" do

    context "without variations" do
      setup do
        @ts_publisher = Factory(:publisher, :label => 'travelsavers', :payment_method => "travelsavers")
        @ts_advertiser = Factory(:advertiser, :publisher => @ts_publisher)
        @source_deal = Factory(:daily_deal_for_syndication, :advertiser => @ts_advertiser, :listing => "BBD-786750619",
                               :travelsavers_product_code => "CXP-TEST", :price => 500)
        @distributed_deal = syndicate(@source_deal, Factory(:publisher))
      end

      should "render TravelSaver checkout form" do
        @daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => @distributed_deal, :uuid => "0bc4cf68-5e52-11e1-b74f-c82a14fffea8")
        @expected_transaction_data = "xzwWavDgYX4wXWRVGOdSPQWIOGmIEBrkod3erEwGFV4=|aa_purchase_id=0bc4cf68-5e52-11e1-b74f-c82a14fffea8&purchase_price=500.0&redirect_url=http%3A%2F%2Ftest.host%2Fdaily_deal_purchases%2F0bc4cf68-5e52-11e1-b74f-c82a14fffea8%2Ftravelsavers_bookings%2Fhandle_redirect&ts_product_id=CXP-TEST"

        assert @daily_deal_purchase.pay_using?(:travelsavers)
        set_purchase_session(@daily_deal_purchase)

        get :confirm, :id => @daily_deal_purchase.to_param
        assert_response :ok
        assert_template 'confirm'
        assert_select "form#travelsavers_booking[action=?]", Travelsavers::BookingRequest::URI do
          assert_transaction_data(@expected_transaction_data)

          assert_select "div#payment_inputs" do
            assert_select "fieldset#credit_card_inputs" do
              assert_select "label[for=credit_card_cardholder_firstname]"
              assert_select "input.required[type=text][name=?]", "credit_card[cardholder_firstname]"
              assert_select "label[for=credit_card_cardholder_lastname]"
              assert_select "input.required[type=text][name=?]", "credit_card[cardholder_lastname]"
              assert_select "label[for=credit_card_vendor_code]", /Card Type/
              assert_select "select.required[name=?]", "credit_card[vendor_code]" do
                assert_select "option[value=]", ""
                assert_select "option[value=AX]", "American Express"
                assert_select "option[value=MC]", "MasterCard"
                assert_select "option[value=VI]", "Visa"
                assert_select "option[value=DS]", "Discover"
              end
              assert_select "label[for=credit_card_number]", /Card Number/
              assert_select "input.required.creditcard[type=text][name=?]", "credit_card[number]"
              assert_select "label[for=credit_card_cvv]", /Security Code/
              assert_select "input.required.creditCardSecurityCode[type=text][name=?]", "credit_card[cvv]"
              assert_select "label[for=credit_card_expiration_date]", /Expiration Date/
              assert_select "input.required.creditCardExpiryDate[type=text][name=?][maxlength=7]", "credit_card[expiration_date]"
            end
            assert_select "fieldset#billing_address_inputs" do
              assert_select "label[for=credit_card_billing_address_line_1]", /Address 1/
              assert_select "input.required[type=text][name=?]", "credit_card[billing][address_line_1]"
              assert_select "label[for=credit_card_billing_address_line_2]", /Address 2/
              assert_select "input[type=text][name=?]", "credit_card[billing][address_line_2]"
              assert_select "label[for=credit_card_billing_locality]", /City/
              assert_select "input.required[type=text][name=?]", "credit_card[billing][locality]"
              assert_select "label[for=credit_card_billing_region]", /State/
              assert_select "select.required[name=?]", "credit_card[billing][region]" do
                assert_select "option[value=]", ""
                Addresses::Codes::US::STATE_NAMES_BY_CODE.each do |code, name|
                  assert_select "option[value=?]", code, name
                end
              end
              assert_select "label[for=credit_card_billing_postal_code]", /Zip Code/
              assert_select "input.required.zipCode[type=text][name=?]", "credit_card[billing][postal_code]"
              assert_select "label[for=credit_card_billing_country_code]", /Country/
              assert_select "input[type=hidden][name=?][value=US]", "credit_card[billing][country_code]"
            end
          end

          assert_select "fieldset#passenger_inputs" do
            [0,1].each do |i|
              assert_select "fieldset#passenger_#{i}_inputs" do
                assert_select "label[for=traveler_#{i}_title]", "Title:"
                assert_select "select#traveler_#{i}_title.required[name=?]", "traveler[#{i}][title]" do
                  assert_select "option[value=]", :text => ""
                  assert_select "option[value=Mr]", :text => "Mr"
                  assert_select "option[value=Ms]", :text => "Ms"
                  assert_select "option[value=Mrs]", :text => "Mrs"
                  assert_select "option[value=Miss]", :text => "Miss"
                  assert_select "option[value=Dr]", :text => "Dr"
                  assert_select "option[value=Mstr]", :text => "Mstr"
                end
                assert_select "label[for=traveler_#{i}_first_name]", /First Name/
                assert_select "input.required[type=text][name=?]", "traveler[#{i}][first_name]"
                assert_select "label[for=traveler_#{i}_last_name]", /Last Name/
                assert_select "input.required[type=text][name=?]", "traveler[#{i}][last_name]"
                assert_select "label[for=traveler_#{i}_gender]", /Gender/
                assert_select "select.required.titleGender[name=?]", "traveler[#{i}][gender]" do
                  assert_select "option[value=]"
                  assert_select "option[value=M]", "Male"
                  assert_select "option[value=F]", "Female"
                end
                assert_select "label[for=traveler_#{i}_birth_date]", /Date Of Birth/
                assert_select "input.required.validDateOfBirth[type=text][name=?][maxlength=10]", "traveler[#{i}][birth_date]"
                assert_select "label[for=traveler_#{i}_citizenship]", /Citizenship/
                assert_select "input.required.countryCode[type=text][name=?]", "traveler[#{i}][citizenship]"
                assert_select "label[for=traveler_#{i}_phone_number]", /Phone Number/
                assert_select "input.required.phoneUS[type=text][name=?]", "traveler[#{i}][phone_number]"
                assert_select "label[for=traveler_#{i}_email]", /Email/
                assert_select "input.required.email[type=text][name=?]", "traveler[#{i}][email]"
                assert_select "label[for=traveler_#{i}_address_line_1]", /Address 1/
                assert_select "input.required[type=text][name=?]", "traveler[#{i}][address_line_1]"
                assert_select "label[for=traveler_#{i}_address_line_2]", /Address 2/
                assert_select "input[type=text][name=?]", "traveler[#{i}][address_line_2]"
                assert_select "label[for=traveler_#{i}_locality]", /City/
                assert_select "input.required[type=text][name=?]", "traveler[#{i}][locality]"
                assert_select "label[for=traveler_#{i}_region]", /State/
                assert_select "select.required[name=?]", "traveler[#{i}][region]" do
                  assert_select "option[value=]", ""
                  Addresses::Codes::US::STATE_NAMES_BY_CODE.each do |code, name|
                    assert_select "option[value=?]", code, name
                  end
                end
                assert_select "label[for=traveler_#{i}_postal_code]", /Zip Code/
                assert_select "input.required.zipCode[type=text][name=?]", "traveler[#{i}][postal_code]"
                assert_select "input[name=?]", "traveler[#{i}][terms_accepted]"
                assert_select "label[for=traveler_#{i}_country_code]", /Country/
                assert_select "input[type=hidden][name=?][value=US]", "traveler[#{i}][country_code]"
              end
            end
          end

          assert_select "input[type=submit][value=?]", "Buy Now"
          assert_select "a", "Cancel"
        end
      end

    end

    context "deal with variations" do

      setup do
        @ts_publisher = Factory(:publisher, :label => 'travelsavers', :payment_method => "travelsavers")
        @ts_advertiser = Factory(:advertiser, :publisher => @ts_publisher)
        @source_deal = Factory(:daily_deal_for_syndication, :advertiser => @ts_advertiser, :listing => "BBD-786750619",
                               :travelsavers_product_code => "CXP-TEST", :price => 500)
        @distributed_deal = syndicate(@source_deal, Factory(:publisher))
        [@source_deal, @distributed_deal].each{|deal| deal.publisher.update_attributes!(:enable_daily_deal_variations => true)}
        @daily_deal_variation = Factory.build(:travelsavers_daily_deal_variation, :daily_deal => @source_deal,
                                        :travelsavers_product_code => "CXP-VARIATION", :price => 250)
        @daily_deal_variation.save(false)
        @daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => @distributed_deal,
                                       :uuid => "0bc4cf68-5e52-11e1-b74f-c82a14fffea8", :daily_deal_variation => @daily_deal_variation)
        @expected_transaction_data = "bxC5VvfXANxHJc13wz5CVmxM/PJ1wEDPsZxeCA4uNm0=|aa_purchase_id=0bc4cf68-5e52-11e1-b74f-c82a14fffea8&purchase_price=250.0&redirect_url=http%3A%2F%2Ftest.host%2Fdaily_deal_purchases%2F0bc4cf68-5e52-11e1-b74f-c82a14fffea8%2Ftravelsavers_bookings%2Fhandle_redirect&ts_product_id=CXP-VARIATION"
      end

      should "generate transaction data using the variation's (not the deal's) Travelsavers product code" do
        set_purchase_session(@daily_deal_purchase)
        get :confirm, :id => @daily_deal_purchase.to_param
        assert_response :ok
        assert_template 'confirm'
        assert_select "form#travelsavers_booking" do
          assert_transaction_data(@expected_transaction_data)
        end
      end
    end
  end
  
  context "GET to confirm when the purchase has 'fixable' errors" do
    
    setup do
      @travelsavers = Factory :publisher, :label => "travelsavers", :payment_method => "travelsavers"
      @advertiser = Factory :advertiser, :publisher => @travelsavers
      @daily_deal = Factory :daily_deal, :advertiser => @advertiser, :travelsavers_product_code => "CXP-TEST"
    end
    
    should "display a list of the errors stored in flash[:ts_validation_errors]" do
      @purchase = Factory :pending_daily_deal_purchase, :daily_deal => @daily_deal
      set_purchase_session(@purchase)
      get :confirm, { :id => @purchase.to_param }, nil, { :travelsavers_errors_user_can_fix => ["the first error", "the second error"] }
      assert_response :success
      assert_select "div#errorExplanation.travelsavers" do
        assert_select "ul" do
          assert_select "li", "the first error"
          assert_select "li", "the second error"
        end
      end
    end
    
    should "not display the error div when there are no errors in flash[:travelsavers_errors_user_can_fix]" do
      @purchase = Factory :pending_daily_deal_purchase, :daily_deal => @daily_deal
      set_purchase_session(@purchase)      
      get :confirm, { :id => @purchase.to_param }
      assert_response :success
      assert_select "div#errorExplanation.travelsavers", false
    end
    
    should "not include the javascript used to render the 'Load Test Data' button" do
      @purchase = Factory :pending_daily_deal_purchase, :daily_deal => @daily_deal
      set_purchase_session(@purchase)      
      get :confirm, { :id => @purchase.to_param }
      assert_response :success
      assert_no_match %r{loadTravelsaversFormFields}i, @response.body
    end
    
    should "display the values entered by the user, based on flash[:travelsavers_checkout_form_values]" do
      @purchase = Factory :pending_daily_deal_purchase, :daily_deal => @daily_deal
      set_purchase_session(@purchase)      
      get :confirm, { :id => @purchase.to_param }, nil, { 
        :travelsavers_checkout_form_values => {
          "credit_card[cardholder_firstname]" => "Jamie",
          "credit_card[cardholder_lastname]" => "Oliver",
          "credit_card[vendor_code]" => "VI",
          "credit_card[number]" => "1234",
          "credit_card[cvv]" => "345",
          "credit_card[expiration_date]" => "01/01/2013",
          "credit_card[billing][address_line_1]" => "123 Test Road",
          "credit_card[billing][address_line_2]" => "unit 111",
          "credit_card[billing][locality]" => "Essex",
          "credit_card[billing][region]" => "AL",
          "credit_card[billing][postal_code]" => "90210",
          "credit_card[billing][country_code]" => "US",
          "traveler[0][title]" => "Mr",
          "traveler[0][last_name]" => "Jobs",          
          "traveler[0][birth_date]" => "30/05/1972",
          "traveler[0][citizenship]" => "US",
          "traveler[0][email]" => "bob@example.com",
          "traveler[1][first_name]" => "Bob",
          "traveler[1][gender]" => "M",
          "traveler[1][phone_number]" => "2042551111",
          "traveler[1][address_line_1]" => "here",
          "traveler[1][address_line_2]" => "there",
          "traveler[1][locality]" => "somewhere",
          "traveler[0][region]" => "NY",
          "traveler[1][postal_code]" => "82717",
          "traveler[0][country_code]" => "US",
          "traveler[0][terms_accepted]" => "1"
        }
      }
      assert_response :success
      assert_select "div#errorExplanation.travelsavers", false
      assert_select "label[for='credit_card_cardholder_firstname']", "Cardholder First Name:"
      assert_select "input[name='credit_card[cardholder_firstname]'][value=?]", "Jamie"
      assert_select "label[for='credit_card_cardholder_lastname']", "Cardholder Last Name:"
      assert_select "input[name='credit_card[cardholder_lastname]'][value=?]", "Oliver"
      assert_select "label[for=credit_card_vendor_code]", "Card Type:"
      assert_select "select[name='credit_card[vendor_code]']" do
        assert_select "option[value=VI][selected=selected]"
      end
      assert_select "input[name='credit_card[number]'][value=?]", "1234"
      assert_select "input[name='credit_card[cvv]'][value=?]", "345"
      assert_select "input[name='credit_card[expiration_date]'][value=?]", "01/01/2013"
      assert_select "input[name='credit_card[billing][address_line_1]'][value=?]", "123 Test Road"
      assert_select "input[name='credit_card[billing][address_line_2]'][value=?]", "unit 111"
      assert_select "input[name='credit_card[billing][locality]'][value=?]", "Essex"
      assert_select "select[name='credit_card[billing][region]']" do
        assert_select "option[selected=selected][value=?]", "AL"
      end
      assert_select "input[name='credit_card[billing][postal_code]'][value=?]", "90210"
      assert_select "input[name='credit_card[billing][country_code]'][value=?]", "US"
      assert_select "select[name='traveler[0][title]']" do
        assert_select "option[value=?][selected=selected]", "Mr"
      end
      assert_select "input[name='traveler[1][first_name]'][value=?]", "Bob"
      assert_select "input[name='traveler[0][last_name]'][value=?]", "Jobs"
      assert_select "select[name='traveler[1][gender]']" do
        assert_select "option[selected=selected][value=?]", "M"
      end
      assert_select "input[name='traveler[0][birth_date]'][value=?]", "30/05/1972"
      assert_select "input[name='traveler[0][citizenship]'][value=?]", "US"
      assert_select "input[name='traveler[0][email]'][value=?]", "bob@example.com"
      assert_select "input[name='traveler[1][phone_number]'][value=?]", "2042551111"
      assert_select "input[name='traveler[1][address_line_1]'][value=?]", "here"
      assert_select "input[name='traveler[1][address_line_2]'][value=?]", "there"
      assert_select "input[name='traveler[1][locality]'][value=?]", "somewhere"
      assert_select "select[name='traveler[0][region]']" do
        assert_select "option[selected=selected][value=?]", "NY"
      end
      assert_select "input[name='traveler[1][postal_code]'][value=?]", "82717"
      assert_select "input[name='traveler[0][country_code]'][value=?]", "US"
      assert_select "input[name='traveler[0][terms_accepted]'][checked=?]", "checked"
    end
    
  end
  
  context "for a purchase belonging to an entertainment publisher" do
    setup do
      init_cyber_source_credentials_for_tests("entertainment")
      publisher = Factory(:publisher_using_cyber_source, :label => "entertainment")
      daily_deal = Factory(:daily_deal, :publisher => publisher, :value => 25.00, :price => 12.00, :listing => "ABCD-1234")
      consumer = Factory(:consumer, :publisher => publisher,
        :email => "joe@blow.com",
        :first_name => "Joe",
        :last_name => "Blow",
        :address_line_1 => "430 Stevens Avenue",
        :address_line_2 => "Suite 350",
        :billing_city => "Solana Beach",
        :state => "CA",
        :zip_code => "92075",
        :country_code => "US"
      )
      @daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer, :quantity => 1)
      credentials = @daily_deal_purchase.cyber_source_credentials
      order_number = @daily_deal_purchase.cyber_source_order_number
    end
      
    should "render the CyberSource order form in the confirm action" do
      set_purchase_session(@daily_deal_purchase)      
      post :confirm, :id => @daily_deal_purchase.uuid

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
      assert_select "input#cyber_source_order_card_number[name=card_accountNumber]", 1
      assert_select "input#cyber_source_order_card_number[name=card_accountNumber][value]", 0
      
      assert_select "select#cyber_source_order_card_expiration_month[name=card_expirationMonth]", 1 do
        assert_select "option", 12
        assert_select "option[selected]", 0
      end
      assert_select "select#cyber_source_order_card_expiration_year[name=card_expirationYear]", 1 do
        assert_select "option[selected]", 0
      end
      assert_select "input#cyber_source_order_card_cvv[name=card_cvNumber]", 1
      assert_select "input#cyber_source_order_card_cvv[name=card_cvNumber][value]", 0

      assert_select ".daily_deal_payment_errors", 0
    end
    
    should "render entertainment custom fields in the confirm action" do
      set_purchase_session(@daily_deal_purchase)
      post :confirm, :id => @daily_deal_purchase.uuid

      assert_select "input[type=hidden][name=billTo_email][value='joe@blow.com']", 1
      assert_select "input[type=hidden][name=merchantDefinedData1][value=52278]", 1
      assert_select "input[type=hidden][name=merchantDefinedData2][value=entertainment]", 1
      assert_select "input[type=hidden][name=merchantDefinedData3][value=ABCD-1234]", 1
    end
  end

  context "for braintree payment" do

    setup do
      @daily_deal_purchase = Factory(:pending_daily_deal_purchase)
      @daily_deal_purchase.publisher.countries << Country.find_by_code("CA")
      @daily_deal_purchase.consumer.update_attributes!({
        :first_name     => 'John',
        :last_name      => 'Smith',          
        :address_line_1 =>  '123 Main St',
        :address_line_2 =>  'Suite 300',
        :billing_city   =>  'Brooklyn',
        :state          =>  'NY',
        :country_code   =>  'CA',
        :zip_code       =>  'K1A 0B1'
      })
      set_purchase_session(@daily_deal_purchase)
      post :confirm, :id => @daily_deal_purchase.uuid
    end

    should "be a credit (braintree) purchase" do
      assert @daily_deal_purchase.publisher.pay_using?(:credit), "should be a credit (braintree) purchase"
    end

    should "render the appropriate form fields" do
      assert_select "#transparent_redirect_form" do      
      
        assert_select "input[name='transaction[credit_card][cardholder_name]'][type='text'][class='required']"
        assert_select "input[name='transaction[credit_card][number]'][type='text'][class='required']"
      
        assert_select ".expiration_date" do
          assert_select "select[name='transaction[credit_card][expiration_month]']"
          assert_select "select[name='transaction[credit_card][expiration_year]']"
        end        
      
        assert_select "input[name='transaction[credit_card][cvv]'][type='text'][class='autowidth required']"    

        assert_select "input[name='transaction[billing][first_name]'][type='text'][value='John']"
        assert_select "input[name='transaction[billing][last_name]'][type='text'][value='Smith']"
        assert_select "input[name='transaction[billing][street_address]'][type='text'][value='123 Main St'][class='required']"
        assert_select "input[name='transaction[billing][extended_address]'][type='text'][value='Suite 300']"
        assert_select "input[name='transaction[billing][locality]'][type='text'][value='Brooklyn'][class='required']" #city
        assert_select "select[name='transaction[billing][region]']" do
          assert_select "option[selected='selected'][value='NY']"
        end
        assert_select "input[name='transaction[billing][postal_code]'][type='text'][value='K1A 0B1'][class='autowidth required zipCode']"
        assert_select "select[name='transaction[billing][country_code_alpha2]']" do
          assert_select "option[selected='selected'][value='CA']"
        end
      end
    end

  end

  context "for paypal payment" do
    setup do
      @daily_deal_purchase = Factory(:daily_deal_purchase)
      pub = @daily_deal_purchase.publisher
      pub.payment_method = 'paypal'
      pub.save!
      assert_equal "paypal", @daily_deal_purchase.publisher.reload.payment_method
      AppConfig.stubs(:paypal_notify_url).returns("http://testhost.com/paypal_notifications")
    end

    should "include notify_url hidden input" do
      set_purchase_session(@daily_deal_purchase)
      get :confirm, :id => @daily_deal_purchase.uuid
      assert_select "input[name=notify_url][type=hidden][value=http://testhost.com/paypal_notifications]"
    end
  end

  context 'when confirming a purchase while signed in as a consumer' do
    setup do
      daily_deal_purchase = Factory :pending_daily_deal_purchase
      login_as(daily_deal_purchase.consumer)
      get :confirm, :id => daily_deal_purchase.to_param
    end
    should 'succeed' do
      assert_response :success
    end
  end

  context 'when confirming a purchase with purchase authorization' do
    setup do
      daily_deal_purchase = Factory :pending_daily_deal_purchase
      set_purchase_session daily_deal_purchase
      get :confirm, :id => daily_deal_purchase.to_param
    end
    should 'succeed' do
      assert_response :success
    end
  end

  context 'when confirming a purchase while neither signed in nor with purchase authorization' do
    setup do
      @daily_deal_purchase = Factory :pending_daily_deal_purchase
      get :confirm, :id => @daily_deal_purchase.to_param
    end
    should 'redirect to login' do
      assert_redirected_to new_publisher_daily_deal_session_path(@daily_deal_purchase.daily_deal.publisher)
    end
  end

  private

  def assert_transaction_data(expected_transaction_data)
    doc = Nokogiri::XML(@response.body)
    transaction_data = doc.css("input[type=hidden][name=transaction_data]")[0][:value]
    assert_select "input[type=hidden][name=transaction_data][value=?]", Rack::Utils.escape_html(expected_transaction_data), {},
                  "Expected transaction data: #{expected_transaction_data.inspect} Found: #{transaction_data.inspect}"
  end

end
