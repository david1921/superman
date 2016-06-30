require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class DailyDealsController::Show::VariationsPricingTest

module DailyDealsController::Show
  class VariationsPricingTest < ActionController::TestCase
    tests DailyDealsController

    context "The default view" do
      setup do
        setup_variations_and_get_deal_show_page_for("notheme123")
      end

      should "display the lowest priced variation's value" do
        assert_select "#daily_deal_value", "$20"
      end

      should "display the lowest priced variation's price" do
        assert_select "#daily_deal_price", "$10"
      end

      should "display the lowest priced variation's savings" do
        assert_select "#daily_deal_savings", "$10"
      end
    end

    context "Clever Betta" do
      setup do
        setup_variations_and_get_deal_show_page_for("cleverbetta")
      end

      should "display the lowest priced variation's value" do
        assert_select "#value_info td", "$20"
      end

      should "display the lowest priced variation's price" do
        assert_select "#value_info td", "$10"
      end

      should "display the lowest priced variation's savings" do
        assert_select "#value_info td", "$10"
      end
    end

    context "Entercom" do
      setup do
        setup_variations_and_get_deal_show_page_for("entercomnew")
      end

      should "display the lowest priced variation's value (or #value_to_display" do
        assert_select "#daily_deal_value", "$20.00", "should be @daily_deal.value_to_display"
      end

      should "display the lowest priced variation's savings" do
        assert_select "#daily_deal_savings", "$7.50", "should be @daily_deal.savings"
      end
    end

    context "Entertainment" do
      setup do
        setup_variations_and_get_deal_show_page_for("entertainment")
      end

      should "display the lowest priced variation's value" do
        assert_select ".dashboard td span", "$20"
      end

      should "display the lowest priced variation's savings as a percentage" do
        assert_select ".dashboard td span", "50%"
      end

      should "display the lowest priced variation's savings" do
        assert_select ".dashboard td span", "$10"
      end
    end

    context "Fundogo" do
      setup do
        setup_variations_and_get_deal_show_page_for("fundogo")
      end

      should "display the lowest priced variation's value" do
        assert_select ".value_summary td", "$20"
      end

      should "display the lowest priced variation's savings as a percentage" do
        assert_select ".value_summary td", "50%"
      end
    end

    context "KPSP" do
      setup do
        setup_variations_and_get_deal_show_page_for("newspress")
      end

      should "display the lowest priced variation's value" do
        assert_select ".value_summary .value", "$20"
      end

      should "display the lowest priced variation's savings as a percentage" do
        assert_select ".value_summary .savings", "50%"
      end
    end

    context "TWC" do
      setup do
        setup_variations_and_get_deal_show_page_for("rr")
      end

      should "display the lowest priced variation's value" do
        assert_select "#value_summary td", "$20"
      end

      should "display the lowest priced variation's savings" do
        assert_select "#value_summary td", "$10"
      end
    end

    context "WCAX" do
      setup do
        setup_variations_and_get_deal_show_page_for("wcax")
      end

      should "display the lowest priced variation's value" do
        assert_select ".dash_value", "$20"
      end

      should "display the lowest priced variation's savings as a percentage" do
        assert_select ".dash_value", "50%"
      end

      should "display the lowest priced variation's savings" do
        assert_select ".dash_value", "$10"
      end
    end

    # context "Prowlingpanther" do
    #   setup do
    #     setup_variations_and_get_deal_show_page_for("prowlingpanther")
    #   end

    #   should "display the lowest priced variation's value" do
    #     assert_select "#daily_deal_value span", "$20"
    #   end

    #   should "display the lowest priced variation's savings" do
    #     assert_select "#daily_deal_savings span", "50%"
    #   end
    # end

    private

    def setup_variations_and_get_deal_show_page_for(label)
      @publisher = Factory(:publisher, :label => label, :enable_daily_deal_variations => true)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher, :value => 10.00, :price => 2.50)
      Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 20.00, :price => 10.00)
      Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 50.00, :price => 25.00)
      Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 10.00, :price => 7.00, :deleted_at => Time.now)
      get :show, :id => @daily_deal.to_param
      assert_response :success
    end
  end
end
