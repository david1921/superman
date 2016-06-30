require File.dirname(__FILE__) + "/../../../../models_helper"

require 'string_extensions'

# hydra class Consumers::AfterCreateStrategy::CoolsavingsTest

module Consumers
  module AfterCreateStrategy
    class CoolsavingsTest < Test::Unit::TestCase

      context "execute" do
        should "not attempt to create member at coolsavings if member already exists" do
          consumer = stub
          consumer.stubs(:email).returns("yo@yahoo.com")
          consumer.stubs(:password).returns("foobar")
          consumer.stubs(:attributes).returns({})
          Consumers::Md5Password.expects(:md5_password).with("foobar").returns("foobar")
          member = stub
          member.expects(:authentic? => true)
          member.expects(:set_attributes!).never
          strategy = ::Consumers::AfterCreateStrategy::Coolsavings.new
          strategy.stubs(:create_member).returns(member)
          strategy.execute(consumer)
        end
      end

    end
  end
end

