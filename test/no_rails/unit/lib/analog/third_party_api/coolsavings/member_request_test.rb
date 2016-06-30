require File.dirname(__FILE__) + "/../../../../../test_helper"
$: << File.join(APP_ROOT, "lib")
require "analog/third_party_api/coolsavings/member_url.rb"
require "analog/third_party_api/coolsavings/member_request.rb"

class MemberReqestTest < Test::Unit::TestCase
  context "construction" do
    should "set the member url" do
      url = Analog::ThirdPartyApi::Coolsavings::MemberUrl.new("yo@yahoo.com", "foots")
      assert_equal url, Analog::ThirdPartyApi::Coolsavings::MemberRequest.new(url).url
    end
  end
end
