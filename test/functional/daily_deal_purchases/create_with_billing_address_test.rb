require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::CreateWithBillingAddress < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  test "create with new consumer required billing address" do 
    publisher = Factory(:publisher, :require_billing_address => true)
    daily_deal = Factory(:daily_deal, :publisher => publisher)
  
    assert_difference "DailyDealPurchase.count" do
      post_create_with_consumer_params(
        daily_deal,
        :name => "John Doe", 
        :email => "john@example.com", 
        :password => "secret", 
        :password_confirmation => "secret", 
        :agree_to_terms => "1",
        :address_line_1 => "123 Main Street", 
        :address_line_2 => "Suite 4", 
        :billing_city => "Hicksville", 
        :state => "NY",
        :zip_code => "11801", 
        :country_code => "US"
      )
      daily_deal_purchase = assigns(:daily_deal_purchase)
      assert_not_nil daily_deal_purchase, "Assignment of daily_deal_purchase"
      assert_no_errors daily_deal_purchase
      assert !daily_deal_purchase.new_record?, "Should have saved new purchase"
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)
      assert_nil session[:user_id], "Consumer should not be logged in"

      consumer = daily_deal_purchase.consumer
      assert_equal daily_deal.publisher, consumer.publisher, "New consumer should belong to daily-deal publisher" 
      assert_not_nil daily_deal_purchase.ip_address
      assert_equal "John Doe", consumer.name
      assert_equal "john@example.com", consumer.email
      assert_equal "123 Main Street", consumer.address_line_1
      assert_equal "Suite 4", consumer.address_line_2
      assert_equal "Hicksville", consumer.billing_city
      assert_equal "NY", consumer.state
      assert_equal "US", consumer.country_code, "Country should default to US"
      assert_equal "11801", consumer.zip_code
      assert !consumer.active?, "New consumer should not be active before purchase is complete"
    end
  end  

  test "create with existing consumer with  billing address publisher require billing address" do 
    publisher = Factory(:publisher, :require_billing_address => true)
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    billing_address_consumer = Factory(:billing_address_consumer, :publisher => daily_deal.publisher)
    assert publisher.require_billing_address
    assert billing_address_consumer.billing_address_present?
  
    assert_difference "DailyDealPurchase.count" do
      login_as billing_address_consumer
      post_create_with_consumer_params daily_deal
      
      daily_deal_purchase = assigns(:daily_deal_purchase)
      assert_no_errors daily_deal_purchase
      assert !daily_deal_purchase.new_record?, "Should have saved new purchase"
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)
  
      assert_equal billing_address_consumer, daily_deal_purchase.consumer
      assert_equal nil, daily_deal_purchase.market
      assert_equal billing_address_consumer.id, session[:user_id], "Consumer should still be logged in"
      assert daily_deal_purchase.consumer.active?, "Existing consumer should still be active"
    end
  end  

  test "create with existing consumer no billing address publisher require billing address" do
    publisher = Factory(:publisher)
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    consumer = Factory(:consumer, :publisher => daily_deal.publisher)

    publisher.require_billing_address = true
    publisher.save!
    publisher.reload
    assert publisher.require_billing_address
    assert ! consumer.billing_address_present?

    assert_no_difference "DailyDealPurchase.count" do
      login_as consumer
      post_create_with_consumer_params(
        daily_deal
      )

      assert_response :success
      assert_template :new
      assert_equal consumer.id, session[:user_id], "Consumer should be logged in"
      assert_select "input[name='consumer[address_line_1]']", 1
      assert_select "input[name='consumer[address_line_2]']", 1
      assert_select "input[name='consumer[billing_city]']", 1
      assert_select "select[name='consumer[state]']", 1
      assert_select "input[name='consumer[zip_code]']", 1
      assert_select "select[name='consumer[country_code]']", 1
    end
  end

  test "create with existing consumer new billing address publisher require billing address" do
    publisher = Factory(:publisher)
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    consumer = Factory(:consumer, :publisher => daily_deal.publisher)
    publisher.require_billing_address = true
    publisher.save!
    publisher.reload
    assert publisher.require_billing_address
    assert ! consumer.billing_address_present?
    assert consumer.active?, "Consumer should be active"

    assert_difference "DailyDealPurchase.count" do
      login_as consumer
      post_create_with_consumer_params(
        daily_deal,
        :address_line_1 => "123 Main Street", :address_line_2 => "Suite 4", :billing_city => "Hicksville", :state => "NY",  :zip_code => "11801", :country_code => "US"
      )

      daily_deal_purchase = assigns(:daily_deal_purchase)
      assert_no_errors daily_deal_purchase
      assert !daily_deal_purchase.new_record?, "Should have saved new purchase"
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)
  
      consumer.reload
      assert_equal consumer, daily_deal_purchase.consumer
      consumer = daily_deal_purchase.consumer
      assert_equal consumer.id, session[:user_id], "Consumer should still be logged in"
      assert daily_deal_purchase.consumer.active?, "Existing consumer should still be active"

      assert_not_nil consumer, "Daily deal purchase should have a consumer"
      assert consumer.billing_address_present?, "Consumer should now have a billing address"
      assert_equal "123 Main Street", consumer.address_line_1
      assert_equal "Suite 4", consumer.address_line_2
      assert_equal "Hicksville", consumer.billing_city
      assert_equal "NY", consumer.state
      assert_equal "US", consumer.country_code, "Country should default to US"
      assert_equal "11801", consumer.zip_code

      assert_equal consumer.id, session[:user_id], "Consumer should still be logged in"
      assert_equal daily_deal.publisher, consumer.publisher, "Consumer should belong to daily-deal publisher" 
      assert_not_nil daily_deal_purchase.ip_address
      assert consumer.active?, "Consumer should still be active"
    end
  end
end
