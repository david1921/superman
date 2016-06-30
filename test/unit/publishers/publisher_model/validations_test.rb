require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::ValidationsTest
module Publishers
  module PublisherModel
    class ValidationsTest < ActiveSupport::TestCase
      test "label validation" do
        Factory(:publisher, :name => "Yahoo!", :label => "yahoo")
        assert !Publisher.new(:name => "Another Yahoo!", :label => "yahoo").valid?, "Validation should catch duplicate label"
        assert !Publisher.new(:name => "Another Yahoo!", :label => "another_yahoo").valid?, "Validation should catch bad label syntax"
        assert Publisher.new(:name => "Another Yahoo!", :label => "another-yahoo").valid?

        Factory(:publisher, :name => "No Label")
        Factory(:publisher, :name => "No Label Again")

        Factory(:publisher, :name => "1010wins", :label => "1010wins")
      end

      test "label required with standard layout" do
        publisher = Publisher.new(:name => "Yahoo!", :theme => "standard")
        publisher.save
        assert publisher.errors.any?, "Should have errors with standard layout and no label"
        assert publisher.errors.on(:label), "Should have error on label with standard layout and no label"

        publisher.label = "yahoo"
        publisher.save
        assert publisher.errors.empty?, "Should have no errors with standard layout and label"
      end

      test "brand txt header validation" do
        assert Publisher.new(:name => "Awesome.com").valid?, "Valid without a TXT brand name"
        assert Publisher.new(:name => "Awesome.com", :brand_txt_header => "").valid?, "Valid with blank TXT brand name"
        assert Publisher.new(:name => "Awesome.com", :brand_txt_header => "X"*15).valid?, "Valid with short TXT brand name"
        assert !Publisher.new(:name => "Awesome.com", :brand_txt_header => "X"*16).valid?, "Invalid with long TXT brand name"
      end

      test "support email address validation" do
        publisher = Publisher.new(:name => "New Publisher", :label => "newpublisher", :support_email_address => "newpublisher")
        assert publisher.invalid?, "Should not be valid with invalid support email"
        assert publisher.errors.on(:support_email_address), "Should have error on email attribute"

        publisher.support_email_address = ""
        assert publisher.valid?, "Should be valid with blank support email"

        publisher.support_email_address = "new@publisher.com"
        assert publisher.valid?, "Should be valid with simple support email"

        publisher.support_email_address = "CouponEvolution.com <new@publisher.com>"
        assert publisher.valid?, "Should be valid with display name and valid email address"

        publisher.support_email_address = "CouponEvolution.com <new>"
        assert !publisher.valid?, "Should not be valid with display name with an invalid email address"
      end

      test "coupon limit validation" do
        publisher = Factory(:publisher, :name => "Publisher", :label => "publisher")
        assert_nil publisher.active_coupon_limit, "Default value for active_coupon_limit"
        assert_nil publisher.active_txt_coupon_limit, "Default value for active_txt_coupon_limit"

        publisher.active_coupon_limit = "1.0"
        assert !publisher.valid?, "Should not be valid with non-integer active_coupon_limit"
        assert publisher.errors.on(:active_coupon_limit), "Should have an error on active_coupon_limit"

        publisher.active_coupon_limit = "-1"
        assert !publisher.valid?, "Should not be valid with negative active_coupon_limit"
        assert publisher.errors.on(:active_coupon_limit), "Should have an error on active_coupon_limit"

        publisher.active_coupon_limit = "0"
        assert publisher.valid?, "Should be valid with zero active_coupon_limit"

        publisher.active_txt_coupon_limit = "1.0"
        assert !publisher.valid?, "Should not be valid with non-integer active_txt_coupon_limit"
        assert publisher.errors.on(:active_txt_coupon_limit), "Should have an error on active_txt_coupon_limit"

        publisher.active_txt_coupon_limit = "-1"
        assert !publisher.valid?, "Should not be valid with negative active_txt_coupon_limit"
        assert publisher.errors.on(:active_txt_coupon_limit), "Should have an error on active_txt_coupon_limit"

        publisher.active_txt_coupon_limit = "0"
        assert publisher.valid?, "Should be valid with zero active_txt_coupon_limit"
      end

      context "email_blast_day_of_week" do

        setup do
          @publisher = Factory.build(:publisher)
        end

        should "allow every day of week" do
          Date::DAYNAMES.each do |day_name|
            @publisher.email_blast_day_of_week = day_name
            assert @publisher.valid?
          end
        end

        should "not allow other days of weeks" do
          @publisher.email_blast_day_of_week = "sat"
          assert @publisher.invalid?
        end

        should "have a useful error message" do
          @publisher.email_blast_day_of_week = "foo"
          assert !@publisher.save
          assert_equal "Email blast day of week is not one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday", @publisher.errors.on(:email_blast_day_of_week)
        end

      end

      context "silverpop weekly email blast validations" do

        setup do
          @publishing_group = Factory(:publishing_group, :silverpop_template_identifier => nil, :silverpop_seed_template_identifier => nil)
          @publisher = Factory.build(:publisher, :publishing_group => @publishing_group)
        end

        should "require the right stuff for contact list weekly send" do
          @publisher.send_weekly_email_blast_to_contact_list = true
          @publisher.email_blast_day_of_week = ""
          @publisher.silverpop_list_identifier = nil
          @publisher.silverpop_template_identifier = nil
          assert !@publisher.valid?
          @publisher.email_blast_day_of_week = "Saturday"
          assert !@publisher.valid?
          @publisher.silverpop_list_identifier = 1234456
          assert !@publisher.valid?
          @publisher.silverpop_template_identifier = 456789
          assert @publisher.valid?, @publisher.errors.full_messages.join(",")
        end

        should "require the right stuff for seed list weekly send" do
          @publisher.send_weekly_email_blast_to_seed_list = true
          @publisher.email_blast_day_of_week = ""
          @publisher.silverpop_seed_database_identifier = nil
          @publisher.silverpop_seed_template_identifier = nil
          assert !@publisher.valid?
          @publisher.email_blast_day_of_week = "Saturday"
          assert !@publisher.valid?
          @publisher.silverpop_seed_database_identifier = 1234456
          assert !@publisher.valid?
          @publisher.silverpop_seed_template_identifier = 456789
          assert @publisher.valid?, @publisher.errors.full_messages.join(",")
        end

        should "should be valid if templates are overridden in publishing group" do
          @publisher.send_weekly_email_blast_to_seed_list = true
          @publisher.email_blast_day_of_week = "Saturday"
          @publisher.silverpop_template_identifier = nil
          @publisher.silverpop_seed_database_identifier = "abcd"
          @publisher.silverpop_template_identifier = nil
          @publisher.silverpop_seed_template_identifier = nil
          @publishing_group.silverpop_template_identifier = "12345"
          @publishing_group.silverpop_seed_template_identifier = "4567"
          assert @publisher.valid?, @publisher.errors.full_messages.join(",")
        end

      end

      context "missing attribute messages" do

        should "have attributes in messages" do
          publisher = Factory(:publisher, :require_daily_deal_category => true)
          deal = Factory.build(:daily_deal, :publisher => publisher, :analytics_category => nil)
          assert deal.invalid?
          assert_equal "Analytics category can't be blank", deal.errors.on(:analytics_category)
        end

      end

      context "payment method" do

        context "cybersource" do
          setup do
            @publisher = Factory.build(:publisher, :payment_method => "cyber_source")
          end

          should "validate that require_billing_address is set" do
            assert_good_value(@publisher, :require_billing_address, true)
            assert_bad_value(@publisher, :require_billing_address, false)

            @publisher.save
            assert_match /^Require billing address must be set/, @publisher.errors.on(:require_billing_address)
          end
        end

        context "non-cybersource method" do
          setup do
            @publisher = Factory(:publisher, :payment_method => "credit")
          end

          should "not validate that require_billing_address is set" do
            assert_good_value(@publisher, :require_billing_address, true)
            assert_good_value(@publisher, :require_billing_address, false)
          end
        end

      end

      context "main publisher" do
        should "allow only one publisher to be the main publisher" do
          publishing_group = Factory(:publishing_group)
          main_publisher = Factory(:publisher, :publishing_group => publishing_group, :main_publisher => true)
          other_main_publisher = Factory.build(:publisher, :publishing_group => publishing_group, :main_publisher => true)
          publishing_group.reload
          assert other_main_publisher.invalid?
          assert_equal "Publishing group can't have more than one main publisher", other_main_publisher.errors.on(:main_publisher)
        end

        should "not allow main publisher to be enabled if there is no publishing group" do
          publisher = Factory.build(:publisher, :publishing_group => nil, :main_publisher => true)
          assert publisher.invalid?
          assert_equal "Publisher must be in a publishing group to be a main publisher", publisher.errors.on(:main_publisher)
        end

        should "allow the main publisher to be saved if it is already the main publisher" do
          publishing_group = Factory(:publishing_group)
          main_publisher = Factory(:publisher, :publishing_group => publishing_group, :main_publisher => true)
          publishing_group.reload
          assert main_publisher.update_attributes(:main_publisher => true), main_publisher.errors.full_messages.join(",")
        end
      end
    end
  end
end
