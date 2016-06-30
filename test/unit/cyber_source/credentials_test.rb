require File.dirname(__FILE__) + "/../../test_helper"

# hydra class CyberSource::CredentialsTest

module CyberSource
  class CredentialsTest < ActiveSupport::TestCase
    context "after init with some credentials" do
      setup do
        @instant = "Jan 15, 2012 12:34:56 UTC"
        CyberSource::Credentials.init({
          :label => "one",
          :merchant_id => "merchant_1",
          :shared_secret => "aaaa",
          :serial_number => "1111",
          :soap_username => "merchant_1",
          :soap_password => "xxxxxx",
          :stopped_at => @instant
        }, {
          :label => "one",
          :merchant_id => "merchant_1",
          :shared_secret => "bbbb",
          :serial_number => "2222",
          :soap_username => "merchant_1",
          :soap_password => "yyyyyy",
          :started_at => @instant
        }, {
          :label => "two",
          :merchant_id => "merchant_2",
          :shared_secret => "cccc",
          :serial_number => "3333",
          :soap_username => "merchant_2",
          :soap_password => "zzzzzz"
        })
      end
      
      should "find active credentials with one known label and one nil label" do
        credentials = CyberSource::Credentials.find("one", nil)
        assert_not_nil credentials, "Should find credentials with a known label"
        assert_equal "merchant_1", credentials.merchant_id
        assert_equal "2222", credentials.serial_number
        assert_equal "merchant_1", credentials.soap_username
        assert_equal "yyyyyy", credentials.soap_password
      end

      should "find active credentials with two known labels" do
        credentials = CyberSource::Credentials.find("one", "two")
        assert_not_nil credentials, "Should find credentials with known labels"
        assert_equal "merchant_1", credentials.merchant_id
        assert_equal "2222", credentials.serial_number
        assert_equal "merchant_1", credentials.soap_username
        assert_equal "yyyyyy", credentials.soap_password
      end

      should "raise with one unknown and one nil label" do
        assert_raise RuntimeError do
          credentials = CyberSource::Credentials.find("foo", nil)
        end
      end
      
      should "find active credentials when the time option is specified" do
        credentials = CyberSource::Credentials.find("one", "two", :time => Time.parse(@instant) - 1.second)
        assert_not_nil credentials, "Should find credentials with known labels"
        assert_equal "merchant_1", credentials.merchant_id
        assert_equal "1111", credentials.serial_number
        assert_equal "merchant_1", credentials.soap_username
        assert_equal "xxxxxx", credentials.soap_password
      end
      
      should "return a digest from the signature instance method" do
        credentials = CyberSource::Credentials.find("one", nil)
        assert_equal "GHiFh3jJ+eVUGqVlDMd345fxKv8=", credentials.signature("somedata")
      end
    end

    context "after load with some credentials" do
      setup do
        CyberSource::Credentials.load File.expand_path("test/config/cyber_source", Rails.root)
        @instant = "Jan 15, 2012 12:34:56 UTC"
      end
      
      should "find active credentials with one known label and one nil label" do
        credentials = CyberSource::Credentials.find("one", nil)
        assert_not_nil credentials, "Should find credentials with a known label"
        assert_equal "merchant_1", credentials.merchant_id
        assert_equal "2222", credentials.serial_number
        assert_equal "merchant_1", credentials.soap_username
        assert_equal "yyyyyy", credentials.soap_password
      end

      should "find active credentials with two known labels" do
        credentials = CyberSource::Credentials.find("one", "two")
        assert_not_nil credentials, "Should find credentials with known labels"
        assert_equal "merchant_1", credentials.merchant_id
        assert_equal "2222", credentials.serial_number
        assert_equal "merchant_1", credentials.soap_username
        assert_equal "yyyyyy", credentials.soap_password
      end

      should "raise with one unknown and one nil label" do
        assert_raise RuntimeError do
          credentials = CyberSource::Credentials.find("foo", nil)
        end
      end
      
      should "find active credentials when the time option is specified" do
        credentials = CyberSource::Credentials.find("one", "two", :time => Time.parse(@instant) - 1.second)
        assert_not_nil credentials, "Should find credentials with known labels"
        assert_equal "merchant_1", credentials.merchant_id
        assert_equal "1111", credentials.serial_number
        assert_equal "merchant_1", credentials.soap_username
        assert_equal "xxxxxx", credentials.soap_password
      end
      
      should "find credentials active at the current time when the time option is not specified" do
        Timecop.freeze Time.parse(@instant) - 1.second do
          credentials = CyberSource::Credentials.find("one", "two")
          assert_not_nil credentials, "Should find credentials with known labels"
          assert_equal "merchant_1", credentials.merchant_id
          assert_equal "1111", credentials.serial_number
          assert_equal "merchant_1", credentials.soap_username
          assert_equal "xxxxxx", credentials.soap_password
        end
      end
      
      should "return a digest from the signature instance method" do
        credentials = CyberSource::Credentials.find("one", nil)
        assert_equal "GHiFh3jJ+eVUGqVlDMd345fxKv8=", credentials.signature("somedata")
      end
    end
  end
end
