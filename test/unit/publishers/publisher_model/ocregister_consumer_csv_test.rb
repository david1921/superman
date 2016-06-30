require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::OcregisterConsumerCsvTest
module Publishers
  module PublisherModel
    class OcregisterConsumerCsvTest < ActiveSupport::TestCase
      test "ocregister consumer csv with consumers activated" do
        publishing_group = Factory(:publishing_group, :name => "Freedome", :label => "freedom")
        ["ocregister", "gazette", "rgv"].each_with_index do |label, index|
          publisher = Factory(:publisher, :name => label.upcase, :label => label)

          publishers_config = UploadConfig.new(:publishers)
          config = publishers_config.fetch!(label)

          advertiser = publisher.advertisers.create!(:name => "Advertiser", :description => "test description")
          advertiser.daily_deals.create!(daily_deal_attributes)
          c_1 = publisher.consumers.create!(valid_user_attributes.merge(:email => "jon@hello.com", :name => "Jon Smith", :device => "mobile", :zip_code => "76823"))
          c_1.activated_at = Time.zone.now - 23.hours
          c_1.activation_code = nil
          c_1.save false
          c_2 = publisher.consumers.create!(valid_user_attributes.merge(:email => "jill@hello.com", :name => "Jill Smith", :device => "tablet", :zip_code => "76223"))
          c_2.activated_at = Time.zone.now - 10.hours
          c_2.activation_code = nil
          c_2.save false

          publisher.generate_consumers_list(csv = [], :columns => config[:cols], :column_title_map => config[:cmap])

          assert_equal 3, csv.size, "should only title element plus 2 consumer"
          assert_equal ["status", "email", "name", "subject", "browser", "zip_code"], csv[0]
          assert_equal ["1", "jon@hello.com", "Jon Smith", "A wonderful deal awaits", "mobile", "76823"], csv[1]
          assert_equal ["1", "jill@hello.com", "Jill Smith", "A wonderful deal awaits", "tablet", "76223"], csv[2]
        end
      end

      test "ocregister consumer csv with subscribers" do
        publishing_group = Factory(:publishing_group, :name => "Freedome", :label => "freedom")
        ["ocregister", "gazette", "rgv"].each_with_index do |label, index|
          publisher = Factory(:publisher, :name => label.upcase, :label => label)

          publishers_config = UploadConfig.new(:publishers)
          config = publishers_config.fetch!(label)

          advertiser = publisher.advertisers.create!(:name => "Advertiser", :description => "test description")
          advertiser.daily_deals.create!(daily_deal_attributes)
          publisher.subscribers.create!(:email => "jon@hello.com", :device => 'web', :zip_code => "98123")
          publisher.subscribers.create!(:email => "jill@hello.com", :device => 'tablet', :zip_code => "98765")

          publisher.generate_consumers_list(csv = [], :columns => config[:cols], :column_title_map => config[:cmap])

          assert_equal 3, csv.size, "should only title element plus 2 consumer"
          assert_equal ["status", "email", "name", "subject", "browser", "zip_code"], csv[0]
          csv.sort!
          assert_equal ["1", "jill@hello.com", "", "A wonderful deal awaits", "tablet", "98765"], csv[0]
          assert_equal ["1", "jon@hello.com", "", "A wonderful deal awaits", "web", "98123"], csv[1]
        end
      end

      test "ocregister consumer csv with subscribers but no daily deal" do
        publishing_group = Factory(:publishing_group, :name => "Freedome", :label => "freedom")
        ["ocregister", "gazette", "themonitor"].each_with_index do |label, index|
          publisher = Factory(:publisher, :name => label.upcase, :label => label)
          publisher.subscribers.create!(:email => "jon@hello.com")
          publisher.subscribers.create!(:email => "jill@hello.com")

          publisher.generate_consumers_list(csv = [], :columns => %w{ status email name subject })

          assert_equal 3, csv.size, "should only title element plus 2 consumer"
          assert_equal ["status", "email", "name", "subject"], csv[0]
          csv.sort!
          assert_equal ["1", "jill@hello.com", "", ""], csv[0]
          assert_equal ["1", "jon@hello.com", "", ""], csv[1]
        end
      end

      test "ocregister consumer csv with consumers and subscribers that overlap" do
        publishing_group = Factory(:publishing_group, :name => "Freedome", :label => "freedom")
        ["ocregister", "gazette", "themonitor"].each_with_index do |label, index|
          publisher = Factory(:publisher, :name => label.upcase, :label => label)
          advertiser = publisher.advertisers.create!(:name => "Advertiser", :description => "test description")
          advertiser.daily_deals.create!(daily_deal_attributes)
          c_1 = publisher.consumers.create!(valid_user_attributes.merge(:email => "jon@hello.com", :name => "Jon Smith"))
          c_1.activated_at = Time.zone.now - 23.hours
          c_1.activation_code = nil
          c_1.save false
          c_2 = publisher.consumers.create!(valid_user_attributes.merge(:email => "jill@hello.com", :name => "Jill Smith"))
          c_2.activated_at = Time.zone.now - 10.hours
          c_2.activation_code = nil
          c_2.save false

          publisher.subscribers.create!(:email => "jon@hello.com")
          publisher.subscribers.create!(:email => "jordan@somewhere.com")

          publisher.generate_consumers_list(csv = [], :columns => %w{ status email name subject })

          assert_equal 4, csv.size, "should only title element plus 3 consumer"
          assert_equal ["status", "email", "name", "subject"], csv[0]
          assert_equal ["1", "jon@hello.com", "Jon Smith", "A wonderful deal awaits"], csv[1]
          assert_equal ["1", "jill@hello.com", "Jill Smith", "A wonderful deal awaits"], csv[2]
          assert_equal ["1", "jordan@somewhere.com", "", "A wonderful deal awaits"], csv[3]
        end
      end

      test "ocregister consumer csv with consumers and subscribers that overlap and column selection" do
        publishing_group = Factory(:publishing_group, :name => "Freedome", :label => "freedom")
        ["ocregister", "gazette", "themonitor"].each_with_index do |label, index|
          publisher = Factory(:publisher, :name => label.upcase, :label => label)
          advertiser = publisher.advertisers.create!(:name => "Advertiser", :description => "test description")
          advertiser.daily_deals.create!(daily_deal_attributes)
          c_1 = publisher.consumers.create!(valid_user_attributes.merge(:email => "jon@hello.com", :name => "Jon Smith"))
          c_1.activated_at = Time.zone.now - 23.hours
          c_1.activation_code = nil
          c_1.save false
          c_2 = publisher.consumers.create!(valid_user_attributes.merge(:email => "jill@hello.com", :name => "Jill Smith"))
          c_2.activated_at = Time.zone.now - 10.hours
          c_2.activation_code = nil
          c_2.save false

          publisher.subscribers.create!(:email => "jon@hello.com")
          publisher.subscribers.create!(:email => "jordan@somewhere.com")

          publisher.generate_consumers_list(csv = [], :columns => %w{ email name })

          assert_equal 4, csv.size, "should only title element plus 3 consumer"
          assert_equal ["email", "name"], csv[0]
          assert_equal ["jon@hello.com", "Jon Smith"], csv[1]
          assert_equal ["jill@hello.com", "Jill Smith"], csv[2]
          assert_equal ["jordan@somewhere.com", ""], csv[3]
        end
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
