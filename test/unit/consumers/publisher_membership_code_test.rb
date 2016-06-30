require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Consumers::PublisherMembershipCodeTest
module Consumers
  class PublisherMembershipCodeTest < ActiveSupport::TestCase

    context "membership code assignment" do
      setup do
        publishing_group = Factory(:publishing_group, :require_publisher_membership_codes => true)
        @publisher = Factory(:publisher, :publishing_group => publishing_group)
        @consumer = Factory.build(:consumer, :publisher => @publisher)
        @code = Factory(:publisher_membership_code, :publisher => @publisher, :code => "XYZ")
      end

      should "assignment of a membership code as part of validation" do
        @consumer.publisher_membership_code_as_text = "XYZ"
        assert_nil @consumer.publisher_membership_code
        assert @consumer.valid?, @consumer.errors.full_messages.join(", ")
        assert_equal @code, @consumer.publisher_membership_code
      end

      should "not assign code if textual code is non existent" do
        @consumer.publisher_membership_code_as_text = "ABC"
        assert_nil @consumer.publisher_membership_code
      end

      should "not be valid if membership code text is bogus" do
        @consumer.publisher_membership_code_as_text = "BOG"
        assert @consumer.invalid?
      end

      should "be invalid if publisher_membership_code_as_text is blank" do
        @consumer.publisher_membership_code_as_text = ""
        assert @consumer.invalid?
      end

    end

    context "validates membership code as appropriate" do
      setup do
        @publishing_group = Factory(:publishing_group, :require_publisher_membership_codes => true)
        @publisher = Factory(:publisher, :publishing_group => @publishing_group)
        @code = Factory(:publisher_membership_code, :publisher => @publisher, :code => "1234")
        @consumer = Factory.build(:consumer, :publisher => @publisher)
      end

      should "not require membership code if publishing group does not care" do
        @publishing_group.update_attributes(:require_publisher_membership_codes => false)
        assert_nil @consumer.publisher_membership_code
        assert @consumer.valid?
      end

      should "require membership code if publishing group cares" do
        @consumer.publisher_membership_code_as_text = "656"
        assert_nil @consumer.publisher_membership_code
        assert !@consumer.valid?, @consumer.errors.full_messages.join(", ")
      end

      should "require membership code belongs to consumer's publisher" do
        publisher2 = Factory(:publisher, :publishing_group => @publishing_group)
        code2 = Factory(:publisher_membership_code, :publisher => publisher2, :code => "3456")
        @consumer.publisher_membership_code = code2
        assert !@consumer.valid?
      end

      should "be invalid if the text version is blank" do
        @consumer.publisher_membership_code_as_text = ""
        assert_nil @consumer.publisher_membership_code
        assert !@consumer.valid?, @consumer.errors.full_messages.join(", ")
      end

      should "be invalid if the text version is nil" do
        @consumer.publisher_membership_code_as_text = nil
        assert_nil @consumer.publisher_membership_code
        assert !@consumer.valid?, @consumer.errors.full_messages.join(", ")
      end

    end

    context "switching publishers based on membership code change" do
      setup do
        @publishing_group = Factory(:publishing_group, :require_publisher_membership_codes => true)
        @publisher = Factory(:publisher, :publishing_group => @publishing_group)
        @code = Factory(:publisher_membership_code, :publisher => @publisher, :code => "1234")
        @consumer = Factory.build(:consumer, :publisher => @publisher)
        @publisher2 = Factory(:publisher, :publishing_group => @publishing_group)
        @code2 = Factory(:publisher_membership_code, :publisher => @publisher2, :code => "3456")
      end

      should "switch publisher based on membership code change" do
        assert_equal @publisher, @consumer.publisher
        @consumer.publisher_membership_code_as_text = "3456"
        @consumer.save!
        @consumer.reload
        assert_equal @publisher2, @consumer.publisher
        assert_equal @code2, @consumer.publisher_membership_code
      end

      should "not be valid if new code does not exist" do
        @consumer.publisher_membership_code_as_text = "does not exist"
        assert !@consumer.valid?
      end

      should "not be valid if new code exists but is not in publishing group" do
        pub3 = Factory(:publisher)
        code3 = Factory(:publisher_membership_code, :publisher => pub3, :code => "FOO")
        @consumer.publisher_membership_code_as_text = "FOO"
        assert !@consumer.valid?
      end

    end

    context "publisher_membership_code but no publisher_membeship_code_as_text should be valid" do

      setup do
        @publishing_group = Factory(:publishing_group, :require_publisher_membership_codes => true)
        @publisher = Factory(:publisher, :publishing_group => @publishing_group)
        @code = Factory(:publisher_membership_code, :publisher => @publisher, :code => "1234")
        @consumer = Factory.build(:consumer, :publisher => @publisher, :publisher_membership_code => @code)
      end

      should "be valid with no publisher_membership_code_as_text" do
        @consumer.publisher_membership_code_as_text = ""
        assert @consumer.valid?
      end

    end


  end

end
