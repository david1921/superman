require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Advertisers::CoreTest
class Advertisers::CoreTest < ActiveSupport::TestCase

  context "PRIMARY_CATEGORY_KEYS" do
    should "have translations for all business categories in the default locale" do
      keys = I18n.t('options.business_categories').keys.map(&:to_s)
      Advertiser::PRIMARY_CATEGORY_KEYS.each do |c|
        assert keys.include?(c), "Should have a translation for #{c}"
      end
    end
  end

  context "SECONDARY_CATEGORY_KEYS" do
    should "have translations for all secondary business categories in the default locale" do
    categories = I18n.t('options.secondary_business_categories').with_indifferent_access
      Advertiser::SECONDARY_CATEGORY_KEYS.each do |primary_key, value|
        if value.is_a? Array
          value.each do |secondary_key|
            assert categories[primary_key].include?(secondary_key), "Should have a translation for #{secondary_key}"
          end
        else
          assert_equal categories[primary_key], value, "Should have a translation for #{value}"
        end
      end
    end
  end

end
