require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::NewTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  test "new" do
    daily_deal = Factory(:daily_deal)
    get :new, :daily_deal_id => daily_deal.to_param
    assert_response :success
    assert_template "daily_deal_purchases/new"
    daily_deal_purchase = assigns(:daily_deal_purchase)
    assert_not_nil daily_deal_purchase, "Assignment of daily_deal_purchase"

    consumer = daily_deal_purchase.consumer
    assert_not_nil consumer, "Daily deal purchase should have a consumer"
    assert_nil session[:user_id], "Consumer should not be logged in"

    assert_equal daily_deal.publisher, consumer.publisher, "New consumer should belong to daily-deal publisher"
    assert_nil consumer.signup_discount, "New consumer should not have a discount"
    assert_select "#daily_deal_purchase_store_id", 0
    assert_select "#review_button", 1, :test => 'Review and Buy'
  end

  test "new for ocregister" do
    publisher = Factory.build(:publisher, :label => "ocregister")
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    get :new, :daily_deal_id => daily_deal.to_param
    assert_response :success
    assert_template "daily_deal_purchases/new"
  end

  test "new for ocregister expired deal" do
    publisher = Factory.build(:publisher, :label => "ocregister")
    daily_deal = Factory(:daily_deal, :publisher => publisher, :hide_at => 1.days.ago)
    assert_raise ActiveRecord::RecordNotFound do
      get :new, :daily_deal_id => daily_deal.to_param
    end
  end

  test "new with category" do
    publisher   = Factory(:publisher, :label => "nydailynews")
    category    = Factory(:daily_deal_category)
    daily_deal  = Factory(:daily_deal, :publisher => publisher, :analytics_category => category)
    get :new, :daily_deal_id => daily_deal.to_param
    assert_response :success
    assert_template "daily_deal_purchases/new"
  end

  test "new for novadog" do
    publisher   = Factory(:publisher, :label => "novadog")
    daily_deal  = Factory(:daily_deal, :publisher => publisher)
    get :new, :daily_deal_id => daily_deal.to_param
    assert_response :success
    assert_template "daily_deal_purchases/new"
    assert_select "form[action='#{daily_deal_daily_deal_purchases_path(daily_deal)}']" do
      assert_select "input[type='text'][name='consumer[referral_code]']", true, "should have referral code"
    end
  end

  test "new should show locations" do
    advertiser = Factory(:store).advertiser
    advertiser.stores.create!(
      :address_line_1 => "123 Main Street",
      :address_line_2 => "Suite 4",
      :city => "Hicksville",
      :state => "NY",
      :zip => "11801"
    )
    daily_deal = Factory(:daily_deal, :advertiser => advertiser, :location_required => true)

    get :new, :daily_deal_id => daily_deal.to_param
    assert_response :success
    daily_deal_purchase = assigns(:daily_deal_purchase)
    assert_not_nil daily_deal_purchase, "Assignment of daily_deal_purchase"

    assert_select "#daily_deal_purchase_store_id", 1 do
      assert_select "option", "Please choose a location"
      assert_select "option", "123 Main Street, Hicksville, NY"
    end
  end

  test "new with consumer logged in and having a signup discount shows subtotal and discount rows" do
    discount = Factory(:discount)
    publisher = discount.publisher
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    consumer = Factory(:consumer, :publisher => publisher, :signup_discount => discount)

    login_as consumer
    get :new, :daily_deal_id => daily_deal.to_param

    assert_response :success
    daily_deal_purchase = assigns(:daily_deal_purchase)
    assert_not_nil daily_deal_purchase, "Assignment of daily_deal_purchase"

    assert_equal consumer, daily_deal_purchase.consumer, "Daily deal purchase should have a consumer"
    assert_equal consumer.id, session[:user_id], "Consumer should be logged in"

    assert_select "tr#subtotal[style='']", 1 do
      assert_select "#purchase_subtotal_value", :text => "$15.00", :quantity => 1
    end
    assert_select "tr#discount[style='']", 1 do
      assert_select "td.description", :text => /discount code/i, :count => 1
      assert_select "td.price", "-&nbsp;$10.00"
    end
  end

  test "new with consumer logged in and not having a signup discount hides subtotal and discount rows" do
    daily_deal = Factory(:daily_deal)
    consumer = Factory(:consumer, :publisher => daily_deal.publisher)

    login_as consumer
    get :new, :daily_deal_id => daily_deal.to_param

    assert_response :success
    daily_deal_purchase = assigns(:daily_deal_purchase)
    assert_not_nil daily_deal_purchase, "Assignment of daily_deal_purchase"

    assert_equal consumer, daily_deal_purchase.consumer, "Daily deal purchase should have a consumer"
    assert_equal consumer.id, session[:user_id], "Consumer should be logged in"

    assert_select "tr#subtotal[style='display: none;']", 1
    assert_select "tr#discount[style='display: none;']", 1
  end

  test "new with consumer logged in and having credit shows subtotal and credit rows" do
    daily_deal = Factory(:daily_deal)
    consumer = Factory(:consumer, :publisher => daily_deal.publisher)
    consumer.credits.create! :amount => 10.00

    login_as consumer
    get :new, :daily_deal_id => daily_deal.to_param

    assert_response :success
    daily_deal_purchase = assigns(:daily_deal_purchase)
    assert_not_nil daily_deal_purchase, "Assignment of daily_deal_purchase"

    assert_equal consumer, daily_deal_purchase.consumer, "Daily deal purchase should have a consumer"
    assert_equal consumer.id, session[:user_id], "Consumer should be logged in"

    assert_select "tr#subtotal[style='']", 1 do
      assert_select "#purchase_subtotal_value", :text => "$15.00", :quantity => 1
    end
    assert_select "tr#credit[style='']", 1 do
      assert_select "td.description", :text => /applied from \$10.00 balance/i, :count => 1
      assert_select "td.price", "-&nbsp;$10.00"
    end
  end

  test "new with consumer logged in and not having credit hides subtotal and credit rows" do
    daily_deal = Factory(:daily_deal)
    consumer = Factory(:consumer, :publisher => daily_deal.publisher)

    login_as consumer
    get :new, :daily_deal_id => daily_deal.to_param

    assert_response :success
    daily_deal_purchase = assigns(:daily_deal_purchase)
    assert_not_nil daily_deal_purchase, "Assignment of daily_deal_purchase"

    assert_equal consumer, daily_deal_purchase.consumer, "Daily deal purchase should have a consumer"
    assert_equal consumer.id, session[:user_id], "Consumer should be logged in"

    assert_select "tr#subtotal[style='display: none;']", 1
    assert_select "tr#credit[style='display: none;']", 1
  end

  test "new with USD publisher, no discount applied" do |variable|
    daily_deal = Factory :daily_deal, :price => 5, :value => 15
    consumer = Factory(:consumer, :publisher => daily_deal.publisher)

    login_as consumer
    get :new, :daily_deal_id => daily_deal.id

    assert_response :success
    assert_select "td.price", :text => "$5.00", :count => 1
    assert_select "span#purchase_total_value", :text => "$5.00", :count => 1
  end

  test "new with USD publisher, discount applied" do
    daily_deal = Factory :daily_deal, :price => "20", :value => "60"
    discount = Factory :discount, :publisher => daily_deal.publisher, :amount => 5
    consumer = Factory(:consumer, :publisher => daily_deal.publisher, :signup_discount => discount)

    login_as consumer
    get :new, :daily_deal_id => daily_deal.id

    assert_response :success
    assert_select "td.price", :text => "$20.00", :count => 1
    assert_select "span#purchase_subtotal_value", :text => "$20.00", :count => 1
    assert_select "span#purchase_total_value", :text => "$15.00", :count => 1
  end

  test "new with GBP publisher, no discount applied" do
    daily_deal = Factory :daily_deal, :price => 5, :value => 15, :min_quantity => 1
    daily_deal.publisher.update_attributes(:currency_code => "GBP")
    consumer = Factory(:consumer, :publisher => daily_deal.publisher)

    login_as consumer
    get :new, :daily_deal_id => daily_deal.id

    assert_response :success
    assert_select "td.price", :text => "£5.00", :count => 1
    assert_select "span#purchase_total_value", :text => "£5.00", :count => 1
  end

  test "new with GBP publisher, discount applied" do
    daily_deal = Factory :daily_deal, :price => 20, :value => 60
    daily_deal.publisher.update_attributes(:currency_code => "GBP")
    discount = Factory :discount, :publisher => daily_deal.publisher, :amount => 5
    consumer = Factory(:consumer, :publisher => daily_deal.publisher, :signup_discount => discount)

    login_as consumer
    get :new, :daily_deal_id => daily_deal.id

    assert_response :success
    assert_select "td.price", :text => "£20.00", :count => 1
    assert_select "span#purchase_subtotal_value", :text => "£20.00", :count => 1
    assert_select "span#purchase_total_value", :text => "£15.00", :count => 1
  end

  test "new with CAD publisher, no discount applied" do
    daily_deal = Factory :daily_deal, :price => 5, :value => 15, :min_quantity => 1
    consumer = Factory(:consumer, :publisher => daily_deal.publisher)
    daily_deal.publisher.update_attributes(:currency_code => "CAD")

    login_as consumer
    get :new, :daily_deal_id => daily_deal.id

    assert_response :success
    assert_select "td.price", :text => "C$5.00", :count => 1
    assert_select "span#purchase_total_value", :text => "C$5.00", :count => 1
  end

  test "new with CAD publisher, discount applied" do
    daily_deal = Factory :daily_deal, :price => 20, :value => 60
    daily_deal.publisher.update_attributes(:currency_code => "CAD")
    discount = Factory :discount, :publisher => daily_deal.publisher, :amount => 5
    consumer = Factory(:consumer, :publisher => daily_deal.publisher, :signup_discount => discount)

    login_as consumer
    get :new, :daily_deal_id => daily_deal.id

    assert_response :success
    assert_select "td.price", :text => "C$20.00", :count => 1
    assert_select "span#purchase_subtotal_value", :text => "C$20.00", :count => 1
    assert_select "span#purchase_total_value", :text => "C$15.00", :count => 1
  end

  test "new with publisher with a payment method of optimal" do
    daily_deal = Factory :daily_deal, :price => 20, :value => 60
    daily_deal.publisher.update_attributes(:currency_code => "GBP", :payment_method => "optimal")

    assert daily_deal.publisher.pay_using?( :optimal )

    get :new, :daily_deal_id => daily_deal.id

    assert_response :success
    assert_template :new
    assert_layout   :daily_deals
    assert_select "iframe[src='#{optimal_daily_deal_daily_deal_purchases_path(daily_deal)}'][class='optimal']"
  end

  test "new with daily deal min quantity" do
    daily_deal = Factory :daily_deal, :price => 20, :value => 60, :min_quantity => 3
    get :new, :daily_deal_id => daily_deal.id

    assert_response :success
    assert_template :new
    assert_layout   :daily_deals
    assert_equal    3, assigns(:daily_deal_purchase).quantity
    assert_select "#daily_deal_purchase_quantity[value=3]"
    assert_select "td.update_total a", "Update Total"
    assert_select "#daily_deal_purchase_gift_true"
    assert_select "#daily_deal_purchase_gift_false"
  end

  context "new with a Travelsavers purchase" do

    setup do
      daily_deal = Factory :travelsavers_daily_deal
      get :new, :daily_deal_id => daily_deal.id
      assert_response :success
      assert_template :new
    end
    
    should "disable the Quantity input and not show the Update Total link" do
      assert_select "#daily_deal_purchase_quantity[disabled=disabled]"
      assert_select "td.update_total a", :text => "Update Total", :count => 0
    end
    
    should "not show the Recipient section" do
      assert_select "h2", :text => "Recipient", :count => 0
      assert_select "#daily_deal_purchase_gift_true", false
      assert_select "#daily_deal_purchase_gift_false", false
    end

  end

  test "new with shopping cart publisher" do
    publisher = Factory(:publisher, :shopping_cart => true)
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    get :new, :daily_deal_id => daily_deal.to_param
    assert_response :success
    assert_template "daily_deal_purchases/new"
    assert_select "#review_button[value='Add to Cart']", 1
  end

  test "optimal with publisher with a payment method of optimal" do
    daily_deal = Factory :daily_deal, :price => 20, :value => 60
    daily_deal.publisher.update_attributes(:currency_code => "GBP", :payment_method => "optimal")

    assert daily_deal.publisher.pay_using?( :optimal )

    get :optimal, :daily_deal_id => daily_deal.id

    assert_response :success
    assert_template :optimal
    assert_layout   :optimal
    assert_select "form[action='#{daily_deal_daily_deal_purchases_path(daily_deal)}']" do
      assert_select "td.price", :text => "£20.00", :count => 1
      assert_select "span#purchase_subtotal_value", :text => "£20.00", :count => 1
      assert_select "span#purchase_total_value", :text => "£20.00", :count => 1
    end
  end

  test "share on facebook check box shown for facebook user" do
    daily_deal = Factory(:daily_deal)
    facebook_consumer = Factory(:facebook_consumer, :publisher => daily_deal.publisher)

    login_as facebook_consumer
    get :new, :daily_deal_id => daily_deal.to_param
    assert_response :success

    assert_select "div#facebook[style='']", 1 do
      assert_select "div#post_to_facebook", 1
    end
  end

  test "share on facebook check box not shown for non facebook user" do
    daily_deal = Factory(:daily_deal)
    consumer = Factory(:consumer, :publisher => daily_deal.publisher)

    login_as consumer
    get :new, :daily_deal_id => daily_deal.to_param
    assert_response :success

    assert_select "div#facebook[style='display: none;']", 1 do
      assert_select "div#post_to_facebook", 1
    end
  end

  test "new with publisher having a discount and allowing discount codes" do
    publisher = Factory.create(:publisher, :allow_discount_codes => true)
    discount = Factory.create(:discount, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :publisher => publisher)

    get :new, :daily_deal_id => daily_deal.to_param

    assert_response :success
    daily_deal_purchase = assigns(:daily_deal_purchase)
    assert_not_nil daily_deal_purchase, "Assignment of daily_deal_purchase"

    assert_select "div#discount_fields", 1 do
      assert_select "input[type=text][name='daily_deal_purchase[discount_code]']", 1
      assert_select "a", "Apply", 1
    end
  end

  test "new with publisher having a discount and not allowing discount codes" do
    publisher = Factory.create(:publisher)
    discount = Factory.create(:discount, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :publisher => publisher)

    get :new, :daily_deal_id => daily_deal.to_param

    assert_response :success
    daily_deal_purchase = assigns(:daily_deal_purchase)
    assert_not_nil daily_deal_purchase, "Assignment of daily_deal_purchase"

    assert_select "div#discount_fields", 0
  end

  test "new with custom payment sidebar" do
    publisher = Factory(:publisher, :label => "entertainment")
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    assert File.exists?("#{Rails.root}/app/views/themes/entertainment/daily_deal_purchases/_payment_sidebar.html.erb")

    get :new, :daily_deal_id => daily_deal.to_param
    assert_response :success
    assert_select "p", :text => /tipping point/, :count => 0
  end

  test "new without custom payment sidebar" do
    publisher = Factory(:publisher, :label => "zingindealz")
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    assert !File.exists?("#{Rails.root}/app/views/themes/zingindealz/daily_deal_purchases/_payment_sidebar.html.erb")
    assert !File.exists?("#{Rails.root}/app/views/themes/freedom/daily_deal_purchases/_payment_sidebar.html.erb")

    get :new, :daily_deal_id => daily_deal.to_param
    assert_response :success
  end

  test "new with required shipping address(es)" do
    daily_deal = Factory(:daily_deal, :requires_shipping_address => true)
    get :new, :daily_deal_id => daily_deal.to_param
    assert_response :success

    assert_select "input[type='hidden'][name='daily_deal_id']"

    assert_select "input[type='text'][name='daily_deal_purchase[recipients_attributes][0][name]']"
    assert_select "input[type='text'][name='daily_deal_purchase[recipients_attributes][0][address_line_1]']"
    assert_select "input[type='text'][name='daily_deal_purchase[recipients_attributes][0][address_line_2]']"
    assert_select "input[type='text'][name='daily_deal_purchase[recipients_attributes][0][city]']"
    assert_select "select[name='daily_deal_purchase[recipients_attributes][0][state]']"
    assert_select "input[type='text'][name='daily_deal_purchase[recipients_attributes][0][zip]']"
  end

  test "new with shipping address message" do
    daily_deal = Factory(:daily_deal, :requires_shipping_address => true, :shipping_address_message => (sa_msg = "We need to know where to send your stuff."))
    get :new, :daily_deal_id => daily_deal.to_param
    assert_response :success
    assert_select "p.shipping_address_message", :text => sa_msg
  end

  context "membership code entry entry" do
    setup do
      @publishing_group = Factory(:publishing_group)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher)
    end

    context "given a publisher not using membership codes" do
      setup do
        @publishing_group.update_attribute(:require_publisher_membership_codes, false)
        get :new, :daily_deal_id => @daily_deal.to_param
      end

      should "not show membership code entry entry for consumer" do
        assert_select "input[type='text'][name='consumer[publisher_membership_code_as_text]']", false
      end
    end

    context "given a publisher using membership codes" do
      setup do
        @publishing_group.update_attribute(:require_publisher_membership_codes, true)
        get :new, :daily_deal_id => @daily_deal.to_param
      end

      should "show membership code entry entry for consumer" do
        assert_select "input[type='text'][name='consumer[publisher_membership_code_as_text]']", true
      end
    end
  end

  context "with publisher.allow_registration_during_purchase" do
    setup do
      @publisher = Factory(:publisher, :allow_registration_during_purchase => false)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher)
    end

    should "redirect to login page if not logged in" do
      get :new, :daily_deal_id => @daily_deal.to_param

      assert_nil session[:user_id]
      assert_equal session[:return_to], new_daily_deal_daily_deal_purchases_path(@daily_deal)
      assert_redirected_to new_publisher_daily_deal_session_path(@publisher)
    end

    should "render page if logged in" do
      consumer = Factory(:consumer, :publisher => @publisher)
      login_as consumer

      get :new, :daily_deal_id => @daily_deal.to_param
      assert_response :success
    end
  end

  context "daily deal variation" do

    setup do
      @daily_deal = Factory(:daily_deal)
      @publisher  = @daily_deal.publisher
      @publisher.update_attribute(:enable_daily_deal_variations, true)

      @consumer   = Factory(:consumer, :publisher => @publisher)

      @variation  = Factory(:daily_deal_variation, :daily_deal => @daily_deal)
    end

    context "with a publisher without daily deal variations enabled" do

        should "not render the daily_deal_variation_id hidden field" do
          assert @publisher.update_attribute(:enable_daily_deal_variations, false)
          login_as @consumer
          get :new, :daily_deal_id => @daily_deal.to_param, :daily_deal_variation_id => @variation.to_param
          assert_template :new
          assert_nil assigns(:daily_deal_variation)
          assert_select "input[type=hidden][name='daily_deal_purchase[daily_deal_variation_id]'][value='#{@variation.to_param}']", false
        end

    end

    context "with a publisher with daily deal variations enabled" do
        
        should "render the daily deal variation id hidden field" do
          assert @publisher.update_attribute(:enable_daily_deal_variations, true)
          login_as @consumer
          get :new, :daily_deal_id => @daily_deal.to_param, :daily_deal_variation_id => @variation.to_param
          assert_template :new
          assert assigns(:daily_deal_variation)
          assert_select "input[type=hidden][name='daily_deal_purchase[daily_deal_variation_id]'][value='#{@variation.to_param}']"
        end

    end

    context "with publisher with daily deal variation enabled and variation has affiliate url" do

      should "redirect to the affilate url" do
        url = "http://localhost/path/to/affiliate"
        @variation.update_attribute(:affiliate_url, url)
        login_as @consumer
        get :new, :daily_deal_id => @daily_deal.to_param, :daily_deal_variation_id => @variation.to_param
        assert_redirected_to url
      end

    end

  end

  context "new with daily deal with an affiliate url" do

    setup do
      @url = "http://www.site.com/path/to/deal"
      @publisher = Factory(:publisher)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher, :affiliate_url => @url)
    end

    should "redirect to the affiliate url" do
      get :new, :daily_deal_id => @daily_deal.to_param
      assert_redirected_to @url
    end

  end

  context "new with daily deal with an affiliate url, entercom" do

    setup do
      @url = "http://www.site.com/path/to/deal"
      pg = Factory(:publishing_group, :label => 'entercomnew')
      @publisher = Factory(:publisher, :label => 'entercom-denver', :publishing_group => pg)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher, :affiliate_url => @url)
    end

    should "redirect to the affiliate url" do
      get :new, :daily_deal_id => @daily_deal.to_param
      assert_redirected_to @url
    end

  end

end
