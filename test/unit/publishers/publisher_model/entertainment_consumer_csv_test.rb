require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::EntertainmentConsumerCsvTest
module Publishers
  module PublisherModel
    class EntertainmentConsumerCsvTest < ActiveSupport::TestCase
      test "entertainment consumer csv with no consumers or subscribers" do
        publisher = Factory(:publisher, :name => "Entertainment", :label => "entertainment")

        publisher.generate_consumers_list(csv = [], :columns => %w{ status email name subject }, :allow_duplicates => true)

        assert_equal 1, csv.size, "should only have title elements"
        assert_equal ["status", "email", "name", "subject"], csv[0]
      end

      test "entertainment consumer csv with consumers activated" do
        publisher = Factory(:publisher, :name => "Entertainment", :label => "entertainment")
        advertiser = publisher.advertisers.create!(:name => "Advertiser")
        advertiser.daily_deals.create!(daily_deal_attributes)
        c_1 = publisher.consumers.create!(valid_user_attributes.merge(:email => "john@hello.com", :name => "John Smith"))
        c_1.activated_at = Time.zone.now - 23.hours
        c_1.activation_code = nil
        c_1.save false
        c_2 = publisher.consumers.create!(valid_user_attributes.merge(:email => "jill@hello.com", :name => "Jill Smith"))
        c_2.activated_at = Time.zone.now - 10.hours
        c_2.activation_code = nil
        c_2.save false

        publisher.generate_consumers_list(csv = [], :columns => %w{ status email name subject }, :allow_duplicates => true)

        assert_equal 3, csv.size, "should only title element plus 2 consumer"
        assert_equal ["status", "email", "name", "subject"], csv[0]
        assert_equal ["1", "john@hello.com", "John Smith", "A wonderful deal awaits"], csv[1]
        assert_equal ["1", "jill@hello.com", "Jill Smith", "A wonderful deal awaits"], csv[2]
      end

      test "entertainment consumer csv with subscribers" do
        publisher = Factory(:publisher, :name => "Entertainment", :label => "entertainment")
        advertiser = publisher.advertisers.create!(:name => "Advertiser")
        advertiser.daily_deals.create!(daily_deal_attributes)
        publisher.subscribers.create!(:email => "john@hello.com")
        publisher.subscribers.create!(:email => "jill@hello.com")

        publisher.generate_consumers_list(csv = [], :columns => %w{ status email name subject }, :allow_duplicates => true)

        assert_equal 3, csv.size, "should only title element plus 2 consumer"
        assert_equal ["status", "email", "name", "subject"], csv[0]
        csv.sort!
        assert_equal ["1", "jill@hello.com", nil, "A wonderful deal awaits"], csv[0]
        assert_equal ["1", "john@hello.com", nil, "A wonderful deal awaits"], csv[1]
      end

      test "entertainment consumer csv with consumers and subscribers that overlap" do
        publisher = Factory(:publisher, :name => "Entertainment", :label => "entertainment", :city => "Portland", :state => "OR", :zip => "97214", :address_line_1 => "3440 SE Tuna Drive")
        advertiser = publisher.advertisers.create!(:name => "Advertiser")
        advertiser.daily_deals.create!(daily_deal_attributes)
        c_1 = publisher.consumers.create!(valid_user_attributes.merge(:email => "john@hello.com", :name => "John Smith"))
        c_1.activated_at = Time.zone.now - 23.hours
        c_1.activation_code = nil
        c_1.save false
        c_2 = publisher.consumers.create!(valid_user_attributes.merge(:email => "jill@hello.com", :name => "Jill Smith"))
        c_2.activated_at = Time.zone.now - 10.hours
        c_2.activation_code = nil
        c_2.save false

        s_1 = publisher.subscribers.create!(:email => "john@hello.com")
        s_1.other_options = {:city => "Los Angeles", :referral_code => "abc123"}
        s_1.save!
        s_2 = publisher.subscribers.create!(:email => "jordan@somewhere.com")
        s_2.other_options = {:referral_code => "def246"}
        s_2.save!

        publisher.generate_consumers_list(csv = [], :columns => %w{ status email name subject city referral_code}, :allow_duplicates => true)

        assert_equal 5, csv.size, "should only title element plus 3 consumer"
        assert_equal ["status", "email", "name", "subject", "city", "referral_code"], csv[0]
        assert_equal ["1", "john@hello.com", "John Smith", "A wonderful deal awaits", "Portland", nil], csv[1]
        assert_equal ["1", "jill@hello.com", "Jill Smith", "A wonderful deal awaits", "Portland", nil], csv[2]
        assert_equal ["1", "john@hello.com", nil, "A wonderful deal awaits", "Los Angeles", "abc123"], csv[3]
        assert_equal ["1", "jordan@somewhere.com", nil, "A wonderful deal awaits", nil, "def246"], csv[4]

        publisher.generate_consumers_list(csv = [], :columns => %w{ status email name subject city referral_code}, :allow_duplicates => false)

        assert_equal 4, csv.size, "should only title element plus 3 consumer"
        assert_equal ["status", "email", "name", "subject", "city", "referral_code"], csv[0]
        assert_equal ["1", "john@hello.com", "John Smith", "A wonderful deal awaits", "Portland", "abc123"], csv[1]
        assert_equal ["1", "jill@hello.com", "Jill Smith", "A wonderful deal awaits", "Portland", ""], csv[2]
        assert_equal ["1", "jordan@somewhere.com", "", "A wonderful deal awaits", "", "def246"], csv[3]

      end

      test "entertainment consumer csv with consumers and subscribers that overlap and column selection" do
        Time.stubs(:now).returns(Time.parse("Mar 01, 2010 12:34:56 UTC"))
        publisher = Factory(:publisher, :name => "Entertainment", :label => "entertainment")
        advertiser = publisher.advertisers.create!(:name => "Advertiser")
        advertiser.daily_deals.create!(daily_deal_attributes)
        c_1 = publisher.consumers.create!(valid_user_attributes.merge(:email => "john@hello.com", :name => "John Smith"))
        c_1.activated_at = Time.zone.now - 23.hours
        c_1.activation_code = nil
        c_1.save false
        c_2 = publisher.consumers.create!(valid_user_attributes.merge(:email => "jill@hello.com", :name => "Jill Smith"))
        c_2.activated_at = Time.zone.now - 10.hours
        c_2.activation_code = nil
        c_2.save false

        publisher.subscribers.create!(:email => "john@hello.com")
        publisher.subscribers.create!(:email => "jordan@somewhere.com")

        publisher.generate_consumers_list(csv = [], :columns => %w{ email name created_at}, :allow_duplicates => true)

        assert_equal 5, csv.size, "should have title element plus 4 consumers"
        assert_equal ["email", "name", "created_at"], csv[0]
        assert_equal ["john@hello.com", "John Smith", "2010-03-01 12:34:56"], csv[1]
        assert_equal ["jill@hello.com", "Jill Smith", "2010-03-01 12:34:56"], csv[2]
        assert_equal ["john@hello.com", nil, "2010-03-01 12:34:56"], csv[3]
        assert_equal ["jordan@somewhere.com", nil, "2010-03-01 12:34:56"], csv[4]
      end

      private

      def entertainment_consumer_csv_with_billing_addr
        publisher = Factory(:publisher, :label => "entertainment")
        advertiser = Factory(:advertiser, :publisher => publisher)
        daily_deal = Factory(:daily_deal, :advertiser => advertiser)
        consumer = Factory(
            :billing_address_consumer,
            :publisher => publisher,
            :first_name => 'Damon',
            :last_name => 'Albarn',
            :referral_code => '123',
            :email => 'hi@hi.com',
            :activated_at => Time.zone.now - 23.hours
        )

        atts = %w{ name email billing_city state country_code zip_code referral_code created_at }
        publisher.generate_consumers_list(csv = [], :columns => atts, :allow_duplicates => true)

        assert_equal atts, csv[0]
        assert_equal ['Damon Albarn', 'hi@hi.com', 'brooklyn', 'NY', 'US', '11215', '123', consumer.created_at], csv[1]
      end

      private

      def daily_deal_attributes
        {
            :value_proposition => "$81 value for $39",
            :price => 39.00,
            :value => 81.00,
            :terms => "One per table",
            :description => "A wonderful deal",
            :start_at => Time.zone.now.yesterday,
            :hide_at => Time.zone.now.tomorrow,
            :short_description => "A wonderful deal awaits"
        }
      end

      def valid_user_attributes
        {
            :email => "joe@blow.com",
            :name => "Joe Blow",
            :password => "secret",
            :password_confirmation => "secret",
            :agree_to_terms => "1"
        }
      end
    end
  end
end