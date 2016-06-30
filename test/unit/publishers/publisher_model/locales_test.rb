require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::LocalesTest
module Publishers
  module PublisherModel
    class LocalesTest < ActiveSupport::TestCase
      context "available locales" do
        should "be valid if existing default locales are selected" do
          I18n.stubs(:available_locales).returns([:en])
          publisher = Factory.build(:publisher, :label => "localetest123", :enabled_locales => ["zh"])
          assert !publisher.save
          assert "Locale not available: zh", publisher.errors.on(:enabled_locales)

          I18n.stubs(:available_locales).returns([:en, :zh])
          assert publisher.save
        end

        should "be valid if existing publisher locales are selected" do
          I18n.stubs(:available_locales).returns([])
          publisher = Factory.build(:publisher, :label => "localetest123", :enabled_locales => ["en"])
          publisher.stubs(:themed_locale_exists?).with(publisher.label, "en").returns(false)
          assert !publisher.save
          assert "locale not available: en", publisher.errors.on(:enabled_locales)

          publisher.stubs(:themed_locale_exists?).with(publisher.label, "en").returns(true)
          assert publisher.save
        end
      end

      context "enabled_locales_for_consumer" do
        should "return a unique list of publisher and publishing group's available locales" do
          publishing_group = Factory(:publishing_group)
          publisher = Factory(:publisher, :publishing_group => publishing_group)
          publisher.stubs(:enabled_locales).returns(["en", "es"])
          publishing_group.stubs(:enabled_locales).returns(["es", "es-MX"])
          assert_same_elements ["en", "es", "es-MX"], publisher.enabled_locales_for_consumer
        end

        should "return publisher enabled_locales when there is no publishing_group" do
          publisher = Factory(:publisher, :publishing_group => nil)
          publisher.stubs(:enabled_locales).returns(["en", "zh"])
          assert_same_elements ["en", "zh"], publisher.enabled_locales_for_consumer
        end
      end
    end
  end
end