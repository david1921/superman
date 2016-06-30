require File.dirname(__FILE__) + "/../../../test_helper"

class LocaleTagTest < ActiveSupport::TestCase

  test "render locale" do
    I18n.locale = "es"
    assert_equal "es", Liquid::Template.parse("{% locale %}").render({})
    I18n.locale = :en
    assert_equal "en", Liquid::Template.parse("{% locale %}").render({})
  end

end
