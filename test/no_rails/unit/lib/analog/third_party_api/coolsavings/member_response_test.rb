require File.dirname(__FILE__) + "/../../../../../test_helper"
$: << File.join(APP_ROOT, "lib")
require "analog/third_party_api/coolsavings/member_response.rb"
require "analog/third_party_api/coolsavings/invalid_response.rb"
require "analog/third_party_api/coolsavings/error_response.rb"

class MemberResponseTest < Test::Unit::TestCase

  context "construction" do
    should "save response body" do
      response = Analog::ThirdPartyApi::Coolsavings::MemberResponse.new("this is the body")
      assert_equal "this is the body", response.raw
    end
  end

  context "invalid responses" do
    should "raise on random string" do
      assert_raises_invalid_response_error("random string")
    end
    should "raise on right form but wrong details" do
      assert_raises_invalid_response_error("2 OK\nFOO=bar")
      assert_raises_invalid_response_error("2 ERRORS\nFOO=bar")
      assert_raises_invalid_response_error("2 OK\nFOO=bar")
      assert_raises_invalid_response_error("0 ERRORS\nFOO=bar")
      assert_raises_invalid_response_error("1 OK\nFOO=bar")
    end
  end

  context "error responses" do
    should "raise a response error" do
      raw_response = "1 ERRORS\nNeed more mojo\nLess fuzz"
      response = Analog::ThirdPartyApi::Coolsavings::MemberResponse.new(raw_response)
      begin
        response.parse!
      rescue Analog::ThirdPartyApi::Coolsavings::ErrorResponse => e
        assert_equal ["Need more mojo", "Less fuzz"], e.errors
      end
    end
  end

  context "good responses" do

    should "not raise anything and have the right attributes" do
      raw_response = "0 OK\nFOO=bar\nGENDER=MALE\nYUCK=Yum\n"
      response = Analog::ThirdPartyApi::Coolsavings::MemberResponse.new(raw_response)
      response.parse!
      assert_equal "0 OK", response.status_line
      assert_equal 4, response.lines.size
      assert_equal ["FOO=bar", "GENDER=MALE", "YUCK=Yum"], response.data_lines
      assert_equal 3, response.attributes.size
      assert_equal "bar", response.attributes["FOO"]
      assert_equal "MALE", response.attributes["GENDER"]
      assert_equal "Yum", response.attributes["YUCK"]
    end

    should "deal with a line without an equals stuff in it" do
      raw_response = "0 OK\nFOO=bar\nGENDERMALE\nYUCK=Yum\n"
      response = Analog::ThirdPartyApi::Coolsavings::MemberResponse.new(raw_response)
      assert_equal 3, response.attributes.size
      assert_equal "", response.attributes["GENDERMALE"]
    end

    should "handle key with empty value" do
      raw_response = "0 OK\nFOO=bar\nGENDER=\nYUCK=Yum\n"
      response = Analog::ThirdPartyApi::Coolsavings::MemberResponse.new(raw_response)
      assert_equal 3, response.attributes.size
      assert_equal "", response.attributes["GENDER"]
    end

  end

  def assert_raises_invalid_response_error(raw_response)
    response = Analog::ThirdPartyApi::Coolsavings::MemberResponse.new(raw_response)
    assert_raises Analog::ThirdPartyApi::Coolsavings::InvalidResponse do
      response.parse!
    end
  end

end
