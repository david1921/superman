require File.dirname(__FILE__) + "/../../models_helper"

# hydra class Publishers::FindersTest
module Publishers
  class FindersTest < Test::Unit::TestCase

    context "find_consumer_by_email" do

      setup do
        @publisher = stub
        @publisher.extend ::Publishers::Finders::InstanceMethods
      end

      should "delegate to consumers" do
        consumers = mock("consumers association")
        consumers.expects(:find_by_email).with("yo@yahoo.com")
        @publisher.stubs(:consumers => consumers)
        @publisher.find_consumer_by_email("yo@yahoo.com")
      end

    end

    context "find_consumer_in_publishing_group_by_email" do

      setup do
        @publisher = stub
        @publisher.extend ::Publishers::Finders::InstanceMethods
      end

      should "return nil if publishing_group is nil" do
        @publisher.stubs(:publishing_group => nil)
        assert_nil @publisher.find_consumer_in_publishing_group_by_email("foo@yahoo.com")
      end

      should "delegate to publishing_group if not nil" do
        publishing_group = mock("publishing_group")
        consumers = mock("consumers association")
        consumers.expects(:find_by_email).with("foo@yahoo.com")
        publishing_group.expects(:consumers => consumers)
        @publisher.expects(:publishing_group).twice.returns(publishing_group)
        @publisher.find_consumer_in_publishing_group_by_email("foo@yahoo.com")
      end

    end

    context "find_consumer_in_publishing_group_by_id" do

      setup do
        @publisher = stub
        @publisher.extend ::Publishers::Finders::InstanceMethods
      end

      should "return nil if publishing_group is nil" do
        @publisher.stubs(:publishing_group => nil)
        assert_nil @publisher.find_consumer_in_publishing_group_by_id(12345)
      end

      should "delegate to publishing_group if not nil" do
        publishing_group = mock("publishing_group")
        consumers = mock("consumers association")
        consumers.expects(:find_by_id).with(12345)
        publishing_group.expects(:consumers => consumers)
        @publisher.expects(:publishing_group).twice.returns(publishing_group)
        @publisher.find_consumer_in_publishing_group_by_id(12345)
      end

    end

    context "find_consumer_by_email_if_access_allowed" do

      setup do
        @publisher = stub
        @publisher.extend ::Publishers::Finders::InstanceMethods
        @email = stub("email")
        @consumer = stub("consumer")
      end

      should "find publisher by email" do
        @publisher.expects(:find_consumer_by_email).with(@email).returns(@consumer)
        actual = @publisher.find_consumer_by_email_if_access_allowed(@email)
        assert_equal @consumer, actual
      end

      should "attempt to find in the publishing_group if flag set" do
        @publisher.expects(:allow_single_sign_on?).returns(true)
        @publisher.stubs(:find_consumer_by_email).returns(nil)
        @publisher.expects(:find_consumer_in_publishing_group_by_email).returns(@consumer)
        actual = @publisher.find_consumer_by_email_if_access_allowed(@email)
        assert_equal @consumer, actual
      end

      should "not attempt to find in publishing_group if flag is false" do
        @publisher.expects(:allow_single_sign_on?).returns(false)
        @publisher.stubs(:find_consumer_by_email).returns(nil)
        @publisher.expects(:find_consumer_in_publishing_group_by_email).never
        actual = @publisher.find_consumer_by_email_if_access_allowed(@email)
        assert_nil actual
      end

    end

    context "find_consumer_by_id_if_access_allowed" do

      setup do
        @publisher = stub
        @publisher.extend ::Publishers::Finders::InstanceMethods
        @consumer = stub("consumer")
      end

      should "find publisher by id" do
        @publisher.expects(:find_consumer_by_id).with(12345).returns(@consumer)
        actual = @publisher.find_consumer_by_id_if_access_allowed(12345)
        assert_equal @consumer, actual
      end

      should "attempt to find in the publishing_group if flag set" do
        @publisher.expects(:allow_single_sign_on?).returns(true)
        @publisher.stubs(:find_consumer_by_id).returns(nil)
        @publisher.expects(:find_consumer_in_publishing_group_by_id).with(12345).returns(@consumer)
        actual = @publisher.find_consumer_by_id_if_access_allowed(12345)
        assert_equal @consumer, actual
      end

      should "not attempt to find in publishing_group if flag is false" do
        @publisher.expects(:allow_single_sign_on?).returns(false)
        @publisher.stubs(:find_consumer_by_id).returns(nil)
        @publisher.expects(:find_consumer_in_publishing_group_by_id).never
        actual = @publisher.find_consumer_by_id_if_access_allowed(12345)
        assert_nil actual
      end

    end

    context "find_consumer_by_email_if_force_password_reset" do

      setup do
        @publisher = stub
        @publisher.extend ::Publishers::Finders::InstanceMethods
        @consumer = stub("consumer")
      end

      should "return nil if no consumer matches the email" do
        @publisher.stubs(:find_consumer_by_email_if_access_allowed).returns(nil)
        assert_nil @publisher.find_consumer_by_email_if_force_password_reset("yo@yahoo.com")
      end

      should "return consumer if found and force_password_reset is true" do
        @consumer.stubs(:force_password_reset? => true)
        @publisher.stubs(:find_consumer_by_email_if_access_allowed).returns(@consumer)
        assert_equal @consumer, @publisher.find_consumer_by_email_if_force_password_reset("yo@yahoo.com")
      end

      should "return not consumer if found and force_password_reset is false" do
        @consumer.stubs(:force_password_reset? => false)
        @publisher.stubs(:find_consumer_by_email_if_access_allowed).returns(@consumer)
        assert_nil @publisher.find_consumer_by_email_if_force_password_reset("yo@yahoo.com")
      end

    end

    context "find_consumer_by_email_for_authentication" do

      setup do
        @publisher = stub
        @publisher.extend ::Publishers::Finders::InstanceMethods
        @consumer = stub("consumer")
      end

      context "given allow_single_sign_on" do
        setup do
          @publisher.expects(:allow_single_sign_on?).returns(true)
          @publisher.expects(:allow_publisher_switch_on_login?).returns(false)
        end

        should "attempt to find in publisher then publishing group" do
          @publisher.expects(:find_consumer_by_email).returns(nil)
          @publisher.expects(:find_consumer_in_publishing_group_by_email).returns(nil)
          assert_nil @publisher.find_consumer_by_email_for_authentication("foo@bar.com")
        end
      end

      context "given allow_publisher_switch_on_login" do
        setup do
          @publisher.expects(:allow_single_sign_on?).returns(false)
          @publisher.expects(:allow_publisher_switch_on_login?).returns(true)
        end

        should "attempt to find in publishing group" do
          @publisher.expects(:find_consumer_by_email).returns(nil)
          @publisher.expects(:find_consumer_in_publishing_group_by_email).returns(nil)
          assert_nil @publisher.find_consumer_by_email_for_authentication("foo@bar.com")
        end
      end

      context "given neither allow_single_sign_on or allow_publisher_switch_on_login" do
        setup do
          @publisher.expects(:allow_single_sign_on?).returns(false)
          @publisher.expects(:allow_publisher_switch_on_login?).returns(false)
        end

        should "not attempt to find in publishing group" do
          @publisher.expects(:find_consumer_by_email).returns(nil)
          @publisher.expects(:find_consumer_in_publishing_group_by_email).never
          assert_nil @publisher.find_consumer_by_email_for_authentication("foo@bar.com")
        end
      end

    end

  end
end

