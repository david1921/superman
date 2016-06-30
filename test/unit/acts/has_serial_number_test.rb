require File.dirname(__FILE__) + "/../../test_helper"

class HasSerialNumberTest < ActiveSupport::TestCase

  class ThingWithSerialNumber
    def self.before_validation_on_create(arg); end
    def self.validates_each(arg); end
    def self.validates_immutability_of(arg); end
    include HasSerialNumber
    def new_record?
      true
    end
  end

  class DispenseFromAListOfSerialNumbers < ThingWithSerialNumber
    alias_method :real_random_serial_number, :random_serial_number
    attr_reader :times_random_serial_number_was_called
    def initialize(serial_numbers_to_dispense)
      @serial_numbers_to_dispense = serial_numbers_to_dispense
      @times_random_serial_number_was_called = 0
    end
    def random_serial_number
      @times_random_serial_number_was_called += 1
      @serial_numbers_to_dispense.shift || real_random_serial_number
    end
  end

  class SameSerialNumberEveryTime < ThingWithSerialNumber
    attr_reader :times_random_serial_number_was_called
    def initialize(serial_number_to_dispense)
      @serial_number_to_dispense = serial_number_to_dispense
      @times_random_serial_number_was_called = 0
    end
    def random_serial_number
      @times_random_serial_number_was_called += 1
      @serial_number_to_dispense
    end
  end

  context "serial number generation" do
    setup do
      @thing_with_serial_number = ThingWithSerialNumber.new
    end
    should "be in the proper format" do
      assert_match /\d{4}-\d{4}/, @thing_with_serial_number.random_serial_number
    end
    should "use the same blowfish instance for encryption" do
      assert_same ::HasSerialNumber.blowfish, ::HasSerialNumber.blowfish
    end
    should "be pretty darn random" do
      unique_serial_numbers = Set.new
      (1..100).each do |n|
        unique_serial_numbers << @thing_with_serial_number.random_serial_number
      end
      assert unique_serial_numbers.size >= 99, "Astronomically implausible outcome. Size was: #{unique_serial_numbers.size}. Should have been 100."
    end
  end

  context "unique_across_certificates_using_internal_serial_numbers?" do
    setup do
      @thing_with_serial_number = ThingWithSerialNumber.new
    end

    context "no deal certificates exist (or very few)" do
      should "be unique" do
        assert @thing_with_serial_number.unique_across_certificates_using_internal_serial_numbers?("1234-5678")
      end
    end

    context "one deal certificate exists" do
      setup do
        Factory(:daily_deal_certificate).update_attribute(:serial_number, "1234-5678")
      end

      should "be unique for non-matching serial-number" do
        assert @thing_with_serial_number.unique_across_certificates_using_internal_serial_numbers?("2345-6789")
      end
      should "not be unique for matching serial-number" do
        assert !@thing_with_serial_number.unique_across_certificates_using_internal_serial_numbers?("1234-5678")
      end
    end

    context "one gift certificate purchase exists" do
      setup do
        Factory(:purchased_gift_certificate).update_attribute(:serial_number, "1234-5678")
      end

      should "be unique for non-matching serial-number" do
        assert @thing_with_serial_number.unique_across_certificates_using_internal_serial_numbers?("2345-6789")
      end
      should "not be unique for matching serial-number" do
        assert !@thing_with_serial_number.unique_across_certificates_using_internal_serial_numbers?("1234-5678")
      end
    end

    context "both a deal certificate and a gift certificate purchase exist" do
      setup do
        Factory(:daily_deal_certificate).update_attribute(:serial_number, "1234-5678")
        Factory(:purchased_gift_certificate).update_attribute(:serial_number, "2345-6789")
      end

      should "be unique for non-matching serial-number" do
        assert @thing_with_serial_number.unique_across_certificates_using_internal_serial_numbers?("9876-5432")
      end
      should "not be unique for matching serial-number" do
        assert !@thing_with_serial_number.unique_across_certificates_using_internal_serial_numbers?("1234-5678")
        assert !@thing_with_serial_number.unique_across_certificates_using_internal_serial_numbers?("2345-6789")
      end

    end
  end

  context "generating simple uniqueness" do
    setup do
      DailyDealCertificate.destroy_all
      PurchasedGiftCertificate.destroy_all
      @thing_with_serial_number = ThingWithSerialNumber.new
    end

    should "get unique random serial number in case where there are no serial numbers in the db" do
      assert_match /\d{4}-\d{4}/, @thing_with_serial_number.unique_random_serial_number
    end
  end

  context "retrying for uniqueness" do
    setup do
      DailyDealCertificate.destroy_all
      PurchasedGiftCertificate.destroy_all
      (0..9).each do |n|
        Factory(:daily_deal_certificate).update_attribute(:serial_number, "1234-567#{n}")
        Factory(:purchased_gift_certificate).update_attribute(:serial_number, "2345-678#{n}")
      end
      @serial_numbers = DailyDealCertificate.all.map(&:serial_number) + PurchasedGiftCertificate.all.map(&:serial_number)
      @thing_with_serial_number = DispenseFromAListOfSerialNumbers.new(@serial_numbers.dup)
    end

    should "have the right serial numbers set up" do
      assert_equal 20, @serial_numbers.size
      assert_equal "1234-5670", @thing_with_serial_number.random_serial_number
      assert_equal "1234-5671", @thing_with_serial_number.random_serial_number
    end

    should "keep retrying until unique serial_number is found" do
      assert !@serial_numbers.include?(@thing_with_serial_number.unique_random_serial_number)
      assert_equal 21, @thing_with_serial_number.times_random_serial_number_was_called
    end
  end

  context "retrying for uniqueness but not forever" do
    setup do
      Factory(:daily_deal_certificate).update_attribute(:serial_number, "1234-5678")
      @thing_with_serial_number = SameSerialNumberEveryTime.new("1234-5678")
    end

    should "have the right serial numbers set up" do
      assert_equal "1234-5678", @thing_with_serial_number.random_serial_number
      assert_equal "1234-5678", @thing_with_serial_number.random_serial_number
      assert_equal "1234-5678", @thing_with_serial_number.random_serial_number
    end

    should "raise when attempt limit is reached" do
      assert_raise RuntimeError do
        @thing_with_serial_number.unique_random_serial_number
      end
      assert_equal 100, @thing_with_serial_number.times_random_serial_number_was_called
    end
  end

end

