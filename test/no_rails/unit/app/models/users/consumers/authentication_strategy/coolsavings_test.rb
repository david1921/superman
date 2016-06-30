require File.dirname(__FILE__) + "/../../../../models_helper"

require 'string_extensions'
require 'timecop'

class CoolSavingsTest < Test::Unit::TestCase

  context "before authentication" do

    setup do
      @strategy = Consumers::AuthenticationStrategy::Coolsavings.new
      @email = "yo@yahoo.com"
      @password = "mypass"
      @member_attrs = stub
      @publisher = stub(:id => 4)
    end

    should "do nothing if authentication fails" do
      @strategy.expects(:member_attributes).with(@email, @password).returns(@member_attrs)
      @strategy.expects(:authenticated?).with(@member_attrs).returns(false)
      @strategy.before_authentication(@publisher, @email, @password)
    end

    should "create the consumer when authentication succeeds" do
      @strategy.expects(:member_attributes).with(@email, @password).returns(@member_attrs)
      @strategy.expects(:authenticated?).with(@member_attrs).returns(true)
      @strategy.expects(:create_or_update_consumer).with(@publisher, @email, @member_attrs, @password).returns(stub)
      @strategy.before_authentication(@publisher, @email, @password)
    end

  end

  context "authenticated?" do

    should "return false when authentication has failed" do
      strategy = Consumers::AuthenticationStrategy::Coolsavings.new
      assert_equal false, strategy.authenticated?("AUTHENTICATION_FAILED")
    end

    should "return true when authentication has failed" do
      strategy = Consumers::AuthenticationStrategy::Coolsavings.new
      assert_equal true, strategy.authenticated?(stub)
    end

  end

  context "member_attributes" do

    should "call retrieve_member_attributes properly but only once" do
      strategy = Consumers::AuthenticationStrategy::Coolsavings.new
      strategy.expects(:retrieve_member_attributes).with("yo@yahoo.com", "mypass").returns({ "SOME_KEY" => "SOME_VALUE" }).once
      result1 = strategy.member_attributes("yo@yahoo.com", "mypass")
      result2 = strategy.member_attributes("yo@yahoo.com", "mypass")
      assert_equal result1["SOME_KEY"], "SOME_VALUE"
      assert_equal result1, result2
    end

  end

  context "retrieve_member_attributes" do

    should "return attributes from the retrieved member" do
      member = stub("member", :get_attributes! => { "ATTR_KEY", "ATTR_VAL" })
      strategy = Consumers::AuthenticationStrategy::Coolsavings.new
      strategy.stubs(:create_member => member)
      actual = strategy.retrieve_member_attributes("not_relevant@yahoo.com", "not_relevant_password")
      assert_equal({ "ATTR_KEY", "ATTR_VAL" }, actual)
    end

    should "return AUTHENTICATION_FAILED when ErrorResponse is raised" do
      member = stub("member")
      member.stubs(:get_attributes!).raises(Analog::ThirdPartyApi::Coolsavings::ErrorResponse)
      strategy = Consumers::AuthenticationStrategy::Coolsavings.new
      strategy.stubs(:create_member => member)
      actual = strategy.retrieve_member_attributes("not_relevant@yahoo.com", "not_relevant_password")
      assert_equal "AUTHENTICATION_FAILED", actual
    end

    should "return AUTHENTICATION_FAILED when email is blank" do
      strategy = Consumers::AuthenticationStrategy::Coolsavings.new
      strategy.stubs(:create_member => stub)
      actual = strategy.retrieve_member_attributes("", "not_relevant_password")
      assert_equal "AUTHENTICATION_FAILED", actual
    end

    should "return AUTHENTICATION_FAILED when password is blank" do
      strategy = Consumers::AuthenticationStrategy::Coolsavings.new
      strategy.stubs(:create_member => stub)
      actual = strategy.retrieve_member_attributes("not_relevant@yahoo.com", "")
      assert_equal "AUTHENTICATION_FAILED", actual
    end

  end

  context "create_or_update_consumer" do

    should "update the consumer's attributes if the consumer already exists" do
      publisher = stub(:id => 45)
      email = "yo@yahoo.com"
      member_attrs = stub
      password = "mypass"
      new_attrs = stub
      consumer = mock("consumer")
      consumer.expects(:update_attributes).with(new_attrs)
      strategy = Consumers::AuthenticationStrategy::Coolsavings.new
      strategy.expects(:analog_attributes_post_authentication).with(member_attrs, password).returns(new_attrs)
      strategy.expects(:find_for_authentication).with(publisher, email).returns(consumer)
      strategy.create_or_update_consumer(publisher, email, member_attrs, password)
    end

    should "create a new consumer if the consumer does not yet exist" do
      Timecop.freeze do
        publisher = stub(:id => 45)
        email = "yo@yahoo.com"
        member_attrs = { "EMAIL" => email }
        password = "mypass"
        new_attrs = { "email" => email }
        strategy = Consumers::AuthenticationStrategy::Coolsavings.new
        strategy.expects(:analog_attributes_post_authentication).with(member_attrs, password).returns(new_attrs)
        strategy.expects(:find_for_authentication).with(publisher, email).returns(nil)
        strategy.expects(:create_consumer).with({ "publisher_id" => publisher.id, "email" => email, "activated_at" => Time.zone.now })
        strategy.create_or_update_consumer(publisher, email, member_attrs, password)
      end
    end

  end

  context "analog_attributes_post_authentication" do

    should "convert attributes add an non-md5'd password to the attributes" do
      Timecop.freeze(Time.zone.now) do
        member_attrs = { "EMAIL" => "yo@yahoo.com" }
        strategy = Consumers::AuthenticationStrategy::Coolsavings.new
        expected = { "password" => "mypass",
                     "password_confirmation" => "mypass",
                     "active" => true,
                     "email" => "yo@yahoo.com",
                     "agree_to_terms" => true,
                     "force_password_reset" => false }
        assert_equal(expected, strategy.analog_attributes_post_authentication(member_attrs, "mypass"))
      end
    end

  end

  context "update_consumer_attributes" do
    should "set force_password_reset to false" do
      strategy = Consumers::AuthenticationStrategy::Coolsavings.new
      consumer = mock
      attrs = stub
      consumer.expects(:update_attributes).with(attrs)
      strategy.update_consumer_attributes(consumer, attrs)
    end
  end


end

