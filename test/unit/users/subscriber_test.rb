require File.dirname(__FILE__) + "/../../test_helper"

class SubscriberTest < ActiveSupport::TestCase

  def test_create
    publishers(:my_space).subscribers.create! :email => "mr_t@example.com"
    publishers(:my_space).subscribers.create! :mobile_number => "4119115555"
    publishers(:my_space).subscribers.create! :mobile_number => "1 (411) 911-5555" 
    publishers(:my_space).subscribers.create! :must_accept_terms => true, :email => "mr_t@example.com", :terms => "1"
    publishers(:my_space).subscribers.create! :email => "for_affiliate@example.com", :subscriber_referrer_code_id => SubscriberReferrerCode.create!.id
  end
  
  def test_create_for_publishing_group
    publishing_group = Factory(:publishing_group)
    publishing_group.subscribers_with_no_market.create! :email => "mr_t@example.com"
    publishing_group.subscribers_with_no_market.create! :mobile_number => "4119115555"
    publishing_group.subscribers_with_no_market.create! :mobile_number => "1 (411) 911-5555" 
    publishing_group.subscribers_with_no_market.create! :must_accept_terms => true, :email => "mr_t@example.com", :terms => "1"
    publishing_group.subscribers_with_no_market.create! :email => "for_affiliate@example.com", :subscriber_referrer_code_id => SubscriberReferrerCode.create!.id
  end
  
  def test_create_with_subscriber_referrer_code_id
    subscriber_referrer_code = SubscriberReferrerCode.create!
    subscriber    = publishers(:my_space).subscribers.create! :email => "for_affiliate@example.com", :subscriber_referrer_code_id => subscriber_referrer_code.id
    assert        subscriber.valid?
    assert_equal  subscriber_referrer_code, Subscriber.find(subscriber.id).subscriber_referrer_code
  end 
  
  def test_create_with_first_and_last_name
    subscriber    = publishers(:my_space).subscribers.create!( :email => "myemail@somesite.com", :first_name => "John", :last_name => "Smith" )
    assert        subscriber.valid?
    assert_equal  "John Smith", subscriber.name    
  end
  
  def test_create_with_first_name_and_missing_last_name
    subscriber    = publishers(:my_space).subscribers.create!( :email => "myemail@somesite.com", :first_name => "John", :last_name => nil )
    assert        subscriber.valid?
    assert_equal  "John ", subscriber.name
  end
  
  def test_create_with_last_name_and_missing_first_name
    subscriber    = publishers(:my_space).subscribers.create!( :email => "myemail@somesite.com", :first_name => nil, :last_name => "Smith" )
    assert        subscriber.valid?
    assert_equal  " Smith", subscriber.name    
  end
  
  def test_create_with_first_name_with_extra_spacing_and_last_name
    subscriber    = publishers(:my_space).subscribers.create!( :email => "myemail@somesite.com", :first_name => " John  ", :last_name => "Smith" )
    assert        subscriber.valid?
    assert_equal  "John Smith", subscriber.name    
  end
  
  def test_create_with_zip_code_missing_and_zip_code_required_is_set_to_true
    subscriber    = publishers(:my_space).subscribers.create( :email => "myemail@somesite.com", :first_name => " John  ", :last_name => "Smith", :zip_code_required => true )    
    assert        !subscriber.valid?
  end
  
  def test_create_with_zip_code_present_and_zip_code_required_is_set_to_true
    subscriber    = publishers(:my_space).subscribers.create( :email => "myemail@somesite.com", :first_name => " John  ", :last_name => "Smith", :zip_code => "97206", :zip_code_required => true )    
    assert        subscriber.valid?
  end

  def test_create_with_device_and_user_agent
    subscriber = publishers(:my_space).subscribers.create! :email => "mr_t@example.com", :device => 'tablet', :user_agent => "Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)"    
    assert subscriber.valid?
    assert_equal "tablet", subscriber.device
    assert_equal "Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)", subscriber.user_agent
  end
  
  def test_validation
    assert !publishers(:my_space).subscribers.build.valid?, "No email, nor mobile_number"
    assert !publishers(:my_space).subscribers.build(:email => "@example.com").valid?, "bad email"
    assert !publishers(:my_space).subscribers.build(:mobile_number => "315 555 121").valid?, "bad mobile_number"                          
    assert !publishers(:my_space).subscribers.build(:must_accept_terms => true, :email => "someone@example.com").valid?, "must accept terms"
  end 
      
  def test_deliver_latest_with_one_basic_publisher
    ActionMailer::Base.deliveries.clear
    
    publisher_name    = "San Diego Weekly Reader"
    subscriber_recipients = "admin@sdreader.com, jill@sdreader"
    publisher         = publishers(:sdreader)
   
    publisher.update_attributes( :name => publisher_name, :subscriber_recipients => subscriber_recipients )

    
    subscriber_emails = ["test@example.com", "hello@somewhere.com"]
    subscriber_emails.each do |email|
      publisher.subscribers.create!( :email => email )
    end
    
    assert_equal ActionMailer::Base.deliveries, [], "there should be 0 emails to start with"
    result = Subscriber.deliver_latest    
    assert_equal ActionMailer::Base.deliveries.size, 1, "there should be only one new email"
    
    assert_equal  "[SUBSCRIBERS][#{publisher_name}] found #{subscriber_emails.size} subscriber(s) and delivered to: #{subscriber_recipients}", result.first
    email         = ActionMailer::Base.deliveries.first
    
    assert_equal "#{publisher_name} Coupon Subscribers", email.subject 

    to_addresses  = email.to_addrs.collect(&:address)    
    to_addresses.each do |email_address|
      assert subscriber_recipients.include?(email_address), "Recipients should be included in subscriber recipients"
    end
 
    attachment = email.parts.last.body
    subscriber_emails.each do |email_address|
      assert attachment[email_address], "Attachment should contain '#{email_address}' in #{attachment}"
    end
  end
  
  def test_deliver_latest_with_vcreporter_publisher
    ActionMailer::Base.deliveries.clear
    
    publishers(:vcreporter).destroy
    
    publisher_name        = "Ventura County Reporter"
    subscriber_recipients = "jill@vcreporter.com, cal@vcreporter.com" 
    publisher = Factory(:publisher,  :name => publisher_name, :label => 'vcreporter', :theme => 'standard', :subscriber_recipients => subscriber_recipients )

    subscriber_emails = ["test@example.com", "hello@somewhere.com"]
    subscriber_emails.each do |email|
      publisher.subscribers.create!( :email => email )
    end
    
    # where date is not on a friday
    date = Date.new(2008, 10, 1)
    date.stubs( :wday ).returns( 3 )
    ActiveSupport::TimeWithZone.any_instance.stubs(:to_date).returns( date )

    Subscriber.deliver_latest
    assert_equal ActionMailer::Base.deliveries, [], "there should be 0 emails since we only send out on friday for VC Reporter"    
    
    # where date is on a friday
    date.stubs( :wday ).returns( 5 )
    
    Subscriber.deliver_latest
    assert_equal ActionMailer::Base.deliveries.size, 1, "there should be only one new email"
    
    email         = ActionMailer::Base.deliveries.first
    
    assert_equal "#{publisher_name} Coupon Subscribers", email.subject 

    to_addresses  = email.to_addrs.collect(&:address)    
    to_addresses.each do |email_address|
      assert subscriber_recipients.include?(email_address), "Recipients should be included in subscriber recipients"
    end
 
    attachment = email.parts.last.body
    subscriber_emails.each do |email_address|
      assert attachment[email_address], "Attachment should contain '#{email_address}' in #{attachment}"
    end    
  end
  
  def test_deliver_latest_with_one_basic_publisher_and_vcreporter_publisher
    ActionMailer::Base.deliveries.clear
    
    sdreader_publisher_name    = "San Diego Weekly Reader"
    sdreader_subscriber_recipients = "admin@sdreader.com, jill@sdreader"
    sdreader_publisher         = publishers(:sdreader)
    sdreader_publisher.update_attributes( :name => sdreader_publisher_name, :subscriber_recipients => sdreader_subscriber_recipients )    
    
    sdreader_subscriber_emails = ["test@example.com", "hello@somewhere.com"]
    sdreader_subscriber_emails.each do |email|
      sdreader_publisher.subscribers.create!( :email => email )
    end
    
    publishers(:vcreporter).destroy

    vcreporter_publisher_name        = "Ventura County Reporter"
    vcreporter_subscriber_recipients = "jill@vcreporter.com, cal@vcreporter.com" 
    vcreporter_publisher = Factory(:publisher,  :name => vcreporter_publisher_name, :label => 'vcreporter', :theme => 'standard', :subscriber_recipients => vcreporter_subscriber_recipients )    

    vcreporter_subscriber_emails = ["abc@example.com", "what@somewhere.com"]
    vcreporter_subscriber_emails.each do |email|
      vcreporter_publisher.subscribers.create!( :email => email )
    end

    # with day of week not being friday    
    date = Date.new(2008, 10, 1)
    date.stubs( :wday ).returns( 3 )
    ActiveSupport::TimeWithZone.any_instance.stubs(:to_date).returns( date )
    
    Subscriber.deliver_latest
    assert_equal ActionMailer::Base.deliveries.size, 1, "we should only have one email for SD Reader"    

    email         = ActionMailer::Base.deliveries.first
    
    assert_equal "#{sdreader_publisher_name} Coupon Subscribers", email.subject 

    to_addresses  = email.to_addrs.collect(&:address)    
    to_addresses.each do |email_address|
      assert sdreader_subscriber_recipients.include?(email_address), "Recipients should be included in subscriber recipients"
    end
 
    attachment = email.parts.last.body
    sdreader_subscriber_emails.each do |email_address|
      assert attachment[email_address], "Attachment should contain '#{email_address}' in #{attachment}"
    end    
    
    # with day of the week being friday
    ActionMailer::Base.deliveries.clear
    date.stubs( :wday ).returns( 5 )    

    Subscriber.deliver_latest
    assert_equal ActionMailer::Base.deliveries.size, 2, "we should only have two emails"
    
    first_email   = ActionMailer::Base.deliveries.first
    second_email  = ActionMailer::Base.deliveries.last
    
    assert_equal "#{sdreader_publisher_name} Coupon Subscribers", first_email.subject 

    to_addresses  = first_email.to_addrs.collect(&:address)    
    to_addresses.each do |email_address|
      assert sdreader_subscriber_recipients.include?(email_address), "Recipients should be included in subscriber recipients"
    end
 
    attachment = first_email.parts.last.body 
    sdreader_subscriber_emails.each do |email_address|
      assert attachment[email_address], "Attachment should contain '#{email_address}' in #{attachment}"
    end    
    
    assert_equal "#{vcreporter_publisher_name} Coupon Subscribers", second_email.subject 

    to_addresses  = second_email.to_addrs.collect(&:address)    
    to_addresses.each do |email_address|
      assert vcreporter_subscriber_recipients.include?(email_address), "Recipients should be included in subscriber recipients"
    end
 
    attachment = second_email.parts.last.body
    vcreporter_subscriber_emails.each do |email_address|
      assert attachment[email_address], "Attachment should contain '#{email_address}' in #{attachment}"
    end
  end

  def test_deliver_latest_with_override
    Timecop.freeze do
      ActionMailer::Base.deliveries.clear
      
      publisher_name    = "San Diego Weekly Reader"
      subscriber_recipients = "admin@sdreader.com, jill@sdreader"
      publisher         = publishers(:sdreader)
     
      publisher.update_attributes( :name => publisher_name, :subscriber_recipients => subscriber_recipients )

      
      subscriber_emails = ["test@example.com", "hello@somewhere.com"]
      subscriber_emails.each do |email|
        publisher.subscribers.create!( :email => email, :created_at => 3.weeks.ago )
      end
      
      assert_equal ActionMailer::Base.deliveries, [], "there should be 0 emails to start with"
      Subscriber.deliver_latest({:custom_interval => 30})
      assert_equal ActionMailer::Base.deliveries.size, 1, "there should be only one new email"
      
      email         = ActionMailer::Base.deliveries.first
      
      assert_equal "#{publisher_name} Coupon Subscribers", email.subject 

      to_addresses  = email.to_addrs.collect(&:address)    
      to_addresses.each do |email_address|
        assert subscriber_recipients.include?(email_address), "Recipients should be included in subscriber recipients"
      end
   
      attachment = email.parts.last.body 
      lines      = attachment.lines.collect(&:to_s)
      assert_equal "Email,Mobile Number,Created At,Categories,Other Options\n", lines[0]
      lines.sort!
      assert_equal "hello@somewhere.com,\"\",#{publisher.subscribers[1].created_at.to_s(:db)},\"\",\"\"\n", lines[1]
      assert_equal "test@example.com,\"\",#{publisher.subscribers[0].created_at.to_s(:db)},\"\",\"\"\n", lines[2]
    end
  end
  
  def test_last_24_hours_scope_with_a_new_subscription_over_one_day
    Timecop.freeze Time.utc(2011, 3, 9, 10, 30) do
      publisher = publishers(:sdreader)
      publisher.subscribers.create!( :email => 'tester@somewhere.com', :created_at => 2.days.ago )
      publisher.reload
      assert_equal 0, publisher.subscribers.created_within(1.day).size, "there should be no subscribers in the past 24 hours"
    end
  end
  
  def test_last_24_hours_scope_with_a_new_subscription_from_today
    publisher = publishers(:sdreader)
    publisher.subscribers.create!( :email => 'tester@somewhere.com', :created_at => Time.zone.now )
    publisher.reload
    assert_equal publisher.subscribers.created_within(1.day).size, 1, "there should be one subscribers in the past 24 hours"
  end
  
  def test_last_week_scope_with_a_new_subscription_over_one_week
    publisher = publishers(:sdreader)
    subscriber = publisher.subscribers.create!( :email => 'tester@somewhere.com', :created_at => (Time.zone.now.to_date - 8) )
    publisher.reload
    assert_equal 0, publisher.subscribers.created_within(7.day).size, "there should be no subscribers in the past week"
  end
  
  def test_last_week_scope_with_a_new_subscription_from_one_week_ago
    # DST
    Timecop.freeze Time.zone.local(2010, 10, 8) do
      publisher = publishers(:sdreader)
      publisher.subscribers.create!( :email => 'tester@somewhere.com', :created_at => 1.week.ago )
      publisher.reload
      assert_equal 1, publisher.subscribers.created_within(7.day).size, "there should be one subscriber in the past week"
    end

    # Not DST. Test fails if it straddles DST boundary.
    Timecop.freeze Time.zone.local(2010, 11, 18) do
      publisher = publishers(:sdreader)
      publisher.subscribers.create!( :email => 'tester@somewhere.com', :created_at => 1.week.ago )
      publisher.reload
      assert_equal 1, publisher.subscribers.created_within(7.day).size, "there should be one subscriber in the past week"
    end
  end
  
  def test_last_week_scope_with_a_new_subscription_from_today
    publisher = publishers(:sdreader)
    publisher.subscribers.create!( :email => 'tester@somewhere.com' )
    publisher.reload
    assert_equal 1, publisher.subscribers.created_within(7.day).size, "there should be one subscriber in the past week"    
  end
  
  def test_require_other_options_methods
    subscriber = Factory(:publisher).subscribers.build(:require_other_options_foo => "true")
    assert  subscriber.require_other_options_foo
    assert !subscriber.require_other_options_bar

    subscriber.require_other_options_foo = "0"
    assert !subscriber.require_other_options_foo
    assert !subscriber.require_other_options_bar
    
    subscriber.require_other_options_bar = true
    assert !subscriber.require_other_options_foo
    assert  subscriber.require_other_options_bar
  end
  
  def test_validate_other_options_with_require_other_options_set
    subscriber = Factory(:publisher).subscribers.build(:email => "x@y.com", :require_other_options_foo => "true", :other_options => { "foo" => "red" })
    assert subscriber.valid?, "Should be valid with required other_options key present and value present"

    subscriber.other_options["foo"] = nil
    assert subscriber.invalid?, "Should not be valid with required other_options key present and value blank"
    assert_match /select or enter a foo/i, subscriber.errors.on(:base)

    subscriber.other_options = { "bar" => "red"}
    assert subscriber.invalid?, "Should not be valid with required other_options key not present"
    assert_match /select or enter a foo/i, subscriber.errors.on(:base)
    
    subscriber.require_other_options_foo = false
    assert subscriber.valid?, "Should be valid with no other_options required"
  end
  
  def test_city
    mr_t = publishers(:my_space).subscribers.create! :email => "mr_t@example.com"
    assert_nil mr_t.city
    mr_t.other_options = {}
    assert_nil mr_t.city
    mr_t.other_options[:city] = 'Los Angeles You Fool'
    assert_equal "Los Angeles You Fool", mr_t.city
    mr_t.save!
    mr_t_from_db = Subscriber.find(mr_t.id)
    mr_t_from_db.city = "Los Angeles You Fool"    
  end

  def test_city_assignment
    mr_t = publishers(:my_space).subscribers.create! :email => "mr_t@example.com"
    assert_nil mr_t.city
    mr_t.city = "Los Angeles You Fool"
    assert_equal "Los Angeles You Fool", mr_t.city
    mr_t.save!
    mr_t_from_db = Subscriber.find(mr_t.id)
    mr_t_from_db.city = "Los Angeles You Fool"
  end

  def test_referral_code
    mr_t = publishers(:my_space).subscribers.create! :email => "mr_t@example.com"
    assert_nil mr_t.referral_code
    mr_t.other_options = {}
    assert_nil mr_t.referral_code
    mr_t.other_options[:referral_code] = "Fool, I don't need no code"
    assert_equal "Fool, I don't need no code", mr_t.referral_code
  end  
  
  def test_referral_code_assignment    
    mr_t = publishers(:my_space).subscribers.create! :email => "mr_t@example.com"
    assert_nil mr_t.referral_code
    mr_t.referral_code = "abc123"
    assert_equal "abc123", mr_t.referral_code
    mr_t.save!
    mr_t_from_db = Subscriber.find(mr_t.id)
    assert_equal "abc123", mr_t_from_db.referral_code    
  end
  
  def test_can_assign_both_city_and_referral_code
    mr_t = publishers(:my_space).subscribers.create! :email => "mr_t@example.com"
    mr_t.city = "Los Angeles You Fool"
    mr_t.referral_code = "abc123"
    mr_t.save!
    mr_t_from_db = Subscriber.find(mr_t.id)
    assert_equal "abc123", mr_t_from_db.referral_code    
    assert_equal "Los Angeles You Fool", mr_t_from_db.city    
  end

  def test_subscribers_are_valid_with_zip_plus4
    country = Country.find_or_create_by_code('US')
    publisher = Factory(:publisher, :countries => [country])
    mr_t = publisher.subscribers.create! :email => "mr_t@example.com"
    mr_t.zip_code = "97214-5752"
    assert mr_t.valid?, "zip plus 4 should be valid zip_code"
  end
  
  def test_subscribers_are_valid_with_regular_zips
    country = Country.find_or_create_by_code('US')
    publisher = Factory(:publisher, :countries => [country])
    mr_t = publisher.subscribers.create! :email => "mr_t@example.com"
    mr_t.zip_code = "97214"
    assert mr_t.valid?, "regular zip should be a valid zip_code"
  end

  def test_canadian_zips
    country = Country.find_or_create_by_code('CA')
    publisher = Factory(:publisher, :countries => [country])
    mr_t = publisher.subscribers.create! :email => "mr_t@example.com"
    mr_t.zip_code = "V5R2V9"
    assert mr_t.valid?, "regular zip should be a valid zip_code"
    mr_t.zip_code = "V5R-2V9"
    assert mr_t.valid?, "regular zip should be a valid zip_code"
    mr_t.zip_code = "V5R 2V9"
    assert mr_t.valid?, "regular zip should be a valid zip_code"
  end

  def test_uk_zips
    country = Country.find_or_create_by_code('UK')
    publisher = Factory(:publisher, :countries => [country])
    subscriber = publisher.subscribers.new(:zip_code_required => true)
    assert_good_value(subscriber, :zip_code, "EC1A 1BB")
    assert_good_value(subscriber, :zip_code, "M1 1AA")
    assert_good_value(subscriber, :zip_code, "M60 1NW")
    assert_good_value(subscriber, :zip_code, "CR2 6XH")
    assert_good_value(subscriber, :zip_code, "DN55 1PT")
    assert_good_value(subscriber, :zip_code, "W1A 1HQ")
  end 
  
  def test_only_publisher_countries_zips_allowed
    country = Country.find_or_create_by_code('UK')
    publisher = Factory(:publisher, :countries => [country])
    subscriber = publisher.subscribers.new(:zip_code_required => true)
    assert_good_value(subscriber, :zip_code, "EC1A 1BB")
    assert_bad_value(subscriber, :zip_code, "98683")
    assert_bad_value(subscriber, :zip_code, "V5R2V9")
  end

  def test_default_to_us_zips_when_publisher_country_codes_empty
    publisher = Factory(:publisher, :countries => [])
    subscriber = publisher.subscribers.new(:zip_code_required => true)
    assert_good_value(subscriber, :zip_code, "98683")
    assert_bad_value(subscriber, :zip_code, "EC1A 1BB")
    assert_bad_value(subscriber, :zip_code, "V5R2V9")
  end

  def test_hashed_id
    subscriber = Factory(:subscriber)
    verifier = ActiveSupport::MessageVerifier.new(AppConfig.message_verifier_secret)

    assert_equal subscriber.id, verifier.verify(subscriber.hashed_id)
  end

  def test_find_by_hashed_id
    subscriber = Factory(:subscriber)

    assert_equal subscriber.id, Subscriber.find_by_hashed_id(subscriber.hashed_id).id
  end

  test "new subscribers should save the current locale" do
    I18n.locale = :es
    subscriber = Factory(:subscriber)
    assert_equal "es", subscriber.preferred_locale

    I18n.locale = :en
    subscriber = Factory(:subscriber)
    assert_equal "en", subscriber.preferred_locale
  end
end
