require File.dirname(__FILE__) + "/../../../test_helper"

class LocaleIsNotDefaultBlockTest < ActiveSupport::TestCase
  test "render contents when current locale is not the default locale" do
    I18n.default_locale = :en
    I18n.locale = :es
    assert_equal "yes", Liquid::Template.parse("{% locale_is_not_default signup %}yes{% endlocale_is_not_default %}").render({})
  end

  test "not render contents when current locale is the default locale" do
    I18n.default_locale = :en
    I18n.locale = :en
    assert_equal "", Liquid::Template.parse("{% locale_is_not_default signup %}yes{% endlocale_is_not_default %}").render({})
  end
end
