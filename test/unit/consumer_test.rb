require File.dirname(__FILE__) + "/../test_helper"

class ConsumerTest < ActiveSupport::TestCase    
  def setup
    @valid_attributes = {
      :email => "joe@blow.com",
      :name => "Joe Blow",
      :password => "secret",
      :password_confirmation => "secret",
      :agree_to_terms => "1"
    }

    Country.find_or_create_by_code('US')
  end
  
  test "cannot create administrator" do
    publisher = publishers(:sdh_austin)
    consumer = publisher.consumers.create!(@valid_attributes)
    assert !consumer.administrator?, "Consumer should not be an administrator"
    
    consumer.attributes = { :company => publisher, :admin_privilege => User::FULL_ADMIN }
    assert_nil consumer.company, "Should not be able to set company via mass assignment"
    assert !consumer.has_admin_privilege?, "Should not be able to set admin privilege via mass assignment"
    assert !consumer.administrator?, "Consumer should not be an administrator"
    
    consumer.company = publisher
    consumer.admin_privilege = User::FULL_ADMIN
    assert_nil consumer.company, "Should not be able to set company via assignment"
    assert !consumer.has_admin_privilege?, "Should not be able to set admin privilege via assignment"
    assert !consumer.administrator?, "Consumer should not be an administrator"
  end
  
  test "activation" do
    publisher = publishers(:sdh_austin)
    consumer = publisher.consumers.create!(@valid_attributes)
    
    assert_equal @valid_attributes[:name], consumer.name
    assert_equal @valid_attributes[:email], consumer.email
    assert consumer.agree_to_terms, "Should have agreed to terms"
    assert !consumer.active?, "Should not be active immediately after create"
    assert_not_nil consumer.activation_code, "Should have an activation code before activation"
    assert !Consumer.authenticate(publisher, @valid_attributes[:email], @valid_attributes[:password]), "Should not authenticate before activation"
    
    consumer.activate!
    assert consumer.active?, "Should be active after activation"
    assert_not_nil consumer.activation_code, "Should still have an activation code after activation"
    assert Consumer.authenticate(publisher, @valid_attributes[:email], @valid_attributes[:password]), "Should authenticate after activation"
  end
  
  test "billing_address_present?" do
    consumer = Factory(:consumer)
    assert !consumer.billing_address_present?
    billing_address_consumer = Factory(:billing_address_consumer)
    assert billing_address_consumer.billing_address_present?

    billing_address_consumer_no_address_line_1 = Factory(:billing_address_consumer, :address_line_1 => nil)
    assert !billing_address_consumer_no_address_line_1.billing_address_present?, "Should detect missing address_line_1"
    billing_address_consumer_no_address_line_2 = Factory(:billing_address_consumer, :address_line_2 => nil)
    assert billing_address_consumer_no_address_line_2.billing_address_present?, "Should allow missing address_line_2"
    billing_address_consumer_no_city = Factory(:billing_address_consumer, :billing_city => nil)
    assert !billing_address_consumer_no_city.billing_address_present?, "Should detect missing city"
    billing_address_consumer_no_zip = Factory(:billing_address_consumer, :zip_code => nil)
    assert !billing_address_consumer_no_zip.billing_address_present?, "Should detect missing zip code"
  end

  test "update_billing_address" do 
    consumer = Factory(:consumer)
    assert !consumer.billing_address_present?
    billing_address = { 
      :address_line_1 => 'somewhere', 
      :address_line_2 => 'special',  
      :billing_city => 'brooklyn', 
      :state => 'NY', 
      :country_code => "US", 
      :zip_code => '11215' 
    }
    consumer.update_billing_address(billing_address)
    consumer.reload
    assert consumer.billing_address_present?
    assert_equal consumer.address_line_1, billing_address[:address_line_1]
    assert_equal consumer.address_line_2, billing_address[:address_line_2]
    assert_equal consumer.billing_city, billing_address[:billing_city]
    assert_equal consumer.state, billing_address[:state]
    assert_equal consumer.country_code, billing_address[:country_code]
    assert_equal consumer.zip_code, billing_address[:zip_code]

    partial_billing_address = { 
      :address_line_1 => 'somewhere else', 
      :address_line_2 => nil,  
      :state => 'CA'
    }
    consumer.update_billing_address(partial_billing_address)
    consumer.reload
    assert consumer.billing_address_present?
    assert_equal consumer.address_line_1, partial_billing_address[:address_line_1]
    assert_equal consumer.address_line_2, partial_billing_address[:address_line_2]
    assert_equal consumer.billing_city, billing_address[:billing_city]
    assert_equal consumer.state, partial_billing_address[:state]
    assert_equal consumer.country_code, billing_address[:country_code]
    assert_equal consumer.zip_code, billing_address[:zip_code]
  end

  test "activation should raise error when consumer does not have billing address but publisher requires one" do
    publisher = Factory(:publisher, 
                          :name => "Foo",
                          :label => "foo",
                          :theme => "enhanced",
                          :production_subdomain => "sb1",
                          :launched => true,
                          :payment_method  => "credit",
                          :require_billing_address => false)               
    consumer = publisher.consumers.create!(@valid_attributes)
    publisher.require_billing_address = true
    publisher.save!
    publisher.reload
    consumer.reload
    assert ! consumer.active?, "New consumer should not be active"
    assert !consumer.billing_address_present?
    
    assert_equal @valid_attributes[:name], consumer.name
    assert_equal @valid_attributes[:email], consumer.email
    assert consumer.agree_to_terms, "Should have agreed to terms"
    assert !consumer.active?, "Should not be active immediately after create"
    assert_not_nil consumer.activation_code, "Should have an activation code before activation"
    assert !Consumer.authenticate(publisher, @valid_attributes[:email], @valid_attributes[:password]), "Should not authenticate before activation"

    assert !consumer.valid?, "Consumer should not have a billing address"
    assert !consumer.errors.empty?

    assert_raise( ActiveRecord::RecordInvalid) {  ! consumer.activate!  }
  end

  test "consumer activated after purchase" do
    daily_deal = Factory(:daily_deal)
    publisher = daily_deal.publisher
    consumer = publisher.consumers.create!(@valid_attributes)
    assert !consumer.active?, "Consumer should not be active before purchcase"
    
    daily_deal_purchase = Factory.build(:authorized_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer)
    consumer.daily_deal_purchase_executed! daily_deal_purchase

    assert consumer.active?, "Consumer should be active after purchcase"
  end
  
  test "build unactivated" do
    daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
    publisher = daily_deal.publisher
    discount = Factory(:discount, :code => "SIGNUP_CREDIT", :publisher => publisher)

    consumer = Consumer.build_unactivated(publisher, :email => "chih.chow@example.com")
    consumer.save!
    
    assert_equal "chih.chow@example.com", consumer.email, "Should set email"
    assert_nil consumer.activated_at, "Should not be activated"
    assert_not_nil consumer.signup_discount , "Should have signup_discount "
    assert_not_nil consumer.crypted_password, "Should have no password"
  end
  
  test "validation of discount code" do
    discount = Factory(:discount)
    publisher = discount.publisher
    
    consumer = Factory.build(:consumer, :publisher => publisher, :discount_code => "NOSUCH")
    assert consumer.invalid?, "Should not be valid with bad discount code"
    assert_match /NOSUCH is not valid/i, consumer.errors.on(:discount_code)
  end

  test "assignment of signup discount from valid code" do
    discount = Factory(:discount)
    publisher = discount.publisher
    publisher.stubs(:show_special_deal?).returns(true)
    
    consumer = Factory(:consumer, :publisher => publisher, :discount_code => discount.code)
    consumer.save!
    assert_equal discount, consumer.signup_discount
  end

  test "assignment of signup discount if publisher has special deal" do
    publisher = Factory(:publisher)
    Factory(:discount, :publisher => publisher, :code => "SIGNUP_CREDIT", :amount => 10.00)
    publisher.stubs(:show_special_deal?).returns(true)
    
    consumer = Factory.build(:consumer, :publisher => publisher)
    consumer.save!
    assert_not_nil(signup_discount = consumer.signup_discount, "Consumer should have discount")
    assert_equal 10.00, signup_discount.amount
  end

  test "no assignment of signup discount if publisher does not have special deal" do
    publisher = Factory(:publisher)
    Factory(:discount, :publisher => publisher, :code => "SIGNUP_CREDIT", :amount => 10.00)
    publisher.stubs(:show_special_deal?).returns(false)
    
    consumer = Factory.build(:consumer, :publisher => publisher)
    consumer.save!
    assert_nil consumer.signup_discount, "Consumer should have no discount"
  end
  
  test "signup discount is not usable after first use" do
    daily_deal = Factory(:daily_deal)
    publisher = daily_deal.publisher
    discount = Factory(:discount, :publisher => publisher)
    
    consumer = Factory(:consumer, :publisher => publisher, :discount_code => discount.code)
    assert_equal discount, consumer.signup_discount_if_usable
    
    daily_deal_purchase = Factory.build(:authorized_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer)
    daily_deal_purchase.discount = discount
    daily_deal_purchase.save!
    daily_deal_purchase.authorized_purchase_factory_after_create

    assert_equal discount, consumer.signup_discount
    assert_equal discount.code, consumer.signup_discount_code
    assert_nil consumer.signup_discount_if_usable, "Signup discount should not be usable if already used"
  end
  
  test "create with first_name and last_name instead of name" do
    publisher = publishers(:sdh_austin)    
    consumer = publisher.consumers.create!(@valid_attributes.except(:name).merge(:first_name => "Jon", :last_name => "Smith") )    
    assert consumer.valid?
    assert_equal "Jon Smith", consumer.name    
  end
  
  test "create with billing address" do
    publisher = publishers(:sdh_austin) 
    publisher.update_attributes! :require_billing_address => true
    @valid_attributes.merge!(
      :address_line_1 => 'Somewhere special',
      :address_line_2 => 'Where there are milkshakes',
      :billing_city => 'Brooklyn',
      :state => 'NY',
      :zip_code => '11215',
      :country_code => 'US'
    )
    consumer = publisher.consumers.create!(@valid_attributes)
    assert consumer.valid?
  end

  test "create with device and user agent" do
    publisher = publishers(:sdh_austin)    
    consumer = publisher.consumers.create!(@valid_attributes.merge(:device => "tablet", :user_agent => "Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)") )        
    assert consumer.valid?    
    assert_equal "tablet", consumer.device
    assert_equal "Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)", consumer.user_agent
  end
  
  test "consumer should respond to first last name" do
    %w{ first_name last_name }.each do |attr|
      assert_respond_to Consumer.new, "#{attr}_required?"
    end
  end
  
  fast_context "facebook consumer" do
    setup do
      publishing_group = Factory(:publishing_group_with_theme)
      @publisher = Factory(:publisher, :publishing_group => publishing_group ) 
      @consumer =  Factory(:facebook_consumer, :publisher => @publisher)  
    end
    
    subject { @consumer }
        
    %w( token first_name last_name facebook_id first_name last_name timezone ).each do |att|
      allow_mass_assignment_of(att)
    end
    
    should "respond to facebook auth instance methods" do
       %w( graph post oauth_facebook_client post_purchase_to_fb_wall facebook_user?).each do |instance_method|
         assert_respond_to Consumer.new, instance_method
       end
    end
    
    should "respond to find_or_create_by_fb" do
      assert_respond_to Consumer, :find_or_create_by_fb
    end
   
    should "have the FacebookAuth module included in the parent class" do
      assert @consumer.class.include?(FacebookAuth)
    end
    
    should "be an instance of OAuth2::AccessToken" do
      assert_instance_of OAuth2::AccessToken, @consumer.oauth_facebook_client
    end
    
    should "have the same access token as the oauth_facebook_client" do
      assert_same @consumer.token, @consumer.oauth_facebook_client.send(:token)
    end
    
    should "rescue from OAuth2::ErrorWithResponse when trying get an invalid graph connection" do
      assert_nothing_thrown { @consumer.stubs(:graph).returns({}) }
    end
    
    should "be able to post a message to a consumer's wall" do
      assert_nothing_thrown { @consumer.stubs(:post).returns('success') }
    end
    
    should "find an existing non-consumer and merge the facebook attributes" do
      publisher = publishers(:sdh_austin)
      consumer = publisher.consumers.create!(@valid_attributes)
      access_token = OpenStruct.new(:token => "33333")
    
      fb = { :facebook_id => 10, :email => consumer.email }
            
      assert_no_difference "Consumer.count" do  
        Consumer.find_or_create_by_fb(fb, access_token, consumer.publisher)
      end      
    end
  end
  
  test "credit_available defaults to zero" do
    assert_equal 0.00, Consumer.new.credit_available
  end
  
  test "mass assignment of credit_available has no effect" do
    assert_equal 0.00, Consumer.new(:credit_available => 10.00).credit_available
  end

  test "assignment to credit_available raises an exception" do
    assert_raise RuntimeError do
      Consumer.new.credit_available = 10.00
    end
  end
  
  test "adding a credit increments credit_available" do
    consumer = Factory(:consumer)
    assert_difference 'consumer.credit_available', 10.00 do
      consumer.credits.build(:amount => 10.00)
    end
  end

  test "removing a credit decrements credit_available" do
    consumer = Factory(:consumer)
    credit = consumer.credits.build(:amount => 10.00)
    assert_difference 'consumer.credit_available', -10.00 do
      consumer.credits.delete credit
    end
  end
  
  test "adding an invalid credit raises an exception" do
    assert_raise ActiveRecord::RecordInvalid do
      Factory(:consumer).credits.build(:amount => "xx.xx")
    end
  end

  test "reset credit available" do
    publisher = Factory(:publisher)
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    consumer = Factory(:consumer, :publisher => publisher)
    Factory(:daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer, :credit_used => 7, :payment_status => 'captured', :daily_deal_payment => Factory(:daily_deal_payment))
    Factory(:daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer, :credit_used => 2)
    Factory(:credit, :consumer => consumer)

    Timecop.freeze(Time.zone.now) do
      consumer.reset_credit_available

      assert_equal consumer.credit_available_reset_at, Time.zone.now
    end

    assert_equal 3, consumer.credit_available

    assert_equal 10, consumer.credits.sum(:amount)
    assert_equal 7, consumer.daily_deal_purchases.captured(nil).sum(:credit_used)
  end

  test "reset credit available to zero if the calculation is negative" do
    publisher = Factory(:publisher)
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    consumer = Factory(:consumer, :publisher => publisher)
    Factory(:daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer, :credit_used => 15, :payment_status => 'captured', :daily_deal_payment => Factory(:daily_deal_payment))
    Factory(:credit, :consumer => consumer)

    assert_equal 10, consumer.credits.sum(:amount)

    Timecop.freeze(Time.zone.now) do
      consumer.reset_credit_available

      assert_equal consumer.credit_available_reset_at, Time.zone.now
    end

    assert_equal 0, consumer.credit_available.to_int

    assert_equal 15, consumer.credits.sum(:amount)
    assert_not_nil consumer.credits.last(:memo)
    assert_equal 15, consumer.daily_deal_purchases.captured(nil).sum(:credit_used)
  end

  test "consumer city" do
    publisher = Factory(:publisher)
    consumer  = Factory.build(:consumer, :publisher => publisher)
    assert_equal "Washington", consumer.city
    publisher.city = "Paris"
    assert_equal "Paris", consumer.city
  end

  test "first_names that are just spaces aren't valid" do
    consumer = Factory.build(:consumer)
    consumer.first_name_required = true
    consumer.first_name = " "
    assert !consumer.valid? 
    consumer.first_name = ""
    assert !consumer.valid?
  end
  
  test "last_names that are just spaces aren't valid" do
    consumer = Factory.build(:consumer)
    consumer.last_name_required = true
    consumer.last_name = " "
    assert !consumer.valid? 
    consumer.last_name = ""
    assert !consumer.valid?
  end

  test "twitter_status" do
    publisher = Factory(:publisher, :name => "OC Register")
    consumer = Factory(:consumer, :publisher => publisher)
    assert_match %r{\ACheck out OC Register\'s daily deal - huge discounts on the coolest stuff! http://bit.ly/}, consumer.twitter_status
  end

  test "consumer country_code must be in publisher country_codes" do
    uk = Country.find_or_create_by_code('UK')
    us = Country.find_or_create_by_code('US')
    publisher = Factory(:publisher, :countries => [uk, us])
    consumer = Factory.build(:consumer, :publisher => publisher)

    assert_bad_value consumer, :country_code, 'ca'
    assert_good_value consumer, :country_code, 'uk'
    assert_good_value consumer, :country_code, 'us'
  end

  test "consumer email validation" do
    consumer = Factory(:consumer)

    assert_good_value(consumer, :email, "foo@bar.com")
    assert_good_value(consumer, :email, "bar@chicken.coop")
    assert_good_value(consumer, :email, "bar@baz.aero")
    assert_good_value(consumer, :email, "baz@test.ca")
    assert_good_value(consumer, :email, "foo+bar@a-b.ca")
    assert_good_value(consumer, :email, "foo-bar@a.b.ca")
    assert_good_value(consumer, :email, "foo.bar@test.ca")

    assert_bad_value(consumer, :email, "foo@bar@baz.com")
    assert_bad_value(consumer, :email, "bar@baz.c")
    assert_bad_value(consumer, :email, "bar@baz.c")
    assert_bad_value(consumer, :email, "bar@a#a.c")
  end
  
  context "update_from_subscribers" do
    setup do
      @publisher = Factory(:publisher)
      @email = "john.public@example.com"
      defaults = { :publisher => @publisher, :email => @email, :zip_code => nil, :name => nil }
      @subscribers = []
      @subscribers << Factory.build(:subscriber, defaults.merge(:birth_year => "1993", :zip_code => "90210"))
      @subscribers << Factory.build(:subscriber, defaults.merge(:name => "Jay Public", :gender => "F"))
      @subscribers << Factory.build(:subscriber, defaults.merge(:birth_year => "1994", :first_name => "Jack"))
    end

    context "consumer with this email does not exist" do
      should "create a consumer" do
        assert !Consumer.find_by_publisher_id_and_email(@publisher.id, @email), "Should not have a consumer with this email yet"
        Consumer.update_from_subscribers! @publisher, @subscribers
        assert Consumer.find_by_publisher_id_and_email(@publisher.id, @email), "Should have created a consumer with this email"
      end

      should "set zip_code" do
        Consumer.update_from_subscribers! @publisher, @subscribers
        assert_equal "90210", Consumer.find_by_publisher_id_and_email(@publisher.id, @email).zip_code
      end

      should "set birth_year to later value" do
        Consumer.update_from_subscribers! @publisher, @subscribers
        assert_equal 1994, Consumer.find_by_publisher_id_and_email(@publisher.id, @email).birth_year
      end

      should "set first_name from explict first name" do
        Consumer.update_from_subscribers! @publisher, @subscribers
        assert_equal "Jack", Consumer.find_by_publisher_id_and_email(@publisher.id, @email).first_name
      end

      should "set last_name from name" do
        Consumer.update_from_subscribers! @publisher, @subscribers
        assert_equal "Public", Consumer.find_by_publisher_id_and_email(@publisher.id, @email).last_name
      end
    end

    context "consumer with this email already exists but is not activated" do
      setup do
        Factory.create(:consumer, :publisher => @publisher, :email => @email, :activated_at => nil)
      end

      should "not create a consumer" do
        assert_no_difference('Consumer.count') { Consumer.update_from_subscribers! @publisher, @subscribers }
      end

      should "set zip_code" do
        Consumer.update_from_subscribers! @publisher, @subscribers
        assert_equal "90210", Consumer.find_by_publisher_id_and_email(@publisher.id, @email).zip_code
      end

      should "set birth_year to later value" do
        Consumer.update_from_subscribers! @publisher, @subscribers
        assert_equal 1994, Consumer.find_by_publisher_id_and_email(@publisher.id, @email).birth_year
      end

      should "set first_name from explict first name" do
        Consumer.update_from_subscribers! @publisher, @subscribers
        assert_equal "Jack", Consumer.find_by_publisher_id_and_email(@publisher.id, @email).first_name
      end

      should "set last_name from name" do
        Consumer.update_from_subscribers! @publisher, @subscribers
        assert_equal "Public", Consumer.find_by_publisher_id_and_email(@publisher.id, @email).last_name
      end
    end

    context "consumer with this email already exists and is activated" do
      setup do
        consumer = Factory.create(:consumer, :publisher => @publisher, :email => @email)
        @original_attributes = consumer.attributes
      end

      should "not create a consumer" do
        assert_no_difference('Consumer.count') { Consumer.update_from_subscribers! @publisher, @subscribers }
      end

      should "not update any attributes" do
        Consumer.update_from_subscribers! @publisher, @subscribers
        attrs = [:first_name, :last_name, :zip_code, :birth_year, :gender]
        assert_equal @original_attributes.values_at(attrs), Consumer.find_by_publisher_id_and_email(@publisher.id, @email).attributes.values_at(attrs)
      end
    end
  end

  test "#pending_order with no existing orders creates new pending order" do
    consumer = Factory(:consumer)
    assert_difference 'consumer.daily_deal_orders.with_payment_status(:pending).count', 1 do
      consumer.pending_order
      consumer.reload
    end
  end

  test "#pending_order with existing completed order creates new pending order" do
    consumer = Factory(:consumer)
    ddo = Factory(:daily_deal_order, :consumer => consumer, :payment_status => 'captured')
    assert_difference 'consumer.daily_deal_orders.with_payment_status(:pending).count', 1 do
      consumer.pending_order
      consumer.reload
    end
  end

  context "preferred_locale" do
    should "should save the current locale on create" do
      I18n.locale = :es
      consumer = Factory(:consumer)
      assert_equal "es", consumer.preferred_locale

      I18n.locale = :en
      consumer = Factory(:consumer)
      assert_equal "en", consumer.preferred_locale
    end

    should "not set the current locale on create if one is present" do
      I18n.locale = :es
      consumer = Factory(:consumer, :preferred_locale => "en")
      assert_equal "en", consumer.preferred_locale

      I18n.locale = :zh
      consumer = Factory(:consumer, :preferred_locale => "es")
      assert_equal "es", consumer.preferred_locale
    end

    should "not be set on update" do
      I18n.locale = :es
      consumer = Factory(:consumer)
      assert_equal "es", consumer.preferred_locale

      I18n.locale = :en
      consumer.update_attribute(:first_name, "John")
      assert_equal "es", consumer.preferred_locale
    end
  end

  context "notifying third parties of account creation" do
    should "enqueue a job if the publisher requires third-party notification" do
      publisher = Factory(:publisher, :notify_third_parties_of_consumer_creation => true)
      consumer = Factory(:consumer, :publisher => publisher)
      NotifyPublisherOfConsumerCreation.expects(:perform).with(consumer.id)
      consumer.notify_third_parties_of_consumer_creation
    end

    should "not enqueue a job if the publisher does not require third-party notification" do
      publisher = Factory(:publisher, :notify_third_parties_of_consumer_creation => false)
      consumer = Factory(:consumer, :publisher => publisher)
      NotifyPublisherOfConsumerCreation.expects(:perform).with(consumer.id).never
      consumer.notify_third_parties_of_consumer_creation
    end

    should "enqueue a job if the publishing group requires third-party notification" do
      publishing_group = Factory(:publishing_group, :notify_third_parties_of_consumer_creation => true)
      publisher = Factory(:publisher, :publishing_group_id => publishing_group.id)
      consumer = Factory(:consumer, :publisher => publisher)
      NotifyPublisherOfConsumerCreation.expects(:perform).with(consumer.id)
      consumer.notify_third_parties_of_consumer_creation
    end

    should "not enqueue a job if the publishing group does not require third-party notification" do
      publishing_group = Factory(:publishing_group, :notify_third_parties_of_consumer_creation => false)
      publisher = Factory(:publisher, :publishing_group_id => publishing_group.id)
      consumer = Factory(:consumer, :publisher => publisher)
      NotifyPublisherOfConsumerCreation.expects(:perform).with(consumer.id).never
      consumer.notify_third_parties_of_consumer_creation
    end
  end

  context "#consumer_for_publishing_group?" do
    
    should "raise if not passed a publishing group" do
      assert_raise RuntimeError do
        publisher = Factory(:publisher)
        consumer = Factory(:consumer, :publisher_id => publisher.id)
        consumer.consumer_for_publishing_group?(nil)
      end
    end

    should "return true if the consumer is a consumer for a publisher under the publishing group" do
      publishing_group = Factory(:publishing_group)
      publisher = Factory(:publisher, :publishing_group_id => publishing_group.id)
      consumer = Factory(:consumer, :publisher_id => publisher.id)
      assert_equal true, consumer.consumer_for_publishing_group?(publishing_group)
    end

    should "return false if the consumer is a consumer for a publisher not under the publishing group" do
      publishing_group = Factory(:publishing_group)
      publisher = Factory(:publisher)
      consumer = Factory(:consumer, :publisher_id => publisher.id)
      assert_equal false, consumer.consumer_for_publishing_group?(publishing_group)
    end

  end

  context "force_password_reset" do

    should "not change if password does not change" do
      consumer = Factory(:consumer, :first_name => "Bob", :force_password_reset => true)
      consumer.first_name = "Sam"
      consumer.save!
      consumer.reload
      assert_equal true, consumer.force_password_reset?, "The password did not change so force_password_reset should not have changed."
    end

    should "change be false after saving a changed password" do
      consumer = Factory(:consumer, :force_password_reset => true)
      consumer.reload
      assert consumer.force_password_reset?
      consumer.password = "newpass"
      consumer.password_confirmation = "newpass"
      consumer.save!
      assert !consumer.force_password_reset?
      consumer.reload
      assert !consumer.force_password_reset?
    end

  end

  context "switch publishers" do

    should "be able to reassign pub and having purchases" do
      publisher = Factory(:publisher)
      daily_deal = Factory(:daily_deal, :publisher => publisher)
      consumer = Factory(:consumer, :publisher => publisher)
      Factory(:daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer)
      Factory(:credit, :consumer => consumer)
      Factory(:daily_deal_order, :consumer => consumer)
      consumer.publisher = Factory(:publisher)
      consumer.save!
    end 

  end

  context "unique email addresses across publisher group" do

    setup do
      @publishing_group = Factory(:publishing_group)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @publisher2 = Factory(:publisher, :publishing_group => @publishing_group)
      @consumer = Factory.build(:consumer, :publisher => @publisher)
      @consumer2 = Factory(:consumer, :publisher => @publisher)
    end

    should "be valid for unique email within publisher" do
      @consumer.email = "iamunique@unique.com"
      assert @consumer.valid?
    end

    should "matter if the unique across pub group flag is set" do
      @consumer.email = "uniqueatfirst@foo.com"
      @consumer.save!
      @consumer2.email = "uniqueatfirst@foo.com"
      assert !@consumer2.valid?
      @consumer2.publisher = @publisher2
      assert @consumer2.valid?
      @publishing_group.unique_email_across_publishing_group = true
      @publishing_group.save!
      assert !@consumer2.valid?
      consumer3 = Factory.build(:consumer, :publisher => @publisher, :email => "uniqueatfirst@foo.com")
      assert !consumer3.valid?
    end

    should "be valid after saving" do
      @publishing_group.unique_email_across_publishing_group = true
      @publishing_group.save!
      @consumer.email = "me@yahoo.com"
      assert @consumer.valid?
      @consumer.save!
      assert @consumer.valid?, @consumer.errors.full_messages.join(", ")
    end

    should "not add more than one uniqueness error on email address" do
      @publishing_group.update_attributes(:unique_email_across_publishing_group => true)
      @consumer2.update_attributes(:email => "foo@bar.com")

      @consumer.email = "foo@bar.com"
      assert !@consumer.valid?

      assert_equal "Email has already been taken", @consumer.errors.on(:email)
    end

  end

  context "member_authorization" do

    setup do
      @publishing_group = Factory(:publishing_group)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @consumer = Factory.build(:consumer, :publisher => @publisher)
    end

    context "member_authorization_required not set" do
      setup do
        @consumer.member_authorization_required = nil
      end

      should "not require member_authorization" do
        assert_good_value @consumer, :member_authorization, nil
        assert_good_value @consumer, :member_authorization, true
      end
    end

    context "member_authorization_required" do
      setup do
        @consumer.member_authorization_required = true
      end

      should "require member_authorization" do
        @consumer.member_authorization = nil
        assert !@consumer.valid?
        assert @consumer.errors.full_messages.include?("You must agree to the Member and Email Authorization terms to use this service")

        @consumer.member_authorization = "1"
        assert @consumer.valid?
      end
    end
  end

  context "#has_master_membership_code?" do
    setup do
      @publishing_group = Factory(:publishing_group, :require_publisher_membership_codes => true)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
    end

    should "return false if the consumer's publishing group does not support membership codes" do
      @publishing_group.update_attribute(:require_publisher_membership_codes, false)
      consumer = Factory(:consumer, :publisher => @publisher)
      assert !consumer.has_master_membership_code?
    end

    should "return false if the consumer's membership code does not have the master flag set" do
      non_master_publisher_membership_code = Factory(:publisher_membership_code, :publisher => @publisher, :master => false)
      consumer = Factory(:consumer, :publisher => @publisher, :publisher_membership_code => non_master_publisher_membership_code)
      assert !consumer.has_master_membership_code?
    end

    should "return true if the consumer's membership code does have the master flag set" do
      master_publisher_membership_code = Factory(:publisher_membership_code, :publisher => @publisher, :master => true)
      consumer = Factory(:consumer, :publisher => @publisher, :publisher_membership_code => master_publisher_membership_code)
      assert consumer.has_master_membership_code?
    end
  end

end
