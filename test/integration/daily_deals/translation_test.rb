require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::TranslationsTest
module DailyDeals
  class TranslationsTest < ActionController::IntegrationTest
    test "html" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      get "/publishers/#{daily_deal.publisher.label}/deal-of-the-day"
      assert_response :success
      assert_equal :en, I18n.locale, "default locale should be English"
    end

    test "html in Spanish" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      get "/publishers/#{daily_deal.publisher.label}/deal-of-the-day?locale=es"
      assert_response :success
      assert_equal :es, I18n.locale, "default locale should be Spanish"
    end

    test "email" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      get "/publishers/#{daily_deal.publisher.label}/deal-of-the-day-email"
      assert_response :success
      assert_equal :en, I18n.locale, "default locale should be English"
    end

    test "json deal of the day" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      get "/publishers/#{daily_deal.publisher.label}/deal-of-the-day.json"
      assert_response :success
      assert_equal :en, I18n.locale, "default locale should be English"
    end

    test "xml deal of the day" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      get "/publishers/#{daily_deal.publisher.label}/deal-of-the-day.xml"
      assert_response :success
      assert_equal :en, I18n.locale, "default locale should be English"
    end

    test "rss deal of the day" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      get "/publishers/#{daily_deal.publisher.label}/deal-of-the-day.rss"
      assert_response :success
      assert_equal :en, I18n.locale, "default locale should be English"
    end

    test "json deal of the day with market" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      market = Factory(:market, :publisher => daily_deal.publisher)
      daily_deal.markets << market
      daily_deal.save!
      get "/publishers/#{daily_deal.publisher.label}/#{market.label}/deal-of-the-day.json"
      assert_response :success
      assert_equal :en, I18n.locale, "default locale should be English"
    end

    test "xml deal of the day with market" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      market = Factory(:market, :publisher => daily_deal.publisher)
      daily_deal.markets << market
      daily_deal.save!
      get "/publishers/#{daily_deal.publisher.label}/#{market.label}/deal-of-the-day.xml"
      assert_response :success
      assert_equal :en, I18n.locale, "default locale should be English"
    end

    test "rss deal of the day with market" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      market = Factory(:market, :publisher => daily_deal.publisher)
      daily_deal.markets << market
      daily_deal.save!
      get "/publishers/#{daily_deal.publisher.label}/#{market.label}/deal-of-the-day.rss"
      assert_response :success
      assert_equal :en, I18n.locale, "default locale should be English"
    end

    test "deal JSON" do
      daily_deal = Factory(:daily_deal)
      get "/daily_deals/#{daily_deal.to_param}.json"
      assert_response :success
      assert_equal :en, I18n.locale, "default locale should be English"
    end

    test "deal XML" do
      daily_deal = Factory(:daily_deal)
      get "/daily_deals/#{daily_deal.to_param}.xml"
      assert_response :success
      assert_equal :en, I18n.locale, "default locale should be English"
    end

    test "localized daily deal english" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      get "/publishers/#{daily_deal.publisher.label}/deal-of-the-day"
      assert_response :success
      assert_equal :en, I18n.locale, "default locale should be English"
      assert !@response.body.include?('translation missing:'), "Should not have translation missing on page: \n" << @response.body
    end

    test "localized daily deal spanish" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      get "/publishers/#{daily_deal.publisher.label}/deal-of-the-day?locale=es"
      assert_response :success
      assert_equal :es, I18n.locale
      assert !@response.body.include?('translation missing:'), "Should not have translation missing on page: \n" << @response.body
    end

    test "localized daily deal with publisher_scoped fields english" do
      publisher = Factory(:publisher, :name => "Busca Ayuda", :label => "buscaayuda")
      daily_deal = Factory(:daily_deal, :publisher => publisher, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      get "/publishers/#{daily_deal.publisher.label}/deal-of-the-day"
      assert_response :success
      assert_equal :en, I18n.locale, "default locale should be English"
      assert !@response.body.include?('translation missing: en, logo, subtext'), "Should not have translation missing on page: \n" << @response.body
    end

    test "localized daily deal with publisher_scoped fields spanish" do
      publisher = Factory(:publisher, :name => "Busca Ayuda", :label => "buscaayuda")
      daily_deal = Factory(:daily_deal, :publisher => publisher, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      get "/publishers/#{daily_deal.publisher.label}/deal-of-the-day?locale=es"
      assert_response :success
      assert_equal :es, I18n.locale
      assert !@response.body.include?('translation missing: en, logo, subtext'), "Should not have translation missing on page: \n" << @response.body
    end

    test "localized sign in english" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      get "/publishers/#{daily_deal.publisher.to_param}/daily_deal_sessions/new"
      assert_response :success
      assert_equal :en, I18n.locale, "default locale should be English"
      assert !@response.body.include?('translation missing:'), "Should not have translation missing on page: \n" << @response.body
    end

    test "localized sign in spanish" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      get "/publishers/#{daily_deal.publisher.to_param}/daily_deal_sessions/new?locale=es"
      assert_response :success
      assert_equal :es, I18n.locale
      assert !@response.body.include?('translation missing:'), "Should not have translation missing on page: \n" << @response.body
    end

    test "localized sign up english" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      get "/publishers/#{daily_deal.publisher.to_param}/consumers/new"
      assert_response :success
      assert_equal :en, I18n.locale, "default locale should be English"
      assert !@response.body.include?('translation missing:'), "Should not have translation missing on page: \n" << @response.body
    end

    test "localized sign up spanish" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      get "/publishers/#{daily_deal.publisher.to_param}/consumers/new?locale=es"
      assert_response :success
      assert_equal :es, I18n.locale
      assert !@response.body.include?('translation missing:'), "Should not have translation missing on page: \n" << @response.body
    end

    test "localized password reset english" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      get "/publishers/#{daily_deal.publisher.to_param}/consumer_password_resets/new"
      assert_response :success
      assert_equal :en, I18n.locale, "default locale should be English"
      assert !@response.body.include?('translation missing:'), "Should not have translation missing on page: \n" << @response.body
    end

    test "localized password reset spanish" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
      get "/publishers/#{daily_deal.publisher.to_param}/consumer_password_resets/new?locale=es"
      assert_response :success
      assert_equal :es, I18n.locale
      assert !@response.body.include?('translation missing:'), "Should not have translation missing on page: \n" << @response.body
    end

    test "change locale via path" do
      daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)

      I18n.default_locale = :en
      I18n.locale = :en

      get "/es/publishers/#{daily_deal.publisher.label}/deal-of-the-day"
      assert_response :success
      assert_equal :es, I18n.locale, "locale should be Spanish"
    end

    test "edit daily deal with spanish locale" do
      post session_path, :user => { :login => "quentin", :password => "monkey" }

      daily_deal = DailyDeal.with_locale(:en) do
        Factory(:daily_deal)
      end

      I18n.locale = :es

      daily_deal.update_attributes!({:value_proposition => "spanish prop",
                                     :description => "a description in spanish",
                                     :terms => "some terms for you, senor"})

      get "/daily_deals/#{daily_deal.id}/translations/es/edit"

      assert_response :success
      assert assigns(:daily_deal)

      assert_select "form.edit_daily_deal" do
        assert_select "input[name='daily_deal[value_proposition]'][value='spanish prop']"
        assert_select "input[name='daily_deal[value_proposition_subhead]']"
        assert_select "textarea[name='daily_deal[description]']", "a description in spanish"
        assert_select "textarea[name='daily_deal[highlights]']"
        assert_select "textarea[name='daily_deal[terms]']", "some terms for you, senor"
        assert_select "textarea[name='daily_deal[reviews]']"
        assert_select "textarea[name='daily_deal[voucher_steps]']"
        assert_select "textarea[name='daily_deal[email_voucher_redemption_message]']"
        assert_select "textarea[name='daily_deal[twitter_status_text]']"
        assert_select "textarea[name='daily_deal[facebook_title_text]']"
        assert_select "textarea[name='daily_deal[short_description]']"
      end
    end

    test "update daily deal with spanish locale" do
      post session_path, :user => { :login => "quentin", :password => "monkey" }

      daily_deal = DailyDeal.with_locale(:en) do
        Factory(:daily_deal)
      end

      put "/daily_deals/#{daily_deal.id}/translations/es", :daily_deal => {
        :value_proposition => "spanish proposition",
        :description => "espanol es bueno",
        :terms => "terms for this spanish deal"
      }

      assert_redirected_to "/daily_deals/#{daily_deal.id}/translations/es/edit"
      
      I18n.locale = :es
      daily_deal = daily_deal.reload
      assert_equal "spanish proposition", daily_deal.value_proposition
      assert_equal "espanol es bueno", daily_deal.description(:plain)
      assert_equal "terms for this spanish deal", daily_deal.terms(:plain)
    end

    test "render localized activation with blank activation_code" do
      publisher = Factory(:publisher, :label => "thinkdigital")
      post "el/publishers/#{publisher.id}/consumers/activate"
      assert_template "consumers/activate.el.html.erb"
    end
  end
end
