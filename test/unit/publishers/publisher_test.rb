require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Publishers::PublisherTest
module Publishers
  class PublisherTest < ActiveSupport::TestCase
    def setup
      GiftCertificateMailer.expects(:deliver_gift_certificate).at_least(0).returns(nil)

      Country.find_or_create_by_code('US')
    end

    def setup_analytics_provider
      publisher = publishers(:my_space)
      publisher.analytics_provider_id = 1
      publisher.analytics_site_id = "presst"
      publisher
    end

    test "disable!" do
      publisher = publishers(:my_space)
      assert_equal true, publisher.launched?
      publisher.disable!
      assert_equal false, publisher.launched?
    end

    test "launch!" do
      (publisher = publishers(:my_space)).update_attributes(:launched =>  false)
      assert_equal false, publisher.launched?
      publisher.launch!
      assert_equal true, publisher.launched?
    end

    test "new publisher page preference should default to 4" do
      assert_equal 4, publishers(:my_space).page_preference
    end

    test "analytics provider is set" do
      publisher = setup_analytics_provider

      assert_equal AnalyticsProvider.new(
        :id => publisher.analytics_provider_id, 
        :site_id => publisher.analytics_site_id
      ).id, publisher.analytics_service_provider.id
    end

    test "using analytics provider not set" do
      publisher = setup_analytics_provider

      assert_equal true, publisher.using_analytics_provider?
    end

    test "using analytics provider when not set" do
      assert_equal false, publishers(:my_space).using_analytics_provider?
    end


    test "available themes" do
      assert_equal 7, Publisher::THEMES.size

      %w( enhanced narrow simple standard sdcitybeat businessdirectory withtheme ).each do |theme|
        assert_not_nil Publisher::THEMES[theme], "#{theme} should available"
      end
    end

    test "short name" do
      assert_equal "my_space", publishers(:my_space).short_name, "MySpace short_name"
      assert_equal "sdnn", Publisher.new(:name => "SDNN").short_name, "SDNN short_name"
      assert_equal "the_hour", Publisher.new(:name => "The Hour").short_name, "The Hour short_name"
    end

    test "txt count" do
      publisher, offers = create_publisher_with_offers(3)
      create_txt  1, publisher, offers[0], "15 Sep 2008 23:59:59", "sent"
      create_txt  2, publisher, offers[0], "16 Sep 2008 00:00:00", "sent"
      create_txt  3, publisher, offers[1], "16 Sep 2008 12:34:56", "sent"
      create_txt  5, publisher, offers[1], "17 Sep 2008 12:34:57", "error"
      create_txt  7, publisher, offers[2], "17 Sep 2008 23:59:59", "sent"
      create_txt  9, publisher, offers[0], "17 Sep 2008 23:59:59", "error"
      create_txt 11, publisher, offers[1], "18 Sep 2008 00:00:00", "sent"

      assert_equal 12, publisher.txts_count(Date.new(2008, 9, 16) .. Date.new(2008, 9, 17)), "txt_count"
    end

    test "email count" do
      publisher, offers = create_publisher_with_offers(3)
      create_email 1, publisher, offers[0], "15 Sep 2008 23:59:59"
      create_email 2, publisher, offers[0], "16 Sep 2008 00:00:00"
      create_email 1, publisher, offers[1], "16 Sep 2008 12:34:56"
      create_email 3, publisher, offers[2], "17 Sep 2008 23:59:59"
      create_email 4, publisher, offers[2], "18 Sep 2008 00:00:00"

      assert_equal 6, publisher.emails_count(Date.new(2008, 9, 16) .. Date.new(2008, 9, 17)), "email_count"
    end

    test "voice message count and minutes" do
      publisher, offers = create_publisher_with_offers(3)
      create_voice_message( 1, publisher, offers[0], "15 Sep 2008 23:59:59", "sent", 1.1)
      create_voice_message( 2, publisher, offers[0], "16 Sep 2008 00:00:00", "sent", 2.2)
      create_voice_message( 1, publisher, offers[1], "16 Sep 2008 12:34:56", "sent", 3.3)
      create_voice_message( 3, publisher, offers[1], "17 Sep 2008 12:34:57", "error")
      create_voice_message( 1, publisher, offers[2], "17 Sep 2008 23:59:59", "sent", 4.4)
      create_voice_message( 4, publisher, offers[0], "17 Sep 2008 23:59:59", "error")
      create_voice_message( 1, publisher, offers[1], "18 Sep 2008 00:00:00", "sent", 5.5)

      dates = Date.new(2008, 9, 16) .. Date.new(2008, 9, 17)
      assert_equal 4, publisher.voice_messages_count(dates), "voice_message_count"
      assert_equal 2103, (145 * publisher.voice_messages_minutes(dates)).round, "voice_message_minutes"
    end

    def test_group_label_or_label
      publisher = Factory(:publisher, :label => 'somelabel', :publishing_group => nil )
      assert_same publisher.label, publisher.group_label_or_label

      publishing_group = Factory(:publishing_group_with_theme)
      publisher.update_attribute(:publishing_group, publishing_group) do
        assert_not_same publisher.label, publisher.group_label_or_label
      end
    end


    test "brand name or name" do
      assert_equal "MySDH.com", Publisher.new(:name => "Student Discount Handbook", :brand_name => "MySDH.com").brand_name_or_name
      assert_equal "Student Discount Handbook", Publisher.new(:name => "Student Discount Handbook", :brand_name => "").brand_name_or_name
      assert_equal "Student Discount Handbook", Publisher.new(:name => "Student Discount Handbook").brand_name_or_name
    end

    test "brand txt header normalization" do
      publisher = Factory.build(:publisher, :name => "Super", :brand_txt_header => "Super")
      assert publisher.valid?, "Publisher should be valid"
      assert_equal "Super", publisher.brand_txt_header, "Normalized TXT brand name"

      publisher = Factory.build(:publisher, :name => "Super", :brand_txt_header => "  Super ")
      assert publisher.valid?, "Publisher should be valid"
      assert_equal "Super", publisher.brand_txt_header, "Normalized TXT brand name"

      publisher = Factory.build(:publisher, :name => "Super Duper", :brand_txt_header => "Spr-Dpr")
      assert publisher.valid?, "Publisher should be valid"
      assert_equal "Spr-Dpr", publisher.brand_txt_header, "Normalized TXT brand name"

      publisher = Factory.build(:publisher, :name => "Super Duper", :brand_txt_header => " Spr -   Dpr  ")
      assert publisher.valid?, "Publisher should be valid"
      assert_equal "Spr - Dpr", publisher.brand_txt_header, "Normalized TXT brand name"
    end

    test "coupon headline" do
      publisher = publishers(:gvnews)
      assert_equal "Green Valley News Coupon", publisher.coupon_headline

      publisher.brand_name = "GVNEWS.COM"
      assert_equal "GVNEWS.COM Coupon", publisher.coupon_headline

      publisher.brand_name = nil
      publisher.brand_headline = "Another Great Coupon from GVNEWS.COM"
      assert_equal "Another Great Coupon from GVNEWS.COM", publisher.coupon_headline
      publisher.brand_name = "GVNEWS.COM"
      assert_equal "Another Great Coupon from GVNEWS.COM", publisher.coupon_headline
    end

    test "theme types" do
      assert_equal "Simple", Publisher::THEMES["simple"], "'simple' coupon layout human name"
      assert_equal "Enhanced", Publisher::THEMES["enhanced"], "'enhanced' coupon layout human name"
      assert_equal "Narrow", Publisher::THEMES["narrow"], "'narrow' coupon layout human name"
      assert_equal "Standard", Publisher::THEMES["standard"], "'standard' coupon layout human name"
      assert_equal "SD CityBeat", Publisher::THEMES["sdcitybeat"], "'sdcitybeat' coupon layout human name"
    end

    test "txt keyword prefixes" do
      assert_equal ["SDH"], publishers(:sdh_austin).txt_keyword_prefixes
    end

    test "next keyword suffix" do
      publisher = publishers(:sdh_austin)
      assert_equal "1", publisher.reload.next_keyword_suffix("SDH")
      assert_equal "2", publisher.next_keyword_suffix("SDH")
      assert_nil publisher.next_keyword_suffix("XXX")
      assert_equal "3", publisher.reload.next_keyword_suffix("SDH")
      assert_equal "4", publisher.next_keyword_suffix("SDH")
    end

    test "email only from support email address with just an email address" do
      publisher = Factory(:publisher, :name => "New Publisher", :label => "newpublisher", :support_email_address => "newpublisher@somepublication.com")
      assert_equal "newpublisher@somepublication.com", publisher.email_only_from_support_email_address
    end

    test "email only from support email address with display name and email address" do
      publisher = Factory(:publisher, :name => "New Publisher", :label => "newpublisher", :support_email_address => "NewPublisher <newpublisher@somepublication.com>")
      assert_equal "newpublisher@somepublication.com", publisher.email_only_from_support_email_address
    end

    test "subscriber report interval on tuesday" do
      Time.zone.expects(:now).at_least_once.returns(Time.zone.parse("Jan 08, 2008 12:34:56"))

      publishers(:vcreporter).destroy
      publisher = publishers(:sdreader)
      assert_equal 1.day, publisher.subscriber_report_interval, "Label not vcreporter, not on Friday"

      publisher.update_attributes! :label => "vcreporter"
      assert_nil publisher.subscriber_report_interval, "Label vcreporter, not on Friday"
    end

    test "subscriber report interval on friday" do
      Time.zone.expects(:now).at_least_once.returns(Time.zone.parse("Jan 11, 2008 12:34:56"))

      publishers(:vcreporter).destroy
      publisher = publishers(:sdreader)
      assert_equal 1.day, publisher.subscriber_report_interval, "Label not vcreporter, on Friday"

      publisher.update_attributes! :label => "vcreporter"
      assert_equal 7.day, publisher.subscriber_report_interval, "Label vcreporter, on Friday"
    end

    test "deliver advertisers categories with categories recipients present" do
      publisher = publishers(:sdreader)
      publisher.update_attributes! :categories_recipients => "scott.willson@analoganalytics.com"

      advertiser = publisher.advertisers.create!(:name => "A1")
      advertiser.offers.create!(:message => "A1 O1", :category_names => "Food : Chinese, Services : Laundry")

      assert_difference 'ActionMailer::Base.deliveries.size' do
        publisher.deliver_advertisers_categories
      end
    end

    test "deliver advertisers categories with categories recipients blank" do
      publisher = publishers(:sdreader)
      publisher.update_attributes! :categories_recipients => " "

      advertiser = publisher.advertisers.create!(:name => "A1")
      advertiser.offers.create!(:message => "A1 O1", :category_names => "Food : Chinese, Services : Laundry")

      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        publisher.deliver_advertisers_categories
      end
    end

    test "txt keyword prefix normalization" do
      publisher = Factory(:publisher, :name => "Publisher One")
      assert_equal [], publisher.txt_keyword_prefixes, "TXT keyword prefix should default to blank"

      publisher.update_attributes! :txt_keyword_prefix => " oNe  "
      assert_equal ["ONE"], publisher.reload.txt_keyword_prefixes, "TXT keyword prefix should have blanks stripped and be upcased"

      publisher.update_attributes! :txt_keyword_prefix => " Tw O "
      assert_equal ["TWO"], publisher.reload.txt_keyword_prefixes, "TXT keyword prefix should have blanks stripped and be upcased"
    end

    test "production subdomain" do
      publisher = Factory(:publisher, :name => "foo")
      assert_not_nil publisher.production_subdomain, "production_subdomain"
      assert_match(/sb\d/, publisher.production_subdomain, "production_subdomain")
      production_subdomain_index = publisher.production_subdomain[/\d/]
    end

    test "twitter handle with no brand twitter prefix or brand name" do
      publisher = Factory(:publisher, :name => "My Publication" )
      assert_equal "[My Publication Coupon]", publisher.twitter_handle
    end

    test "twitter handle with no brand twitter prefix but with brand name" do
      publisher = Factory(:publisher,  :name => "My Publication", :brand_name => "MP" )
      assert_equal "[MP Coupon]", publisher.twitter_handle
    end

    test "twitter handle with brand twitter prefix" do
      publisher = Factory(:publisher, :name => "My Publication", :brand_twitter_prefix => "Coupon from @MP:" )
      assert_equal "Coupon from @MP:", publisher.twitter_handle
    end


    test "upcoming deal certificates with no deal certificates" do
      publisher = Factory(:publisher, {:name => "Publisher"})
      assert publisher.gift_certificates.empty?
      assert publisher.gift_certificates.starting_on( 2.days.from_now ).empty?
    end

    test "upcoming deal certificates with deal certificate in the past" do
      publisher         = Factory(:publisher, {:name => "Publisher"})
      advertiser        = publisher.advertisers.create!(:name => "Advertiser")
      gift_certificate  = advertiser.gift_certificates.create(
        :message => "Advertiser Deal Certificate",
        :value => 30.00,
        :price => 14.99,
        :show_on => "Nov 18, 2008",
        :expires_on => "Nov 20, 2008",
        :number_allocated => 30
      )

      assert !publisher.gift_certificates.empty?
      assert publisher.gift_certificates.starting_on( 2.days.from_now ).empty?
    end

    test "upcoming deal certificate with deal certificate showing on 2 days from now" do
      publisher        = Factory(:publisher, {:name => "Publisher"})
      advertiser       = publisher.advertisers.create!(:name => "Advertiser")
      gift_certificate = advertiser.gift_certificates.create(
        :message => "Advertiser Deal Certificate",
        :value => 30.00,
        :price => 14.99,
        :show_on => (Time.zone.now + 2.days).beginning_of_day,
        :expires_on => (Time.zone.now + 30.days),
        :number_allocated => 30
      )

      assert !publisher.gift_certificates.empty?
      assert !publisher.gift_certificates.starting_on( 2.days.from_now ).empty?
    end

    test "with no deals" do
      publisher = publishers(:sdh_austin)
      publisher.daily_deals.all(&:destroy)
      dates = Date.parse("2010-01-20")..Date.parse("2010-01-30")

      assert_equal [], Publisher.all_with_purchased_daily_deal_counts(dates, [publisher])
    end

    test "with deals but no purchases" do
      publisher = publishers(:sdh_austin)
      publisher.daily_deals.all(&:destroy)
      advertiser = publisher.advertisers.first

      d_1 = advertiser.daily_deals.create!(
        :value_proposition => "Daily Deal 2 For A1", 
        :price => 25.00, 
        :value => 74.00, 
        :quantity => 100,
        :terms => "these are my terms", 
        :description => "this is my description",
        :start_at => Time.zone.parse("Jan 20, 2010 09:00:00"),
        :hide_at  => Time.zone.parse("Jan 20, 2010 19:00:00")
      )
      d_2 = advertiser.daily_deals.create!(
        :value_proposition => "Daily Deal 2 For A1", 
        :price => 25.00, 
        :value => 74.00, 
        :quantity => 100,
        :terms => "these are my terms", 
        :description => "this is my description",
        :start_at => Time.zone.parse("Jan 21, 2010 11:00:00"),
        :hide_at  => Time.zone.parse("Jan 21, 2010 23:09:00")
      )
      d_3 = advertiser.daily_deals.create!(
        :value_proposition => "Daily Deal 2 For A1", 
        :price => 25.00, 
        :value => 74.00, 
        :quantity => 100,
        :terms => "these are my terms", 
        :description => "this is my description",
        :start_at => Time.zone.parse("Jan 26, 2010 10:30:00"),
        :hide_at => Time.zone.parse("Jan 26, 2010 23:30:00")
      )
      d_4 = advertiser.daily_deals.create!(
        :value_proposition => "Daily Deal 2 For A1", 
        :price => 25.00, 
        :value => 74.00, 
        :quantity => 100,
        :terms => "these are my terms", 
        :description => "this is my description",
        :start_at => Time.zone.parse("Jan 31, 2010 12:00:00"),
        :hide_at => Time.zone.parse("Jan 31, 2010 22:00:00")
      )
      dates = Date.parse("2010-01-20")..Date.parse("2010-01-30")
      assert_equal [], Publisher.all_with_purchased_daily_deal_counts(dates, [publisher])
    end 

    test "with deals that have been purchased" do
      publisher = publishers(:sdh_austin)

      existing_purchases_count = publisher.daily_deal_purchases.count

      advertiser = publisher.advertisers.first

      ConsumerMailer.stubs(:deliver_activation_request)

      valid_user_attributes = {
        :email => "joe@blow.com",
        :name => "Joe Blow",
        :password => "secret",
        :password_confirmation => "secret",
        :agree_to_terms => "1"
      }
      c_1 = publisher.consumers.create!( valid_user_attributes.merge(:email => "jon@hello.com", :name => "Jon Smith") )
      c_2 = publisher.consumers.create!( valid_user_attributes.merge(:email => "jill@hello.com", :name => "Jill Smith") )
      c_3 = publisher.consumers.create!( valid_user_attributes.merge(:email => "cheap@hello.com", :name => "Cheap Skate") )

      d_1 = advertiser.daily_deals.create!(
        :value_proposition => "Daily Deal 2 For A1", 
        :price => 25.00, 
        :value => 74.00, 
        :quantity => 100,
        :terms => "these are my terms", 
        :description => "this is my description",
        :start_at => Time.zone.parse("Jan 20, 2010 12:00:00"),
        :hide_at  => Time.zone.parse("Jan 20, 2010 23:00:00")      
      )

      p_1 = d_1.daily_deal_purchases.build
      p_1.quantity = 1
      p_1.consumer = c_1
      p_1.payment_status = "pending"
      p_1.save!
      p_1.daily_deal_payment = Factory(:braintree_payment, :daily_deal_purchase => p_1)
      p_1.payment_status = "captured"
      p_1.executed_at = "Jan 20, 2010 12:34:56 PST"
      p_1.daily_deal_payment.payment_gateway_id = "301181649"
      p_1.daily_deal_payment.amount = "25.00"
      p_1.daily_deal_payment.credit_card_last_4 = "5555"
      p_1.daily_deal_payment.payment_at = p_1.executed_at
      p_1.save!
      p_1.create_certificates!

      p_2 = d_1.daily_deal_purchases.build
      p_2.quantity = 3
      p_2.consumer = c_2
      p_2.payment_status = "pending"
      p_2.save!
      p_2.daily_deal_payment = Factory(:braintree_payment, :daily_deal_purchase => p_2)
      p_2.executed_at = "Jan 21, 2010 14:34:56 PST"
      p_2.payment_status = "captured"
      p_2.daily_deal_payment.payment_gateway_id = "301181650"
      p_2.daily_deal_payment.amount = "75.00"
      p_2.daily_deal_payment.credit_card_last_4 = "5555"
      p_2.daily_deal_payment.payment_at = p_2.executed_at
      p_2.save!
      p_2.create_certificates!

      assert DailyDealPurchase.count >= 2
      assert_equal p_1.analog_purchase_id, p_1.daily_deal_payment.analog_purchase_id
      assert_equal p_2.analog_purchase_id, p_2.daily_deal_payment.analog_purchase_id
      assert_not_nil DailyDealPayment.find_by_analog_purchase_id(p_1.analog_purchase_id)
      assert_not_nil DailyDealPayment.find_by_analog_purchase_id(p_2.analog_purchase_id)
      assert_not_nil DailyDealPayment.find_by_daily_deal_purchase_id(p_1.id)
      assert_not_nil DailyDealPayment.find_by_daily_deal_purchase_id(p_2.id)
      assert_equal 2, publisher.daily_deal_purchases.count - existing_purchases_count

      d_2 = advertiser.daily_deals.create!(
        :value_proposition => "Daily Deal 2 For A1", 
        :price => 25.00, 
        :value => 74.00, 
        :quantity => 100,
        :terms => "these are my terms", 
        :description => "this is my description",
        :start_at => Time.zone.parse("Jan 21, 2010 12:00:00"),
        :hide_at => Time.zone.parse("Jan 21, 2010 22:00:00")

      )
      d_3 = advertiser.daily_deals.create!(
        :value_proposition => "Daily Deal 2 For A1", 
        :price => 25.00, 
        :value => 74.00, 
        :quantity => 100,
        :terms => "these are my terms", 
        :description => "this is my description",
        :start_at => Time.zone.parse("Jan 26, 2010 08:00:00"),
        :hide_at => Time.zone.parse("Jan 26, 2010 23:00:00")
      )
      d_4 = advertiser.daily_deals.create!(
        :value_proposition => "Daily Deal 2 For A1", 
        :price => 25.00, 
        :value => 74.00, 
        :quantity => 100,
        :terms => "these are my terms", 
        :description => "this is my description",
        :start_at => Time.zone.parse("Jan 31, 2010 10:00:00"),
        :hide_at => Time.zone.parse("Jan 31, 2010 20:00:00")
      )  
      dates = Date.parse("2010-01-20")..Date.parse("2010-01-30")
      row = Publisher.all_with_purchased_daily_deal_counts(dates, [publisher]).first

      assert_equal 1, row.daily_deals_count
      assert_equal 2, row.daily_deal_purchasers_count
      assert_equal 4, row.daily_deal_purchases_total_quantity
      assert_equal 100.0, row.daily_deal_purchases_gross
      assert_equal 100.0, row.daily_deal_purchases_actual_purchase_price
    end 

    test "freedom consumer csv with no consumers or subscribers" do
      publishing_group = Factory(:publishing_group, :name => "Freedome", :label => "freedom")
      ["ocregister", "gazette", "oaoa", "gastongazette", "themonitor", "shelbystar"].each_with_index do |label, index|
        publisher = Factory(:publisher, :name => label.upcase, :label => label)

        config  = YAML.load(ERB.new(File.expand_path("config/tasks/daily_deals/upload_consumers_csv.yml", RAILS_ROOT)).result)
        cols    = config[:cols] 

        publisher.generate_consumers_list(csv = [], :columns => cols)

        assert_equal 1, csv.size, "should only have title elements"
        assert_equal ["status", "email", "name", "subject"], csv[0]      
      end
    end

    test "make sure if nil is passed for default values, defaults are used" do
      publisher = Factory(:publisher, :name => "OC Register", :label => "ocregister")

      publisher.generate_consumers_list(csv = [], :columns => nil)

      assert_equal 1, csv.size, "should only have title elements"
      assert_equal ["status", "email", "name", "subject"], csv[0]

      publisher.generate_consumers_list(csv = [], :include_header => nil)
      assert_equal 1, csv.size, "should not have a header"
    end

    test "advertisers with daily deal counts" do
      click_count = lambda do |mode, publisher, clickable|
        Factory(:click_count, :mode => mode, :publisher => publisher, :clickable => clickable)
      end

      advertiser = Factory(:daily_deal_advertiser, :name => "Bar")
      daily_deal = Factory(:daily_deal, :advertiser => advertiser)
      publisher  = advertiser.publisher
      facebook_click_count = click_count.call("facebook", publisher, daily_deal)
      twitter_click_count  = click_count.call("twitter", publisher, daily_deal)

      advertiser2 = Factory(:daily_deal_advertiser, :publisher => publisher, :name => "Foo")
      daily_deal2 = Factory(:daily_deal, :advertiser => advertiser2, :start_at => daily_deal.hide_at + 1.day, :hide_at => Time.zone.now.tomorrow + 10.days)
      facebook_click_count2 = click_count.call("facebook", publisher, daily_deal2)
      twitter_click_count2  = click_count.call("twitter", publisher, daily_deal2)

      dates = Date.parse(10.days.ago.to_s) .. Date.parse(Time.zone.now.to_s)

      advertisers = publisher.reload.advertisers_with_daily_deal_counts(dates)

      assert_equal advertiser.name, advertisers.first.name
      assert_equal facebook_click_count.count.to_s, advertisers.first.facebook_count
      assert_equal twitter_click_count.count.to_s, advertisers.first.twitter_count
    end

    test "special deal" do
      publisher = Factory(:publisher, :name => "Big Time", :label => "bigtime")
      assert_equal false, publisher.show_special_deal?
    end

    test "blank how it works" do
      publisher = Factory.stub(:publisher, :how_it_works => nil)
      assert_equal nil, publisher.how_it_works, "how_it_works"
    end

    test "should accept textile format for daily_deal_universal_terms" do
      publisher = Factory(:publisher, :label => "nydailynews", :daily_deal_universal_terms => "these are *my* terms" )
      assert_equal "<p>these are <strong>my</strong> terms</p>", publisher.daily_deal_universal_terms
      assert_equal "these are *my* terms", publisher.daily_deal_universal_terms_source
      assert_equal "these are my terms", publisher.daily_deal_universal_terms_plain
    end

    test "signup_discount_amount" do
      publisher = Factory(:publisher, :label => "nydailynews", :daily_deal_universal_terms => "these are *my* terms" )
      discount = Discount.new
      discount.publisher = publisher
      discount.amount = 7.00
      discount.code = "SIGNUP_CREDIT"
      discount.save!
      assert_equal 7.00, publisher.signup_discount_amount
    end

    test "signup_discount_amount with no signup discounts" do
      publisher = Factory(:publisher, :launched => false)
      assert_equal nil, publisher.signup_discount_amount
    end

    test "Publisher.update_unique_subscribers_count! should update publisher unique_subscribers_count" do
      publisher = Factory(:publisher)
      publisher_2 = Factory(:publisher)

      Publisher.update_unique_subscribers_count!
      assert_equal 0, publisher.reload.unique_subscribers_count, "Publisher unique_subscribers_count"
      assert_equal 0, publisher_2.reload.unique_subscribers_count, "Publisher unique_subscribers_count"

      Factory(:subscriber, :publisher => publisher, :email => "chih@example.com")
      assert_equal 0, publisher.reload.unique_subscribers_count, "Publisher unique_subscribers_count"
      assert_equal 0, publisher_2.reload.unique_subscribers_count, "Publisher unique_subscribers_count"
      Publisher.update_unique_subscribers_count!
      assert_equal 1, publisher.reload.unique_subscribers_count, "Publisher unique_subscribers_count"
      assert_equal 0, publisher_2.reload.unique_subscribers_count, "Publisher unique_subscribers_count"

      Factory(:subscriber, :publisher => publisher, :email => "chih@example.com")
      Publisher.update_unique_subscribers_count!
      assert_equal 1, publisher.reload.unique_subscribers_count, "Publisher unique_subscribers_count"
      assert_equal 0, publisher_2.reload.unique_subscribers_count, "Publisher unique_subscribers_count"

      Factory(:subscriber, :publisher => publisher_2, :email => "chih@example.com")
      Publisher.update_unique_subscribers_count!
      assert_equal 1, publisher.reload.unique_subscribers_count, "Publisher unique_subscribers_count"
      assert_equal 1, publisher_2.reload.unique_subscribers_count, "Publisher unique_subscribers_count"

      Factory(:consumer, :publisher => publisher, :email => "chih@example.com")
      Factory(:consumer, :publisher => publisher, :email => "mom@example.com")
      Factory(:consumer, :publisher => publisher, :email => "dad@example.com")
      Publisher.update_unique_subscribers_count!
      assert_equal 3, publisher.reload.unique_subscribers_count, "Publisher unique_subscribers_count"
      assert_equal 1, publisher_2.reload.unique_subscribers_count, "Publisher unique_subscribers_count"
    end

    test "send_todays_email_blast_at" do
      publisher = Factory(:publisher, :time_zone => "Eastern Time (US & Canada)", :email_blast_hour => 6, :email_blast_minute => 15)
      timestamp = Time.parse("Dec 15, 2010 03:00:00 PST")
      Time.stubs(:now).returns(timestamp)

      assert_equal Time.parse("Dec 15, 2010 03:15:00 PST"), publisher.send_todays_email_blast_at

      publisher.update_attributes! :time_zone => "Hawaii"
      assert_equal Time.parse("Dec 15, 2010 08:15:00 PST"), publisher.send_todays_email_blast_at
    end

    test "subscribers_in_date_range" do
      subscriber = Factory(:subscriber)
      publisher  = subscriber.publisher
      dates      = Time.zone.now.beginning_of_month .. Time.zone.now.end_of_month

      Factory(:subscriber, :publisher => publisher, :created_at => 3.months.ago)

      subscribers = publisher.subscribers_in_date_range(dates)

      assert_equal 1, subscribers.size
    end

    test "referrals_in_date_range" do
      consumer  = Factory(:consumer, :referrer_code => "834jj2")
      publisher = consumer.publisher

      # consumer with no referrals
      Factory(:consumer, :publisher => publisher)
      # consumer out of date range
      consumer2 = Factory(:consumer, :publisher => publisher, :referral_code => consumer.referrer_code, :created_at => 3.months.ago)
      # referral in different publisher to make sure only getting this publishers referrals
      other_consumer = Factory(:consumer, :referrer_code => "1234asd")
      other_publisher = other_consumer.publisher
      Factory(:consumer, :publisher => other_publisher, :referral_code => other_consumer.referrer_code)

      # 2 good referrals and a daily_deal_purchase
      2.times do
        Factory(:consumer, :referral_code => consumer.referrer_code, :publisher => publisher)
        Factory(:credit, :consumer => consumer, :amount => 10.00)
      end
      daily_deal = Factory(:daily_deal, :publisher => publisher)
      Factory(:daily_deal_purchase, :consumer => consumer, :credit_used => 10.00, :daily_deal => daily_deal)

      dates     = Time.zone.now.beginning_of_month .. Time.zone.now.end_of_month
      referrals = publisher.referrals_in_date_range(dates)

      assert_equal 1, referrals.size

      row = referrals.first

      assert_equal consumer.id, row.id
      assert_equal consumer.email, row.email
      assert_equal "2", row.referral_count
      assert_equal "20.00", row.credits_given
      assert_equal "10.00", row.credit_used
    end

    test "currency_code" do
      publisher = Factory(:publisher)

      assert_equal "USD", publisher.currency_code
      assert_equal false, Publisher::ALLOWED_CURRENCY_CODES.include?("XYZ")

      publisher.currency_code = "XYZ"
      publisher.save

      assert 1, publisher.errors
    end

    test "currency_symbol" do
      publisher = Factory(:publisher)
      assert "$", publisher.currency_symbol

      publisher.currency_code = "GBP"
      publisher.save
      assert_equal "£", publisher.currency_symbol

      publisher.currency_code = "CAD"
      publisher.save
      assert_equal "C$", publisher.currency_symbol
    end

    test "allowed payment methods" do
      assert_equal 5, Publisher::ALLOWED_PAYMENT_METHODS.size

      %w( credit paypal optimal travelsavers cyber_source).each do |payment_method|
        assert_not_nil Publisher::ALLOWED_PAYMENT_METHODS[payment_method], "#{payment_method} should available"
      end    
    end  

    test "should not allow invalid google analytics account ids" do
      publisher = Factory.build(:publisher)
      assert_bad_value(publisher, :google_analytics_account_ids, "asdf")
      assert_bad_value(publisher, :google_analytics_account_ids, "UA-19396594-184")
    end

    test "should only allow comma-delimited google analytics account ids" do
      publisher = Factory.build(:publisher)
      assert_good_value(publisher, :google_analytics_account_ids, "UA-19396594-1, UA-19396594-2,UA-2018839-18")
      assert_good_value(publisher, :google_analytics_account_ids, "UA-19396594-1")
      assert_good_value(publisher, :google_analytics_account_ids, "UA-19396594-18")
      assert_good_value(publisher, :google_analytics_account_ids, "")
      assert_good_value(publisher, :google_analytics_account_ids, nil)
    end

    test "daily_deal_name for publisher with using default value" do
      publisher = Factory(:publisher, :label => "newpublisher")
      assert_equal "Deal of the Day", publisher.daily_deal_name
    end

    test "daily_deal_name for TWC publisher" do
      publishing_group = Factory(:publishing_group, :label => "rr")
      publisher        = Factory(:publisher, :publishing_group => publishing_group, :label => "clickedin-austin")
      assert_equal "Daily Deal", publisher.daily_deal_name
    end

    test "ignore_daily_deal_short_description_size" do
      publisher = Factory(:publisher)

      assert_equal false, publisher.ignore_daily_deal_short_description_size?, "should default to false"
    end

    test "publisher model is versioned" do
      assert Publisher.versioned?
    end

    test "should use User.current to capture updated_by in versioning" do
      User.current = Factory(:admin)
      publisher = Factory(:publisher)
      publisher.update_attribute(:merchant_account_id, "123ABC")
      assert_equal User.current.id, publisher.versions.last.user.id
    end

    test "delegate_advertiser_financial_details" do
      publishing_group = Factory(:publishing_group, 
                                 :advertiser_financial_detail => true)
      publisher = Factory(:publisher, :publishing_group => publishing_group)
      assert_equal true, publisher.advertiser_financial_detail?, "should delegate to publishing group"
    end
    
    test "delegate_advertiser_financial_details_with_no_publishing_group" do
      publisher = Factory(:publisher)
      assert_equal false, publisher.advertiser_financial_detail?, "should be false with no publishing group"
    end
    
    test "delegate_require_federal_tax_id" do
      publishing_group = Factory(:publishing_group, 
                                 :advertiser_financial_detail => true, 
                                 :require_federal_tax_id => true)
      publisher = Factory(:publisher, :publishing_group => publishing_group)
      assert_equal true, publisher.require_federal_tax_id?, "should delegate to publishing group"
    end
    
    test "delegate_require_federal_tax_id_with_no_publishing_group" do
      publisher = Factory(:publisher)
      assert_equal false, publisher.require_federal_tax_id?, "should be false with no publishing group"
    end

    test "find_market_by_zip_code" do
      publisher = Factory(:publisher, :label => "kowabunga")
      market    = Factory(:market, :publisher => publisher)
      market2   = Factory(:market, :publisher => publisher)
      market_zip_code = Factory(:market_zip_code, :market => market, :zip_code => "97211")
      
      assert_equal market, publisher.find_market_by_zip_code("97211")
    end

    test "available_country_code? should return true for available country codes" do
      uk = Country.find_or_create_by_code('UK')
      us = Country.find_or_create_by_code('US')
      publisher = Factory(:publisher, :countries => [uk, us])
      assert publisher.available_country_code?('uk')
      assert publisher.available_country_code?(:uk)
      assert publisher.available_country_code?('UK')
      assert publisher.available_country_code?('us')
      assert !publisher.available_country_code?('ca')
    end

    test "publishers countries should default to US" do
      publisher = Factory.build(:publisher)
      us = Country.find_or_create_by_code('us')
      ca = Country.find_or_create_by_code('ca')

      publisher.countries = []
      assert publisher.valid?
      assert_equal [us], publisher.countries

      publisher.countries = [ca]
      assert publisher.valid?
      assert_equal [ca], publisher.countries
    end

    test "included_in_market_selection should not include publishers marked for exclusion" do
      publishing_group = Factory(:publishing_group)
      publisher1 = Factory(:publisher, :publishing_group => publishing_group)
      publisher2 = Factory(:publisher, :publishing_group => publishing_group, :exclude_from_market_selection => true)

      assert_same_elements [publisher1], publishing_group.publishers.included_in_market_selection
    end

    fast_context "sweepstakes" do

      setup do
        @publisher = Factory(:publisher)
      end

      fast_context "create new sweepstake" do

        setup do
          @sweepstake = @publisher.sweepstakes.create( Factory.attributes_for(:sweepstake) )
        end

        should "be valid" do
          assert @sweepstake.valid?
        end

        should "not be a new record" do
          assert !@sweepstake.new_record?
        end

      end

    end
    
    test "delegate allows_donations" do
      publishing_group = Factory(:publishing_group, :allows_donations => true)
      publisher = Factory(:publisher, :publishing_group => publishing_group)
      assert_equal true, publisher.allows_donations?, "should delegate to publishing group"
    end

    test "syndication_allowed_to_publisher?" do
      publishing_group1 = Factory(:publishing_group, :restrict_syndication_to_publishing_group => true)
      publishing_group2 = Factory(:publishing_group)

      publisher1 = Factory(:publisher, :publishing_group => publishing_group1)
      publisher2 = Factory(:publisher, :publishing_group => publishing_group1)
      publisher3 = Factory(:publisher, :publishing_group => publishing_group2)
      publisher4 = Factory(:publisher, :publishing_group => nil)

      assert !publisher1.syndication_allowed_to_publisher?(publisher1)
      assert  publisher1.syndication_allowed_to_publisher?(publisher2)
      assert !publisher1.syndication_allowed_to_publisher?(publisher3)
      assert !publisher1.syndication_allowed_to_publisher?(publisher4)

      assert  publisher2.syndication_allowed_to_publisher?(publisher1)
      assert !publisher2.syndication_allowed_to_publisher?(publisher2)
      assert !publisher2.syndication_allowed_to_publisher?(publisher3)
      assert !publisher2.syndication_allowed_to_publisher?(publisher4)

      assert !publisher3.syndication_allowed_to_publisher?(publisher1)
      assert !publisher3.syndication_allowed_to_publisher?(publisher2)
      assert !publisher3.syndication_allowed_to_publisher?(publisher3)
      assert  publisher3.syndication_allowed_to_publisher?(publisher4)

      assert !publisher4.syndication_allowed_to_publisher?(publisher1)
      assert !publisher4.syndication_allowed_to_publisher?(publisher2)
      assert  publisher4.syndication_allowed_to_publisher?(publisher3)
      assert !publisher4.syndication_allowed_to_publisher?(publisher4)
    end

    context "silverpop" do

      should "delegate silverpop_template_identifier to publishing_group" do
        pg = Factory(:publishing_group, :silverpop_template_identifier => "12345")
        p = Factory(:publisher, :publishing_group => pg, :silverpop_template_identifier => nil)
        assert_equal "12345", p.silverpop_template_identifier
      end

      should "delegate silverpop_seed_template_identifier to publishing_group" do
        pg = Factory(:publishing_group, :silverpop_seed_template_identifier => "45678")
        p = Factory(:publisher, :publishing_group => pg, :silverpop_seed_template_identifier => nil)
        assert_equal "45678", p.silverpop_seed_template_identifier
      end

    end

    context "daily_deals_available_for_syndication_by_default" do
      setup do
        @publishing_group = Factory(:publishing_group)
        @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      end

      should "be false by default and save" do
        assert !@publisher.daily_deals_available_for_syndication_by_default_override?

        @publisher.daily_deals_available_for_syndication_by_default_override = true
        assert @publisher.daily_deals_available_for_syndication_by_default_override?
      end
      should "inherit the value from the publishing group, and be able to override it" do
        assert !@publishing_group.daily_deals_available_for_syndication_by_default?
        assert !@publisher.daily_deals_available_for_syndication_by_default_override?
 
        @publishing_group.daily_deals_available_for_syndication_by_default = true
        assert @publishing_group.daily_deals_available_for_syndication_by_default?
        assert @publisher.daily_deals_available_for_syndication_by_default_override?
 
        @publisher.daily_deals_available_for_syndication_by_default_override = false
        assert !@publisher.reload.daily_deals_available_for_syndication_by_default_override?
      end
    end

    context "federal_tax_id" do
      # should "validate presence" do
        # publisher = Factory(:publisher)
        # assert_good_value(publisher, :federal_tax_id, "12-12121212")
        # assert_bad_value(publisher, :federal_tax_id, nil)
      # end

      should "set encrypted attribute" do
        publisher = Factory(:publisher, :federal_tax_id => "12-12121212")
        assert publisher.encrypted_federal_tax_id.present?
      end
    end

    context "specific publisher" do
      setup do
        @publisher = Factory(:publisher, :label => 'bcbsa-national')
      end

      should 'know its bcbsa-national' do
        assert @publisher.bcbsa_national?
      end
    end

    private
    def create_publisher_with_offers(count)
      publisher = Factory(:publisher, :name => "Test Publisher")
      offers = returning([]) do |array|
        count.times do |i|
          advertiser = publisher.advertisers.create!(:name => "Advertiser #{i}", :voice_response_code => "123")
          array << advertiser.offers.create!(:message => "Message #{i}", :txt_message => "TXT Message #{i}")
        end
      end
      [publisher, offers]
    end

    def create_txt(count, publisher, offer, time, status)
      count.times do
        lead = offer.leads.create!(:publisher => publisher, :txt_me => true, :mobile_number => "858-555-1212")
        txt = Txt.find_by_source_type_and_source_id('Lead', lead.id)
        txt.update_attributes! :created_at => Time.zone.parse(time), :status => status
      end
    end

    def create_email(count, publisher, offer, time)
      count.times do
        offer.leads.create!(:publisher => publisher, :email_me => true, :email => "test@example.com", :created_at => Time.zone.parse(time))
      end
    end

    def create_voice_message(count, publisher, offer, time, status, talk_minutes = nil)
      time = Time.zone.parse(time)
      intelligent_minutes = 0.6

      count.times do |i|
        lead = offer.leads.create!(:publisher => publisher, :offer => offer, :call_me => true, :mobile_number => "858-555-1212")
        voice_message = VoiceMessage.find_by_lead_id(lead)
        if "sent" == status
          sid = "123#{voice_message.id}"
          CallDetailRecord.create!(
            :sid => sid,
            :date_time => (time - 4.hours + (intelligent_minutes + talk_minutes).minutes + 1.second).strftime("%Y-%m-%d %H:%M:%S"),
            :viewer_phone_number => "8585551212",
            :center_phone_number => "8001234567",
            :intelligent_minutes => intelligent_minutes,
            :talk_minutes => talk_minutes
          )
          voice_message.call_detail_record_sid = sid
        end
        voice_message.created_at = time
        voice_message.status = status
        voice_message.save!
      end
    end
  end
end
