require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::CreateWithCoolsavings < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  context "create for coolsavings" do

    setup do
      @publisher = Factory(:publisher, :consumer_authentication_strategy => "coolsavings")
      @daily_deal = Factory(:daily_deal, :publisher => @publisher)
    end

    should "authenticate against coolsavings and create purchase when consumer already exists" do
      Consumers::AuthenticationStrategy::Coolsavings.any_instance.expects(:retrieve_member_attributes).returns({})
      consumer = Factory(:consumer, :publisher => @publisher, :email => "yo@yahoo.com")
      assert_difference "DailyDealPurchase.count" do
        post_create_with_consumer_params(@daily_deal, consumer.attributes)
      end
      daily_deal_purchase = assigns(:daily_deal_purchase)
      assert_equal consumer, daily_deal_purchase.consumer
    end

    should "authenticate against coolsavings and create purchase and consumer when consumer does not already exist" do
      Consumers::AuthenticationStrategy::Coolsavings.any_instance.expects(:retrieve_member_attributes).returns({ "EMAIL" => "yo@yahoo.com", "FNAME" => "Joseph", "LNAME" => "Blow" })
      assert_difference "DailyDealPurchase.count" do
        post_create_with_consumer_params(@daily_deal, :email => "yo@yahoo.com", :password => "does_not_matter")
      end
      daily_deal_purchase = assigns(:daily_deal_purchase)
      assert_redirected_to confirm_daily_deal_purchase_path(daily_deal_purchase)
      consumer = Consumer.find_by_publisher_id_and_email(@publisher.id, "yo@yahoo.com")
      assert_not_nil consumer, "No consumer found"
      assert_equal consumer, daily_deal_purchase.consumer
    end

    should "behave appropriately when authentication fails" do
      Consumers::AuthenticationStrategy::Coolsavings.any_instance.expects(:retrieve_member_attributes).returns({})
      Consumers::AuthenticationStrategy::Coolsavings.any_instance.expects(:authenticated?).twice.returns(false)
      consumer = Factory(:consumer, :publisher => @publisher, :email => "yo@yahoo.com", :password => "wrongpass", :password_confirmation => "wrongpass")
      assert_no_difference "DailyDealPurchase.count" do
        post_create_with_consumer_params(@daily_deal, consumer.attributes)
      end
      assert_response :success
      assert_template :new
      assert_nil session[:user_id], "Consumer should not be logged in"
    end

  end

end
