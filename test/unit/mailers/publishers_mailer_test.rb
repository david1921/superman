require File.dirname(__FILE__) + "/../../test_helper"

class PublishersMailerTest < ActionMailer::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end
  
  def test_latest_subscribers_without_other_options
    publisher = Factory(:publisher, :name => "San Diego Weekly Reader")
    publisher.subscribers.create! :email => "click@example.com", :created_at => Time.zone.now.to_date - 2
    categories = [ Category.create!(:name => "Auto"), Category.create!(:name => "Advice") ]
    timestamp = Time.zone.now
    todays_subscriber = publisher.subscribers.create!(
      :email => "clack@example.com",
      :mobile_number => "626-674-5901",
      :created_at => timestamp,
      :categories => categories
    )
    publisher.update_attribute( :subscriber_recipients, "scott.willson@analoganalytics.com" )
    
    email = PublishersMailer.deliver_latest_subscribers(publisher, publisher.subscribers.created_within(24.hours))
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [ "scott.willson@analoganalytics.com" ], email.to
    assert_equal [ "support@analoganalytics.com" ], email.from
    assert_equal "San Diego Weekly Reader Coupon Subscribers", email.subject

    assert_equal 1, email.attachments.size, "Should have one attachment"
    attachment = email.attachments.first
    assert_match /\Asubscribers-\d{4}-\d{2}-\d{2}.csv\z/, attachment.original_filename     
    assert_equal "text/csv", attachment.content_type

    have_subscribers = [].tap do |array|
      FasterCSV.parse(attachment, :headers => true) do |row|
        array << {
          :email => row["Email"],
          :mobile_number => row["Mobile Number"],
          :created_at => row["Created At"],
          :categories => row["Categories"],
          :other_options => row["Other Options"]
        }
      end
    end
    want_subscribers = [
      {
        :email => "clack@example.com",
        :mobile_number => "16266745901",
        :created_at => timestamp.to_formatted_s(:db),
        :categories => "Advice,Auto",
        :other_options => ""
      }
    ]
    assert_equal want_subscribers, have_subscribers
  end
  
  def test_latest_subscribers_with_other_options
    publisher = Factory(:publisher, :name => "San Diego Weekly Reader")
    publisher.subscribers.create! :email => "click@example.com", :created_at => Time.zone.now.to_date - 2
    categories = [ Category.create!(:name => "Auto"), Category.create!(:name => "Advice") ]
    timestamp = Time.zone.now
    todays_subscriber = publisher.subscribers.create!(
      :email => "clack@example.com",
      :mobile_number => "626-674-5901",
      :created_at => timestamp,
      :categories => categories,
      :other_options => ["steals"]
    )
    publisher.update_attribute( :subscriber_recipients, "scott.willson@analoganalytics.com" )
    
    email = PublishersMailer.deliver_latest_subscribers(publisher, publisher.subscribers.created_within(24.hours))
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [ "scott.willson@analoganalytics.com" ], email.to
    assert_equal [ "support@analoganalytics.com" ], email.from
    assert_equal "San Diego Weekly Reader Coupon Subscribers", email.subject

    assert_equal 1, email.attachments.size, "Should have one attachment"
    attachment = email.attachments.first
    assert_match /\Asubscribers-\d{4}-\d{2}-\d{2}.csv\z/, attachment.original_filename     
    assert_equal "text/csv", attachment.content_type

    have_subscribers = [].tap do |array|
      FasterCSV.parse(attachment, :headers => true) do |row|
        array << {
          :email => row["Email"],
          :mobile_number => row["Mobile Number"],
          :created_at => row["Created At"],
          :categories => row["Categories"],
          :other_options => row["Other Options"]
        }
      end
    end
    want_subscribers = [
      {
        :email => "clack@example.com",
        :mobile_number => "16266745901",
        :created_at => timestamp.to_formatted_s(:db),
        :categories => "Advice,Auto",
        :other_options => "steals"
      }
    ]
    assert_equal want_subscribers, have_subscribers
  end

  def test_latest_subscribers_with_other_options_cities_or_locations
    YAML.stubs(:load_file).with(File.expand_path("config/publisher_mailer.yml", Rails.root)).returns({
      "udailydeal" => {
        "include_in_email" => true,
        "include_all_subscribers" => true,
        "other_options" => {
          "locations" => %w(atlanta boston dc philadelphia),
          "other_cities" => true
        },
        "columns" => %w(first_name last_name email created_at affiliate atlanta boston dc philadelphia city_state)
      }
    })

    publisher = Factory(:publisher, :name => "UDailyDeal", :label => "udailydeal")
    subscriber_atts = {
      :email => "geoff@example.com", 
      :created_at => 2.hours.ago,
      :first_name => "someone",
      :last_name => "special"
    }
    subscriber_1 = publisher.subscribers.create!(
      subscriber_atts.merge(:other_options => {"city" => "atlanta"})
    )
    subscriber_2 = publisher.subscribers.create!(
      subscriber_atts.merge(:other_options => {"locations" => {"dc" => "1"}})
    )
    publisher.update_attribute( :subscriber_recipients, "root@localhost" )
    email = PublishersMailer.deliver_latest_subscribers(publisher, publisher.subscribers.created_within(24.hours))
    
    actual = FasterCSV.parse(email.attachments.first, :headers => true).map do |row|
      { :atlanta => row["Atlanta"], :dc => row["Dc"] }
    end
    
    expected = [ 
      { :atlanta => "yes", :dc => "no" },
      { :atlanta => "no", :dc => "yes" } 
    ]

    assert_equal expected, actual
  end
  
  def test_advertisers_categories
    publisher = publishers(:sdreader)
    publisher.update_attributes! :categories_recipients => "scott.willson@analoganalytics.com"

    advertiser = publisher.advertisers.create!(:name => "A1")
    advertiser.offers.create!(:message => "A1 O1", :category_names => "Food : Chinese, Services : Laundry")
    advertiser.offers.create!(:message => "A1 O2", :category_names => "Automotive")
    
    advertiser = publisher.advertisers.create!(:name => "A2")
    advertiser.offers.create!(:message => "A2 O1", :category_names => "Food : Mexican")
    
    PublishersMailer.deliver_advertisers_categories(publisher)
    assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email message"
    email = ActionMailer::Base.deliveries.first

    assert_equal [ "scott.willson@analoganalytics.com" ], email.to
    assert_equal [ "support@analoganalytics.com" ], email.from
    assert_equal "San Diego Reader Advertiser Categories", email.subject

    assert_equal 1, email.attachments.size, "Should have one attachment"
    attachment = email.attachments.first
    assert_match /\Aadvertisers-categories-\d{4}-\d{2}-\d{2}.csv\z/, attachment.original_filename
    assert_equal "text/csv", attachment.content_type

    have_advertisers_categories = returning({}) do |hash|
      FasterCSV.parse(attachment, :col_sep => "\t", :headers => true) do |row|
        advertiser = row["Advertiser"]
        hash[advertiser] = (hash[advertiser] || {}).merge(row["Coupon"] => row["Categories"])
      end
    end
    want_advertisers_categories = { 
      "A1" => { "A1 O1" => "Food: Chinese, Services: Laundry", "A1 O2" => "Automotive" },
      "A2" => { "A2 O1" => "Food: Mexican" }
    }
    assert_equal want_advertisers_categories, have_advertisers_categories
  end

  context "support_contact_request" do
    setup do
      @publisher = Factory(:publisher, :support_email_address => "support@example.com")

      @support_contact_request = SupportContactRequest.new(
        :first_name => "John",
        :last_name  => "Doe",
        :email      => "john@example.com",
        :message    => "Hello\n\nThis is a test.\n\nThanks, John",
        :reason_for_request => "Refund"
      )
    end

    should "send an email with correct headers" do
      PublishersMailer.deliver_support_contact_request(@publisher, @support_contact_request)

      assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email message"
      email = ActionMailer::Base.deliveries.first

      assert_equal ["support@example.com"], email.to
      assert_equal ["support@analoganalytics.com"], email.from
      assert_equal "Support Request from John Doe", email.subject
    end

    should "send form field values within body" do
      PublishersMailer.deliver_support_contact_request(@publisher, @support_contact_request)
      email = ActionMailer::Base.deliveries.first

      assert email.body =~ /Name: John Doe\n/
      assert email.body =~ /Email: john@example.com\n/
      assert email.body =~ /Message:\nHello\n\nThis is a test.\n\nThanks, John/
      assert email.body =~ /Reason for request: #{@support_contact_request.reason_for_request}/
    end

    should "use the optional subject line" do
      @support_contact_request.email_subject_format = "{{first_name}} {{ last_name }} - {{reason_for_request }}"

      PublishersMailer.deliver_support_contact_request(@publisher, @support_contact_request)
      email = ActionMailer::Base.deliveries.first
      assert_equal "John Doe - Refund", email.subject
    end
  end

  context "sales_contact_request" do
    setup do
      @publisher = Factory(:publisher, :sales_email_address => "sales@example.com")

      @sales_contact_request = SalesContactRequest.new(
        :first_name   => "John",
        :last_name    => "Doe",
        :title        => "Sales Rep",
        :company      => "Widgets R Us",
        :phone_number => "1 555 123 4567",
        :website      => "www.example.com",
        :email        => "john@example.com",
        :message      => "Hello\n\nThis is a test.\n\nThanks, John"
      )
    end

    should "send an email with correct headers" do
      PublishersMailer.deliver_sales_contact_request(@publisher, @sales_contact_request)

      assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email message"
      email = ActionMailer::Base.deliveries.first

      assert_equal ["sales@example.com"], email.to
      assert_equal ["support@analoganalytics.com"], email.from
      assert_equal "Sales Request from John Doe", email.subject
    end

    should "send form field values within body" do
      PublishersMailer.deliver_sales_contact_request(@publisher, @sales_contact_request)
      email = ActionMailer::Base.deliveries.first

      assert email.body =~ /Name: John Doe\n/
      assert email.body =~ /Title: Sales Rep\n/
      assert email.body =~ /Company: Widgets R Us\n/
      assert email.body =~ /Phone Number: 1 555 123 4567\n/
      assert email.body =~ /Email: john@example.com\n/
      assert email.body =~ /Website: www.example.com\n/
      assert email.body =~ /Message:\nHello\n\nThis is a test.\n\nThanks, John/
    end
  end

  context "business_contact_request" do
    setup do
      @publisher = Factory(:publisher, :support_email_address => "support@example.com")

      @business_contact_request = BusinessContactRequest.new(
        :first_name => "Bob",
        :last_name  => "Doe",
        :email      => "bob@example.com",
        :business   => "Holy Shirts and Pants",
        :message    => "Hello\n\nThis is a test.\n\nThanks, Bob"
      )
    end

    should "send an email with correct headers" do
      PublishersMailer.deliver_business_contact_request(@publisher, @business_contact_request)

      assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email message"
      email = ActionMailer::Base.deliveries.first

      assert_equal ["support@example.com"], email.to
      assert_equal ["support@analoganalytics.com"], email.from
      assert_equal "Business Request from Bob Doe", email.subject
    end

    should "send form field values within body" do
      PublishersMailer.deliver_business_contact_request(@publisher, @business_contact_request)
      email = ActionMailer::Base.deliveries.first

      assert email.body =~ /Name: Bob Doe\n/
      assert email.body =~ /Email: bob@example.com\n/
      assert email.body =~ /Business: Holy Shirts and Pants\n/
      assert email.body =~ /Message:\nHello\n\nThis is a test.\n\nThanks, Bob/
    end
  end
    
  context "suggested_daily_deal" do
    setup do
      @publisher = Factory(:publisher, :suggested_daily_deal_email_address => "suggested_deals@example.com")

      @consumer = Factory(:consumer, :first_name => "John", :last_name => "Doe", :email => "john@example.com")

      # creation of suggested_daily_deal calls deliver_suggested_daily_deal
      @suggested_daily_deal = Factory(:suggested_daily_deal,
                                      :consumer => @consumer,
                                      :publisher => @publisher,
                                      :description => "Free donuts!")
    end

    should "deliver an email with the correct subject and body" do
      assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email message"
      email = ActionMailer::Base.deliveries.first

      assert_equal ["suggested_deals@example.com"], email.to
      assert_equal ["support@analoganalytics.com"], email.from
      assert_equal "Suggested Deal from John Doe", email.subject

      assert email.body =~ /Name: John Doe\n/
      assert email.body =~ /Email: john@example.com\n/
      assert email.body =~ /Description:\nFree donuts!\n/
    end
  end
  context "#daily_deal_sold_out_notification" do
    setup do
      @publisher  = Factory.build(:publisher, :send_daily_deal_notification => true, :notification_email_address => "notification_email@publisher.com")
    @daily_deal = Factory.build(:daily_deal, :publisher => @publisher, :quantity => 5)
    end
    should "send an email notification if Publisher.enable_daily_deal_notification is checked" do
      @daily_deal.stubs(:sold_out_without_sold_out_at?).returns(true)
      @daily_deal.sold_out!
      assert !ActionMailer::Base.deliveries.empty?
      email = ActionMailer::Base.deliveries.first
      assert_equal [ "notification_email@publisher.com" ], email.to
      assert_equal "Daily Deal Sold Out! (#{@daily_deal.id})", email.subject

    end
  end
end
