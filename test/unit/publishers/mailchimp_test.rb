require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Publishers::MailchimpTest
module Publishers
  class MailchimpTest < ActiveSupport::TestCase

    def setup
      Net::HTTP.stubs(:new).returns(nil)

      @publisher = Factory :publisher
      @publisher.stubs(:mailchimp_api_key).returns("fake_api_key-dc1")
      @publisher.stubs(:mailchimp_list_id).returns("test_list_id")
      @emails = Set.new
      %w(foo bar baz).each do |email_name|
        @emails << email = "#{email_name}@example.com"
        Factory :subscriber, :publisher_id => @publisher.id, :email => email
      end
      %w(spam fnorb).each do |email_name|
        @emails << email = "#{email_name}@example.com"
        Factory :consumer, :publisher_id => @publisher.id, :email => email
      end
    end

    def test_publisher_update_mailchimp_list_no_period
      mailchimp = MailChimp.new :apikey => "fake_api_key-dc1"
      mailchimp.
        expects(:list_batch_subscribe).
        with() { |value| expected_args(value) }.
        returns({ :added => 5, :updated => 0, :errors => [] })

      MailChimp.expects(:new).returns(mailchimp)
      assert_equal({ :added => 5, :updated => 0, :errors => [] }, @publisher.update_mailchimp_list)
    end

    def test_publisher_update_mailchimp_list_no_period_passes_nil_interval
      mailchimp = MailChimp.new :apikey => "fake_api_key-dc1"
      mailchimp.stubs(:list_batch_subscribe).returns({ :added => 5, :updated => 0, :errors => [] })
      @publisher.expects(:signups).with(nil)

      MailChimp.stubs(:new).returns(mailchimp)
      @publisher.update_mailchimp_list
    end

    def test_publisher_update_mailchimp_list_with_period
      mailchimp = MailChimp.new :apikey => "fake_api_key-dc1"
      mailchimp.
        expects(:list_batch_subscribe).
        with() { |value| expected_args(value) }.
        returns({ :added => 5, :updated => 0, :errors => [] })

      MailChimp.expects(:new).returns(mailchimp)
      assert_equal({ :added => 5, :updated => 0, :errors => [] }, @publisher.update_mailchimp_list(:period => 24.hours))
    end

    def test_publisher_update_mailchimp_list_with_period_passes_interval_in_hours
      mailchimp = MailChimp.new :apikey => "fake_api_key-dc1"
      mailchimp.stubs(:list_batch_subscribe).returns({ :added => 5, :updated => 0, :errors => [] })
      @publisher.expects(:signups).with(24)

      MailChimp.stubs(:new).returns(mailchimp)
      @publisher.update_mailchimp_list(:period => 24.hours)
    end

    def test_publisher_update_mailchimp_list_missing_list_id
      @publisher.stubs(:mailchimp_list_id).returns(nil)
      assert_raises(MailChimpConfigurationError) { @publisher.update_mailchimp_list }
    end

    def test_publisher_update_mailchimp_list_missing_api_key
      @publisher.stubs(:mailchimp_api_key).returns(nil)
      assert_raises(MailChimpConfigurationError) { @publisher.update_mailchimp_list }
    end

    def test_publisher_update_mailchimp_list_with_batch_size
      mailchimp = MailChimp.new :apikey => "fake_api_key-dc1"
      mailchimp.expects(:list_batch_subscribe).times(3).returns(
        { :added => 2, :updated => 0, :errors => [] },
        { :added => 2, :updated => 0, :errors => [] },
        { :added => 1, :updated => 0, :errors => [] })
      MailChimp.expects(:new).returns(mailchimp)
      assert_equal({ :added => 5, :updated => 0, :errors => [] }, @publisher.update_mailchimp_list(:period => 24.hours, :batch_size => 2))
    end

    def test_mailchimp_config_for_queenscourier
      publisher = Factory :publisher, :label => "queenscourier"
      assert_equal "ce9eb062c67c01b024254e25d55a2778-us2", publisher.mailchimp_api_key
      assert_equal "0a63b093d2", publisher.mailchimp_list_id
    end

    def test_mailchimp_config_for_pub_without_mailchimp
      publisher = Factory :publisher, :label => "foobar"
      assert_equal nil, publisher.mailchimp_api_key
      assert_equal nil, publisher.mailchimp_list_id
    end

    def test_publisher_mailchimp_lists_by_name
      mailchimp = MailChimp.new :apikey => "fake_api_key-dc1"
      mailchimp.
        expects(:lists_by_name).
        with("Test List").
        returns([MailChimp::List.new(:id => "some-id", :name => "Test List")])

      MailChimp.expects(:new).returns(mailchimp)
      mailing_list = @publisher.mailchimp_lists_by_name("Test List")
      assert mailing_list.is_a?(Array)
    end

    protected

    def expected_args(value)
      value[:id] == "test_list_id" &&
      value[:double_optin] == false &&
      value[:update_existing] == true &&
      Set.new(value[:emails]) == @emails
    end

  end
end
