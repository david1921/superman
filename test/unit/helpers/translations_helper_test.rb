require File.dirname(__FILE__) + "/../../test_helper"

class TranslationsHelperTest < ActionView::TestCase
  
  test "locale_paths_json" do

    I18n.stubs(:available_locales).returns([:es, :en])

    daily_deal = Factory(:daily_deal)

    paths = {
      "es" => edit_daily_deal_translations_for_locale_path(daily_deal, 'es'),
      "en" => edit_daily_deal_translations_for_locale_path(daily_deal, 'en')
    }

    assert_equal paths.to_json, locale_paths_json(daily_deal)
  end
end
