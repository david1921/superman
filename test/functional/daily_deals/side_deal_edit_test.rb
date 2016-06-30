require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::SideDealEditTest < ActionController::TestCase
  tests DailyDealsController
  include DailyDealHelper

  context "side-deal fields" do
    setup do
      login_as Factory(:admin)
    end

    context "when the deal has no side-deal-date attributes" do
      setup do
        daily_deal = Factory(:featured_daily_deal)
        get :edit, :id => daily_deal.to_param
      end
      
      should "not display" do
        assert_select("div[id='side_deal_fields'][style='display: none']", :count => 1) do
          assert_select("label[for='daily_deal_side_start_at']", :count => 1)
          assert_select("label[for='daily_deal_side_end_at']", :count => 1)
        end
      end

      should "instead have a button to display the fields" do
        assert_select("div[id='enable_side_deal']", :count => 1)
      end
    end

    context "when the deal has side-deal-date attributes" do
      setup do
        daily_deal = Factory(:side_daily_deal)
        get :edit, :id => daily_deal.to_param
      end
      
      should "display" do
        assert_select("div[id='side_deal_fields'][style='display: block']", :count => 1) do
          assert_select("label[for='daily_deal_side_start_at']", :count => 1)
          assert_select("label[for='daily_deal_side_end_at']", :count => 1)
        end
      end

      should "not have a button to display the fields" do
        assert_select("div[id='enable_side_deal']", :count => 0)
      end
    end

  end
end
