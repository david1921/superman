require File.dirname(__FILE__) + "/../../test_helper"

class Consumers::ZipCodeTest < ActiveSupport::TestCase

  test "create with zip code required and no zip code present" do
    publisher =  Factory(:publisher)
    consumer  = Factory.build(:consumer, :publisher => publisher, :zip_code_required => true )
    assert !consumer.valid?
  end

  test "create with zip code required and valid zip code present" do
    publisher = Factory(:publisher)
    consumer  = Factory.build(:consumer, :publisher => publisher, :zip_code_required => true, :zip_code => '97206' )
    assert consumer.valid?
  end

  test "create with zip code required and invalid zip code present" do
    publisher = Factory(:publisher)
    consumer  = Factory.build(:consumer, :publisher => publisher, :zip_code_required => true, :zip_code => '9720' )
    assert !consumer.valid?
    consumer  = Factory.build(:consumer, :publisher => publisher, :zip_code_required => true, :zip_code => 'abcde' )
    assert !consumer.valid?
    consumer  = Factory.build(:consumer, :publisher => publisher, :zip_code_required => true, :zip_code => '' )
    assert !consumer.valid?
  end

  test "create with invalid CA zip code" do
    ca = Country.find_or_create_by_code('CA')
    publisher = Factory(:publisher,
                        :require_billing_address => true,
                        :countries => [ca])
    consumer = Factory.build(
      :billing_address_consumer,
      :publisher => publisher,
      :country_code => 'CA'
    )

    valid_us_codes = %w{ 11215 92708 90210 }
    invalid_can_codes = %w{ K110BB X122BB ABCD1E }
    valid_can_codes = %w{ K1A0B1 T2B1C2 B3C2D3 }

    (valid_us_codes + invalid_can_codes).each do |invalid|
      consumer.zip_code = invalid
      assert !consumer.valid?, "should be invalid but is valid: #{invalid}"
      assert consumer.errors.on(:zip_code).present?
    end

    valid_can_codes.each do |valid|
      consumer.zip_code = valid
      assert consumer.valid?
    end
  end

  test "US zips with 6 digits are not valid" do
    consumer = Factory.build(:consumer, :country_code  => "US", :zip_code => "999999")
    consumer.zip_code_required = true
    assert !consumer.valid?
  end

  context "consumers and their zip codes" do

    context "in the united states of amerika" do
      setup do
        @consumer = Factory.create(:consumer)
        @consumer.zip_code = nil
        @consumer.country_code = "US"
        @consumer.zip_code_required = true
      end

      should "have valid zips sometimes" do
        @consumer.zip_code = "97214"
        assert @consumer.valid?
      end

      should "be invalid if too long" do
        @consumer.zip_code = "972145"
        assert !@consumer.valid?
      end

      should "be invalid if too short" do
        @consumer.zip_code = "9721"
        assert !@consumer.valid?
      end

      should "be invalid if there is no zip" do
        assert !@consumer.valid?
      end

    end

  end

  context "zip_code_required?" do

    setup do
      @consumer = Factory.create(:consumer)
    end

    should "not be dependent on whether there is a zip_code in the record" do
      assert_nil @consumer.zip_code_required?
      @consumer.zip_code = "97214"
      assert_nil @consumer.zip_code_required?
      @consumer.zip_code_required = true
      assert @consumer.zip_code_required?
    end

    should "be invalid regardless of whether it is required" do
      @consumer.zip_code = "12039120349124"
      @consumer.zip_code_required = false
      assert !@consumer.valid?
      @consumer.zip_code_required = nil
      assert !@consumer.valid?
      @consumer.zip_code_required = true
      assert !@consumer.valid?
    end

    should "be valid regardless of whether it is required" do
      @consumer.zip_code = "97214"
      @consumer.zip_code_required = nil
      assert @consumer.valid?
      @consumer.zip_code_required = false
      assert @consumer.valid?
      @consumer.zip_code_required = true
      assert @consumer.valid?, "zip_code: #{@consumer.zip_code}"
    end

    should "be invalid if blank when required" do
      @consumer.zip_code = ""
      @consumer.zip_code_required = true
      assert !@consumer.valid?
    end

  end

end
