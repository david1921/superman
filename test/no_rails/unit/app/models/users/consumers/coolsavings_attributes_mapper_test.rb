require File.dirname(__FILE__) + "/../../../models_helper"

class AttributesMapperTest < Test::Unit::TestCase

  context "map" do

    should "map keys empty mapping" do
      mapper = Analog::ThirdPartyApi::Coolsavings::AttributesMapper.new
      in_hash = { "FOO" => "foo", "BAR" => "bar", "CAR" => "car" }
      mapping = {}
      assert_equal({}, mapper.map(in_hash, mapping))
    end

    should "map keys no overlap" do
      mapper = Analog::ThirdPartyApi::Coolsavings::AttributesMapper.new
      in_hash = { "FOO" => "foo", "BAR" => "bar", "CAR" => "car" }
      mapping = { "ZOO" => "zoo", "ALPHA" => "alpha" }
      assert_equal({}, mapper.map(in_hash, mapping))
    end

    should "map some overlap" do
      mapper = Analog::ThirdPartyApi::Coolsavings::AttributesMapper.new
      in_hash = { "FOO" => "foo", "BAR" => "bar", "CAR" => "car" }
      mapping = { "FOO" => "NEW_FOO", "CAR" => "NEW_CAR" }
      assert_equal({ "NEW_FOO" => "foo", "NEW_CAR" => "car" }, mapper.map(in_hash, mapping))
    end

    should "map all overlapping but not others" do
      mapper = Analog::ThirdPartyApi::Coolsavings::AttributesMapper.new
      in_hash = { "FOO" => "foo", "BAR" => "bar", "CAR" => "car" }
      mapping = { "FOO" => "NEW_FOO", "CAR" => "NEW_CAR", "YURGLE" => "NEW_YURGLE" }
      assert_equal({ "NEW_FOO" => "foo", "NEW_CAR" => "car" }, mapper.map(in_hash, mapping))
    end

  end

  context "mapping back and forth" do

    setup do
      @coolsavings_attributes = {
        "EMAIL" => "yo@yahoo.com",
        "STREET" => "666 Happiness Lane",
        "CITY" => "Nowheresville",
        "STATE" => "WA",
        "COUNTRY" => "US",
        "FNAME" => "Foo",
        "LNAME" => "Barinski",
        "GENDER" => "M"
      }
      @analog_attributes = {
        "email" => "yo@yahoo.com",
        "address_line_1" => "666 Happiness Lane",
        "billing_city" => "Nowheresville",
        "state" => "WA",
        "country_code" => "US",
        "gender" => "M",
        "first_name" => "Foo",
        "last_name" => "Barinski"
      }
      @extra_garbage = {
        "SOME" => "BS",
        "MEMBER_SINCE" => "ignored",
        "referral_code" => "12345"
      }
    end

    should "map to analog" do
      source_hash = @coolsavings_attributes.merge(@extra_garbage)
      expected_hash = @analog_attributes
      assert_equal expected_hash, Analog::ThirdPartyApi::Coolsavings::AttributesMapper.new.map_to_analog(source_hash)
    end

    should "map to coolsavings" do
      source_hash = @analog_attributes.merge(@extra_garbage)
      expected_hash = @coolsavings_attributes
      assert_equal expected_hash, Analog::ThirdPartyApi::Coolsavings::AttributesMapper.new.map_to_coolsavings(source_hash)
    end

  end

end

