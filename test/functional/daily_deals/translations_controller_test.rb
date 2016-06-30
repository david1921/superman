require File.dirname(__FILE__) + "/../../test_helper"

# More tests are in integration/daily_deals/translation_test.rb
# because routing-filter does not support passing :locale
# in functional tests.

# hydra class DailyDeals::TranslationsControllerTest
class DailyDeals::TranslationsControllerTest < ActionController::TestCase
  fast_context "edit" do
    setup do
      @daily_deal = Factory(:daily_deal)
      login_as Factory(:admin)
      get :edit, :daily_deal_id => @daily_deal.to_param
    end

    should render_template(:edit)
    should assign_to(:daily_deal)
  end

  fast_context "update" do
    setup do
      @daily_deal = Factory(:daily_deal)
      login_as Factory(:admin)
    end

    fast_context "valid attributes" do
      setup do
        put :update, :daily_deal_id => @daily_deal.to_param, 
            :daily_deal => { :value_proposition => "test value proposition" }
      end

      should "redirect to daily deal translation edit page" do
        assert_redirected_to edit_daily_deal_translations_for_locale_path(@daily_deal, I18n.default_locale)
      end
      should "update the daily_deal" do
        assert_equal "test value proposition", @daily_deal.reload.value_proposition
      end
    end

    fast_context "invalid attributes" do
      setup do
        put :update, :daily_deal_id => @daily_deal.to_param, 
            :daily_deal => { :value_proposition => "" }
      end

      should render_template(:edit)
      should "have errors on the daily_deal" do
        assert assigns(:daily_deal).errors.on(:value_proposition)
      end
    end
  end
end
