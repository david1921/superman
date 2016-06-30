require File.dirname(__FILE__) + "/../test_helper"

class PublishingGroupTest < ActiveSupport::TestCase
  test "label validation" do
    publishing_group = Factory(:publishing_group_with_theme)
    assert !PublishingGroup.new(:name => "Another", :label => "villagevoicemedia").valid?, "Validation should catch duplicate label"
    assert !PublishingGroup.new(:name => "Another", :label => "villagevoicemedia").valid?, "Validation should catch bad label syntax"
    assert  PublishingGroup.new(:name => "Another", :label => "lang").valid?
  
    PublishingGroup.create! :name => "No Label"
    PublishingGroup.create! :name => "No Label Again"
  end


  test "create" do
    publishing_group = PublishingGroup.create(:name => "Test Publishing Group")
    assert_not_nil publishing_group, "Should create a publishing group"
    assert_equal "Test Publishing Group", publishing_group.name
    assert !publishing_group.allow_consumer_show_action?, "should default allow_consumer_show_action to false"
  end
  
  test "default how it works text" do
    publishing_group = PublishingGroup.create(:name => "Test Publishing Group")
    assert_match %r{<h4>Click and Buy</h4>}, publishing_group.how_it_works
    assert_match %r{<h4>Share</h4>}, publishing_group.how_it_works
    assert_match %r{<h4>Print</h4>}, publishing_group.how_it_works
  end
  
  test "name required" do
    publishing_group = PublishingGroup.new
    assert !publishing_group.valid?, "Should not be valid without a name"
    assert publishing_group.errors.on(:name), "Should have a :name error"
    assert_match %r{can\'t be blank}i, publishing_group.errors.on(:name), ":name error"
  end
  
  test "name uniqueness" do
    PublishingGroup.create!(:name => "Test Publishing Group")
    
    publishing_group = PublishingGroup.new(:name => "Test Publishing Group")
    assert !publishing_group.valid?, "Should not be valid with duplicate name"
    assert publishing_group.errors.on(:name), "Should have a :name error"
    assert_match /has already been taken/i, publishing_group.errors.on(:name), ":name error"
  end

  test "country should be the country of the first publisher in the group, or nil if no publishers exist" do
    publishing_group = Factory :publishing_group
    assert_nil publishing_group.country
    Factory :publisher_with_uk_address, :publishing_group => publishing_group, :country => Country::UK
    assert_equal Country::UK, publishing_group.reload.country
  end
  
  test "default stick_consumer_to_publisher_based_on_zip_code should be false" do
    assert !PublishingGroup.create!(:name => "Test").stick_consumer_to_publisher_based_on_zip_code
  end

  test "destroy destroys dependent users" do
    publishing_group = publishing_groups(:student_discount_handbook)
    users = publishing_group.users
    assert users.size > 0, "Publishing Group fixture should have at least one user"
    
    publishing_group.destroy
    assert_nil PublishingGroup.find_by_name(publishing_group.name), "Publishing group should no longer exist"
    users.each { |user| assert_nil User.find_by_email(user.email), "User #{user.name} should no longer exist" }
  end

  test "default how it works" do
    publishing_group = Factory(:publishing_group)
    assert_match %r{<h4>Click and Buy</h4>}, publishing_group.how_it_works, "how_it_works"
  end
  
  test "default require_login_for_active_daily_deal_feed" do
    publishing_group = Factory(:publishing_group)
    assert publishing_group.require_login_for_active_daily_deal_feed, "should default require_login_for_active_daily_deal_feed to true"
  end

  test "signups does not return dups" do
    group = Factory(:publishing_group)
    publisher1 = Factory(:publisher, :publishing_group => group)
    publisher2 = Factory(:publisher, :publishing_group => group)
    Factory(:consumer, :publisher => publisher1)
    Factory(:consumer, :publisher => publisher2)
    assert_equal 2, group.signups.size
    Factory(:consumer, :email => "same@email.com", :publisher => publisher1)
    Factory(:consumer, :email => "same@email.com", :publisher => publisher2)
    assert_equal 3, group.signups.size
  end

  test "associations" do
    publishing_group = Factory(:publishing_group)
    assert_equal [], publishing_group.daily_deal_purchases, "daily_deal_purchases"
    assert_equal [], publishing_group.daily_deals, "daily_deals"
    assert_equal [], publishing_group.advertisers, "advertisers"
    assert_equal [], publishing_group.daily_deal_certificates, "daily_deal_certificates"
  end

  test "available_categories returns all categories if the publishing group does not have their own set" do
    3.times { Factory(:category) }
    publishing_group = Factory(:publishing_group)
    assert_same_elements Category.all, publishing_group.available_categories
  end
  
  test "available_categories returns only publishing groups categories when they have some set" do
    publishing_group1 = Factory(:publishing_group)
    publishing_group2 = Factory(:publishing_group)

    Factory(:category)
    3.times { publishing_group1.categories << Factory(:category) }
    publishing_group2.categories << Factory(:category)

    assert_same_elements publishing_group1.categories, publishing_group1.available_categories
  end

  test "should not allow invalid google analytics account ids" do
    publishing_group = Factory.build(:publishing_group)
    assert_bad_value(publishing_group, :google_analytics_account_ids, "asdf")
    assert_bad_value(publishing_group, :google_analytics_account_ids, "UA-19396594-184")
  end

  test "should only allow comma-delimited google analytics account ids" do
    publishing_group = Factory.build(:publishing_group)
    assert_good_value(publishing_group, :google_analytics_account_ids, "UA-19396594-1, UA-19396594-2,UA-2018839-18")
    assert_good_value(publishing_group, :google_analytics_account_ids, "UA-19396594-1")
    assert_good_value(publishing_group, :google_analytics_account_ids, "UA-19396594-18")
    assert_good_value(publishing_group, :google_analytics_account_ids, "")
    assert_good_value(publishing_group, :google_analytics_account_ids, nil)
  end

  test "publishing_group is versioned" do
    assert PublishingGroup.versioned?
  end

  test "merchant_id is versioned" do
    publishing_group = Factory(:publishing_group)
    publishing_group.update_attribute(:merchant_account_id, "345DSA")

    assert_equal({"merchant_account_id" => [nil, "345DSA"]}, publishing_group.versions.last.changes)
  end
  
  test "merchant_account_id can not be all integers" do
    pg = Factory(:publishing_group)
    pg.merchant_account_id = "12345"
    pg.save
    assert pg.errors.on(:merchant_account_id)
  end

  test "merchant_account_id can not have spaces" do
    pg = Factory(:publishing_group)
    pg.merchant_account_id = "Test Id"
    pg.save
    assert pg.errors.on(:merchant_account_id)
  end

  test "publishing_group.display_text_for with a default value for a label" do
    publishing_group = Factory :publishing_group, :label => "pub-group-without-custom-label"
    assert_equal "Deal of the Day", publishing_group.display_text_for(:daily_deal_name)
  end

  test "publishing_group.display_text_for with a custom label value" do
    publishing_group = Factory :publishing_group, :label => "rr"
    assert_equal "Fine Print", publishing_group.display_text_for(:fine_print_label)
  end

  test "publishing_group.display_text_for with no default or customized label" do
    publishing_group = Factory :publisher, :label => "mytestpub"
    assert_equal "", publishing_group.display_text_for(:doesnt_exist)
  end

  test "daily_deal_name for publisher with using default value" do
    publishing_group = Factory(:publishing_group, :label => "newpublishinggroup")
    assert_equal "Deal of the Day", publishing_group.daily_deal_name
  end
  
  test "daily_deal_name for TWC" do
    publishing_group = Factory(:publishing_group, :label => "rr")
    assert_equal "Daily Deal", publishing_group.daily_deal_name
  end
  
  test "advertiser_financial_details_and_require_federal_tax_id" do
    publishing_group = Factory.build(:publishing_group, 
                                     :advertiser_financial_detail => true, 
                                     :require_federal_tax_id => true)
    assert publishing_group.valid?, "Should be valid with advertiser financial detail and federal tax id required"
  end
  
  test "advertiser_financial_details_and_do_not_require_federal_tax_id" do
    publishing_group = Factory.build(:publishing_group, 
                                     :advertiser_financial_detail => true, 
                                     :require_federal_tax_id => false)
    assert publishing_group.valid?, "Should be valid with advertiser financial detail and federal tax id not required"
  end
  
  test "no_advertiser_financial_details_and_require_federal_tax_id" do
    publishing_group = Factory.build(:publishing_group, 
                                     :advertiser_financial_detail => false, 
                                     :require_federal_tax_id => true)
    assert publishing_group.invalid?, "Should be invalid with no advertiser financial detail and required federal tax id"
    assert_equal "Require federal tax can not be set when advertiser financial detail is not set.", publishing_group.errors.on(:require_federal_tax_id)
  end
  
  test "revenue sharing agreements" do
    publishing_group = Factory(:publishing_group)
    assert publishing_group.platform_revenue_sharing_agreements.count == 0
    assert publishing_group.syndication_revenue_sharing_agreements.count == 0
    
    prsa = Factory.build(:platform_revenue_sharing_agreement, :agreement => publishing_group)
    prsa.save!
    assert publishing_group.platform_revenue_sharing_agreements.reload.count == 1
    
    srsa = Factory.build(:syndication_revenue_sharing_agreement, :agreement => publishing_group)
    srsa.save!
    assert publishing_group.syndication_revenue_sharing_agreements.reload.count == 1
  end

  context "promotion" do
    should have_many(:promotions)
  end

  context "single sign on" do
    should "require unique_email_across_publishing_group if allow_single_sign_on enabled" do
      publishing_group = Factory.build(:publishing_group, :allow_single_sign_on => true)

      assert_bad_value publishing_group, :unique_email_across_publishing_group, false
      assert_good_value publishing_group, :unique_email_across_publishing_group, true
    end

    should "not require allow_single_sign_on if unique_email_across_publishing_group is set" do
      publishing_group = Factory.build(:publishing_group, :unique_email_across_publishing_group => true)

      assert_good_value publishing_group, :allow_single_sign_on, false
      assert_good_value publishing_group, :allow_single_sign_on, true
    end
  end
  
  context "publisher switch on login" do
    should "require unique_email_across_publishing_group if allow_publisher_switch_on_login enabled" do
      publishing_group = Factory.build(:publishing_group, :allow_publisher_switch_on_login => true)

      assert_bad_value publishing_group, :unique_email_across_publishing_group, false
      assert_good_value publishing_group, :unique_email_across_publishing_group, true
    end

    should "not require allow_publisher_switch_on_login if unique_email_across_publishing_group is set" do
      publishing_group = Factory.build(:publishing_group, :unique_email_across_publishing_group => true)

      assert_good_value publishing_group, :allow_publisher_switch_on_login, false
      assert_good_value publishing_group, :allow_publisher_switch_on_login, true
    end
  end

  context "featured deals excluding publisher" do

    setup do
      @publishing_group = Factory(:publishing_group)
      @publisher1 = Factory(:publisher, :publishing_group => @publishing_group)
      @publisher2 = Factory(:publisher, :publishing_group => @publishing_group)
      @publisher3 = Factory(:publisher, :publishing_group => @publishing_group)
    end

    should "return empty array if no featured deals" do
      assert_equal [], @publishing_group.featured_deals_excluding_publisher(@publisher1)
    end

    should "exclude deals from the exclude publisher" do
      deal = Factory(:daily_deal, :publisher => @publisher1)
      assert_equal [], @publishing_group.featured_deals_excluding_publisher(@publisher1)
    end

    should "not exclude deals from other publishers" do
      deal = Factory(:daily_deal, :publisher => @publisher2)
      assert_equal [deal], @publishing_group.featured_deals_excluding_publisher(@publisher1)
    end

    should "work when things get a little complicated" do
      deal1 = Factory(:daily_deal, :publisher => @publisher1)
      deal2 = Factory(:daily_deal, :publisher => @publisher2)
      deal3 = Factory(:daily_deal, :publisher => @publisher3)
      assert_equal_arrays [deal2, deal3], @publishing_group.featured_deals_excluding_publisher(@publisher1)
    end

  end


  fast_context "#paychex_initial_payment_percentage" do

    setup do
      @publishing_group = Factory :publishing_group
    end

    context "when uses_paychex" do
      setup do
        @publishing_group.update_attributes(:uses_paychex => true)
      end

      should "be a number between 0 and 100 (inclusive)" do
        assert_good_value @publishing_group, :paychex_initial_payment_percentage, 0
        assert_good_value @publishing_group, :paychex_initial_payment_percentage, 50
        assert_good_value @publishing_group, :paychex_initial_payment_percentage, 100
        assert_bad_value @publishing_group, :paychex_initial_payment_percentage, -1
        assert_bad_value @publishing_group, :paychex_initial_payment_percentage, 101
      end
    end

    context "when NOT uses_paychex" do
      setup do
        @publishing_group.update_attributes(:uses_paychex => false)
      end

      should "allow nil or a number between 0 and 100 (inclusive)" do
        assert_good_value @publishing_group, :paychex_initial_payment_percentage, nil
        assert_good_value @publishing_group, :paychex_initial_payment_percentage, 0
        assert_good_value @publishing_group, :paychex_initial_payment_percentage, 50
        assert_good_value @publishing_group, :paychex_initial_payment_percentage, 100
        assert_bad_value @publishing_group, :paychex_initial_payment_percentage, -1
        assert_bad_value @publishing_group, :paychex_initial_payment_percentage, 101
      end
    end

  end

  fast_context "#paychex_num_days_after_which_full_payment_released" do

    setup do
      @publishing_group = Factory :publishing_group, :paychex_initial_payment_percentage => 40
    end

    context "when uses_paychex" do
      setup do
        @publishing_group.update_attributes(:uses_paychex => true)
      end

      should "be >= 4 (as it takes that long for us to receive the funds from our processor)" do
        @publishing_group.paychex_num_days_after_which_full_payment_released = 0
        assert @publishing_group.invalid?
        assert @publishing_group.errors.on(:paychex_num_days_after_which_full_payment_released).present?

        @publishing_group.paychex_num_days_after_which_full_payment_released = 3
        assert @publishing_group.invalid?
        assert @publishing_group.errors.on(:paychex_num_days_after_which_full_payment_released).present?

        @publishing_group.paychex_num_days_after_which_full_payment_released = 4
        assert @publishing_group.valid?

        @publishing_group.paychex_num_days_after_which_full_payment_released = 90
        assert @publishing_group.valid?

        assert_bad_value @publishing_group, :paychex_num_days_after_which_full_payment_released, nil
      end
    end

    context "when NOT uses_paychex" do
      setup do
        @publishing_group.update_attributes(:uses_paychex => false)
      end

      should "allow nil or a number >= 4" do
        assert_good_value @publishing_group, :paychex_num_days_after_which_full_payment_released, nil
        assert_good_value @publishing_group, :paychex_num_days_after_which_full_payment_released, 4
        assert_good_value @publishing_group, :paychex_num_days_after_which_full_payment_released, 90
        assert_bad_value @publishing_group, :paychex_num_days_after_which_full_payment_released, 0
        assert_bad_value @publishing_group, :paychex_num_days_after_which_full_payment_released, 3
      end
    end

  end

  context "#main_publisher" do
    setup do
      @publishing_group = Factory(:publishing_group)
    end

    should "return the main publisher if there is one" do
      publisher = Factory(:publisher, :publishing_group => @publishing_group, :main_publisher => true)
      @publishing_group.reload
      assert_equal publisher, @publishing_group.main_publisher
    end

    should "return nil if there is no main publisher" do
      assert_nil @publishing_group.main_publisher
    end
  end

  context "available locales" do
    should "be valid if existing default locales are selected" do
      I18n.stubs(:available_locales).returns([:en])
      publishing_group = Factory.build(:publishing_group, :label => "localetest123", :enabled_locales => ["zh"])
      assert !publishing_group.save
      assert_equal "locale not available: zh", publishing_group.errors.on(:enabled_locales)

      I18n.stubs(:available_locales).returns([:en, :zh])
      assert publishing_group.save
    end

    should "be valid if existing publishing group locales are selected" do
      I18n.stubs(:available_locales).returns([])
      publishing_group = Factory.build(:publishing_group, :label => "localetest123", :enabled_locales => ["en"])
      publishing_group.stubs(:themed_locale_exists?).with(publishing_group.label, "en").returns(false)
      assert !publishing_group.save
      assert_equal "locale not available: en", publishing_group.errors.on(:enabled_locales)

      publishing_group.stubs(:themed_locale_exists?).with(publishing_group.label, "en").returns(true)
      assert publishing_group.save
    end
  end

end

