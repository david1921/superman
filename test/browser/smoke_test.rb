require File.dirname(__FILE__) + "/browser_test"

require File.dirname(__FILE__) + "/resources/publisher"
require File.dirname(__FILE__) + "/resources/publishing_group"
require File.dirname(__FILE__) + "/resources/publisher_membership_code"
require File.dirname(__FILE__) + "/resources/publishing_groups/market"

require File.dirname(__FILE__) + "/smoke/deal_site/deal_site"

# Run like so:
#   ruby -Itest test/browser/smoke_test.rb
#   ruby -Itest test/browser/smoke_test.rb -- --help to get a list of options
#
class SmokeTest < BrowserTest
  include Smoke::Logger
  include Smoke::Capybara
  include Smoke::ResourceHost

  teardown :flunk_on_errors
  setup :setup_active_resource_host, :setup_messages

  def setup_driver
    setup_capybara(options)
  end

  def options
    @options ||= ::Smoke::SmokeOptions.new(ARGV)
  end

  def setup_messages
    @messages = ::Smoke::Messages.new(ENV["QUIET"].present?)
  end

  def log_configuration_info
    log "Rails environment is #{Rails.env}"
    log "Active resource house is #{AppConfig.active_resource_host} (--active_resource_host)"
    log "Capybara app_host is #{::Capybara.app_host} (--app_host)" if ::Capybara.app_host.present?
    log "Capybara driver is #{::Capybara.current_driver} (--driver)"
    log "More options with --help (ruby test/browser/smoke_test.rb -- --help)"
  end

  def messages
    @messages
  end

  test "visit root" do
    log "Visiting Root"
    visit "/"
    assert page.has_content?("Log in"), "Should have 'Log in'"
    assert page.has_content?("Unauthorized access"), "Should have 'Unauthorized access'"
  end

  test "visit all coupon pages" do
    log "Visiting All Coupon Pages"
    log_configuration_info
    create_countries
    create_publishing_groups
    create_publishers :coupons
    create_coupons
    create_markets
    page_validator = Smoke::PageValidator.new(messages)
    Publisher.all.each do |publisher|
      page_validator.validate_page(publisher.label, "/publishers/#{publisher.id}/offers")
    end
  end

  test "visit all deal sites" do
    log "Visiting Deal Sites"
    messages.banner do
      log_configuration_info
    end

    create_countries
    create_publishing_groups
    create_publishers :daily_deals
    create_publisher_membership_codes
    create_markets
    create_daily_deals
    create_national_daily_deals

    deal_site_checker = Smoke::DealSite::Checker.new(options, messages)
    complete = 0
    publishers = Publisher.all
    publishers.each do |publisher|
      messages.banner do
        log publisher.label
      end
      messages.indent do
        deal_site_checker.check_site(publisher.id, publisher.label)
        complete += 1
        log "#{complete}/#{publishers.size}"
      end
    end
  end

  test "consumer mailings" do
    log "Testing Consumer Mailings"
    create_countries
    create_publishing_groups
    create_publishers :daily_deals
    log "Creating consumers (one for each publisher)"
    fake_consumer_creator = Smoke::FakeConsumerCreator.new
    fake_consumer_creator.create_one_consumer_for_each_publisher(Publisher.all)
    consumer_email_generator = Smoke::DealSite::ConsumerEmails.new
    page_validator = Smoke::PageValidator.new(messages)

    consumers = Consumer.all
    total = consumers.size
    complete = 0
    consumers.each do |consumer|
      messages.banner do
        log consumer.publisher.label
        begin
          messages.indent do
            welcome_body = consumer_email_generator.welcome_body(consumer)
            page_validator.assert_no_errors(welcome_body, consumer.publisher.label, "consumer welcome email")
            reset_body = consumer_email_generator.password_reset_body(consumer)
            page_validator.assert_no_errors(reset_body, consumer.publisher.label, "consumer reset email")
            activation_body = consumer_email_generator.activation_body(consumer)
            page_validator.assert_no_errors(activation_body, consumer.publisher.label, "consumer activation email")
            log "success"
          end
        rescue => e
          error(consumer.publisher.label, "emails", e)
        ensure
          complete += 1
        end
        log "#{complete}/#{total}"
      end
    end
  end

  def create_countries
    country = Country.new(:name => "United States", :code => "US")
    country.id = 1
    country.save!
    
    country = Country.new(:name => "United Kingdom", :code => "UK")
    country.id = 2
    country.save!

    country = Country.new(:name => "Canada", :code => "CA")
    country.id = 3
    country.save!

    country = Country.new(:name => "Greece", :code => "GR")
    country.id = 88
    country.save!
  end
  
  def create_publishing_groups
    log "Getting publishing groups from #{AppConfig.active_resource_host}"
    Resources::PublishingGroup.find(:all).each do |attributes|
      log "  #{attributes.name} (#{attributes.label})"
      pub_group = PublishingGroup.new(
        :name => attributes.name, 
        :label => attributes.label,
        :parent_theme => attributes.parent_theme,
        :facebook_page_url => attributes.facebook_page_url,
        :facebook_app_id => attributes.facebook_app_id,
        :facebook_api_key => attributes.facebook_api_key,
        :google_analytics_account_ids => attributes.google_analytics_account_ids,
        :redirect_to_deal_of_the_day_on_market_lookup => attributes.redirect_to_deal_of_the_day_on_market_lookup
      )
      pub_group.id = attributes.id
      pub_group.save!
    end
  end
  
  def create_publishers(source)
    log "Creating publishers from #{source} on #{AppConfig.active_resource_host}"
    Resources::Publisher.get(source).each do |attributes|
      log "  #{attributes["name"]} (#{attributes["label"]})"
      publisher = Publisher.new(
        :address_line_1 => attributes["address_line_1"],
        :advertiser_has_listing => attributes["advertiser_has_listing"],
        :allow_gift_certificates => attributes["allow_gift_certificates"],
        :city => attributes["city"],
        :country_id => attributes["country_id"],
        :coupon_border_type => attributes["coupon_border_type"],
        :excluded_clipping_modes => attributes["excluded_clipping_modes"],
        :exclude_from_market_selection => attributes["exclude_from_market_selection"],
        :label => attributes["label"],
        :launched => attributes["launched"],
        :launched => true,
        :market_name => attributes["market_name"],
        :name => attributes["name"],
        :parent_theme => attributes["parent_theme"],
        :publishing_group_id => attributes["publishing_group_id"],
        :search_box => attributes["search_box"],
        :show_bottom_pagination => attributes["show_bottom_pagination"],
        :show_call_button => attributes["show_call_button"],
        :show_facebook_button => attributes["show_facebook_button"],
        :show_phone_number => attributes["show_phone_number"],
        :show_small_icons => attributes["show_small_icons"],
        :show_twitter_button => attributes["show_twitter_button"],
        :state => attributes["state"],
        :subcategories => attributes["subcategories"],
        :theme => attributes["theme"],
        :zip => attributes["zip"]
      )
      publisher.id = attributes["id"]
      publisher.save!
    end
  end
  
  def create_markets
    log "Getting markets from #{AppConfig.active_resource_host}"
    Resources::PublishingGroups::Market.find(:all).each do |attributes|
      if Publisher.exists?(attributes.publisher_id)
        log "  #{attributes.name}"
        Market.create!(:publisher_id => attributes.publisher_id, :name => attributes.name)
      end
    end
  end

  def create_publisher_membership_codes
    log "Getting publisher_membership_codes from #{AppConfig.active_resource_host}"
    Resources::PublisherMembershipCode.find(:all).each do |attributes|
      if Publisher.exists?(attributes.publisher_id)
        log "  #{attributes.code}"
        PublisherMembershipCode.create!(:publisher_id => attributes.publisher_id, :code => attributes.code)
      end
    end
  end
  
  def create_coupons
    Publisher.all.each do |publisher|
      publisher.
        advertisers.create!(:listing => publisher.advertiser_has_listing? ? "123" : nil, :description => publisher.enable_google_offers_feed? ? "Advertiser" : nil).
        offers.create!(:message => "buy now", :listing => publisher.offer_has_listing? ? "123" : nil)

      if publisher.allow_gift_certificates?
        publisher.advertisers.create!(:listing => publisher.advertiser_has_listing? ? "456" : nil, :description => publisher.enable_google_offers_feed? ? "Advertiser" : nil).
        gift_certificates.create!(
          :message => "message",
          :value => 40.00,
          :price => 19.99,
          :number_allocated => 10
        )
      end
    end    
  end
  
  def create_daily_deals
    Publisher.all.each do |publisher|
      publisher.
        advertisers.create!(:listing => publisher.advertiser_has_listing? ? "123" : nil, :description => publisher.enable_google_offers_feed? ? "Advertiser" : nil).
        daily_deals.create!(
          :value_proposition => "$81 value for $39", 
          :price => 39.00, 
          :value => 81.00, 
          :quantity => 100,
          :terms => "these are my terms", 
          :description => "this is my description",
          :start_at => 10.days.ago,
          :hide_at => Time.zone.now.tomorrow,
          :short_description => "A wonderful deal"
        )
    end
  end
  
  def create_national_daily_deals
    Market.all.each do |market|
      if market.name == "National"
        publisher = market.publisher
        publisher.advertisers.create!(:listing => publisher.advertiser_has_listing? ? "456" : nil, :description => publisher.enable_google_offers_feed? ? "Advertiser" : nil).
          daily_deals.create!(
            :value_proposition => "$81 value for $39", 
            :price => 39.00, 
            :value => 81.00, 
            :quantity => 100,
            :terms => "these are my terms", 
            :description => "this is my description",
            :start_at => 10.days.ago,
            :hide_at => Time.zone.now.tomorrow,
            :short_description => "National deal",
            :markets => [ market ]
          )
      end
    end
  end

  def flunk_on_errors
    if messages.errors_and_warnings.present?
      messages.banner do
        messages.errors_and_warnings.each do |error_or_warning|
          puts error_or_warning
        end
        flunk "There were #{messages.errors.size} errors and #{messages.warnings.size} warnings."
      end
    end
  end

  def say_if_verbose(text)
    log(text)
  end

end
