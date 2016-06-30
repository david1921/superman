require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Consumers::PreferredLocaleTest
class Consumers::PreferredLocaleTest < ActiveSupport::TestCase
  context "preferred_locale" do
    setup do
      @publisher = Factory(:publisher)
      @consumer = Factory(:consumer, :publisher => @publisher)
    end

    should "validate that the preferred locale is in the consumer's publishers enabled locales if any exist" do
      @consumer.publisher.stubs(:enabled_locales_for_consumer).returns(["en", "es", "zh"])
      assert !@consumer.update_attributes(:preferred_locale => "es-MX")
      assert_equal "es-MX is not a supported locale", @consumer.errors.on(:preferred_locale)
      assert @consumer.update_attributes(:preferred_locale => "es")
    end

    should "validate that the preferred locale is in the default locales if the consumer's publisher does not have any locales enabled" do
      @consumer.publisher.stubs(:enabled_locales_for_consumer).returns([])
      I18n.stubs(:available_locales).returns([:en, :es])
      assert_bad_value @consumer, :preferred_locale, "zh"
      assert_equal "zh is not a supported locale", @consumer.errors.on(:preferred_locale)
      assert_good_value @consumer, :preferred_locale, "en"
    end
  end
end