require File.dirname(__FILE__) + "/../test_helper"

class DailyDealCategoryTest < ActiveSupport::TestCase
  context "DailyDealCategory" do
    setup do
      @custom_categories_publisher = Factory(:publisher, :require_daily_deal_category => true)
      @foo = @custom_categories_publisher.daily_deal_categories.create!(:name => "Foo", :abbreviation => "F")
      @bar = @custom_categories_publisher.daily_deal_categories.create!(:name => "Bar")
      @custom_cats_advertiser = Factory(:advertiser, :publisher_id => @custom_categories_publisher.id)

      @publisher = Factory(:publisher)
      @advertiser = Factory(:advertiser, :publisher_id => @publisher.id)
      
      @baz = DailyDealCategory.create!(:name => "Baz", :abbreviation => "B")
      @qux = DailyDealCategory.create!(:name => "Qux", :abbreviation => "Q")
      @bar = DailyDealCategory.create!(:name => "Bar", :publisher => Factory(:publisher))
    end

    should belong_to(:publisher)
    should validate_presence_of(:name)
    should validate_uniqueness_of(:name).scoped_to(:publisher_id)
    
    should "require that deals created for require_daily_deal_category Publisher have an associated category" do
      daily_deal = Factory(:daily_deal, :publisher_id => @custom_categories_publisher.id, :advertiser_id => @custom_cats_advertiser.id, :analytics_category => @baz)
      assert daily_deal.valid?
    end
    
    should "only be able to set analytics category to standard category" do
      daily_deal = Factory(:daily_deal, :publisher_id => @custom_categories_publisher.id, :advertiser_id => @custom_cats_advertiser.id, :analytics_category => @baz)
      assert daily_deal.valid?
      daily_deal.analytics_category = @foo
      assert !daily_deal.valid?
      assert daily_deal.errors.on(:analytics_category).present?
      daily_deal.analytics_category = @qux
      assert daily_deal.valid?
      
      assert_equal [ @baz, @qux ], DailyDealCategory.analytics, "analytics"
    end
    
    should "always able to set default categories" do
      daily_deal = Factory(:daily_deal, :publisher_id => @publisher.id, :advertiser_id => @advertiser.id, :analytics_category => @baz)
      assert daily_deal.valid?
      daily_deal.analytics_category = @bar
      assert !daily_deal.valid?
      
      assert_equal [ @baz, @qux ], DailyDealCategory.analytics, "analytics"
    end
    
    should "require category if Publisher require_daily_deal_category" do
      daily_deal = Factory.build(:daily_deal, :publisher_id => @custom_categories_publisher.id, :advertiser_id => @custom_cats_advertiser.id, :analytics_category => nil)
      assert !daily_deal.valid?
      assert daily_deal.errors.on(:analytics_category)
    end
    
    should "allow nil category if Publisher not require_daily_deal_category" do
      daily_deal = Factory(:daily_deal, :publisher_id => @publisher.id, :advertiser_id => @advertiser.id, :analytics_category => nil)
      assert daily_deal.valid?
    end
    
    should "nicely format name_with_abbreviation" do
      assert_equal "Foo (F)", @foo.name_with_abbreviation, "name_with_abbreviation with abbreviation"
      assert_equal "Bar", @bar.name_with_abbreviation, "name_with_abbreviation no abbreviation"
    end

    context "with_deals_in_zip_radius" do
      setup do
        @publisher = Factory(:publisher, :enable_publisher_daily_deal_categories => true)

        @daily_deal_category1 = Factory(:daily_deal_category, :publisher => @publisher)
        @daily_deal_category2 = Factory(:daily_deal_category, :publisher => @publisher)
        @daily_deal_category3 = Factory(:daily_deal_category, :publisher => @publisher)

        @daily_deal1 = Factory(:side_daily_deal, :publisher => @publisher, :publishers_category => @daily_deal_category1)
        @daily_deal1.advertiser.store.update_attributes(:zip_code => "98686")
        @daily_deal2 = Factory(:side_daily_deal, :publisher => @publisher, :publishers_category => @daily_deal_category2)
        @daily_deal2.advertiser.store.update_attributes(:zip_code => "01000")
      end

      should "return deals within zip radius" do
        ZipCode.stubs(:zips_near_zip_and_radius).returns(["98685", "98686"])

        daily_deal_categories = DailyDealCategory.for_publisher(@publisher).with_deals_in_zip_radius("98585", 25)
        assert_same_elements [@daily_deal_category1.id], daily_deal_categories.map(&:id)
      end
    end

    context "with_active_deals_for_publisher" do
      context "with daily_deal_categories assigned to publisher" do
        setup do
          @publisher = Factory(:publisher, :enable_publisher_daily_deal_categories => true)

          @daily_deal_category1 = Factory(:daily_deal_category, :publisher => @publisher)
          @daily_deal_category2 = Factory(:daily_deal_category, :publisher => @publisher)
          @daily_deal_category3 = Factory(:daily_deal_category, :publisher => @publisher)

          @daily_deal1 = Factory(:side_daily_deal,
                                 :publisher => @publisher,
                                 :publishers_category => @daily_deal_category1,
                                 :start_at => Time.zone.local(2011, 10, 20),
                                 :hide_at => Time.zone.local(2011, 11, 20))
          @daily_deal2 = Factory(:side_daily_deal,
                                 :publisher => @publisher,
                                 :publishers_category => @daily_deal_category2,
                                 :start_at => Time.zone.local(2012, 10, 20),
                                 :hide_at => Time.zone.local(2012, 11, 20))
        end

        should "return only categories with active deals" do
          Timecop.freeze(Time.zone.local(2011, 10, 25)) do
            daily_deal_categories = DailyDealCategory.for_publisher(@publisher).with_active_deals_for_publisher(@publisher)
            assert_same_elements [@daily_deal_category1.id], daily_deal_categories.map(&:id)
          end
        end
      end

      context "with daily_deal_categories assigned to publishing_group" do
        setup do
          publishing_group = Factory(:publishing_group)

          @publisher1 = Factory(:publisher, :publishing_group => publishing_group, :enable_publisher_daily_deal_categories => true)
          @publisher2 = Factory(:publisher, :publishing_group => publishing_group, :enable_publisher_daily_deal_categories => true)

          @daily_deal_category1 = Factory(:daily_deal_category, :publishing_group => publishing_group)
          @daily_deal_category2 = Factory(:daily_deal_category, :publishing_group => publishing_group)
          @daily_deal_category3 = Factory(:daily_deal_category, :publishing_group => publishing_group)

          @daily_deal1 = Factory(:side_daily_deal,
                                 :publisher => @publisher1,
                                 :publishers_category => @daily_deal_category1,
                                 :start_at => Time.zone.local(2011, 10, 20),
                                 :hide_at => Time.zone.local(2011, 11, 20))
          @daily_deal2 = Factory(:side_daily_deal,
                                 :publisher => @publisher1,
                                 :publishers_category => @daily_deal_category2,
                                 :start_at => Time.zone.local(2012, 10, 20),
                                 :hide_at => Time.zone.local(2012, 11, 20))
          @daily_deal3 = Factory(:side_daily_deal,
                                 :publisher => @publisher2,
                                 :publishers_category => @daily_deal_category3,
                                 :start_at => Time.zone.local(2011, 10, 20),
                                 :hide_at => Time.zone.local(2011, 11, 20))
        end

        should "return only categories with active deals" do
          Timecop.freeze(Time.zone.local(2011, 10, 25)) do
            daily_deal_categories = DailyDealCategory.for_publisher(@publisher1).with_active_deals_for_publisher(@publisher1)
            assert_same_elements [@daily_deal_category1.id], daily_deal_categories.map(&:id)
          end
        end
      end
    end
  end

  test "with_names scope" do
    publisher = Factory(:publisher)
    categories = (1..3).collect{|i| Factory(:daily_deal_category, :publisher => publisher, :name => "Category #{i}")}

    # Test with zero names
    assert publisher.daily_deal_categories.with_names(nil).empty?
    assert publisher.daily_deal_categories.with_names([]).empty?

    # Test with one name
    found = publisher.daily_deal_categories.with_names([categories.first.name])
    assert_contains found, categories.first
    categories[1..-1].each do |category|
      assert_does_not_contain found, category
    end

    # Test with two names
    expected_categories = categories[0..1]
    found = publisher.daily_deal_categories.with_names(expected_categories.map(&:name))
    expected_categories.each do |category|
      assert_contains found, category
    end
    assert_does_not_contain found, categories.last
  end
  
  context "abbreviation" do
    should "be required if no publisher or publishing group set" do
      cat = Factory.build(:daily_deal_category, :abbreviation => nil, :publisher => nil, :publishing_group => nil)
      assert_equal true, cat.analytics?
      assert_equal false, cat.valid?, cat.errors.on(:abbreviation) || "unknown error"
    end
  end

  context "analytics?" do
    should "be analytics" do
      assert_equal true, Factory.build(:daily_deal_category, :publisher => nil, :publishing_group => nil).analytics?
    end
    should "not be analytics when there's a publisher'" do
      assert_equal false, Factory.build(:daily_deal_category, :publisher => Factory(:publisher), :publishing_group => nil).analytics?
    end
    should "not be analytics when there's publishing_group'" do
      assert_equal false, Factory.build(:daily_deal_category, :publisher => nil, :publishing_group => Factory(:publishing_group)).analytics?
    end
  end

end
