require File.dirname(__FILE__) + "/../../../../../test_helper"
$: << File.join(APP_ROOT, "lib")
require "analog/third_party_api/coolsavings/member_url.rb"

class MemberUrlTest < Test::Unit::TestCase

  context "construction" do

    should "be able to make a member url and get its bits back" do
      attrs = { "GENDER" => "F", "HAIR" => "brown" }
      url = Analog::ThirdPartyApi::Coolsavings::MemberUrl.new("yo@yahoo.com", "mypword", attrs)
      assert_equal "yo@yahoo.com", url.email
      assert_equal "mypword", url.md5password
      assert_equal attrs, url.attributes
    end

    should "raise if email is blank" do
      assert_raises ArgumentError do
        Analog::ThirdPartyApi::Coolsavings::MemberUrl.new("", "mypword")
      end
    end

    should "raise if pword is blank" do
      assert_raises ArgumentError do
        Analog::ThirdPartyApi::Coolsavings::MemberUrl.new("yo@yahoo.com", nil)
      end
    end

  end

  context "export" do

    should "take all the bits and make the right url" do
      AppConfig.stubs(:coolsavings => { :partner_id => 1, :api_key => "456" })
      url = Analog::ThirdPartyApi::Coolsavings::MemberUrl.new("yo@yahoo.com","topsecret")
      assert_equal "/member_export?PARTNER=1&KEY=456&EMAIL=yo@yahoo.com&PASSWORD=topsecret", url.export_path
    end

  end

  context "import" do

    should "take all the bits and make the right url" do
      AppConfig.stubs(:coolsavings => { :partner_id => 1, :api_key => "456" })
      attrs = ActiveSupport::OrderedHash.new
      attrs["FOO"] = "fooness"
      attrs["BAR"] = "barness"
      attrs["EMAIL"] = "should be removed"
      attrs["GENDER"] = "f"
      url = Analog::ThirdPartyApi::Coolsavings::MemberUrl.new("yo@yahoo.com", "topsecret", attrs)
      assert_equal "/member_import?PARTNER=1&KEY=456&EMAIL=yo@yahoo.com&PASSWORD=topsecret&FOO=fooness&BAR=barness&GENDER=f", url.import_path
    end

  end

  context "query_string_from_attributes" do

    should "take attributes and makes a query string" do
      attrs = ActiveSupport::OrderedHash.new
      attrs["EMAIL"] = "yo@yahoo.com"
      attrs["PASSWORD"] = "topsecret"
      attrs["FOO"] = "fooness"
      url = Analog::ThirdPartyApi::Coolsavings::MemberUrl.new("yo@yahoo.com", "topsecret", attrs)
      assert_equal "&PASSWORD=topsecret&FOO=fooness", url.query_string_from_attributes
    end

    should "leave out empty attributes when making query string" do
      attrs = ActiveSupport::OrderedHash.new
      attrs["EMAIL"] = "yo@yahoo.com"
      attrs["PASSWORD"] = "topsecret"
      attrs["FOO"] = ""
      url = Analog::ThirdPartyApi::Coolsavings::MemberUrl.new("yo@yahoo.com", "topsecret", attrs)
      assert_equal "&PASSWORD=topsecret", url.query_string_from_attributes
    end

  end

end
