require File.dirname(__FILE__) + "/../test_helper"

class SuggestedDailyDealsControllerTest < ActionController::TestCase

  context "logged in" do
    setup do
      @publisher = Factory(:publisher)
      @consumer = Factory(:consumer, :publisher => @publisher)
      login_as @consumer
    end

    context "create" do
      setup do
        @suggested_deal_params = {:description => "This is my suggestion"}
      end

      should "create a new suggested deal" do
        assert_difference "SuggestedDailyDeal.count", 1 do
          put :create, :publisher_id => @publisher.id, :suggested_daily_deal => @suggested_deal_params
        end
      end

      should "assign current user to suggested deal" do
        put :create, :publisher_id => @publisher.id, :suggested_daily_deal => @suggested_deal_params

        @suggested_daily_deal = SuggestedDailyDeal.last
        assert_equal @consumer.id, @suggested_daily_deal.consumer.id
      end
    end

  end

  context "not logged in" do

    context "create" do
      setup do
        @publisher = Factory(:publisher)
        @suggested_deal_params = {:description => "This is my suggestion"}
      end

      should "create a new suggested deal" do
        assert_no_difference "SuggestedDailyDeal.count" do
          put :create, :publisher_id => @publisher.id, :suggested_daily_deal => @suggested_deal_params
          assert_redirected_to new_publisher_daily_deal_session_path(@publisher)
        end
      end
    end

  end
end
