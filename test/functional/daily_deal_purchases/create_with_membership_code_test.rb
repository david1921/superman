require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::CreateWithMembershipCodeTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  context "with require_publisher_membership_codes" do
    setup do
      @publishing_group = Factory(:publishing_group, :require_publisher_membership_codes => true)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher)
      @publisher_membership_code = Factory(:publisher_membership_code, :publisher => @publisher, :code => "XYZ")
    end

    should "create with new consumer and publisher_membership_code" do
      assert_difference "DailyDealPurchase.count" do
        post_create_with_consumer_params(
          @daily_deal,
          :name => "Joseph Blow",
          :email => "joe@blow.com",
          :password => "secret",
          :password_confirmation => "secret",
          :agree_to_terms => "1",
          :publisher_membership_code_as_text => "XYZ"
        )

        daily_deal_purchase = assigns(:daily_deal_purchase)
        consumer = daily_deal_purchase.consumer

        assert_equal @daily_deal.publisher, consumer.publisher, "New consumer should belong to daily-deal publisher"
      end
    end

    should "fail to create with an invalid membership code" do
      assert_no_difference "DailyDealPurchase.count" do
        post_create_with_consumer_params(
          @daily_deal,
          :name => "Joseph Blow",
          :email => "joe@blow.com",
          :password => "secret",
          :password_confirmation => "secret",
          :agree_to_terms => "1",
          :publisher_membership_code_as_text => "ABC"
        )

        daily_deal_purchase = assigns(:daily_deal_purchase)
        consumer = daily_deal_purchase.consumer

        assert_equal @daily_deal.publisher, consumer.publisher, "New consumer should belong to daily-deal publisher"

        assert consumer.errors.full_messages.include?("ID Card Prefix can't be blank"), consumer.errors.full_messages.join(", ")
        assert !consumer.valid?

        assert_template :new
      end
    end
  end
end
