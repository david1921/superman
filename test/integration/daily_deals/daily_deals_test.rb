require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::DailyDealsTest
module DailyDeals
  class DailyDealsTest < ActionController::IntegrationTest
    include BraintreeHelper

    assert_no_angle_brackets :except => :test_consumer_signup_credit

    # Replicate a real user's path to expose bug
    test "multiple activation attempts from email" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      publisher = daily_deal.publisher
      discount = Factory(:discount, :code => "SIGNUP_CREDIT", :publisher => publisher)

      assert_equal publisher, discount.publisher

      get "/publishers/#{publisher.to_param}/consumers/deal_credit"
      assert_response :success

      assert_select "#consumer_name"
      assert_select "#consumer_email"
      assert_select "#consumer_discount_code[value=#{discount.code}]"

      post "/publishers/#{publisher.to_param}/consumers",
           :consumer => { :name => "Joe Viper", :agree_to_terms => true, :purchase_credit => 10.00, :password_confirmation => "secret",
                          :password => "secret", :email => "top.gun@hotmail.com"},
           :sign_up => "Sign Up"

      assert_response :success
      assert_select "p", :text => /check your email/

      consumer = Consumer.first(:conditions => { :email => "top.gun@hotmail.com", :publisher_id => publisher.id })

      get "/publishers/#{publisher.to_param}/consumers/activate?activation_code=#{consumer.activation_code}"
      assert_redirected_to "/publishers/#{publisher.label}/deal-of-the-day"
      follow_redirect!
      assert_response :success

      # dashboard AJAX
      8.times do
        xhr :get, "/daily_deals/#{daily_deal.to_param}.json"
      end

      get "/publishers/#{publisher.to_param}/daily_deal/logout"
      assert_redirected_to "/publishers/#{publisher.label}/deal-of-the-day"
      follow_redirect!
      assert_response :success

      2.times do
        xhr :get, "/daily_deals/#{daily_deal.to_param}.json"
      end

      # Try to activate again. This is current behavior. Whether it's what we want is another thing.
      get "/publishers/#{publisher.to_param}/consumers/activate?activation_code=#{consumer.activation_code}"
      assert_redirected_to "/publishers/#{publisher.to_param}/daily_deal/login"
      follow_redirect!
      assert_response :success
    end

    test "new as post" do
      daily_deal = Factory(:daily_deal, :hide_at => Time.zone.now.tomorrow)
      post "/daily_deals/#{daily_deal.to_param}/daily_deal_purchases/new"
      assert_response :success
    end

    test "consumer signup credit" do
      publisher = Factory.create(:publisher, :allow_discount_codes => true, :show_special_deal => true)
      signup_and_purchase publisher

      # Second purchase should ignore signup discount
      daily_deal = Factory.create(:side_daily_deal, :publisher => publisher, :price => 130)

      get new_daily_deal_daily_deal_purchase_path(daily_deal)
      assert_response :success
      assert_select "form[action='#{daily_deal_daily_deal_purchases_path(daily_deal)}'][method=post]", 1

      # Sign in this time
      post publisher_daily_deal_sessions_path(publisher),
        :session => {
          :email => "mickey@disney.com",
          :password => "minnieme"
        }
      assert_response :redirect
      assert_not_nil session[:user_id], "session :user_id"

      post daily_deal_daily_deal_purchases_path(daily_deal), :daily_deal_purchase => {
        :quantity => "1",
        :gift => "0"
      }
      assert_not_nil(daily_deal_purchase = assigns(:daily_deal_purchase), "Assignment of @daily_deal_purchase")
      assert daily_deal_purchase.valid?, daily_deal_purchase.errors.full_messages
      assert !daily_deal_purchase.new_record?, "Should save DailyDealPurchase"
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)
      assert_nil daily_deal_purchase.discount, "Purchase should not have a daily deal discount"
      assert_equal 0.00, daily_deal_purchase.discount_amount
      assert_equal 130.00, daily_deal_purchase.actual_purchase_price
      assert_no_match /credit has been applied/i, flash[:notice]
    end

    test "consumer signup credit for Liquid templates" do
      publisher = Factory.create(:publisher, :allow_discount_codes => true, :label => "easyreadernews", :show_special_deal => true)
      signup_and_purchase publisher
    end

    test "discount codes in British pounds for Optimal" do
      publisher = Factory.create(:publisher, :allow_discount_codes => true, :label => "thomsonlocal", :currency_code => "GBP", :payment_method => "optimal")
      publisher.discounts.create!(:code => "sexpistols", :amount => 10)
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now, :price => 40, :value => 80, :publisher => publisher)

      get "/publishers/thomsonlocal/deal-of-the-day"
      assert_response :success
      assert !@response.body["Liquid"], "Found Liquid tag error in #{@response.body}"

      get new_daily_deal_daily_deal_purchase_path(daily_deal)
      assert_response :success
      assert !@response.body["Liquid"], "Found Liquid tag error"
      assert_select "iframe.optimal"
      assert_select "iframe.optimal[src='/daily_deals/#{daily_deal.id}/daily_deal_purchases/optimal']"

      get "/daily_deals/#{daily_deal.id}/daily_deal_purchases/optimal"
      assert_response :success
      assert !@response.body["Liquid"], "Found Liquid tag error"
      assert_select "form[action='#{daily_deal_daily_deal_purchases_path(daily_deal)}'][method=post]"
      assert_select "#daily_deal_purchase_discount_code"
      assert_select "#flash_warn"

      xhr :post, apply_publisher_discounts_path(publisher), :daily_deal_purchase => {
        :discount_code => "SEXPISTOLS",
      }
      assert_response :success

      discount = publisher.discounts.usable.at_checkout.find_by_code(Discount.normalize_code("SEXPISTOLS"))
      post daily_deal_daily_deal_purchases_path(daily_deal), :daily_deal_purchase => {
        :quantity => "1",
        :gift => "false",
        :post_to_facebook => "0",
        :credit_used => "0",
        :discount_uuid => discount.uuid,
        :discount_code => ""
      }, :consumer => {
        :name => "Michael Mouse",
        :email => "mickey@disney.com",
        :password => "minnieme",
        :password_confirmation => "minnieme",
        :agree_to_terms => "1"
      }, :review => "Review and Buy",
      :daily_deal_id => daily_deal.to_param

      assert_not_nil(daily_deal_purchase = assigns(:daily_deal_purchase), "Assignment of @daily_deal_purchase")
      assert_redirected_to optimal_confirm_daily_deal_purchase_path(daily_deal_purchase)
      assert_not_nil daily_deal_purchase.discount, "Purchase should have a daily-deal discount"
      assert_equal 10.00, daily_deal_purchase.discount_amount
      assert_match /credit has been applied/i, flash[:notice]
    end

    test "discount codes in Candian dollars" do
      publisher = Factory.create(:publisher, :allow_discount_codes => true, :label => "gazzzebocom", :currency_code => "CAD")
      publisher.discounts.create!(:code => "sexpistols", :amount => 10)
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now, :price => 40, :value => 80, :publisher => publisher)

      get "/publishers/gazzzebocom/deal-of-the-day"
      assert_response :success
      assert !@response.body["Liquid"], "Found Liquid tag error in #{@response.body}"

      get new_daily_deal_daily_deal_purchase_path(daily_deal)
      assert_response :success
      assert !@response.body["Liquid"], "Found Liquid tag error"

      get new_daily_deal_daily_deal_purchase_path(daily_deal)
      assert_response :success
      assert !@response.body["Liquid"], "Found Liquid tag error"
      assert_select "form[action='#{daily_deal_daily_deal_purchases_path(daily_deal)}'][method=post]", 1

      xhr :post, apply_publisher_discounts_path(publisher), :daily_deal_purchase => {
        :discount_code => "SEXPISTOLS",
      }
      assert_response :success

      discount = publisher.discounts.usable.at_checkout.find_by_code(Discount.normalize_code("SEXPISTOLS"))
      post daily_deal_daily_deal_purchases_path(daily_deal), :daily_deal_purchase => {
        :quantity => "1",
        :gift => "false",
        :post_to_facebook => "0",
        :credit_used => "0",
        :discount_uuid => discount.uuid,
        :discount_code => ""
      }, :consumer => {
        :name => "Michael Mouse",
        :email => "mickey@disney.com",
        :password => "minnieme",
        :password_confirmation => "minnieme",
        :agree_to_terms => "1"
      }, :review => "Review and Buy",
      :daily_deal_id => daily_deal.to_param

      assert_not_nil(daily_deal_purchase = assigns(:daily_deal_purchase), "Assignment of @daily_deal_purchase")
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)
      assert_not_nil daily_deal_purchase.discount, "Purchase should have a daily-deal discount"
      assert_equal 10.00, daily_deal_purchase.discount_amount
      assert_match /credit has been applied/i, flash[:notice]
    end

    test "signup and purchase" do
      ActionMailer::Base.deliveries.clear
      publisher = Factory(:publisher, :label => "seattlepi")
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now, :publisher => publisher)

      get "/publishers/seattlepi/deal-of-the-day"
      assert_response :success

      get new_daily_deal_daily_deal_purchase_path(daily_deal)
      assert_response :success

      post daily_deal_daily_deal_purchases_path(daily_deal),
        :daily_deal_purchase => {
          :quantity => "1",
          :gift => "false",
          :post_to_facebook => "0",
          :credit_used => "0",
          :discount_uuid => "0",
          :discount_code => ""
        },
        :consumer => {
          :name => "Michael Mouse",
          :email => "mickey@disney.com",
          :password => "minnieme",
          :password_confirmation => "minnieme",
          :agree_to_terms => "1"
        },
        :review => "Review and Buy",
        :daily_deal_id => daily_deal.to_param
      
      assert_not_nil(daily_deal_purchase = assigns(:daily_deal_purchase))
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)

      Braintree::TransparentRedirect.expects(:confirm).returns(braintree_transaction_submitted_result(daily_deal_purchase))

      get braintree_redirect_daily_deal_purchase_path(:id => daily_deal_purchase.to_param),
        :kind => "create_transaction",
        :hash => "c7520d7b430f03a767834f221a749a33776aa442",
        :http_status => "200"

      assert_redirected_to thank_you_daily_deal_purchase_path(daily_deal_purchase)
      assert_equal 1, ActionMailer::Base.deliveries.size
      assert_equal 1, daily_deal_purchase.daily_deal_certificates(true).size
      assert_equal 'captured', daily_deal_purchase.reload.payment_status
    end

    test "signup and purchase with capture_on_purchase as false" do
      ActionMailer::Base.deliveries.clear
      AppConfig.capture_on_purchase = false

      publisher = Factory(:publisher, :label => "seattlepi")
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now, :publisher => publisher)

      get "/publishers/seattlepi/deal-of-the-day"
      assert_response :success

      get new_daily_deal_daily_deal_purchase_path(daily_deal)
      assert_response :success

      post daily_deal_daily_deal_purchases_path(daily_deal),
        :daily_deal_purchase => {
          :quantity => "1",
          :gift => "false",
          :post_to_facebook => "0",
          :credit_used => "0",
          :discount_uuid => "0",
          :discount_code => ""
        },
        :consumer => {
          :name => "Michael Mouse",
          :email => "mickey@disney.com",
          :password => "minnieme",
          :password_confirmation => "minnieme",
          :agree_to_terms => "1"
        },
        :review => "Review and Buy",
        :daily_deal_id => daily_deal.to_param
      
      assert_not_nil(daily_deal_purchase = assigns(:daily_deal_purchase))
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)

      Braintree::TransparentRedirect.expects(:confirm).returns(braintree_transaction_authorized_result(daily_deal_purchase))

      get braintree_redirect_daily_deal_purchase_path(:id => daily_deal_purchase.to_param),
        :kind => "create_transaction",
        :hash => "c7520d7b430f03a767834f221a749a33776aa442",
        :http_status => "200"

      assert_redirected_to thank_you_daily_deal_purchase_path(daily_deal_purchase)
      assert_equal 1, ActionMailer::Base.deliveries.size
      assert_equal 1, daily_deal_purchase.daily_deal_certificates(true).size
      assert_equal 'authorized', daily_deal_purchase.reload.payment_status
    end
    
    def signup_and_purchase(publisher)
      publisher.discounts.create!(:code => "SIGNUP_CREDIT", :amount => 10)

      get deal_credit_publisher_consumers_path(publisher)
      assert_response :success
      assert_select "form[action='#{publisher_consumers_path(publisher)}'][method=post]"
      assert_select "input[type=text][name='consumer[discount_code]'][value=SIGNUP_CREDIT][disabled=disabled]", 1

      post publisher_consumers_path(publisher), :consumer => {
        :name => "Michael Mouse",
        :email => "mickey@disney.com",
        :password => "minnieme",
        :password_confirmation => "minnieme",
        :agree_to_terms => "1"
      }
      assert_response :success
      assert_not_nil(consumer = assigns(:consumer), "Assignment of @consumer")
      assert_not_nil consumer.signup_discount, "Consumer should have a daily-deal discount"
      assert_equal "SIGNUP_CREDIT", consumer.signup_discount.code
      assert_equal 10.00, consumer.signup_discount.amount

      daily_deal = Factory.create(:daily_deal, :publisher => publisher)
      get new_daily_deal_daily_deal_purchase_path(daily_deal)
      assert_response :success
      assert_select "form[action='#{daily_deal_daily_deal_purchases_path(daily_deal)}'][method=post]", 1

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
      assert_not_nil(daily_deal_purchase = assigns(:daily_deal_purchase), "Assignment of @daily_deal_purchase")
      assert daily_deal_purchase.valid?, daily_deal_purchase.errors.full_messages
      assert !daily_deal_purchase.new_record?, "Should save DailyDealPurchase"
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)
      assert_not_nil daily_deal_purchase.discount, "Purchase should have a daily-deal discount"
      assert_equal 10.00, daily_deal_purchase.discount_amount
      assert_match /credit has been applied/i, flash[:notice]

      get confirm_daily_deal_purchase_path(:id => daily_deal_purchase.uuid)
      assert_response :success

      Braintree::TransparentRedirect.expects(:confirm).returns(braintree_transaction_submitted_result(daily_deal_purchase))

      get braintree_redirect_daily_deal_purchase_path(:id => daily_deal_purchase.to_param),
        :kind => "create_transaction",
        :hash => "c7520d7b430f03a767834f221a749a33776aa442",
        :http_status => "200"

      assert_redirected_to thank_you_daily_deal_purchase_path(daily_deal_purchase)
    end

  end
end
