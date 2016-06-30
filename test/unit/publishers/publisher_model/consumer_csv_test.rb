require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::ConsumerCsvTest
module Publishers
  module PublisherModel
    class ConsumerCsvTest < ActiveSupport::TestCase
      test "nydailynews with just consumers" do
        publisher = Factory(:publisher, :name => "NY Daily News", :label => "nydailynews")
        advertiser = publisher.advertisers.create!(:name => "Advertiser")
        advertiser.daily_deals.create!(daily_deal_attributes)
        c_1 = publisher.consumers.create!(valid_user_attributes.merge(:email => "jon@hello.com", :name => "Jon Smith", :zip_code => "97205"))
        c_1.activated_at = Time.zone.now - 23.hours
        c_1.activation_code = nil
        c_1.save false
        c_2 = publisher.consumers.create!(valid_user_attributes.merge(:email => "jill@hello.com", :name => "Jill Smith", :zip_code => "97226"))
        c_2.activated_at = Time.zone.now - 10.hours
        c_2.activation_code = nil
        c_2.save false

        publisher.generate_consumers_list(csv = [], :columns => %w{ email first_name last_name zip })

        assert_equal 3, csv.size, "should only title element plus 2 consumer"
        assert_equal ["email", "first_name", "last_name", "zip"], csv[0]
        assert_equal ["jon@hello.com", "Jon", "Smith", "97205"], csv[1]
        assert_equal ["jill@hello.com", "Jill", "Smith", "97226"], csv[2]
      end

      test "nydailynews consumer csv with subscribers but no daily deal" do
        publisher = Factory(:publisher, :name => "NY Daily News", :label => "nydailynews")
        publisher.subscribers.create!(:email => "jon@hello.com", :first_name => "Jon", :last_name => "Smith", :zip_code => "97205")
        publisher.subscribers.create!(:email => "jill@hello.com", :first_name => "Jill", :last_name => "Smith", :zip_code => "97226")

        publisher.generate_consumers_list(csv = [], :columns => %w{ email first_name last_name zip })

        assert_equal 3, csv.size, "should only title element plus 2 consumer"
        assert_equal ["email", "first_name", "last_name", "zip"], csv[0]
        csv.sort!
        assert_equal ["jill@hello.com", "Jill", "Smith", "97226"], csv[1]
        assert_equal ["jon@hello.com", "Jon", "Smith", "97205"], csv[2]
      end

      test "gogosavings with just consumers" do
        publisher = Factory(:publisher, :name => "GoGoSavings", :label => "gogosavings")
        advertiser = publisher.advertisers.create!(:name => "Advertiser")
        advertiser.daily_deals.create!(daily_deal_attributes)
        c_1 = publisher.consumers.build(valid_user_attributes.merge(:email => "jon@hello.com", :name => "Jon Smith", :zip_code => "97205"))
        c_1.save!
        c_1.activated_at = Time.zone.now - 23.hours
        c_1.activation_code = nil
        c_1.save false
        c_2 = publisher.consumers.create!(valid_user_attributes.merge(:email => "jill@hello.com", :name => "Jill Smith", :zip_code => "97226", :mobile_number => "555-555-5555"))
        c_2.activated_at = Time.zone.now - 10.hours
        c_2.activation_code = nil
        c_2.save false

        assert_not_nil c_2.mobile_number, "c_2 should have mobile number"

        publisher.generate_consumers_list(csv = [], :columns => %w{ first_name last_name email mobile_number zip_code created_at })

        assert_equal 3, csv.size, "should only title element plus 2 consumer"
        assert_equal ["first_name", "last_name", "email", "mobile_number", "zip_code", "created_at"], csv[0]
        assert_equal ["Jon", "Smith", "jon@hello.com", "", "97205", c_1.created_at.to_s], csv[1]
        assert_equal ["Jill", "Smith", "jill@hello.com", "555-555-5555", "97226", c_2.created_at.to_s], csv[2]
      end

      test "gogosavings consumer csv with subscribers but no daily deal plus working referral code" do
        publisher = Factory(:publisher, :name => "GoGoSavings", :label => "gogosavings")
        s_1 = publisher.subscribers.create!({:email => "jon@hello.com",
                                             :first_name => "Jon", :last_name => "Smith",
                                             :zip_code => "97205",
                                             :other_options => {:referral_code => "123"}})

        s_2 = publisher.subscribers.create!({:email => "jill@hello.com",
                                             :first_name => "Jill", :last_name => "Smith",
                                             :zip_code => "97226",
                                             :mobile_number => "555-555-5555",
                                             :other_options => {:referral_code => "456"}})

        assert_not_nil s_2.reload.mobile_number, "s_2 should have mobile number"

        publisher.generate_consumers_list(csv = [], :columns => %w{ first_name last_name email mobile_number zip_code referral_code created_at })

        assert_equal 3, csv.size, "should only title element plus 2 consumer"
        assert_equal ["first_name", "last_name", "email", "mobile_number", "zip_code", "referral_code", "created_at"], csv[0]
        csv.sort!
        assert_equal ["Jill", "Smith", "jill@hello.com", "15555555555", "97226", "456", s_2.created_at.to_s], csv[0]
        assert_equal ["Jon", "Smith", "jon@hello.com", "", "97205", "123", s_1.created_at.to_s], csv[1]
      end

      test "entercom-providence with refer a friend information" do
        publisher = Factory(:publisher, :name => "Entercom Providence", :label => "entercom-providence")
        advertiser = publisher.advertisers.create!(:name => "Advertiser")
        daily_deal = advertiser.daily_deals.create!(daily_deal_attributes)

        consumer_with_referrer_code = Factory(:billing_address_consumer,
                                              :publisher => publisher,
                                              :first_name => "John", :last_name => "Smith",
                                              :referrer_code => "123",
                                              :email => "john.smith@somewhere.com"
        )
        daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer_with_referrer_code, :credit_used => 10.0)
        consumer_with_referrer_code.credits.create! :amount => 10.0, :origin => daily_deal_purchase


        consumer_with_referral_code = Factory(:billing_address_consumer, {
            :publisher => publisher,
            :first_name => "Sally", :last_name => "Johnson",
            :referral_code => "123",
            :email => "sally@johnson.com"
        })

        publisher.generate_consumers_list(csv = [], :columns => %w{ name email referred spent_credit }, :allow_duplicates => true)

        assert_equal 3, csv.size, "should have title and two entries"
        header = csv[0]
        assert_equal ["name", "email", "referred", "spent_credit"], header
        actual = csv[1, 2]
        expected = [
          ["John Smith", "john.smith@somewhere.com", nil, BigDecimal.new("10.0")],
          ["Sally Johnson", "sally@johnson.com", true, BigDecimal.new("0.0")]
        ]
        assert_equal_arrays(expected, actual)
      end

      test "novadog consumer csv with subscribers and consumers with some signup discounts" do
        publisher = Factory(:publisher, :name => "Novadog", :label => "novadog", :city => "Portland", :state => "OR", :zip => "97214", :address_line_1 => "3440 SE Tuna Drive")
        discount = publisher.discounts.create!(:code => "MYCODE", :amount => 10.00)
        advertiser = publisher.advertisers.create!(:name => "Advertiser")
        advertiser.daily_deals.create!(daily_deal_attributes)
        c_1 = publisher.consumers.create!(valid_user_attributes.merge(:email => "john@hello.com", :name => "John Smith", :discount_code => discount.code))
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

        publisher.generate_consumers_list(csv = [], :columns => %w{ email name referral_code signup_discount_code }, :allow_duplicates => true)

        assert_equal 5, csv.size, "should only title element plus 3 consumer"
        assert_equal ["email", "name", "referral_code", "signup_discount_code"], csv[0]
        assert_equal ["john@hello.com", "John Smith", nil, "#{discount.code}"], csv[1]
        assert_equal ["jill@hello.com", "Jill Smith", nil, nil], csv[2]
        assert_equal ["john@hello.com", nil, "abc123", nil], csv[3]
        assert_equal ["jordan@somewhere.com", nil, "def246", nil], csv[4]

      end

      test "generate_consumers_list should include preferred_locale when requested" do
        publisher = Factory(:publisher)

        I18n.locale = "zh"
        consumer = Factory(:consumer, :publisher => publisher)
        I18n.locale = "es-MX"
        subscriber = Factory(:subscriber, :publisher => publisher)

        publisher.generate_consumers_list(csv = [], :columns => %w{ preferred_locale })

        assert_equal [["preferred_locale"], ["zh"], ["es-MX"]], csv
      end

      test "inuvo_consumer_csv" do
        publisher = Factory(:publisher, :name => "kowabunga", :label => "kowabunga")
        market_1 = Factory(:market, :name => "Portland, OR", :publisher => publisher)
        market_2 = Factory(:market, :name => "Seattle, WA", :publisher => publisher)
        market_3 = Factory(:market, :name => "Washougal, WA", :publisher => publisher)
        market_4 = Factory(:market, :name => "Stevenson, WA", :publisher => publisher)

        Factory(:market_zip_code, :market => market_1, :zip_code => "97209")
        Factory(:market_zip_code, :market => market_1, :zip_code => "97210")
        Factory(:market_zip_code, :market => market_2, :zip_code => "98115")
        Factory(:market_zip_code, :market => market_2, :zip_code => "98116")
        Factory(:market_zip_code, :market => market_3, :zip_code => "98671")
        Factory(:market_zip_code, :market => market_4, :zip_code => "98672")

        consumer_1 = Factory(:consumer_with_name, valid_user_attributes.merge({
                                                                        :publisher => publisher,
                                                                        :email => "joe@blow.com",
                                                                        :name => "Joe Blow",
                                                                        :zip_code => "98671"
                                                                    }))
        consumer_2 = Factory(:consumer_with_name, valid_user_attributes.merge({
                                                                        :email => "jon@doe.com",
                                                                        :publisher => publisher,
                                                                        :name => "Jon Doe",
                                                                        :zip_code => "97209"
                                                                    }))
        consumer_3 = Factory(:consumer_with_name, valid_user_attributes.merge({
                                                                        :email => "jane@smith.com",
                                                                        :publisher => publisher,
                                                                        :name => "Jane Smith",
                                                                        :zip_code => "98115"
                                                                    }))
        #consumer with different publisher
        consumer_4 = Factory(:consumer_with_name, valid_user_attributes.merge({
                                                                        :email => "joe@smith.com",
                                                                        :publisher => Factory(:publisher),
                                                                        :name => "Joe Smith",
                                                                        :zip_code => "98115"
                                                                    }))

        subscriber_1 = Factory(:subscriber,
                               :publisher => publisher,
                               :email => "john@hello.com",
                               :name => "John Hello",
                               :zip_code => "97210")
        subscriber_2 = Factory(:subscriber,
                               :publisher => publisher,
                               :email => "bill@jones.com",
                               :name => "Bill Jones",
                               :zip_code => "98116")
        subscriber_3 = Factory(:subscriber,
                               :publisher => publisher,
                               :email => "jim@a.com",
                               :name => nil,
                               :zip_code => nil)
        #subscriber with different publisher
        subscriber_4 = Factory(:subscriber,
                               :publisher => Factory(:publisher),
                               :email => "bill@jones.com",
                               :zip_code => "98116")

        publisher.generate_consumers_list(csv = [], :columns => %w{ email name zip market }, :allow_duplicates => true)

        assert_equal ["email", "name", "zip", "market"], csv[0]
        csv.sort!
        assert_equal ["bill@jones.com", "Bill Jones", "98116", "Seattle, WA"], csv[0]
        assert_equal ["jane@smith.com", "Jane Smith", "98115", "Seattle, WA"], csv[2]
        assert_equal ["jim@a.com", nil, nil, nil], csv[3]
        assert_equal ["joe@blow.com", "Joe Blow", "98671", "Washougal, WA"], csv[4]
        assert_equal ["john@hello.com", "John Hello", "97210", "Portland, OR"], csv[5]
        assert_equal ["jon@doe.com", "Jon Doe", "97209", "Portland, OR"], csv[6]

        assert_equal 7, csv.size, "should only title element plus 6 consumer"

        #when allow duplicates is false another method is called for de-duplication so testing it here
        publisher.generate_consumers_list(csv = [], :columns => %w{ email name zip market }, :allow_duplicates => false)

        assert_equal ["email", "name", "zip", "market"], csv[0]
        csv.sort!
        assert_equal ["bill@jones.com", "Bill Jones", "98116", "Seattle, WA"], csv[0]
        assert_equal ["jane@smith.com", "Jane Smith", "98115", "Seattle, WA"], csv[2]
        #nil fields are set to empty when allow duplicates is false - leaving existing behaviour as is
        assert_equal ["jim@a.com", "", "", ""], csv[3]
        assert_equal ["joe@blow.com", "Joe Blow", "98671", "Washougal, WA"], csv[4]
        assert_equal ["john@hello.com", "John Hello", "97210", "Portland, OR"], csv[5]
        assert_equal ["jon@doe.com", "Jon Doe", "97209", "Portland, OR"], csv[6]

        assert_equal 7, csv.size, "should only title element plus 6 consumer"
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
            :password => "secret",
            :password_confirmation => "secret",
            :agree_to_terms => "1"
        }
      end
    end
  end
end
