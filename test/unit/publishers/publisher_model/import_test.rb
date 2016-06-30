require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::ImportTest
module Publishers
  module PublisherModel
    class ImportTest < ActiveSupport::TestCase
      test "publisher.import_subscriber_emails_from_file should raise an ArgumentError when passed a non-existent file" do
        publisher = Factory.create(:publisher, :label => "mytestpub")
        assert_raise(ArgumentError) { publisher.import_subscriber_emails_from_file "doesnt_exist.txt" }
      end

      test "publisher.import_subscriber_emails_from_file should add a Subscriber row for each email in the input file" do
        publisher = Factory.create(:publisher, :label => "mytestpub")
        subscribers_filename = File.join(Rails.root, "test/data/four-subscribers.txt")
        assert_nil publisher.subscribers.find_by_email("first@example.com")
        assert_difference 'publisher.subscribers.count', 4 do
          publisher.import_subscriber_emails_from_file(subscribers_filename)
        end
        assert_not_nil publisher.subscribers.find_by_email("first@example.com")
      end

      test "publisher.import_subscriber_emails_from_file ignore all lines that don't look like email addresses" do
        publisher = Factory.create(:publisher, :label => "mytestpub")
        subscribers_filename = File.join(Rails.root, "test/data/five-subscribers-and-some-junk.txt")
        assert_nil publisher.subscribers.find_by_email("fifth@example.com")
        assert_difference 'publisher.subscribers.count', 5 do
          publisher.import_subscriber_emails_from_file(subscribers_filename)
        end
        assert_not_nil publisher.subscribers.find_by_email("fifth@example.com")
      end

      test "publisher.import_subscriber_emails_from_file should return a hash that includes :num_added" do
        publisher = Factory.create(:publisher, :label => "mytestpub")
        subscribers_filename = File.join(Rails.root, "test/data/five-subscribers-and-some-junk.txt")
        result = publisher.import_subscriber_emails_from_file(subscribers_filename)
        assert result.has_key? :num_added
        assert_equal 5, result[:num_added]
      end

      test "publisher.import_subscriber_emails_from_file should return a hash that includes :errors" do
        publisher = Factory.create(:publisher, :label => "mytestpub")
        subscribers_filename = File.join(Rails.root, "test/data/two-subscribers-and-one-bad-email.txt")
        result = nil
        assert_difference "publisher.subscribers.count", 2 do
          result = publisher.import_subscriber_emails_from_file(subscribers_filename)
        end
        assert result.has_key? :errors
        assert_equal ["bro ken@example.com"], result[:errors]
      end

      test "publisher.import_subscriber_emails_from_csv should raise an ArgumentError when passed a non-existent or non-csv file" do
        publisher = Factory.create(:publisher, :label => "mytestpub")
        assert_raise(ArgumentError) { publisher.import_subscriber_emails_from_csv "doesnt_exist.csv" }
        assert_raise(ArgumentError) { publisher.import_subscriber_emails_from_csv "test/data/four-subscribers.txt" }
      end

      test "publisher.import_subscriber_emails_from_csv should add subscribers from a CSV files" do
        publisher = Factory.create(:publisher)
        subscribers_filename = File.join(Rails.root, "test/data/four-subscribers.csv")
        result = nil
        assert_difference 'publisher.subscribers.count', 4 do
          result = publisher.import_subscriber_emails_from_csv(subscribers_filename)
        end
        subscriber1 = publisher.subscribers.find_by_email("foo@example.com")
        assert_not_nil subscriber1
        assert_equal "foo@example.com", subscriber1.email
        assert_equal "Bob", subscriber1.first_name
        assert_equal "Smith", subscriber1.last_name
        assert_equal "123 Foo Drive", subscriber1.address_line_1
        assert_equal nil, subscriber1.address_line_2
        assert_equal "Seattle", subscriber1.city
        assert_equal "WA", subscriber1.state
        assert_equal "98585", subscriber1.zip_code

        assert_equal [], result[:errors]
      end

      test "publisher.import_subscriber_emails_from_csv should return a hash that includes :errors when importing CSV" do
        publisher = Factory.create(:publisher)
        subscribers_filename = File.join(Rails.root, "test/data/two-subscribers-and-one-bad-email.csv")
        result = nil
        assert_difference "publisher.subscribers.count", 2 do
          result = publisher.import_subscriber_emails_from_csv(subscribers_filename)
        end
        assert result.has_key? :errors
        assert_equal ["bro ken@example.com"], result[:errors]
      end

      test "publisher.import_subscriber_emails_from_csv should return a hash that includes :num_added when importing CSV" do
        publisher = Factory.create(:publisher)
        subscribers_filename = File.join(Rails.root, "test/data/four-subscribers.csv")
        result = publisher.import_subscriber_emails_from_csv(subscribers_filename)
        assert result.has_key? :num_added
        assert_equal 4, result[:num_added]
      end

      test "publisher.import_subscriber_emails_from_csv should be able to ignore invalid zip codes" do
        publisher = Factory.create(:publisher)
        subscribers_filename = File.join(Rails.root, "test/data/one-bad-email-and-one-bad-zip.csv")
        result = publisher.import_subscriber_emails_from_csv(subscribers_filename, :ignore_invalid_zip_codes => true)
        assert result.has_key? :num_added
        assert_equal 2, result[:num_added]

        subscriber1 = publisher.subscribers.find_by_email("foo@example.com")
        assert_equal "foo@example.com", subscriber1.email
        assert_equal nil, subscriber1.zip_code
      end

    end
  end
end