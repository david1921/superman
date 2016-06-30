require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::ZipCodeTest
module Publishers
  module PublisherModel
    class ZipCodeTest < ActiveSupport::TestCase

      test "publisher must belong to a publishing group" do
        pub_group = Factory :publishing_group
        pub_with_group = Factory :publisher, :publishing_group_id => pub_group.id
        pub_without_group = Factory :publisher, :publishing_group_id => nil

        pub_zip_code_with_group = Factory.build(:publisher_zip_code, :publisher_id => pub_with_group.id)
        assert pub_with_group.valid?

        pub_zip_code_without_group = Factory.build(:publisher_zip_code, :publisher_id => pub_without_group.id)
        assert !pub_zip_code_without_group.valid?
        assert_equal "publisher must be associated with a publishing group",
                     pub_zip_code_without_group.errors.on_base
      end

      test "Publisher#zip_codes should return all the zip codes associated with a publisher" do
        publisher = Factory :publisher, :label => "wikileaks"
        other_publisher = Factory :publisher

        assert_nil publisher.zip_codes

        Factory :publisher_zip_code, :publisher_id => publisher.id, :zip_code => "12345"
        publisher.reload
        assert_equal ["12345"], publisher.zip_codes

        Factory :publisher_zip_code, :publisher_id => publisher.id, :zip_code => "90210"
        Factory :publisher_zip_code, :publisher_id => other_publisher.id

        publisher.reload
        assert_equal ["12345", "90210"], publisher.zip_codes
      end

      test "should return publisher for zip code" do
        pub_group = Factory :publishing_group
        publisher1 = Factory :publisher, :publishing_group_id => pub_group.id
        publisher2 = Factory :publisher, :publishing_group_id => pub_group.id

        Factory :publisher_zip_code, :publisher_id => publisher1.id, :zip_code => "12345"
        Factory :publisher_zip_code, :publisher_id => publisher1.id, :zip_code => "90210"
        Factory :publisher_zip_code, :publisher_id => publisher2.id, :zip_code => "98671"

        assert_equal publisher1, PublisherZipCode.find_by_zip_code("90210").publisher
      end

    end
  end
end