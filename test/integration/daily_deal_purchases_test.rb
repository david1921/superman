require File.dirname(__FILE__) + "/../test_helper"

class DailyDealPurchasesTest < ActionController::IntegrationTest
  test "referral credit is awarded" do
    publisher = Factory(:publisher)
    referrer = Factory(:consumer)
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    get_via_redirect public_deal_of_day_url(:label => publisher.label, :referral_code => referrer.referrer_code)

    # Create and capture purchase
    post daily_deal_daily_deal_purchases_path(daily_deal), :daily_deal_purchase => {
        :quantity => "1",
        :gift => "0"
    }, :consumer => {
        :name => "Michael Mouse",
        :email => "mickey@disney.com",
        :password => "minnieme",
        :password_confirmation => "minnieme",
        :agree_to_terms => "1"
    }
    daily_deal_purchase = assigns(:daily_deal_purchase)
    get confirm_daily_deal_purchase_path(:id => daily_deal_purchase.uuid)

    Braintree::TransparentRedirect.expects(:confirm).returns(braintree_transaction_submitted_result(daily_deal_purchase))

    get braintree_redirect_daily_deal_purchase_path(:id => daily_deal_purchase.to_param),
        :kind => "create_transaction",
        :hash => "c7520d7b430f03a767834f221a749a33776aa442",
        :http_status => "200"

    # Check that the referrer got a referral credit
    assert 1, referrer.credits.size
  end

  test "localized daily deal purchase english" do
    daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
    get "daily_deals/#{daily_deal.to_param}/daily_deal_purchases/new"
    assert_response :success
    assert_template "daily_deal_purchases/new"
    assert_equal :en, I18n.locale, "default locale should be English"
    assert !@response.body.include?('translation missing:'), "Should not have translation missing on page: \n" << @response.body
  end

  test "localized daily deal purchase spanish" do
    daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
    get "daily_deals/#{daily_deal.to_param}/daily_deal_purchases/new?locale=es"
    assert_response :success
    assert_template "daily_deal_purchases/new"
    assert_equal :es, I18n.locale
    assert !@response.body.include?('translation missing:'), "Should not have translation missing on page: \n" << @response.body
  end

  context "index action guard" do
    setup do
      @publisher = Factory(:publisher)
      @consumer = Factory(:consumer, :publisher => @publisher, :password => "foobar", :password_confirmation => "foobar")
    end

    should "redirect to new session when consumer is not logged in" do
      get_via_redirect "publishers/#{@publisher.id}/consumers/#{@consumer.id}/daily_deal_purchases"
      assert_response :success
      assert_template "daily_deal_sessions/new"
    end

    should "redirect to new session when current_consumer is requesting page for different consumer" do
      wrong_consumer = Factory(:consumer, :password => "foobar", :password_confirmation => "foobar")
      post session_path, :user => { :login => wrong_consumer.login, :password => "foobar" }
      assert_equal wrong_consumer.id, session[:user_id]
      get_via_redirect "publishers/#{@publisher.id}/consumers/#{@consumer.id}/daily_deal_purchases"
      assert_response :success
      assert_template "daily_deal_sessions/new"
      assert_equal nil, session[:user_id]
      post_via_redirect session_path, :user => { :login => @consumer.login, :password => "foobar" }
      assert_response :success
      assert_equal @consumer.id, session[:user_id]
      assert_template "daily_deal_purchases/index"
    end

    should "redirect to new session when current_consumer is logged in to a different publisher" do
      wrong_publisher = Factory(:publisher)
      post session_path, :user => { :login => @consumer.login, :password => "foobar" }
      assert_equal @consumer.id, session[:user_id]
      get_via_redirect "publishers/#{wrong_publisher.id}/consumers/#{@consumer.id}/daily_deal_purchases"
      assert_response :success
      assert_template "daily_deal_sessions/new"
      assert_equal nil, session[:user_id]
    end

    should "allow admin access" do
      admin = Factory(:admin, :password => "foobar", :password_confirmation => "foobar")
      post session_path, :user => { :login => admin.login, :password => "foobar" }
      assert_equal admin.id, session[:user_id]
      get_via_redirect "publishers/#{@publisher.id}/consumers/#{@consumer.id}/daily_deal_purchases"
      assert_response :success
      assert_template "daily_deal_purchases/index"
    end
  end

  context "auto login after purchase" do
    context "using Travelsavers payment method" do
        should "log in consumer after successful purchase" do
          booking = Factory(:successful_travelsavers_booking)
          daily_deal_purchase = booking.daily_deal_purchase
          my_deals_path = "publishers/#{daily_deal_purchase.publisher.id}/consumers/#{daily_deal_purchase.consumer.id}/daily_deal_purchases"
          get my_deals_path
          assert_response :redirect
          assert_nil session[:user_id]
          get "/travelsavers_bookings/try_to_resolve/#{booking.to_param}"
          assert_response :success
          assert_not_equal " ", @response.body
          get my_deals_path
          assert_response :success
          assert_equal daily_deal_purchase.consumer.id, session[:user_id]
        end

        should "not log in consumer after unsucessful purchase" do
          booking = Factory(:successful_travelsavers_booking_with_failed_payment)
          daily_deal_purchase = booking.daily_deal_purchase
          my_deals_path = "publishers/#{daily_deal_purchase.publisher.id}/consumers/#{daily_deal_purchase.consumer.id}/daily_deal_purchases"
          get my_deals_path
          assert_response :redirect
          assert_nil session[:user_id]
          get "/travelsavers_bookings/try_to_resolve/#{booking.to_param}"
          assert_response :success
          assert_not_equal " ", @response.body
          get my_deals_path
          assert_response :redirect
          assert_nil session[:user_id]
        end
    end
  end

end
