require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Advertisers::ValidationsTest

class Advertisers::ValidationsTest < ActiveSupport::TestCase
  context "#at_least_one_store_for_paychex_publisher" do
    setup do
      @publisher = Factory(:publisher_using_paychex)
    end

    should "add an error if there are no stores" do
      advertiser = Advertiser.new(:publisher => @publisher)
      assert advertiser.invalid?
      assert_equal "Stores must have at least one valid store", advertiser.errors[:base]
    end
  end

  context "size" do
    should "be one of [SME, Large]" do
      advertiser = Advertiser.new(:size => "invalid", :publisher => Publisher.new)
      assert advertiser.invalid?
      assert_equal "Size is not included in the list", advertiser.errors[:size]

      [nil, "SME", "Large"].each do |size|
        advertiser.size = size
        assert advertiser.valid?
      end
    end
  end

  context "primary_business_category" do
    should "be included in PRIMARY_CATEGORY_KEYS" do
      advertiser = Factory.build(:advertiser, :primary_business_category => "bad_cateogry")
      assert advertiser.invalid?

      Advertiser::PRIMARY_CATEGORY_KEYS.each do |key|
        advertiser.primary_business_category = key
        assert advertiser.valid?, "Should allow #{key}"
      end
    end

    should "have a translation for all keys in the default locale" do
      keys = I18n.t('options.business_categories').keys.map(&:to_s)
      Advertiser::PRIMARY_CATEGORY_KEYS.each do |c|
        assert keys.include?(c), "Should have a translations for #{c}"
      end
    end
  end

  context "secondary_business_category" do
    should "only be validated if it is not nil or blank and a valid primary_business_category has been selected" do
      advertiser = Factory(:advertiser, :secondary_business_category => nil)
      assert advertiser.valid?

      advertiser.secondary_business_category = ""
      assert advertiser.valid?

      advertiser.primary_business_category = "fake category"
      advertiser.secondary_business_category = "mobile"
      assert advertiser.invalid?, "Should not allow a validate if the primary_business_category is not valid"

      advertiser.primary_business_category = "electrical"
      advertiser.secondary_business_category = "chainsaws"
      assert advertiser.invalid?, "Should not allow a value not in Advertiser::SECONDARY_BUSINESS_CATEGORIES"
      assert advertiser.errors.on(:secondary_business_category).present?

      advertiser.secondary_business_category = "mobile"
      advertiser.valid?
      puts advertiser.errors.full_messages
      assert advertiser.valid?
    end
  end
end