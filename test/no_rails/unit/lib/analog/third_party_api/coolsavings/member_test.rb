require File.dirname(__FILE__) + "/../../../../../test_helper"
require 'string_extensions'
require "analog/third_party_api/coolsavings/member.rb"
require 'digest/md5'

class MemberTest < Test::Unit::TestCase

  def setup
    AppConfig.stubs(:coolsavings => { :partner_id => 2, :api_key => "3242352" })
  end

  context "creation" do

    should "store instance variables on creation" do
      consumer = Analog::ThirdPartyApi::Coolsavings::Member.new("yo@example.com", "md5pass")
      assert_equal "yo@example.com", consumer.email
      assert_equal "md5pass", consumer.md5password
    end

    should "be able to create with literal password" do
      consumer = Analog::ThirdPartyApi::Coolsavings::Member.create_with_literal_password("yo@example.com", "my_literal_password")
      assert_equal "yo@example.com", consumer.email
      assert_equal Digest::MD5.hexdigest("my_literal_password"), consumer.md5password
    end

  end

  context "authentic?" do

    should "return true when no exceptions occur" do
      member = Analog::ThirdPartyApi::Coolsavings::Member.new("yo@yahoo.com", "mypassm5")
      member.expects(:get_attributes!).returns({})
      assert member.authentic?
    end

    should "return false when ErrorResponse is raised" do
      member = Analog::ThirdPartyApi::Coolsavings::Member.new("yo@yahoo.com", "mypassm5")
      member.expects(:get_attributes!).raises(Analog::ThirdPartyApi::Coolsavings::ErrorResponse.new([]))
      assert !member.authentic?
    end

    should "allow InvalidResponse to propagate" do
      member = Analog::ThirdPartyApi::Coolsavings::Member.new("yo@yahoo.com", "mypassm5")
      member.expects(:get_attributes!).raises(Analog::ThirdPartyApi::Coolsavings::InvalidResponse.new)
      assert_raises Analog::ThirdPartyApi::Coolsavings::InvalidResponse do
        assert !member.authentic?
      end
    end

  end

end
