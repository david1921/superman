require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Advertisers::AdvertiserTest

class Advertisers::AdvertiserTest < ActiveSupport::TestCase
  def setup
    AppConfig.expects(:default_voice_response_code).at_most_once.returns(nil)
  end

  def test_create
    publishers(:my_space).advertisers.create!
  end

  context "#notes" do
    setup do
      @advertiser = Factory(:advertiser)
      @user = Factory(:user)
    end

    should "return the notes for this Advertiser" do
      note = Note.create!(:user => @user, :notable => @advertiser, :text => "I'm a note")
      assert_contains @advertiser.reload.notes, note
    end

    should "retain saved text" do
      note = Note.create!(:user => @user, :notable => @advertiser, :text => "I'm a note")
      assert_contains @advertiser.reload.notes, note
      assert_equal "I'm a note", @advertiser.reload.notes[0].text
    end

    should "have a user associated with it" do
      note = Note.create!(:user => @user, :notable => @advertiser, :text => "I'm a note")
      assert_contains @advertiser.reload.notes, note
      assert_equal @user, @advertiser.reload.notes[0].user
    end

  end

  def test_create_with_a_simple_name
    advertiser = publishers(:my_space).advertisers.create!( :name => "New Seasons" )
    assert_equal "new-seasons", Advertiser.find_by_id(advertiser.id).label
    assert_equal advertiser, publishers(:my_space).advertisers.find_by_label( advertiser.label )
  end

  def test_create_with_a_name_that_contains_an_apostrophe
    advertiser = publishers(:my_space).advertisers.create!( :name => "Jim's Automotive Services" )
    assert_equal "jims-automotive-services", Advertiser.find_by_id(advertiser.id).label
    assert_equal advertiser, publishers(:my_space).advertisers.find_by_label( advertiser.label )
  end

  def test_create_with_existing_advertiser_with_same_name_for_publisher
    existing_advertiser =  publishers(:my_space).advertisers.create!( :name => "New Seasons" )
    assert !existing_advertiser.new_record?

    new_advertiser = publishers(:my_space).advertisers.create( :name => "New Seasons" )
    assert_equal "new-seasons-2", Advertiser.find_by_id(new_advertiser.id).label
    assert_equal new_advertiser, publishers(:my_space).advertisers.find_by_label( new_advertiser.label )
  end

  def test_create_with_existing_advertiser_with_same_basic_label_for_publisher
    existing_advertiser =  publishers(:my_space).advertisers.create!( :name => "New Seasons" )
    new_advertiser = publishers(:my_space).advertisers.create!( :name => "New Season's" )
    assert_equal "new-seasons-2", Advertiser.find_by_id(new_advertiser.id).label
    assert_equal new_advertiser, publishers(:my_space).advertisers.find_by_label( new_advertiser.label )
  end

  def test_create_with_invalid_payment_type
    advertiser =  publishers(:my_space).advertisers.build( :name => "New Seasons", :payment_type => 'blah' )
    assert !advertiser.valid?

    advertiser =  publishers(:my_space).advertisers.build( :name => "New Seasons", :payment_type => 'check' )
    assert !advertiser.valid?
  end

  def test_create_with_valid_payment_type
    advertiser = publishers(:my_space).advertisers.build( :name => "New Seasons", :payment_type => 'ACH' )
    assert advertiser.valid?

    advertiser = publishers(:my_space).advertisers.build( :name => "New Seasons", :payment_type => 'Check' )
    assert advertiser.valid?
  end

  def test_create_with_financial_data_for_entertainment
    advertiser = publishers(:my_space).advertisers.create!( :name => "New Seasons", :payment_type => 'ACH', :bank_routing_number => "123123123", :bank_account_number => "56565656", :federal_tax_id => "12-12121212", :merchant_id => "77777777777" )
    assert advertiser.encrypted_bank_routing_number.present?
    assert advertiser.encrypted_bank_account_number.present?
    assert advertiser.encrypted_federal_tax_id
  end

  def test_create_with_revenue_share_percentage_of_0
    publisher = Factory(:publisher)
    advertiser = publisher.advertisers.build( Factory.attributes_for(:advertiser).merge(:revenue_share_percentage => 0) )
    assert !advertiser.valid?
  end

  def test_create_with_revenue_share_percentage_of_50
    publisher = Factory(:publisher)
    advertiser = publisher.advertisers.build( Factory.attributes_for(:advertiser).merge(:revenue_share_percentage => 50) )
    assert advertiser.valid?
  end

  def test_create_with_revenue_share_percentage_of_100
    publisher = Factory(:publisher)
    advertiser = publisher.advertisers.build( Factory.attributes_for(:advertiser).merge(:revenue_share_percentage => 100) )
    assert advertiser.valid?
  end

  def test_create_with_a_nil_revenue_share_percentage
    publisher = Factory(:publisher)
    advertiser = publisher.advertisers.build( Factory.attributes_for(:advertiser).merge(:revenue_share_percentage => nil) )
    assert advertiser.valid?
  end

  def test_create_with_a_blank_revenue_share_percentage
    publisher = Factory(:publisher)
    advertiser = publisher.advertisers.build( Factory.attributes_for(:advertiser).merge(:revenue_share_percentage => "") )
    assert advertiser.valid?
  end

  def test_create_with_nil_merchant_commission_percentage
    publisher = Factory(:publisher)
    advertiser = publisher.advertisers.build( Factory.attributes_for(:advertiser).merge(:merchant_commission_percentage => nil) )
    assert advertiser.valid?
  end

  def test_create_with_blank_merchant_commission_percentage
    publisher = Factory(:publisher)
    advertiser = publisher.advertisers.build( Factory.attributes_for(:advertiser).merge(:merchant_commission_percentage => "") )
    assert advertiser.valid?
  end

  def test_create_with_merchant_commission_percentage_of_0
    publisher = Factory(:publisher)
    advertiser = publisher.advertisers.build( Factory.attributes_for(:advertiser).merge(:merchant_commission_percentage => 0) )
    assert !advertiser.valid?
  end

  def test_create_with_merchant_commission_percentage_of_100
    publisher = Factory(:publisher)
    advertiser = publisher.advertisers.build( Factory.attributes_for(:advertiser).merge(:merchant_commission_percentage => 100) )
    assert !advertiser.valid?
  end

  def test_destroy
    advertiser = publishers(:my_space).advertisers.create
    advertiser.destroy
  end

  def test_destroy_with_dependencies
    publisher =  publishers(:my_space)
    advertiser = publisher.advertisers.create
    offer = advertiser.offers.create!( :message => "Offer 2", :txt_message => "txt message")
    offer.click_counts.create! :publisher => publisher
    lead = offer.leads.create!(:publisher => publisher, :mobile_number => "12123334455", :txt_me => true)
    Txt.create!
    VoiceMessage.create!(:voice_response_code => "123", :lead => lead, :mobile_number => "12123334455")
    advertiser.destroy
  end

  def test_cant_destroy_advertiser_that_has_daily_deals_purchases
    daily_deals_purchase = Factory(:pending_daily_deal_purchase)
    advertiser = daily_deals_purchase.advertiser
    assert !advertiser.destroy, "Should not destroy Advertiser"
    assert DailyDeal.exists?(daily_deals_purchase.daily_deal.id), "Should not delete DailyDeal"
    assert DailyDealPurchase.exists?(daily_deals_purchase.id), "Should not delete DailyDealPurchase"
  end

  def test_save
    advertiser = advertisers(:burger_king)
    advertiser.tagline = "new tagline"
    assert_nothing_raised { advertiser.save! }
  end

  def test_to_sym
    assert_equal(:burger_king, advertisers(:burger_king).to_sym, "to_sym")
  end

  def fixture_file_upload(path, mime_type = nil, binary = false)
    fixture_path = ActionController::TestCase.send(:fixture_path) if ActionController::TestCase.respond_to?(:fixture_path)
    ActionController::TestUploadedFile.new("#{fixture_path}#{path}", mime_type, binary)
  end

  def test_default_coupon_clipping_modes
    advertiser = publishers(:my_space).advertisers.create
    Advertiser::RECOGNIZED_COUPON_CLIPPING_MODES.each do |mode|
      assert !advertiser.allows_clipping_via(mode)
    end
  end

  def test_create_with_coupon_clipping_modes
    advertiser = publishers(:my_space).advertisers.create!(:coupon_clipping_modes => ["email", "txt"])
    assert advertiser.allows_clipping_via(:email)
    assert advertiser.allows_clipping_via(:txt)
  end

  def test_create_with_empty_clipping_mode
    advertiser = publishers(:my_space).advertisers.create!(:coupon_clipping_modes => ["", "txt"])
    assert advertiser.allows_clipping_via(:txt)
  end

  def test_update_coupon_clipping_modes
    advertiser = publishers(:my_space).advertisers.create!(:coupon_clipping_modes => ["email"])
    assert advertiser.allows_clipping_via(:email)
    assert !advertiser.allows_clipping_via(:txt)

    advertiser.update_attributes!(:coupon_clipping_modes => ["txt"])
    assert !advertiser.allows_clipping_via(:email)
    assert advertiser.allows_clipping_via(:txt)
  end

  def test_validation_with_click_to_call
    advertiser = publishers(:my_space).advertisers.create!(
      :coupon_clipping_modes => ["call"],
      :voice_response_code => "123",
      :call_phone_number => "323-571-2335")
    assert advertiser.allows_clipping_via(:call)
    assert_equal "123", advertiser.voice_response_code, "voice_response_code"
    assert_equal "13235712335", advertiser.call_phone_number, "call_phone_number"

    advertiser_new = Advertiser.new(
        :coupon_clipping_modes => ["call"],
        :call_phone_number => "323-571-2335",
        :voice_response_code => "not a number",
        :publisher => publishers(:my_space)
    )
    assert !advertiser_new.valid?
    assert_equal "Voice response code is not a number", advertiser_new.errors[:voice_response_code]
  end

  def test_url_validation
    test_url = lambda do |value, valid, normal|
      %w{ website_url google_map_url }.each do |attr|
        advertiser = publishers(:gvnews).advertisers.build(attr => value)
        if valid
          assert advertiser.valid?, "Advertiser should be valid with #{attr} '#{value}'"
          assert_equal normal, advertiser.send(attr), "#{attr} #{value} should be normalized to '#{normal}'"
        else
          assert !advertiser.valid?, "Advertiser should not be valid with #{attr} '#{value}'"
          assert advertiser.errors.on(attr), "Advertiser should have error on #{attr} when value is '#{value}'"
        end
      end
    end
    test_url.call nil, true, ""
    test_url.call "", true, ""
    test_url.call "http://www.example.com", true, "http://www.example.com"
    test_url.call "www.example.com", true, "http://www.example.com"
    test_url.call "https://www.example.com", true, "https://www.example.com"
    test_url.call "http://www.example.com@/", false, nil
    test_url.call "www.example.com@/", false, nil
    test_url.call "https://www.example.com@/", false, nil
  end

  def test_email_address_validation
    test_email = lambda do |value, valid|
      advertiser = publishers(:gvnews).advertisers.build(:email_address => value)
      if valid
        assert advertiser.valid?, "Advertiser should be valid with email '#{value}'"
      else
        assert !advertiser.valid?, "Advertiser should not be valid with email '#{value}'"
        assert advertiser.errors.on(:email_address), "Advertiser should have error on email when value is '#{value}'"
      end
    end
    test_email.call nil, true
    test_email.call "", true
    test_email.call "tbuscher@hotmail.com", true
    test_email.call "tbuscher", false
    test_email.call "@hotmail.com", false
    test_email.call "tbuscher@@hotmail.com", false
    test_email.call "tbuscher@hotmail.com/", false
  end

  def test_voice_response_code_validation
    publisher = publishers(:gvnews)

    advertiser = publisher.advertisers.create!(:voice_response_code => " 123 ")
    assert_equal "123", advertiser.voice_response_code, "Advertiser should have the specified voice response code"

    advertiser = publisher.advertisers.build(:voice_response_code => "abc123")
    assert !advertiser.valid?, "Advertiser should not be valid with non-numeric voice response code"
    assert advertiser.errors.on(:voice_response_code)
  end

  def test_default_voice_response_code_without_app_config
    advertiser = publishers(:gvnews).advertisers.create!
    assert_match(/\A\d+\Z/, advertiser.voice_response_code, "Default voice response code should be non-empty and numeric")
  end

  def test_address_with_nil_store
    advertiser = publishers(:gvnews).advertisers.create!
    assert_nil advertiser.store, "Advertiser should not have a store"
    assert_equal [], advertiser.address, "Advertiser address with nil store"
  end

  def test_stores
    advertiser = Factory :advertiser

    assert_equal 1, advertiser.stores.count

    primary_store = advertiser.stores.first
    assert_equal primary_store, advertiser.store, "primary store"

    second_store = advertiser.stores.build
    assert_equal primary_store, advertiser.store, "primary_store with many stores"
    assert_equal [ primary_store, second_store ], advertiser.stores, "stores"
  end

  def test_validation_of_txt_clipping_mode
    advertiser = advertisers(:changos)

    advertiser.offers.destroy_all
    advertiser.coupon_clipping_modes = []
    assert advertiser.valid?, "Should be valid without TXT clipping mode and no offers"
    advertiser.coupon_clipping_modes = [:txt]
    assert advertiser.valid?, "Should be valid with TXT clipping mode and no offers"

    advertiser.offers.destroy_all
    offer = advertiser.offers.create! :message => "Free taco"

    advertiser.coupon_clipping_modes = []
    assert advertiser.valid?, "Should be valid without TXT clipping mode and offer with no TXT message"
    advertiser.coupon_clipping_modes = [:txt]
    assert !advertiser.valid?, "Should not be valid with TXT clipping mode and offer with no TXT message"
    assert advertiser.errors.on(:coupon_clipping_modes)

    offer.update_attributes! :deleted_at => Time.now

    advertiser.coupon_clipping_modes = []
    assert advertiser.valid?, "Should be valid without TXT clipping mode and deleted offer with no TXT message"
    advertiser.coupon_clipping_modes = [:txt]
    assert advertiser.valid?, "Should be valid with TXT clipping mode and deleted offer with no TXT message"

    advertiser.offers.destroy_all
    advertiser.offers.create! :message => "Free taco", :txt_message => "Free taco"

    advertiser.coupon_clipping_modes = []
    assert advertiser.valid?, "Should be valid without TXT clipping mode and offer with TXT message"
    advertiser.coupon_clipping_modes = [:txt]
    assert advertiser.valid?, "Should be valid with TXT clipping mode and offer with TXT message"
  end

  def test_effective_active_txt_coupon_limit
    advertiser = advertisers(:changos)
    assert_effective_limit = lambda do |publisher_limit, advertiser_limit, effective_limit|
      advertiser.publisher.active_txt_coupon_limit = publisher_limit
      advertiser.active_txt_coupon_limit = advertiser_limit
      assert_equal effective_limit, advertiser.effective_active_txt_coupon_limit, "Effective limit with publisher limit #{publisher_limit}, advertiser limit #{advertiser_limit}"
    end
    assert_effective_limit.call nil, nil, nil
    assert_effective_limit.call nil, 0, 0
    assert_effective_limit.call 0, nil, 0
    assert_effective_limit.call nil, 3, 3
    assert_effective_limit.call 3, nil, 3
    assert_effective_limit.call 0, 0, 0
    assert_effective_limit.call 3, 0, 0
    assert_effective_limit.call 0, 3, 0
    assert_effective_limit.call 1, 3, 1
    assert_effective_limit.call 3, 1, 1
    assert_effective_limit.call 3, 3, 3
  end

  def test_effective_active_coupon_limit
    advertiser = advertisers(:changos)
    assert_effective_limit = lambda do |publisher_limit, advertiser_limit, effective_limit|
      advertiser.publisher.active_coupon_limit = publisher_limit
      advertiser.active_coupon_limit = advertiser_limit
      assert_equal effective_limit, advertiser.effective_active_coupon_limit, "Effective limit with publisher limit #{publisher_limit}, advertiser limit #{advertiser_limit}"
    end
    assert_effective_limit.call nil, nil, nil
    assert_effective_limit.call nil, 0, 0
    assert_effective_limit.call 0, nil, 0
    assert_effective_limit.call nil, 3, 3
    assert_effective_limit.call 3, nil, 3
    assert_effective_limit.call 0, 0, 0
    assert_effective_limit.call 3, 0, 0
    assert_effective_limit.call 0, 3, 0
    assert_effective_limit.call 1, 3, 1
    assert_effective_limit.call 3, 1, 1
    assert_effective_limit.call 3, 3, 3
  end

  def test_coupon_limits_validation
    advertiser = publishers(:sdh_austin).advertisers.create!(:name => "Advertiser One")
    assert_nil advertiser.active_coupon_limit, "Default active coupon limit"
    assert_nil advertiser.active_txt_coupon_limit, "Default active TXT coupon limit"

    advertiser.active_coupon_limit = "X"
    assert advertiser.invalid?, "Should be invalid with non-numeric active coupon limit"
    advertiser.active_coupon_limit = "1.0"
    assert advertiser.invalid?, "Should be invalid with non-integer active coupon limit"
    advertiser.active_coupon_limit = "-1"
    assert advertiser.invalid?, "Should be invalid with negative active coupon limit"
    advertiser.active_coupon_limit = "0"
    assert advertiser.valid?, "Should be valid with zero active coupon limit"
    advertiser.active_coupon_limit = "3"
    assert advertiser.valid?, "Should be valid with positive active coupon limit"

    advertiser.active_txt_coupon_limit = "X"
    assert advertiser.invalid?, "Should be invalid with non-numeric active TXT coupon limit"
    advertiser.active_txt_coupon_limit = "1.0"
    assert advertiser.invalid?, "Should be invalid with non-integer active TXT coupon limit"
    advertiser.active_txt_coupon_limit = "-1"
    assert advertiser.invalid?, "Should be invalid with negative active TXT coupon limit"
    advertiser.active_txt_coupon_limit = "0"
    assert advertiser.valid?, "Should be valid with zero active TXT coupon limit"
    advertiser.active_txt_coupon_limit = "3"
    assert advertiser.valid?, "Should be valid with positive active TXT coupon limit"
  end

  def test_active_and_approved
    publisher = Factory(:publisher, :name => "No Self-service Publisher")
    advertiser = publisher.advertisers.create!(:name => "Advertiser")
    assert !advertiser.approved?, "By default, Advertisers are not approved"
    assert advertiser.active?, "If publishers is not self-serve, advertisers are active"
    assert !advertiser.subscribed?, "Advertiser should not be subscribed"
  end

  def test_paid_advertiser_active_and_approved
    publisher = Factory(:publisher, :name => "Self-service Publisher", :self_serve => true)
    subscription_rate_schedule = publisher.subscription_rate_schedules.create!(:name => "rates")
    advertiser = publisher.advertisers.create!(:name => "Advertiser", :paid => true, :subscription_rate_schedule => subscription_rate_schedule)
    assert !advertiser.approved?, "By default, Advertisers are not approved"
    assert !advertiser.active?, "Paid advertisers are not active unless they have a subscription"
    assert !advertiser.subscribed?, "Advertiser should not be subscribed"

    advertiser.paypal_subscription_notifications.create!(
      :paypal_mc_amount3 => "23.99",
      :paypal_payer_email => "jay@example.com",
      :paypal_txn_type => "subscr_signup")
    assert !advertiser.approved?, "Subscribed advertisers are not approved"
    assert !advertiser.active?, "Paid advertisers are not active unless they have a subscription"
    assert advertiser.subscribed?, "Advertiser should be subscribed"

    advertiser.approve!
    assert advertiser.active?, "Paid advertisers are active if they have a subscription and are approved"
    assert advertiser.subscribed?, "Advertiser should be subscribed"
  end

  def test_keyword_prefixes
    advertiser = advertisers(:changos)
    assert_equal "SDH", advertiser.publisher.txt_keyword_prefix, "TXT keyword prefix of publisher fixture"

    advertiser.update_attributes! :txt_keyword_prefix => nil
    assert_equal ["SDH"], advertiser.txt_keyword_prefixes, "TXT keyword prefixes with blank advertiser TXT keyword prefix"

    advertiser.update_attributes! :txt_keyword_prefix => " TA CO "
    assert_equal ["SDHTACO"], advertiser.txt_keyword_prefixes, "TXT keyword prefixes with advertiser TXT keyword prefix present"

    advertiser.publisher.update_attributes! :txt_keyword_prefix => nil
    assert_equal [], advertiser.txt_keyword_prefixes, "TXT keyword prefixes with blank publisher TXT keyword prefix"
  end

  def test_keyword_prefix_must_be_unique_per_publisher
    publisher_1 = publishers(:sdh_austin)
    publisher_1.advertisers.create!(:name => "Advertiser One", :txt_keyword_prefix => "TACO1")

    advertiser = publisher_1.advertisers.new(:name => "Advertiser Two", :txt_keyword_prefix => "TACO2")
    assert advertiser.valid?, "Should be valid with unique TXT keyword prefix"

    advertiser.txt_keyword_prefix = " TACO 1 "
    assert advertiser.invalid?, "Should be invalid with non-unique TXT keyword prefix"
    assert_match(/has already been taken/, advertiser.errors.on(:txt_keyword_prefix), "TXT keyword prefix error")

    publisher_2 = publishers(:houston_press)
    advertiser = publisher_2.advertisers.new(:name => "Advertiser Two", :txt_keyword_prefix => "TACO1", :listing => "2")
    assert advertiser.valid?, "Should be valid with unique TXT keyword prefix"
  end

  def test_facebook_logo
    advertiser = advertisers(:burger_king)
    advertiser.logo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/burger_king.png", 'image/png')
    advertiser.save!
    assert_equal 130, advertiser.logo_facebook_width, "logo_facebook_width"
    assert_equal 110, advertiser.logo_facebook_height, "logo_facebook_height"
    assert advertiser.logo_dimension_valid_for_facebook?, "logo_dimension_valid_for_facebook?"

    advertiser.logo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/advertiser_logo.png", 'image/png')
    advertiser.save!
    assert_equal 130, advertiser.logo_facebook_width, "logo_facebook_width"
    assert_equal 110, advertiser.logo_facebook_height, "logo_facebook_height"
    assert advertiser.logo_dimension_valid_for_facebook?, "logo_dimension_valid_for_facebook?"
  end

  def test_paid_validation
    publisher = publishers(:sdh_austin)

    advertiser = publisher.advertisers.create!(:name => "Advertiser One")
    assert !advertiser.paid, "Paid flag should default to false"
    advertiser.paid = true
    assert advertiser.invalid?, "Advertiser should not be valid with modified paid flag"
    assert_match(/cannot be changed/i, advertiser.errors.on(:paid))

    advertiser = publisher.advertisers.create!(
      :name => "Advertiser Two",
      :paid => true,
      :subscription_rate_schedule => subscription_rate_schedules(:sdh_austin_rates)
    )
    assert advertiser.paid, "Paid flag should be set for new advertiser"
    advertiser.paid = false
    assert advertiser.invalid?, "Advertiser should not be valid with modified paid flag"
    assert_match(/cannot be changed/i, advertiser.errors.on(:paid))
  end

  def test_activation
    publisher = publishers(:sdh_austin)

    advertiser = publisher.advertisers.create!(:name => "Advertiser One")
    assert !advertiser.paid, "Paid flag should default to false"
    assert advertiser.active?, "Regular advertiser should be active"

    offer = advertiser.offers.create!(:message => "Offer")
    assert offer.advertiser_active, "Offer should have advertiser marked active"
    assert offer.showable, "Offer should be showable"

    advertiser = publisher.advertisers.create!(
      :name => "Advertiser Two",
      :paid => true,
      :subscription_rate_schedule => subscription_rate_schedules(:sdh_austin_rates)
    )
    assert advertiser.paid, "Paid flag should be set for new advertiser"
    assert !advertiser.active?, "Paid advertiser should not be active initially"

    offer_1 = advertiser.offers.create!(:message => "Offer One")
    assert !offer_1.advertiser_active, "Offer should not have advertiser marked active"
    assert !offer_1.showable, "Offer should not be showable"

    advertiser.paypal_subscription_notifications.create!(
      :paypal_txn_type => "subscr_signup",
      :paypal_payer_email => "joe@blow.com",
      :paypal_mc_amount3 => "9.99"
    )
    assert advertiser.subscribed?, "Advertiser should be subscribed after subscription signup without publisher approval"
    assert !advertiser.active?, "Advertiser should not be active after subscription signup without publisher approval"
    assert !offer_1.reload.advertiser_active, "Offer should not have advertiser marked active without publisher approval"
    assert !offer_1.showable, "Offer should not be showable without publisher approval"

    advertiser.approve!
    assert advertiser.approved?, "Advertiser should be approved"
    assert advertiser.subscribed?, "Advertiser should be subscribed after subscription signup with publisher approval"
    assert advertiser.active?, "Advertiser should be active after subscription signup"
    assert offer_1.reload.advertiser_active, "Offer should have advertiser marked active"
    assert offer_1.showable, "Offer should be showable"

    offer_2 = advertiser.offers.create!(:message => "Offer Two")
    assert offer_2.advertiser_active, "Offer should have advertiser marked active"
    assert offer_2.showable, "Offer should be showable"

    advertiser.paypal_subscription_notifications.create!(
      :paypal_txn_type => "subscr_eot",
      :paypal_payer_email => "joe@blow.com",
      :paypal_mc_amount3 => "9.99")
    assert !advertiser.active?, "Advertiser should not be active after subscription ends"
    assert !offer_1.reload.advertiser_active, "Offer should not have advertiser marked active"
    assert !offer_1.showable, "Offer should not be showable"
    assert !offer_2.reload.advertiser_active, "Offer should not have advertiser marked active"
    assert !offer_2.showable, "Offer should not be showable"
  end

  def test_subscription_rate_schedule_validation
    advertiser = publishers(:sdh_austin).advertisers.create!(
      :name => "Advertiser Two",
      :paid => true,
      :subscription_rate_schedule => subscription_rate_schedules(:sdh_austin_rates)
    )
    advertiser.subscription_rate_schedule = SubscriptionRateSchedule.create(:item_owner => publishers(:sdh_boulder), :name => "Boulder Rates")
    assert advertiser.invalid?, "Advertiser should not be valid with a rate schedule belonging to another publisher"
    assert_match(/does not belong to .* publisher/, advertiser.errors.on(:subscription_rate_schedule))
  end

  def test_offer_has_listing
    publisher = Factory(:publisher, :offer_has_listing => false)
    advertiser = Factory(:advertiser, :publisher => publisher)
    assert !advertiser.offer_has_listing?
    publisher = Factory(:publisher, :offer_has_listing => true)
    advertiser = Factory(:advertiser, :publisher => publisher)
    assert advertiser.offer_has_listing?
  end

  def test_require_federal_tax_id_with_financial_data
    publishing_group = Factory(:publishing_group,
                               :advertiser_financial_detail => true,
                               :require_federal_tax_id => true)
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    advertiser = publisher.advertisers.build(:name => "New Seasons",
                                             :payment_type => 'ACH',
                                             :bank_routing_number => "123123123",
                                             :bank_account_number => "56565656",
                                             :merchant_id => "77777777777" )
    assert advertiser.invalid?, "Should be invalid without federal tax id"
    assert_match "Federal tax can't be blank", advertiser.errors.on(:federal_tax_id)
  end

  def test_do_not_require_federal_tax_id_with_financial_data
    publishing_group = Factory(:publishing_group,
                               :advertiser_financial_detail => true,
                               :require_federal_tax_id => false)
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    advertiser = publisher.advertisers.build(:name => "New Seasons",
                                             :payment_type => 'ACH',
                                             :bank_routing_number => "123123123",
                                             :bank_account_number => "56565656",
                                             :merchant_id => "77777777777" )
    assert advertiser.valid?, "Should be valid, but had errors: " << advertiser.errors.full_messages.join(", ")
  end

  context "has_many :advertiser_owners" do
    setup do
      @advertiser = Factory(:advertiser)
    end

    should "not have any advertiser_owners" do
      assert_equal 0, @advertiser.advertiser_owners.size, "shouldn't have any"
    end

    should "have 2 advertiser_owners" do
      @advertiser.advertiser_owners << AdvertiserOwner.new
      @advertiser.advertiser_owners << AdvertiserOwner.new
      assert_equal 2, @advertiser.advertiser_owners.size, 'should have 2'
    end
  end

  context "Advertiser#description" do

    should "be required for advertisers whose publisher.enable_google_offers_feed? is true" do
      publisher = Factory :publisher, :label => "ocregister"
      advertiser = Factory.build(:advertiser, :description => "", :publisher_id => publisher.id)
      assert publisher.enable_google_offers_feed?
      assert advertiser.invalid?
    end

    should "NOT be required for advertisers whose publisher.enable_google_offers_feed? is false" do
      publisher = Factory :publisher, :label => "some-random-pub"
      advertiser = Factory.build(:advertiser, :description => "", :publisher_id => publisher.id)
      assert !publisher.enable_google_offers_feed?
      assert advertiser.valid?
    end

  end

  context "Advertiser#gross_annual_turnover" do
    setup do
      @advertiser = Factory.build(:advertiser)
    end

    should "exist" do
      assert @advertiser.respond_to? :gross_annual_turnover
    end

    should "accept only numbers" do
      @advertiser.gross_annual_turnover = "aaa"
      assert @advertiser.invalid?

      @advertiser.gross_annual_turnover = "1000.00"
      assert @advertiser.valid?
    end
  end

  context "Advertiser#registerd_with_companies_house" do
    setup do
      @advertiser = Factory.build(:advertiser)
    end

    should "exist" do
      assert @advertiser.respond_to? :registered_with_companies_house
    end

    should "be false by default" do
      assert_equal false, @advertiser.registered_with_companies_house
    end

    should "only accept true or false" do
      @advertiser.registered_with_companies_house = true
      assert @advertiser.valid?

      @advertiser.registered_with_companies_house = "foo"
      assert_equal false, @advertiser.invalid?
    end
  end

  context "Advertiser#business_trading_name" do
    setup do
      @advertiser = Factory.build(:advertiser)
    end

    should "exist" do
      assert @advertiser.respond_to?(:business_trading_name)
    end

  end

  context "Advertiser#registered_company_name" do
    setup do
      @advertiser = Factory.build(:advertiser)
    end

    should "exist" do
      assert @advertiser.respond_to?(:registered_company_name)
    end
  end

  context "Advertiser#company_registration_number" do
    setup do
      @advertiser = Factory.build(:advertiser)
    end

    should "exist" do
      assert @advertiser.respond_to?(:company_registration_number)
    end

    should "be alpha-numeric" do
      @advertiser.company_registration_number = "abc123"
      assert @advertiser.valid?

      @advertiser.company_registration_number = "abc$%#"
      assert @advertiser.invalid?
    end

    should "be 20 characters long" do
      @advertiser.company_registration_number = "a" * 21
      assert @advertiser.invalid?
    end
  end

  private

  def create_advertiser_with_offers(count)
    advertiser = publishers(:sdh_austin).advertisers.create!(:name => "New Advertiser")
    offers = []
    count.times do |i|
      offers << advertiser.offers.create!(:message => "Message #{i}", :txt_message => "TXT Message #{i}")
    end
    [advertiser, offers]
  end

  def create_txt(count, offer, time, status)
    count.times do
      lead = offer.leads.create!(:publisher => offer.publisher, :txt_me => true, :mobile_number => "858-555-1212")
      txt = Txt.find_by_source_type_and_source_id('Lead', lead.id)
      txt.update_attributes! :created_at => Time.zone.parse(time), :status => status
    end
  end
end
